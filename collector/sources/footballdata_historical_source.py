"""
Football-Data.co.uk Historical Season connector using Crawl4AI / HTTP stream.
Fetches verified historical match results, halftime scores, and in-depth match statistics
(shots, shots on target, corners, fouls, cards, referee) from open data CSV archives.
"""

import csv
import io
import logging
from datetime import datetime, timezone
from typing import List, Tuple, Dict, Any, Optional

from crawl4ai import AsyncWebCrawler

from .base import BaseSource
from ..config import get_current_utc
from ..models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedMatch,
    NormalizedResult,
    NormalizedStatistic,
    SyncReport,
)

logger = logging.getLogger("betsoccer.collector.footballdata_historical")

HISTORICAL_LEAGUE_MAP = {
    "E0": {
        "comp_id": "comp_fduk_e0",
        "name": "English Premier League",
        "code": "EPL",
        "country": "England",
        "country_code": "GB",
        "tier": 1,
    },
    "D1": {
        "comp_id": "comp_fduk_d1",
        "name": "1. Bundesliga",
        "code": "BL1",
        "country": "Germany",
        "country_code": "DE",
        "tier": 1,
    },
    "SP1": {
        "comp_id": "comp_fduk_sp1",
        "name": "La Liga",
        "code": "LL",
        "country": "Spain",
        "country_code": "ES",
        "tier": 1,
    },
    "I1": {
        "comp_id": "comp_fduk_i1",
        "name": "Serie A",
        "code": "SA",
        "country": "Italy",
        "country_code": "IT",
        "tier": 1,
    },
    "F1": {
        "comp_id": "comp_fduk_f1",
        "name": "Ligue 1",
        "code": "L1",
        "country": "France",
        "country_code": "FR",
        "tier": 1,
    },
}


class FootballDataHistoricalSource(BaseSource):
    def __init__(
        self,
        seasons: Optional[List[str]] = None,
        leagues: Optional[List[str]] = None,
        max_retries: int = 3,
        rate_limit_delay: float = 1.0,
    ):
        super().__init__(
            provider_id="football_data_co_uk",
            display_name="Football-Data.co.uk Historical (CSV)",
            max_retries=max_retries,
            rate_limit_delay=rate_limit_delay,
        )
        # Default: 2023-2024 season code '2324'
        self.seasons = seasons or ["2324"]
        # Default: Premier League ('E0'), La Liga ('SP1'), Serie A ('I1'), Ligue 1 ('F1')
        self.leagues = leagues or ["E0", "SP1", "I1", "F1"]

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

        try:
            for season_code in self.seasons:
                # Season year label: e.g. "2324" -> "2023/24"
                start_yr = 2000 + int(season_code[:2])
                end_yr_short = int(season_code[2:])
                season_label = f"{start_yr}/{end_yr_short:02d}"

                for div in self.leagues:
                    league_meta = HISTORICAL_LEAGUE_MAP.get(div)
                    if not league_meta:
                        continue

                    comp_id = league_meta["comp_id"]
                    if comp_id not in competitions:
                        competitions[comp_id] = NormalizedCompetition(
                            id=comp_id,
                            sport_id=sport.id,
                            name=league_meta["name"],
                            code=league_meta["code"],
                            country=league_meta["country"],
                            country_code=league_meta["country_code"],
                            tier=league_meta["tier"],
                            source_provider=self.provider_id,
                        )

                    season_id = f"season_{comp_id}_{start_yr}"
                    if season_id not in seasons:
                        seasons[season_id] = NormalizedSeason(
                            id=season_id,
                            competition_id=comp_id,
                            year_label=season_label,
                            is_current=False,
                            start_date=f"{start_yr}-08-01",
                            end_date=f"{start_yr + 1}-05-31",
                        )

                    url = f"https://www.football-data.co.uk/mmz4281/{season_code}/{div}.csv"
                    logger.info(f"[{self.provider_id}] Fetching historical CSV: {url}")
                    try:
                        raw_csv = await self.fetch_with_crawl4ai(crawler, url)
                        cleaned_csv = raw_csv.strip().lstrip("\ufeff")
                        reader = csv.DictReader(io.StringIO(cleaned_csv))

                        div_matches_count = 0
                        for row in reader:
                            match = self._normalize_csv_row(row, sport.id, comp_id, season_id, div)
                            if match:
                                matches.append(match)
                                div_matches_count += 1
                                synced_count += 1

                        logger.info(
                            f"[{self.provider_id}] Parsed {div_matches_count} matches for {div} ({season_label})"
                        )
                    except Exception as e:
                        logger.error(f"[{self.provider_id}] Error fetching {url}: {e}")
                        if error_msg is None:
                            error_msg = f"{div}: {str(e)}"
                        else:
                            error_msg += f"; {div}: {str(e)}"

        except Exception as e:
            logger.error(f"[{self.provider_id}] Global collection error: {e}")
            error_msg = str(e)

        finished_time = get_current_utc()
        duration_ms = int((finished_time - start_time).total_seconds() * 1000)

        report = SyncReport(
            provider_id=self.provider_id,
            key=f"sync_{self.provider_id}_hist_{start_time.strftime('%Y%m%d_%H%M%S')}",
            status="SUCCESS" if error_msg is None else ("PARTIAL" if synced_count > 0 else "ERROR"),
            records_synced=synced_count,
            started_at=start_time,
            finished_at=finished_time,
            duration_ms=duration_ms,
            error_message=error_msg,
            details={"leagues": self.leagues, "seasons": self.seasons, "matches_parsed": len(matches)},
        )

        return [sport], list(competitions.values()), list(seasons.values()), matches, report

    def _normalize_csv_row(
        self, row: Dict[str, Any], sport_id: str, comp_id: str, season_id: str, div: str
    ) -> Optional[NormalizedMatch]:
        try:
            date_str = (row.get("Date") or "").strip()
            time_str = (row.get("Time") or "").strip() or "15:00"
            home_team = (row.get("HomeTeam") or "").strip()
            away_team = (row.get("AwayTeam") or "").strip()

            if not (date_str and home_team and away_team):
                return None

            # Parse date: format DD/MM/YYYY
            date_parts = date_str.split("/")
            if len(date_parts) != 3:
                return None
            day, month, year = int(date_parts[0]), int(date_parts[1]), int(date_parts[2])
            if year < 100:
                year += 2000

            time_parts = time_str.split(":")
            hour = int(time_parts[0]) if len(time_parts) > 0 and time_parts[0].isdigit() else 15
            minute = int(time_parts[1]) if len(time_parts) > 1 and time_parts[1].isdigit() else 0

            utc_dt = datetime(year, month, day, hour, minute, tzinfo=timezone.utc)
            utc_kickoff = utc_dt.strftime("%Y-%m-%dT%H:%M:%SZ")

            home_id = f"team_{home_team.lower().replace(' ', '_').replace('.', '').replace('-', '_')}"
            away_id = f"team_{away_team.lower().replace(' ', '_').replace('.', '').replace('-', '_')}"
            match_id = f"fduk_hist_{div}_{home_id}_{away_id}_{int(utc_dt.timestamp())}"

            # Scores
            fthg_raw = row.get("FTHG")
            ftag_raw = row.get("FTAG")
            home_score = int(fthg_raw) if fthg_raw not in (None, "") and fthg_raw.isdigit() else None
            away_score = int(ftag_raw) if ftag_raw not in (None, "") and ftag_raw.isdigit() else None

            status = "finished" if (home_score is not None and away_score is not None) else "upcoming"

            result = None
            if status == "finished":
                hthg_raw = row.get("HTHG")
                htag_raw = row.get("HTAG")
                home_ht = int(hthg_raw) if hthg_raw not in (None, "") and hthg_raw.isdigit() else None
                away_ht = int(htag_raw) if htag_raw not in (None, "") and htag_raw.isdigit() else None

                winner_team_id = None
                if home_score > away_score:
                    winner_team_id = home_id
                elif away_score > home_score:
                    winner_team_id = away_id

                result = NormalizedResult(
                    id=f"res_{match_id}",
                    match_id=match_id,
                    home_score=home_score,
                    away_score=away_score,
                    home_halftime_score=home_ht,
                    away_halftime_score=away_ht,
                    winner_team_id=winner_team_id,
                )

            # In-depth Match Statistics
            statistics: List[NormalizedStatistic] = []
            stats_mappings = [
                ("HS", "AS", "shots"),
                ("HST", "AST", "shots_on_target"),
                ("HF", "AF", "fouls"),
                ("HC", "AC", "corners"),
                ("HY", "AY", "yellow_cards"),
                ("HR", "AR", "red_cards"),
            ]

            for h_key, a_key, metric_name in stats_mappings:
                h_val_raw = row.get(h_key)
                a_val_raw = row.get(a_key)
                if h_val_raw not in (None, "") and a_val_raw not in (None, ""):
                    try:
                        h_val = float(h_val_raw)
                        a_val = float(a_val_raw)
                        statistics.append(
                            NormalizedStatistic(
                                id=f"stat_{match_id}_{metric_name}",
                                match_id=match_id,
                                metric_name=metric_name,
                                home_value=h_val,
                                away_value=a_val,
                                raw_unit="count",
                            )
                        )
                    except ValueError:
                        pass

            referee = (row.get("Referee") or "").strip()
            if referee:
                statistics.append(
                    NormalizedStatistic(
                        id=f"stat_{match_id}_referee",
                        match_id=match_id,
                        metric_name="referee_assigned",
                        home_value=1.0,
                        away_value=1.0,
                        raw_unit=referee,
                    )
                )

            return NormalizedMatch(
                id=match_id,
                sport_id=sport_id,
                competition_id=comp_id,
                season_id=season_id,
                home_team_id=home_id,
                home_team_name=home_team,
                away_team_id=away_id,
                away_team_name=away_team,
                utc_kickoff=utc_kickoff,
                status=status,
                source_provider=self.provider_id,
                source_match_id=match_id,
                result=result,
                statistics=statistics,
            )

        except Exception as e:
            logger.debug(f"Failed to parse row: {e}")
            return None
