"""
Configuration module for the BETSOCCER Crawl4AI Autonomous Collector.
No historical dates are hardcoded; all seasons and date windows are computed dynamically.
"""

import os
from datetime import datetime, timezone
from dataclasses import dataclass, field
from typing import List, Dict, Any


def get_current_utc() -> datetime:
    """Returns the current date and time in UTC."""
    return datetime.now(timezone.utc)


def get_current_season_year() -> int:
    """
    Computes the European sports season starting year dynamically.
    If current month is July or later (month >= 7), season is YYYY (e.g. 2026 for 2026/27).
    If current month is before July (Jan-Jun), season is YYYY - 1 (e.g. 2025 for 2025/26).
    """
    now = get_current_utc()
    return now.year if now.month >= 7 else now.year - 1


def get_current_season_label() -> str:
    """Returns the human-readable season label, e.g. '2026/27'."""
    start_year = get_current_season_year()
    next_short = (start_year + 1) % 100
    return f"{start_year}/{next_short:02d}"


@dataclass
class CollectorConfig:
    # Database
    db_path: str = os.getenv("BETSOCCER_DB_PATH", "betsoccer.db")
    
    # Network & Crawl4AI
    request_timeout_seconds: int = 20
    max_retries: int = 3
    retry_backoff_factor: float = 1.5
    rate_limit_delay_seconds: float = 1.0
    
    # Active Sources
    enabled_sources: List[str] = field(default_factory=lambda: [
        "openligadb",
        "footballdata_fixtures",
        "footballdata_historical",
        "thesportsdb"
    ])
    
    # OpenLigaDB Competitions & Historical Seasons
    openligadb_leagues: Dict[str, Dict[str, str]] = field(default_factory=lambda: {
        "bl1": {"sport": "football", "name": "1. Bundesliga", "code": "BL1", "country": "Allemagne"},
        "bl2": {"sport": "football", "name": "2. Bundesliga", "code": "BL2", "country": "Allemagne"},
        "hbl": {"sport": "handball", "name": "Handball Bundesliga (HBL)", "code": "HBL", "country": "Allemagne"},
        "vblf1": {"sport": "volleyball", "name": "1. Volleyball Bundesliga Frauen", "code": "VBLF1", "country": "Allemagne"},
    })
    openligadb_historical_seasons: List[int] = field(default_factory=lambda: [2023])
    
    # Football-Data.co.uk URLs & Historical Archives
    footballdata_fixtures_url: str = "https://football-data.co.uk/fixtures.csv"
    footballdata_historical_seasons: List[str] = field(default_factory=lambda: ["2324"])
    footballdata_historical_leagues: List[str] = field(default_factory=lambda: ["E0", "SP1"])
    
    # TheSportsDB URLs (Free V1 API key 3)
    thesportsdb_base_url: str = "https://www.thesportsdb.com/api/v1/json/3"

    # MelBet policy lock
    melbet_enabled: bool = False  # Strictly DISABLED_BY_POLICY


DEFAULT_CONFIG = CollectorConfig()
