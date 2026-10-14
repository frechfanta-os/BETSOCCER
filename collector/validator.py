"""
Data validation and sanitization module for BETSOCCER.
Ensures zero corrupted, malformed or invalid records enter SQLite.
"""

import re
import logging
from datetime import datetime, timezone
from typing import Tuple, Optional, List

from .models import NormalizedMatch, NormalizedResult, NormalizedStatistic

logger = logging.getLogger("betsoccer.collector.validator")

VALID_STATUSES = {"upcoming", "live", "finished", "postponed", "cancelled"}


class DataValidationError(Exception):
    """Raised when sports data fails structural or integrity validation."""
    pass


class DataValidator:
    """Validates and sanitizes sports data before database persistence."""

    @staticmethod
    def validate_iso_kickoff(kickoff_str: str) -> Tuple[bool, Optional[str]]:
        if not kickoff_str or not isinstance(kickoff_str, str):
            return False, "Missing or non-string utc_kickoff"
        try:
            # Handle standard UTC strings (e.g. 2026-10-14T15:00:00Z)
            cleaned = kickoff_str.replace("Z", "+00:00")
            dt = datetime.fromisoformat(cleaned)
            # Guard against invalid years (must be between 1990 and 2040)
            if not (1990 <= dt.year <= 2040):
                return False, f"Kickoff year {dt.year} is out of realistic bounds [1990, 2040]"
            return True, None
        except Exception as e:
            return False, f"Invalid ISO-8601 kickoff date '{kickoff_str}': {e}"

    @classmethod
    def validate_match(cls, match: NormalizedMatch) -> Tuple[bool, Optional[str]]:
        """
        Validates the logical consistency and completeness of a NormalizedMatch.
        Returns: (is_valid, rejection_reason)
        """
        if not match:
            return False, "Null match object"

        # 1. Mandatory Identifiers
        if not match.id or not str(match.id).strip():
            return False, "Empty match id"
        if not match.sport_id or not str(match.sport_id).strip():
            return False, f"Match {match.id}: empty sport_id"
        if not match.competition_id or not str(match.competition_id).strip():
            return False, f"Match {match.id}: empty competition_id"
        if not match.source_provider or not str(match.source_provider).strip():
            return False, f"Match {match.id}: empty source_provider"

        # 2. Team Names
        if not match.home_team_name or not str(match.home_team_name).strip():
            return False, f"Match {match.id}: empty home_team_name"
        if not match.away_team_name or not str(match.away_team_name).strip():
            return False, f"Match {match.id}: empty away_team_name"
        if match.home_team_name.strip() == match.away_team_name.strip():
            return False, f"Match {match.id}: identical home and away teams ('{match.home_team_name}')"

        # 3. Status
        status = str(match.status).lower().strip()
        if status not in VALID_STATUSES:
            return False, f"Match {match.id}: invalid status '{match.status}'. Expected one of {VALID_STATUSES}"

        # 4. Kickoff date
        is_date_valid, date_err = cls.validate_iso_kickoff(match.utc_kickoff)
        if not is_date_valid:
            return False, f"Match {match.id}: {date_err}"

        # 5. Result verification
        if match.result:
            res = match.result
            if res.home_score is not None and res.home_score < 0:
                return False, f"Match {match.id}: negative home score ({res.home_score})"
            if res.away_score is not None and res.away_score < 0:
                return False, f"Match {match.id}: negative away score ({res.away_score})"
            if res.home_halftime_score is not None and res.home_halftime_score < 0:
                return False, f"Match {match.id}: negative home halftime score ({res.home_halftime_score})"
            if res.away_halftime_score is not None and res.away_halftime_score < 0:
                return False, f"Match {match.id}: negative away halftime score ({res.away_halftime_score})"

            # Halftime score logic: in football, halftime goals cannot exceed fulltime goals
            if match.sport_id == "sport_football":
                if res.home_score is not None and res.home_halftime_score is not None:
                    if res.home_halftime_score > res.home_score:
                        return False, f"Match {match.id}: home halftime ({res.home_halftime_score}) > fulltime ({res.home_score})"
                if res.away_score is not None and res.away_halftime_score is not None:
                    if res.away_halftime_score > res.away_score:
                        return False, f"Match {match.id}: away halftime ({res.away_halftime_score}) > fulltime ({res.away_score})"

        # 6. Statistics verification
        for stat in match.statistics:
            if not stat.metric_name or not str(stat.metric_name).strip():
                return False, f"Match {match.id}: empty metric_name in statistics"
            if stat.home_value is not None and stat.home_value < 0:
                return False, f"Match {match.id}: negative home statistic value for '{stat.metric_name}'"
            if stat.away_value is not None and stat.away_value < 0:
                return False, f"Match {match.id}: negative away statistic value for '{stat.metric_name}'"

        return True, None

    @classmethod
    def sanitize_match(cls, match: NormalizedMatch) -> NormalizedMatch:
        """Sanitizes strings and formats of a valid NormalizedMatch."""
        match.home_team_name = match.home_team_name.strip()
        match.away_team_name = match.away_team_name.strip()
        match.status = match.status.lower().strip()
        # Ensure UTC suffix
        if match.utc_kickoff.endswith("+00:00"):
            match.utc_kickoff = match.utc_kickoff.replace("+00:00", "Z")
        elif not match.utc_kickoff.endswith("Z"):
            match.utc_kickoff = f"{match.utc_kickoff}Z"
        return match

    @classmethod
    def filter_and_sanitize(cls, matches: List[NormalizedMatch]) -> Tuple[List[NormalizedMatch], List[Tuple[NormalizedMatch, str]]]:
        """
        Partitions matches into valid sanitized matches and rejected matches with reasons.
        """
        valid_matches = []
        rejected = []
        for m in matches:
            is_valid, reason = cls.validate_match(m)
            if is_valid:
                valid_matches.append(cls.sanitize_match(m))
            else:
                logger.warning(f"Rejecting invalid match record: {reason}")
                rejected.append((m, reason or "Unknown validation error"))
        return valid_matches, rejected
