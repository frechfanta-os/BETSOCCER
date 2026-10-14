"""
OpenLigaDB connector using Crawl4AI.
Fetches current matches, recent results, and upcoming fixtures for Bundesliga, Handball, and Volleyball.
No hardcoded dates: uses dynamic current season and matchday endpoints.
"""

import json
import logging
from datetime import datetime, timezone
from typing import List, Tuple, Dict, Any, Optional
from bs4 import BeautifulSoup

from crawl4ai import AsyncWebCrawler

from .base import BaseSource
from ..config import get_current_utc, get_current_season_year, get_current_season_label
from ..models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedMatch,
    NormalizedResult,
    NormalizedStatistic,
    SyncReport,
)

logger = logging.getLogger("betsoccer.collector.openligadb")


class OpenLigaDbSource(BaseSource):
    def __init__(
        self,
        leagues_config: Optional[Dict[str, Dict[str, str]]] = None,
        historical_seasons: Optional[List[int]] = None,
        max_retries: int = 3,
        rate_limit_delay: float = 1.0,
    ):
        super().__init__(
            provider_id="openligadb",
            display_name="OpenLigaDB (Open REST API)",
            max_retries=max_retries,
            rate_limit_delay=rate_limit_delay,
        )
        self.leagues = leagues_config or {
            "bl1": {"sport": "football", "name": "1. Bundesliga", "code": "BL1", "country": "Allemagne"},
            "bl2": {"sport": "football", "name": "2. Bundesliga", "code": "BL2", "country": "Allemagne"},
            "hbl": {"sport": "handball", "name": "Handball Bundesliga (HBL)", "code": "HBL", "country": "Allemagne"},
            "vblf1": {"sport": "volleyball", "name": "1. Volleyball Bundesliga Frauen", "code": "VBLF1", "country": "Allemagne"},
        }
        self.historical_seasons = historical_seasons or []

    def _extract_json(self, raw_content: str) -> Any:
        try:
            return json.loads(raw_content)
        except json.JSONDecodeError:
            soup = BeautifulSoup(raw_content, "html.parser")
            pre = soup.find("pre")
            if pre and pre.text:
                return json.loads(pre.text)
            raise

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
        sports: Dict[str, NormalizedSport] = {}
        competitions: List[NormalizedCompetition] = []
        seasons: List[NormalizedSeason] = []
        matches: List[NormalizedMatch] = []
        synced_count = 0
        error_msg = None

        current_season_label = get_current_season_label()

        # 1. Initialize Normalized Sports
        sports_meta = {
            "football": ("Football (Soccer)", "SOCCER", "sports_soccer"),
            "handball": ("Handball", "HANDBALL", "sports_handball"),
            "volleyball": ("Volleyball", "VOLLEYBALL", "sports_volleyball"),
        }
        for s_key, (s_name, s_code, s_icon) in sports_meta.items():
            sports[s_key] = NormalizedSport(
                id=f"sport_{s_key}",
                name=s_name,
                code=s_code,
                icon_ref=s_icon,
                source_provider=self.provider_id,
            )

        for league_shortcut, meta in self.leagues.items():
            sport_key = meta["sport"]
            comp_id = f"comp_old_{league_shortcut}"
            competition = NormalizedCompetition(
                id=comp_id,
                sport_id=sports[sport_key].id,
                name=meta["name"],
                code=meta["code"],
                country=meta["country"],
                country_code="DE",
                tier=1,
                source_provider=self.provider_id,
            )
            competitions.append(competition)

            season_id = f"season_{comp_id}_{get_current_season_year()}"
            season = NormalizedSeason(
                id=season_id,
                competition_id=comp_id,
                year_label=current_season_label,
                is_current=True,
            )
            seasons.append(season)

            # 1. Historical Seasons (if configured)
            for hist_yr in self.historical_seasons:
                hist_season_id = f"season_{comp_id}_{hist_yr}"
                hist_season = NormalizedSeason(
                    id=hist_season_id,
                    competition_id=comp_id,
                    year_label=f"{hist_yr}/{str(hist_yr + 1)[-2:]}",
                    is_current=False,
                    start_date=f"{hist_yr}-08-01",
                    end_date=f"{hist_yr + 1}-05-31",
                )
                seasons.append(hist_season)
                hist_url = f"https://api.openligadb.de/getmatchdata/{league_shortcut}/{hist_yr}"
                try:
                    raw_html = await self.fetch_with_crawl4ai(crawler, hist_url)
                    data = self._extract_json(raw_html)
                    if isinstance(data, list):
                        for item in data:
                            match = self._normalize_match(item, sports[sport_key].id, comp_id, hist_season_id)
                            if match:
                                matches.append(match)
                                synced_count += 1
                        logger.info(f"[{self.provider_id}] Processed {len(data)} historical matches for {league_shortcut}/{hist_yr}")
                except Exception as e:
                    logger.error(f"[{self.provider_id}] Error collecting historical {league_shortcut}/{hist_yr}: {e}")
                    error_msg = str(e)

            # 2. Endpoint /getmatchdata/{league} fetches the CURRENT dynamic matchday
            url = f"https://api.openligadb.de/getmatchdata/{league_shortcut}"
            try:
                raw_html = await self.fetch_with_crawl4ai(crawler, url)
                data = self._extract_json(raw_html)

                if isinstance(data, list):
                    for item in data:
                        match = self._normalize_match(item, sports[sport_key].id, comp_id, season_id)
                        if match:
                            matches.append(match)
                            synced_count += 1
                logger.info(f"[{self.provider_id}] Processed {len(data)} matches for current {league_shortcut}")

            except Exception as e:
                logger.error(f"[{self.provider_id}] Error collecting current {league_shortcut}: {e}")
                error_msg = str(e)

        finished_time = get_current_utc()
        duration_ms = int((finished_time - start_time).total_seconds() * 1000)

        report = SyncReport(
            provider_id=self.provider_id,
            key=f"sync_{self.provider_id}_{start_time.strftime('%Y%m%d_%H%M%S')}",
            status="SUCCESS" if error_msg is None else ("PARTIAL" if synced_count > 0 else "ERROR"),
            records_synced=synced_count,
            started_at=start_time,
            finished_at=finished_time,
            duration_ms=duration_ms,
            error_message=error_msg,
            details={"leagues_requested": list(self.leagues.keys()), "matches_parsed": len(matches)},
        )

        return list(sports.values()), competitions, seasons, matches, report

    def _normalize_match(
        self, item: Dict[str, Any], sport_id: str, comp_id: str, season_id: str
    ) -> Optional[NormalizedMatch]:
        try:
            match_id_raw = item.get("matchID")
            if not match_id_raw:
                return None

            team1 = item.get("team1") or {}
            team2 = item.get("team2") or {}
            home_name = team1.get("teamName") or "Équipe Domicile"
            away_name = team2.get("teamName") or "Équipe Extérieur"

            home_id = f"team_{home_name.lower().replace(' ', '_')}"
            away_id = f"team_{away_name.lower().replace(' ', '_')}"

            utc_kickoff = item.get("matchDateTimeUTC")
            if not utc_kickoff:
                # Fallback to local with UTC formatting
                local_dt = item.get("matchDateTime")
                utc_kickoff = f"{local_dt}Z" if local_dt else get_current_utc().isoformat()

            # Status determination
            is_finished = item.get("matchIsFinished", False)
            match_results = item.get("matchResults") or []
            status = "finished" if is_finished else "upcoming"

            # Parse results
            result = None
            if is_finished or match_results:
                final_res = next((r for r in match_results if r.get("resultName") == "Endergebnis" or r.get("resultOrderID") == 2), None)
                if not final_res and match_results and is_finished:
                    final_res = sorted(match_results, key=lambda r: r.get("resultOrderID", 0))[-1]
                halftime_res = next((r for r in match_results if r.get("resultOrderID") == 1 or "Halbzeit" in r.get("resultName", "")), None)

                if final_res:
                    home_score = final_res.get("pointsTeam1")
                    away_score = final_res.get("pointsTeam2")
                    winner_id = None
                    if home_score is not None and away_score is not None:
                        if home_score > away_score:
                            winner_id = home_id
                        elif away_score > home_score:
                            winner_id = away_id

                    result = NormalizedResult(
                        id=f"res_old_{match_id_raw}",
                        match_id=f"old_{match_id_raw}",
                        home_score=home_score,
                        away_score=away_score,
                        home_halftime_score=halftime_res.get("pointsTeam1") if halftime_res else None,
                        away_halftime_score=halftime_res.get("pointsTeam2") if halftime_res else None,
                        winner_team_id=winner_id,
                    )

            # Statistics from goals
            stats = []
            goals = item.get("goals") or []
            if goals:
                stats.append(NormalizedStatistic(
                    id=f"stat_old_{match_id_raw}_goals_count",
                    match_id=f"old_{match_id_raw}",
                    metric_name="total_goals",
                    home_value=float(len([g for g in goals if g.get("scoringTeamId") == team1.get("teamId")])),
                    away_value=float(len([g for g in goals if g.get("scoringTeamId") == team2.get("teamId")])),
                ))

            group = item.get("group") or {}
            matchday = group.get("groupOrderID")
            round_label = group.get("groupName")

            return NormalizedMatch(
                id=f"old_{match_id_raw}",
                sport_id=sport_id,
                competition_id=comp_id,
                season_id=season_id,
                home_team_id=home_id,
                home_team_name=home_name,
                away_team_id=away_id,
                away_team_name=away_name,
                utc_kickoff=utc_kickoff,
                status=status,
                matchday=matchday,
                round_label=round_label,
                source_provider=self.provider_id,
                source_match_id=str(match_id_raw),
                result=result,
                statistics=stats,
            )
        except Exception as e:
            logger.warning(f"[{self.provider_id}] Failed to normalize match: {e}")
            return None
