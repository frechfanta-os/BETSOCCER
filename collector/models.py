"""
Data models for the BETSOCCER Autonomous Collector.
Normalized to match BETSOCCER Flutter schema and domain entities.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List, Dict, Any


@dataclass
class NormalizedSport:
    id: str
    name: str
    code: str
    source_provider: str
    icon_ref: Optional[str] = None


@dataclass
class NormalizedCompetition:
    id: str
    sport_id: str
    name: str
    source_provider: str
    code: Optional[str] = None
    country: Optional[str] = None
    country_code: Optional[str] = None
    badge_url: Optional[str] = None
    tier: int = 1


@dataclass
class NormalizedSeason:
    id: str
    competition_id: str
    year_label: str
    is_current: bool = True
    start_date: Optional[str] = None
    end_date: Optional[str] = None


@dataclass
class NormalizedTeam:
    id: str
    sport_id: str
    name: str
    source_provider: str
    short_name: Optional[str] = None
    tla: Optional[str] = None
    badge_url: Optional[str] = None
    country: Optional[str] = None
    elo_rating: float = 1500.0


@dataclass
class NormalizedResult:
    id: str
    match_id: str
    home_score: Optional[int] = None
    away_score: Optional[int] = None
    home_halftime_score: Optional[int] = None
    away_halftime_score: Optional[int] = None
    home_extratime_score: Optional[int] = None
    away_extratime_score: Optional[int] = None
    home_penalties_score: Optional[int] = None
    away_penalties_score: Optional[int] = None
    winner_team_id: Optional[str] = None


@dataclass
class NormalizedStatistic:
    id: str
    match_id: str
    metric_name: str
    home_value: Optional[float] = None
    away_value: Optional[float] = None
    raw_unit: Optional[str] = None


@dataclass
class NormalizedMatch:
    id: str
    sport_id: str
    competition_id: str
    home_team_id: str
    home_team_name: str
    away_team_id: str
    away_team_name: str
    utc_kickoff: str  # ISO-8601 UTC
    status: str       # upcoming, live, finished, postponed, cancelled
    source_provider: str
    season_id: Optional[str] = None
    matchday: Optional[int] = None
    round_label: Optional[str] = None
    current_minute: Optional[str] = None
    is_sample_data: bool = False
    source_match_id: Optional[str] = None
    result: Optional[NormalizedResult] = None
    statistics: List[NormalizedStatistic] = field(default_factory=list)


@dataclass
class SyncReport:
    provider_id: str
    key: str
    status: str       # SUCCESS, PARTIAL, ERROR
    records_synced: int
    started_at: datetime
    finished_at: datetime
    duration_ms: int
    error_message: Optional[str] = None
    details: Dict[str, Any] = field(default_factory=dict)
