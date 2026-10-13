"""
Football-Data.co.uk Fixtures connector using Crawl4AI.
Fetches real-time upcoming matches and schedules for today and the upcoming week.
No hardcoded dates: ingests dynamic fixtures.csv directly from the source.
"""

import csv
import io
import logging
from datetime import datetime, timezone
from typing import List, Tuple, Dict, Any, Optional

from crawl4ai import AsyncWebCrawler

from .base import BaseSource
from ..config import get_current_utc, get_current_season_year, get_current_season_label
from ..models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedMatch,
    NormalizedStatistic,
    SyncReport,
)

logger = logging.getLogger("betsoccer.collector.footballdata_fixtures")

DIV_MAPPING = {
    "E0": ("comp_fduk_e0", "Premier League", "Angleterre", "GB"),
    "E1": ("comp_fduk_e1", "Championship", "Angleterre", "GB"),
    "E2": ("comp_fduk_e2", "League 1", "Angleterre", "GB"),
    "E3": ("comp_fduk_e3", "League 2", "Angleterre", "GB"),
    "D1": ("comp_fduk_d1", "Bundesliga", "Allemagne", "DE"),
    "D2": ("comp_fduk_d2", "2. Bundesliga", "Allemagne", "DE"),
    "SP1": ("comp_fduk_sp1", "La Liga", "Espagne", "ES"),
    "SP2": ("comp_fduk_sp2", "La Liga 2", "Espagne", "ES"),
    "I1": ("comp_fduk_i1", "Serie A", "Italie", "IT"),
    "I2": ("comp_fduk_i2", "Serie B", "Italie", "IT"),
    "F1": ("comp_fduk_f1", "Ligue 1", "France", "FR"),
    "F2": ("comp_fduk_f2", "Ligue 2", "France", "FR"),
    "N1": ("comp_fduk_n1", "Eredivisie", "Pays-Bas", "NL"),
    "B1": ("comp_fduk_b1", "Jupiler Pro League", "Belgique", "BE"),
    "P1": ("comp_fduk_p1", "Liga Portugal", "Portugal", "PT"),
    "T1": ("comp_fduk_t1", "Süper Lig", "Turquie", "TR"),
    "G1": ("comp_fduk_g1", "Super League", "Grèce", "GR"),
}


class FootballDataFixturesSource(BaseSource):
    def __init__(
        self,
        fixtures_url: str = "https://football-data.co.uk/fixtures.csv",
        max_retries: int = 3,
        rate_limit_delay: float = 1.0,
    ):
        super().__init__(
            provider_id="football_data_co_uk",
            display_name="Football-Data.co.uk Fixtures (CSV)",
            max_retries=max_retries,
            rate_limit_delay=rate_limit_delay,
        )
        self.fixtures_url = fixtures_url

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
        sport = NormalizedSport(
            id="sport_football",
            name="Football (Soccer)",
            code="SOCCER",
            icon_ref="sports_soccer",
            source_provider=self.provider_id,
        )

        competitions: Dict[str, NormalizedCompetition] = {}
        seasons: Dict[str, NormalizedSeason] = {}
        matches: List[NormalizedMatch] = []
        synced_count = 0
        error_msg = None

        current_season_label = get_current_season_label()

        try:
            csv_content = await self.fetch_with_crawl4ai(crawler, self.fixtures_url)
            # Remove HTML wrapping if any
            if "<html" in csv_content.lower():
                from bs4 import BeautifulSoup
                soup = BeautifulSoup(csv_content, "html.parser")
                pre = soup.find("pre")
                if pre and pre.text:
                    csv_content = pre.text

            # Parse CSV
            cleaned_csv = csv_content.strip().lstrip("\ufeff")
            reader = csv.DictReader(io.StringIO(cleaned_csv))
            for row in reader:
                div = (row.get("Div") or row.get("\ufeffDiv") or "").strip()
                date_str = (row.get("Date") or "").strip()
                time_str = (row.get("Time") or "").strip() or "15:00"
                home_team = (row.get("HomeTeam") or "").strip()
                away_team = (row.get("AwayTeam") or "").strip()

                if not (div and date_str and home_team and away_team):
                    continue

                comp_info = DIV_MAPPING.get(div, (f"comp_fduk_{div.lower()}", f"Division {div}", "International", "INT"))
                comp_id, comp_name, comp_country, comp_cc = comp_info

                if comp_id not in competitions:
                    competitions[comp_id] = NormalizedCompetition(
                        id=comp_id,
                        sport_id=sport.id,
                        name=comp_name,
                        code=div,
                        country=comp_country,
                        country_code=comp_cc,
                        tier=1 if div in ["E0", "D1", "SP1", "I1", "F1"] else 2,
                        source_provider=self.provider_id,
                    )
                    season_id = f"season_{comp_id}_{get_current_season_year()}"
                    seasons[season_id] = NormalizedSeason(
                        id=season_id,
                        competition_id=comp_id,
                        year_label=current_season_label,
                        is_current=True,
                    )

                season_id = f"season_{comp_id}_{get_current_season_year()}"

                # Parse Kickoff date to UTC ISO-8601
                try:
                    # Date format in fixtures.csv is DD/MM/YYYY
                    day, month, year = map(int, date_str.split("/"))
                    time_parts = time_str.split(":")
                    hour = int(time_parts[0])
                    minute = int(time_parts[1]) if len(time_parts) > 1 else 0
                    utc_dt = datetime(year, month, day, hour, minute, tzinfo=timezone.utc)
                    utc_kickoff = utc_dt.isoformat()
                except Exception as e:
                    logger.debug(f"Date parse error for {date_str} {time_str}: {e}")
                    continue

                home_id = f"team_{home_team.lower().replace(' ', '_').replace('.', '')}"
                away_id = f"team_{away_team.lower().replace(' ', '_').replace('.', '')}"
                match_id = f"fduk_{div}_{home_id}_{away_id}_{int(utc_dt.timestamp())}"

                stats = []
                referee = row.get("Referee")
                if referee:
                    stats.append(NormalizedStatistic(
                        id=f"stat_{match_id}_referee",
                        match_id=match_id,
                        metric_name="referee_assigned",
                        home_value=1.0,
                        away_value=1.0,
                        raw_unit=referee.strip(),
                    ))

                match = NormalizedMatch(
                    id=match_id,
                    sport_id=sport.id,
                    competition_id=comp_id,
                    season_id=season_id,
                    home_team_id=home_id,
                    home_team_name=home_team,
                    away_team_id=away_id,
                    away_team_name=away_team,
                    utc_kickoff=utc_kickoff,
                    status="upcoming",
                    source_provider=self.provider_id,
                    source_match_id=match_id,
                    statistics=stats,
                )
                matches.append(match)
                synced_count += 1

            logger.info(f"[{self.provider_id}] Successfully parsed {len(matches)} current fixtures.")

        except Exception as e:
            logger.error(f"[{self.provider_id}] Error in collect(): {e}")
            error_msg = str(e)

        finished_time = get_current_utc()
        duration_ms = int((finished_time - start_time).total_seconds() * 1000)

        report = SyncReport(
            provider_id=self.provider_id,
            key=f"sync_{self.provider_id}_{start_time.strftime('%Y%m%d_%H%M%S')}",
            status="SUCCESS" if error_msg is None else "ERROR",
            records_synced=synced_count,
            started_at=start_time,
            finished_at=finished_time,
            duration_ms=duration_ms,
            error_message=error_msg,
            details={"fixtures_url": self.fixtures_url, "matches_parsed": len(matches)},
        )

        return [sport], list(competitions.values()), list(seasons.values()), matches, report
