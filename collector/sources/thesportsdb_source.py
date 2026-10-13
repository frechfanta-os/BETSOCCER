"""
TheSportsDB connector using Crawl4AI.
Fetches multisport metadata and schedules using the free public V1 API key '3'.
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
    NormalizedTeam,
    NormalizedMatch,
    NormalizedResult,
    SyncReport,
)

logger = logging.getLogger("betsoccer.collector.thesportsdb")


class TheSportsDbSource(BaseSource):
    def __init__(
        self,
        base_url: str = "https://www.thesportsdb.com/api/v1/json/3",
        max_retries: int = 3,
        rate_limit_delay: float = 1.0,
    ):
        super().__init__(
            provider_id="thesportsdb",
            display_name="TheSportsDB API (V1 Test Key 3)",
            max_retries=max_retries,
            rate_limit_delay=rate_limit_delay,
        )
        self.base_url = base_url

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
        sports: List[NormalizedSport] = []
        competitions: List[NormalizedCompetition] = []
        seasons: List[NormalizedSeason] = []
        matches: List[NormalizedMatch] = []
        synced_count = 0
        error_msg = None

        current_season_label = get_current_season_label()

        try:
            # 1. Fetch Sports metadata
            sports_url = f"{self.base_url}/all_sports.php"
            raw_sports = await self.fetch_with_crawl4ai(crawler, sports_url)
            sports_data = self._extract_json(raw_sports)

            raw_list = sports_data.get("sports") or []
            for item in raw_list[:10]:  # Top 10 primary sports
                s_name = item.get("strSport")
                if not s_name:
                    continue
                if s_name.lower() in ("soccer", "football"):
                    s_id = "sport_football"
                    s_code = "SOCCER"
                else:
                    s_id = f"sport_{s_name.lower().replace(' ', '_')}"
                    s_code = s_name.upper().replace(" ", "_")[:10]

                sports.append(NormalizedSport(
                    id=s_id,
                    name=s_name,
                    code=s_code,
                    icon_ref=item.get("strSportIconGreen"),
                    source_provider=self.provider_id,
                ))

            # 2. Fetch Sample League Upcoming / Current Season Events
            # EPL (idLeague 4328)
            epl_url = f"{self.base_url}/eventsseason.php?id=4328&s={get_current_season_year()}-{get_current_season_year() + 1}"
            raw_epl = await self.fetch_with_crawl4ai(crawler, epl_url)
            epl_data = self._extract_json(raw_epl)
            events = epl_data.get("events") or []

            comp_id = "comp_tsdb_4328"
            season_id = f"season_{comp_id}_{get_current_season_year()}"

            competitions.append(NormalizedCompetition(
                id=comp_id,
                sport_id="sport_football",
                name="English Premier League",
                code="EPL",
                country="England",
                country_code="GB",
                tier=1,
                source_provider=self.provider_id,
            ))
            seasons.append(NormalizedSeason(
                id=season_id,
                competition_id=comp_id,
                year_label=current_season_label,
                is_current=True,
            ))

            for ev in events:
                m = self._normalize_event(ev, "sport_football", comp_id, season_id)
                if m:
                    matches.append(m)
                    synced_count += 1

            logger.info(f"[{self.provider_id}] Processed {len(sports)} sports and {len(matches)} events.")

        except Exception as e:
            logger.error(f"[{self.provider_id}] Error in collect(): {e}")
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
            details={"sports_count": len(sports), "matches_count": len(matches)},
        )

        return sports, competitions, seasons, matches, report

    def _normalize_event(
        self, ev: Dict[str, Any], sport_id: str, comp_id: str, season_id: str
    ) -> Optional[NormalizedMatch]:
        try:
            ev_id = ev.get("idEvent")
            if not ev_id:
                return None

            home_name = ev.get("strHomeTeam") or "Home"
            away_name = ev.get("strAwayTeam") or "Away"
            home_id = f"team_{home_name.lower().replace(' ', '_')}"
            away_id = f"team_{away_name.lower().replace(' ', '_')}"

            ts_str = ev.get("strTimestamp")
            if ts_str:
                utc_kickoff = f"{ts_str}Z" if not ts_str.endswith("Z") else ts_str
            else:
                d_event = ev.get("dateEvent", "2026-10-13")
                t_event = ev.get("strTime", "15:00:00")
                utc_kickoff = f"{d_event}T{t_event}Z"

            home_score = int(ev.get("intHomeScore")) if ev.get("intHomeScore") not in (None, "") else None
            away_score = int(ev.get("intAwayScore")) if ev.get("intAwayScore") not in (None, "") else None
            status = "finished" if (home_score is not None and away_score is not None) else "upcoming"

            result = None
            if home_score is not None and away_score is not None:
                result = NormalizedResult(
                    id=f"res_tsdb_{ev_id}",
                    match_id=f"tsdb_{ev_id}",
                    home_score=home_score,
                    away_score=away_score,
                )

            return NormalizedMatch(
                id=f"tsdb_{ev_id}",
                sport_id=sport_id,
                competition_id=comp_id,
                season_id=season_id,
                home_team_id=home_id,
                home_team_name=home_name,
                away_team_id=away_id,
                away_team_name=away_name,
                utc_kickoff=utc_kickoff,
                status=status,
                matchday=int(ev.get("intRound")) if ev.get("intRound") and ev.get("intRound").isdigit() else None,
                round_label=f"Journée {ev.get('intRound')}" if ev.get("intRound") else None,
                source_provider=self.provider_id,
                source_match_id=str(ev_id),
                result=result,
            )
        except Exception as e:
            logger.debug(f"Failed to normalize TSDB event: {e}")
            return None
