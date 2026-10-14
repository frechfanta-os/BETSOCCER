"""
HTML and Structured Data (JSON-LD) Scraper for BETSOCCER.
Extracts sports matches, fixtures, and results from public HTML pages.
Supports standard HTML tables and Schema.org SportsEvent JSON-LD.
"""

import json
import re
import logging
from typing import List, Tuple, Optional, Dict, Any
from datetime import datetime, timezone
from bs4 import BeautifulSoup, Tag

from crawl4ai import AsyncWebCrawler

from .base import BaseSource
from ..models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedMatch,
    NormalizedResult,
    NormalizedStatistic,
    SyncReport,
)
from ..validator import DataValidator
from ..config import get_current_utc

logger = logging.getLogger("betsoccer.collector.html_scraper")


class HtmlSportsParser:
    """Parser for sports matches embedded in HTML (Tables and JSON-LD SportsEvent)."""

    @staticmethod
    def parse_score(score_str: Optional[str]) -> Tuple[Optional[int], Optional[int]]:
        """
        Parses score string formatted as '2 - 0', '1:1', '3-2', etc.
        Returns (home_score, away_score) or (None, None).
        """
        if not score_str:
            return None, None
        s = score_str.strip()
        if s in ("-", "vs", "v", "TBD", "postp.", "canc.", ""):
            return None, None
        
        # Match pattern "X - Y" or "X:Y" or "X-Y"
        m = re.match(r"^(\d+)\s*[-:]\s*(\d+)$", s)
        if m:
            return int(m.group(1)), int(m.group(2))
        return None, None

    @staticmethod
    def parse_kickoff(date_str: Optional[str], time_str: Optional[str] = None) -> Optional[str]:
        """
        Parses date and time strings into UTC ISO-8601 'YYYY-MM-DDTHH:MM:SSZ'.
        Supports:
        - ISO-8601 strings (e.g. '2026-10-18T16:30:00Z', '2026-10-18T16:30:00+00:00')
        - 'YYYY-MM-DD'
        - 'DD/MM/YYYY'
        - 'DD.MM.YYYY'
        """
        if not date_str:
            return None

        clean_date = date_str.strip()
        clean_time = time_str.strip() if time_str else "00:00"

        # Check if already ISO format with T
        if "T" in clean_date:
            try:
                # Handle trailing Z or offsets
                norm_iso = clean_date.replace("Z", "+00:00")
                dt = datetime.fromisoformat(norm_iso)
                return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            except Exception:
                pass

        # Try common date formats
        for fmt in ("%Y-%m-%d", "%d/%m/%Y", "%d.%m.%Y", "%Y/%m/%d"):
            try:
                if clean_time and ":" in clean_time:
                    combined = f"{clean_date} {clean_time}"
                    dt = datetime.strptime(combined, f"{fmt} %H:%M")
                else:
                    dt = datetime.strptime(clean_date, fmt)
                return dt.replace(tzinfo=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
            except ValueError:
                continue

        logger.warning(f"Could not parse kickoff date: '{date_str}', time: '{time_str}'")
        return None

    @staticmethod
    def normalize_status(status_str: Optional[str], has_score: bool) -> str:
        """Normalizes match status into standard BETSOCCER status."""
        if not status_str:
            return "finished" if has_score else "upcoming"
        
        low = status_str.strip().lower()
        if any(term in low for term in ("finish", "ft", "ended", "completed", "terminé", "end")):
            return "finished"
        if any(term in low for term in ("live", "in play", "1h", "2h", "ht", "direct")):
            return "live"
        if any(term in low for term in ("postponed", "reporté")):
            return "postponed"
        if any(term in low for term in ("cancelled", "abandoned", "annulé")):
            return "cancelled"
        if any(term in low for term in ("upcoming", "scheduled", "à venir")):
            return "upcoming"
        
        return "finished" if has_score else "upcoming"

    @classmethod
    def extract_from_json_ld(
        cls,
        soup: BeautifulSoup,
        sport_id: str,
        competition_id: str,
        season_id: str,
        provider_id: str,
    ) -> List[NormalizedMatch]:
        """Extracts SportsEvent objects from Schema.org JSON-LD scripts."""
        matches: List[NormalizedMatch] = []
        scripts = soup.find_all("script", attrs={"type": "application/ld+json"})

        for script in scripts:
            if not script.string:
                continue
            try:
                data = json.loads(script.string)
            except Exception as e:
                logger.warning(f"Failed to parse JSON-LD script content: {e}")
                continue

            items = data if isinstance(data, list) else [data]
            for item in items:
                if not isinstance(item, dict):
                    continue
                if item.get("@type") != "SportsEvent":
                    continue

                home_team_info = item.get("homeTeam") or {}
                away_team_info = item.get("awayTeam") or {}

                home_name = home_team_info.get("name") if isinstance(home_team_info, dict) else str(home_team_info)
                away_name = away_team_info.get("name") if isinstance(away_team_info, dict) else str(away_team_info)

                if not home_name or not away_name:
                    # Fallback to name split "Team A vs Team B"
                    name_str = item.get("name", "")
                    if " vs " in name_str:
                        parts = name_str.split(" vs ")
                        home_name, away_name = parts[0].strip(), parts[1].strip()

                if not home_name or not away_name:
                    continue

                start_date = item.get("startDate")
                kickoff = cls.parse_kickoff(start_date)
                if not kickoff:
                    continue

                home_id = f"team_{re.sub(r'[^a-z0-9]+', '_', home_name.lower()).strip('_')}"
                away_id = f"team_{re.sub(r'[^a-z0-9]+', '_', away_name.lower()).strip('_')}"

                # Extract score if available
                sub_event = item.get("subEvent") or {}
                home_score = sub_event.get("homeScore") if isinstance(sub_event, dict) else None
                away_score = sub_event.get("awayScore") if isinstance(sub_event, dict) else None

                event_status = item.get("eventStatus", "")
                status = cls.normalize_status(event_status, has_score=(home_score is not None and away_score is not None))

                match_id = f"match_ld_{provider_id}_{home_id}_{away_id}_{kickoff[:10]}"
                result = None
                if home_score is not None and away_score is not None and status == "finished":
                    winner_id = None
                    if home_score > away_score:
                        winner_id = home_id
                    elif away_score > home_score:
                        winner_id = away_id

                    result = NormalizedResult(
                        id=f"res_{match_id}",
                        match_id=match_id,
                        home_score=int(home_score),
                        away_score=int(away_score),
                        winner_team_id=winner_id,
                    )

                match = NormalizedMatch(
                    id=match_id,
                    sport_id=sport_id,
                    competition_id=competition_id,
                    season_id=season_id,
                    home_team_id=home_id,
                    home_team_name=home_name,
                    away_team_id=away_id,
                    away_team_name=away_name,
                    utc_kickoff=kickoff,
                    status=status,
                    source_provider=provider_id,
                    source_match_id=match_id,
                    result=result,
                )
                matches.append(match)

        return matches

    @classmethod
    def extract_from_tables(
        cls,
        soup: BeautifulSoup,
        sport_id: str,
        competition_id: str,
        season_id: str,
        provider_id: str,
    ) -> List[NormalizedMatch]:
        """Extracts match rows from HTML tables."""
        matches: List[NormalizedMatch] = []

        # Find rows with class 'match-row' or table rows
        rows = soup.find_all("tr", class_=re.compile(r"match[-_]?row|fixture[-_]?row"))
        if not rows:
            # Look inside any table tbody
            for table in soup.find_all("table"):
                tbody = table.find("tbody") or table
                potential_rows = tbody.find_all("tr")
                for r in potential_rows:
                    if r.find_all("td"):
                        rows.append(r)

        for row in rows:
            # Check for dedicated class elements first
            date_cell = row.find(class_=re.compile(r"date|kickoff|time"))
            time_cell = row.find(class_=re.compile(r"time"))
            home_cell = row.find(class_=re.compile(r"home|team[-_]?1|host"))
            away_cell = row.find(class_=re.compile(r"away|team[-_]?2|guest"))
            score_cell = row.find(class_=re.compile(r"score|result"))
            status_cell = row.find(class_=re.compile(r"status|state"))

            home_name = home_cell.get_text(strip=True) if home_cell else None
            away_name = away_cell.get_text(strip=True) if away_cell else None
            score_text = score_cell.get_text(strip=True) if score_cell else None
            date_text = date_cell.get_text(strip=True) if date_cell else None
            time_text = time_cell.get_text(strip=True) if (time_cell and time_cell != date_cell) else None
            status_text = status_cell.get_text(strip=True) if status_cell else None

            # Fallback to positional columns if class names not matched
            cells = row.find_all("td")
            if (not home_name or not away_name) and len(cells) >= 5:
                # Common pattern: Date | Time | Home | Score | Away | (Status)
                date_text = date_text or cells[0].get_text(strip=True)
                time_text = time_text or cells[1].get_text(strip=True)
                home_name = home_name or cells[2].get_text(strip=True)
                score_text = score_text or cells[3].get_text(strip=True)
                away_name = away_name or cells[4].get_text(strip=True)
                if len(cells) >= 6:
                    status_text = status_text or cells[5].get_text(strip=True)

            if not home_name or not away_name or not date_text:
                continue

            kickoff = cls.parse_kickoff(date_text, time_text)
            if not kickoff:
                continue

            home_score, away_score = cls.parse_score(score_text)
            has_score = (home_score is not None and away_score is not None)
            status = cls.normalize_status(status_text, has_score=has_score)

            home_id = f"team_{re.sub(r'[^a-z0-9]+', '_', home_name.lower()).strip('_')}"
            away_id = f"team_{re.sub(r'[^a-z0-9]+', '_', away_name.lower()).strip('_')}"
            match_id = f"match_tbl_{provider_id}_{home_id}_{away_id}_{kickoff[:10]}"

            result = None
            if has_score and status == "finished":
                winner_id = None
                if home_score > away_score:
                    winner_id = home_id
                elif away_score > home_score:
                    winner_id = away_id

                result = NormalizedResult(
                    id=f"res_{match_id}",
                    match_id=match_id,
                    home_score=home_score,
                    away_score=away_score,
                    winner_team_id=winner_id,
                )

            match = NormalizedMatch(
                id=match_id,
                sport_id=sport_id,
                competition_id=competition_id,
                season_id=season_id,
                home_team_id=home_id,
                home_team_name=home_name,
                away_team_id=away_id,
                away_team_name=away_name,
                utc_kickoff=kickoff,
                status=status,
                source_provider=provider_id,
                source_match_id=match_id,
                result=result,
            )
            matches.append(match)

        return matches

    @classmethod
    def parse_html(
        cls,
        html_content: str,
        sport_id: str,
        competition_id: str,
        season_id: str,
        provider_id: str = "html_scraper",
    ) -> List[NormalizedMatch]:
        """
        Parses HTML string, extracting both JSON-LD and HTML table matches,
        and runs them through DataValidator.
        """
        if not html_content or not html_content.strip():
            logger.warning("Empty HTML content passed to parse_html.")
            return []

        try:
            soup = BeautifulSoup(html_content, "html.parser")
        except Exception as e:
            logger.error(f"HTML parsing failed: {e}")
            return []

        # 1. Extract JSON-LD matches
        ld_matches = cls.extract_from_json_ld(
            soup=soup,
            sport_id=sport_id,
            competition_id=competition_id,
            season_id=season_id,
            provider_id=provider_id,
        )

        # 2. Extract Table matches
        tbl_matches = cls.extract_from_tables(
            soup=soup,
            sport_id=sport_id,
            competition_id=competition_id,
            season_id=season_id,
            provider_id=provider_id,
        )

        all_matches = ld_matches + tbl_matches
        valid_matches: List[NormalizedMatch] = []

        # Validate with DataValidator
        for m in all_matches:
            is_valid, reason = DataValidator.validate_match(m)
            if is_valid:
                valid_matches.append(m)
            else:
                logger.warning(f"Discarding invalid match from HTML ({m.id}): {reason}")

        return valid_matches


class HtmlScraperSource(BaseSource):
    """Crawl4AI Autonomous HTML Scraper Source."""

    def __init__(
        self,
        urls: Optional[List[str]] = None,
        default_sport_id: str = "sport_football",
        default_competition_id: str = "comp_html_default",
        default_season_id: str = "season_2026",
        provider_id: str = "html_scraper",
        display_name: str = "Public HTML Sports Scraper",
        max_retries: int = 3,
        rate_limit_delay: float = 1.0,
    ):
        super().__init__(
            provider_id=provider_id,
            display_name=display_name,
            max_retries=max_retries,
            rate_limit_delay=rate_limit_delay,
        )
        self.urls = urls or []
        self.default_sport_id = default_sport_id
        self.default_competition_id = default_competition_id
        self.default_season_id = default_season_id

    async def collect(
        self, crawler: AsyncWebCrawler
    ) -> Tuple[
        List[NormalizedSport],
        List[NormalizedCompetition],
        List[NormalizedSeason],
        List[NormalizedMatch],
        SyncReport,
    ]:
        start_time = get_current_utc()
        all_matches: List[NormalizedMatch] = []
        errors: List[str] = []

        for url in self.urls:
            try:
                html_content = await self.fetch_with_crawl4ai(crawler, url)
                matches = HtmlSportsParser.parse_html(
                    html_content=html_content,
                    sport_id=self.default_sport_id,
                    competition_id=self.default_competition_id,
                    season_id=self.default_season_id,
                    provider_id=self.provider_id,
                )
                all_matches.extend(matches)
            except Exception as e:
                logger.error(f"Error scraping {url}: {e}")
                errors.append(f"{url}: {e}")

        finish_time = get_current_utc()
        duration_ms = int((finish_time - start_time).total_seconds() * 1000)
        status = "SUCCESS" if not errors else ("PARTIAL" if all_matches else "ERROR")

        report = SyncReport(
            provider_id=self.provider_id,
            key=f"sync_{self.provider_id}_{start_time.strftime('%Y%m%d_%H%M%S')}",
            status=status,
            records_synced=len(all_matches),
            started_at=start_time,
            finished_at=finish_time,
            duration_ms=duration_ms,
            error_message="; ".join(errors) if errors else None,
            details={"urls_crawled": len(self.urls)},
        )

        sports = [
            NormalizedSport(
                id=self.default_sport_id,
                name="Football",
                code="SOCCER",
                source_provider=self.provider_id,
            )
        ]
        competitions = [
            NormalizedCompetition(
                id=self.default_competition_id,
                sport_id=self.default_sport_id,
                name="HTML Scraped Competition",
                code="HTML_COMP",
                source_provider=self.provider_id,
            )
        ]
        seasons = [
            NormalizedSeason(
                id=self.default_season_id,
                competition_id=self.default_competition_id,
                year_label="2026/27",
                is_current=True,
            )
        ]

        return sports, competitions, seasons, all_matches, report
