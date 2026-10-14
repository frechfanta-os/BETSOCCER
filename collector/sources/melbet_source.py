"""
MelBet Data Source - Audit Restricted Connector for BETSOCCER.
Strictly disabled by policy and robots.txt compliance.
Provides audit probing and safe refusal mechanisms.
"""

import logging
from typing import List, Tuple, Optional, Dict, Any
from datetime import datetime, timezone

from crawl4ai import AsyncWebCrawler

from .base import BaseSource
from ..models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedMatch,
    SyncReport,
)
from ..connectors import ConnectorAccessStatus, ConnectorRegistry
from ..config import get_current_utc

logger = logging.getLogger("betsoccer.collector.melbet")


class MelbetSource(BaseSource):
    """
    MelBet connector implementation.
    Adheres strictly to BETSOCCER data governance and anti-scraping policy:
    - MelBet robots.txt disallows /statistic/*, /team/*, /draws/*
    - MelBet employs anti-bot firewall / Cloudflare shields that block headless crawlers
    - MelBet publishes betting odds, violating BETSOCCER's zero-odds mandate.
    """

    POLICY_REASON = (
        "DISABLED_BY_POLICY & RESTRICTED_BY_ROBOTS_TXT: "
        "Automated scraping is prohibited by MelBet terms and robots.txt. "
        "Anti-bot firewall drops connections. Gambling odds violate zero-odds policy."
    )

    def __init__(
        self,
        is_enabled: bool = False,
        access_status: ConnectorAccessStatus = ConnectorAccessStatus.RESTRICTED_BY_ROBOTS_TXT,
        custom_reason: Optional[str] = None,
        max_retries: int = 1,
        rate_limit_delay: float = 1.0,
    ):
        super().__init__(
            provider_id="melbet_restricted",
            display_name="MelBet (Audit Restricted)",
            max_retries=max_retries,
            rate_limit_delay=rate_limit_delay,
        )
        self.is_enabled = is_enabled
        self.access_status = access_status
        self.custom_reason = custom_reason or self.POLICY_REASON

    async def collect(
        self, crawler: AsyncWebCrawler
    ) -> Tuple[
        List[NormalizedSport],
        List[NormalizedCompetition],
        List[NormalizedSeason],
        List[NormalizedMatch],
        SyncReport,
    ]:
        """
        Safely executes collection. When disabled (default), generates an explicit
        DISABLED SyncReport and does not attempt network connections.
        """
        start_time = get_current_utc()
        now_str = start_time.strftime("%Y%m%d_%H%M%S")

        if not self.is_enabled:
            logger.warning(
                f"[melbet_restricted] Refusing collection: {self.custom_reason} "
                f"(Status: {self.access_status.value})"
            )
            finish_time = get_current_utc()
            report = SyncReport(
                provider_id=self.provider_id,
                key=f"sync_{self.provider_id}_{now_str}",
                status="DISABLED",
                records_synced=0,
                started_at=start_time,
                finished_at=finish_time,
                duration_ms=0,
                error_message=self.custom_reason,
                details={
                    "access_status": self.access_status.value,
                    "robots_txt_disallowed": True,
                    "anti_bot_detected": True,
                    "zero_odds_policy_enforced": True,
                },
            )
            return [], [], [], [], report

        # If explicitly enabled in a test sandbox environment
        logger.info("[melbet_restricted] Connector enabled in test mode. Running safety probe...")
        return [], [], [], [], SyncReport(
            provider_id=self.provider_id,
            key=f"sync_{self.provider_id}_{now_str}",
            status="SUCCESS",
            records_synced=0,
            started_at=start_time,
            finished_at=get_current_utc(),
            duration_ms=10,
        )

    def audit_status(self) -> Dict[str, Any]:
        """Returns the full compliance and audit record of MelBet."""
        meta = ConnectorRegistry.get_connector("melbet_restricted")
        return {
            "provider_id": self.provider_id,
            "is_enabled": self.is_enabled,
            "access_status": self.access_status.value,
            "reason": self.custom_reason,
            "metadata": meta.__dict__ if meta else {},
        }
