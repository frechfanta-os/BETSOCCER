"""
Autonomous Sports Data Collector using Crawl4AI.
Orchestrates collection, validation, deduplication, and persistence into SQLite.
"""

import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone

from crawl4ai import AsyncWebCrawler

from .config import CollectorConfig, DEFAULT_CONFIG, get_current_utc
from .db import DatabaseManager
from .models import SyncReport
from .sources.base import BaseSource
from .sources.openligadb_source import OpenLigaDbSource
from .sources.footballdata_fixtures_source import FootballDataFixturesSource
from .sources.footballdata_historical_source import FootballDataHistoricalSource
from .sources.thesportsdb_source import TheSportsDbSource
from .sources.html_scraper import HtmlScraperSource
from .sources.melbet_source import MelbetSource

logger = logging.getLogger("betsoccer.collector")


class AutonomousCollector:
    def __init__(self, config: Optional[CollectorConfig] = None):
        self.config = config or DEFAULT_CONFIG
        self.db = DatabaseManager(db_path=self.config.db_path)
        self.sources: Dict[str, BaseSource] = {}
        self._init_sources()

    def _init_sources(self) -> None:
        if "openligadb" in self.config.enabled_sources:
            self.sources["openligadb"] = OpenLigaDbSource(
                leagues_config=self.config.openligadb_leagues,
                historical_seasons=self.config.openligadb_historical_seasons,
                max_retries=self.config.max_retries,
                rate_limit_delay=self.config.rate_limit_delay_seconds,
            )

        if "footballdata_fixtures" in self.config.enabled_sources:
            self.sources["footballdata_fixtures"] = FootballDataFixturesSource(
                fixtures_url=self.config.footballdata_fixtures_url,
                max_retries=self.config.max_retries,
                rate_limit_delay=self.config.rate_limit_delay_seconds,
            )

        if "footballdata_historical" in self.config.enabled_sources:
            self.sources["footballdata_historical"] = FootballDataHistoricalSource(
                seasons=self.config.footballdata_historical_seasons,
                leagues=self.config.footballdata_historical_leagues,
                max_retries=self.config.max_retries,
                rate_limit_delay=self.config.rate_limit_delay_seconds,
            )

        if "thesportsdb" in self.config.enabled_sources:
            self.sources["thesportsdb"] = TheSportsDbSource(
                base_url=self.config.thesportsdb_base_url,
                max_retries=self.config.max_retries,
                rate_limit_delay=self.config.rate_limit_delay_seconds,
            )

        if "html_scraper" in self.config.enabled_sources:
            self.sources["html_scraper"] = HtmlScraperSource(
                urls=self.config.html_scraper_urls,
                max_retries=self.config.max_retries,
                rate_limit_delay=self.config.rate_limit_delay_seconds,
            )

        if "melbet" in self.config.enabled_sources or "melbet_restricted" in self.config.enabled_sources:
            self.sources["melbet_restricted"] = MelbetSource(
                is_enabled=self.config.melbet_enabled,
                custom_reason=self.config.melbet_policy_reason,
            )

    async def run_sync_cycle(self, dry_run: bool = False) -> Dict[str, Any]:
        """
        Executes one full autonomous synchronization cycle using Crawl4AI.
        """
        cycle_start = get_current_utc()
        logger.info(f"=== Starting Crawl4AI autonomous collection cycle at {cycle_start.isoformat()} ===")
        logger.info(f"Target SQLite database: {self.config.db_path}")
        logger.info(f"Enabled sources: {list(self.sources.keys())}")

        total_sports = 0
        total_competitions = 0
        total_seasons = 0
        total_matches = 0
        reports: List[SyncReport] = []

        async with AsyncWebCrawler(verbose=False) as crawler:
            for src_name, source in self.sources.items():
                logger.info(f"--> Collecting from source: {source.display_name} ({src_name})")
                try:
                    sports, competitions, seasons, matches, report = await source.collect(crawler)
                    reports.append(report)

                    if not dry_run:
                        # 1. Upsert Sports
                        for s in sports:
                            self.db.upsert_sport(s)
                        total_sports += len(sports)

                        # 2. Upsert Competitions
                        for c in competitions:
                            self.db.upsert_competition(c)
                        total_competitions += len(competitions)

                        # 3. Upsert Seasons
                        for sea in seasons:
                            self.db.upsert_season(sea)
                        total_seasons += len(seasons)

                        # 4. Batch Save Matches & Deduplicate
                        saved = self.db.save_matches_batch(matches)
                        total_matches += saved

                        # 5. Record Sync State
                        self.db.record_sync_state(report)
                    else:
                        total_matches += len(matches)
                        logger.info(f"[DRY-RUN] Would save {len(matches)} matches from {src_name}")

                    logger.info(
                        f"✓ [{src_name}] Synced: {report.records_synced} records "
                        f"in {report.duration_ms}ms (Status: {report.status})"
                    )

                except Exception as e:
                    logger.error(f"✗ [{src_name}] Unhandled collection failure: {e}", exc_info=True)
                    failed_report = SyncReport(
                        provider_id=source.provider_id,
                        key=f"sync_{source.provider_id}_{src_name}_{cycle_start.strftime('%Y%m%d_%H%M%S')}",
                        status="ERROR",
                        records_synced=0,
                        started_at=cycle_start,
                        finished_at=get_current_utc(),
                        duration_ms=0,
                        error_message=str(e),
                    )
                    reports.append(failed_report)
                    if not dry_run:
                        self.db.record_sync_state(failed_report)

        cycle_end = get_current_utc()
        total_duration_sec = (cycle_end - cycle_start).total_seconds()

        summary = {
            "cycle_start": cycle_start.isoformat(),
            "cycle_end": cycle_end.isoformat(),
            "duration_seconds": round(total_duration_sec, 2),
            "dry_run": dry_run,
            "sources_processed": len(self.sources),
            "total_sports": total_sports,
            "total_competitions": total_competitions,
            "total_seasons": total_seasons,
            "total_matches_synced": total_matches,
            "reports": [
                {
                    "provider": r.provider_id,
                    "status": r.status,
                    "records": r.records_synced,
                    "duration_ms": r.duration_ms,
                    "error": r.error_message,
                }
                for r in reports
            ],
            "db_stats": self.db.get_summary_stats() if not dry_run else {},
        }

        logger.info(f"=== Cycle finished: {total_matches} matches processed in {total_duration_sec:.2f}s ===")
        return summary
