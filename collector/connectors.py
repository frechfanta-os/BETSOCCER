"""
Connectors Architecture and Status Registry for BETSOCCER.
Defines connector configuration, accessibility status, and governance auditing.
"""

from enum import Enum
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone
import urllib.request
import urllib.error
import logging

logger = logging.getLogger("betsoccer.collector.connectors")


class ConnectorAccessStatus(str, Enum):
    """Status indicating connector accessibility and policy compliance."""
    AVAILABLE = "AVAILABLE"
    DISABLED_BY_CONFIG = "DISABLED_BY_CONFIG"
    RESTRICTED_BY_ROBOTS_TXT = "RESTRICTED_BY_ROBOTS_TXT"
    ANTI_BOT_BLOCKED = "ANTI_BOT_BLOCKED"
    DISABLED_BY_POLICY = "DISABLED_BY_POLICY"
    AUTHENTICATION_REQUIRED = "AUTHENTICATION_REQUIRED"
    RATE_LIMITED = "RATE_LIMITED"


@dataclass
class ConnectorMetadata:
    """Metadata describing a sports data connector."""
    provider_id: str
    display_name: str
    is_enabled: bool
    access_status: ConnectorAccessStatus
    policy_reason: Optional[str] = None
    supported_data_types: List[str] = field(default_factory=list)
    last_checked_at: Optional[datetime] = None
    last_error: Optional[str] = None
    robots_txt_disallowed: bool = False
    anti_bot_detected: bool = False
    details: Dict[str, Any] = field(default_factory=dict)


class ConnectorRegistry:
    """Central registry and diagnostic probe for all data connectors."""

    @staticmethod
    def get_all_connectors() -> Dict[str, ConnectorMetadata]:
        now = datetime.now(timezone.utc)
        return {
            "openligadb": ConnectorMetadata(
                provider_id="openligadb",
                display_name="OpenLigaDB",
                is_enabled=True,
                access_status=ConnectorAccessStatus.AVAILABLE,
                supported_data_types=["sports", "competitions", "matches", "results", "historical"],
                last_checked_at=now,
            ),
            "football_data_co_uk": ConnectorMetadata(
                provider_id="football_data_co_uk",
                display_name="Football-Data.co.uk",
                is_enabled=True,
                access_status=ConnectorAccessStatus.AVAILABLE,
                supported_data_types=["competitions", "fixtures", "historical_results", "match_statistics"],
                last_checked_at=now,
            ),
            "thesportsdb": ConnectorMetadata(
                provider_id="thesportsdb",
                display_name="TheSportsDB (V1 Free)",
                is_enabled=True,
                access_status=ConnectorAccessStatus.AVAILABLE,
                supported_data_types=["sports", "competitions", "teams", "upcoming_matches"],
                last_checked_at=now,
            ),
            "football_data_org": ConnectorMetadata(
                provider_id="football_data_org",
                display_name="Football-Data.org",
                is_enabled=False,
                access_status=ConnectorAccessStatus.AUTHENTICATION_REQUIRED,
                policy_reason="API key required for automated retrieval",
                supported_data_types=["competitions", "matches", "historical"],
                last_checked_at=now,
                last_error="No API key configured in environment",
            ),
            "melbet_restricted": ConnectorMetadata(
                provider_id="melbet_restricted",
                display_name="MelBet (Audit Restricted)",
                is_enabled=False,
                access_status=ConnectorAccessStatus.RESTRICTED_BY_ROBOTS_TXT,
                policy_reason=(
                    "DISABLED_BY_POLICY & RESTRICTED_BY_ROBOTS_TXT: "
                    "MelBet robots.txt strictly disallows automated crawlers on /statistic/*, /team/*, /draws/*. "
                    "Anti-bot defense (Cloudflare / traincdn) drops automated requests (connection timeout). "
                    "BETSOCCER zero-odds policy prohibits gambling/bookmaker odds ingestion."
                ),
                supported_data_types=[],
                last_checked_at=now,
                last_error="robots.txt disallow rule & anti-bot connection timeout",
                robots_txt_disallowed=True,
                anti_bot_detected=True,
                details={
                    "robots_txt_rules": [
                        "Disallow: */statistic/*",
                        "Disallow: */team/*",
                        "Disallow: */draws/*",
                        "Disallow: */coupons/*",
                        "User-agent: Google-Extended Disallow: /",
                    ],
                    "antibot_signal": "net::ERR_CONNECTION_TIMED_OUT on headless probe",
                    "policy_compliance": "VIOLATION_OF_ZERO_ODDS_POLICY",
                },
            ),
        }

    @classmethod
    def get_connector(cls, provider_id: str) -> Optional[ConnectorMetadata]:
        return cls.get_all_connectors().get(provider_id)
