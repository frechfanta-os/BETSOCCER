"""
SQLite database manager for the BETSOCCER Autonomous Collector.
Guarantees 100% schema compatibility with BETSOCCER Flutter app (V1InitialSchema).
"""

import sqlite3
import json
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any, Tuple

from .models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedTeam,
    NormalizedMatch,
    NormalizedResult,
    NormalizedStatistic,
    SyncReport,
)
from .validator import DataValidator

logger = logging.getLogger("betsoccer.collector.db")


class DatabaseManager:
    def __init__(self, db_path: str = "betsoccer.db"):
        self.db_path = db_path
        self._init_schema()

    def get_connection(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON;")
        return conn

    def _init_schema(self) -> None:
        """Initializes the identical 10 relational tables matching Flutter's V1InitialSchema."""
        with self.get_connection() as conn:
            # 1. sports
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sports (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    code TEXT NOT NULL UNIQUE,
                    icon_ref TEXT,
                    source_provider TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_sports_code ON sports (code);")

            # 2. competitions
            conn.execute("""
                CREATE TABLE IF NOT EXISTS competitions (
                    id TEXT PRIMARY KEY,
                    sport_id TEXT NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
                    name TEXT NOT NULL,
                    code TEXT,
                    country TEXT,
                    country_code TEXT,
                    badge_url TEXT,
                    tier INTEGER,
                    source_provider TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_competitions_sport ON competitions (sport_id);")

            # 3. seasons
            conn.execute("""
                CREATE TABLE IF NOT EXISTS seasons (
                    id TEXT PRIMARY KEY,
                    competition_id TEXT NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
                    year_label TEXT NOT NULL,
                    start_date TEXT,
                    end_date TEXT,
                    is_current INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    UNIQUE(competition_id, year_label)
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_seasons_comp ON seasons (competition_id);")

            # 4. teams
            conn.execute("""
                CREATE TABLE IF NOT EXISTS teams (
                    id TEXT PRIMARY KEY,
                    sport_id TEXT NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
                    name TEXT NOT NULL,
                    short_name TEXT,
                    tla TEXT,
                    badge_url TEXT,
                    country TEXT,
                    elo_rating REAL NOT NULL DEFAULT 1500.0,
                    source_provider TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    UNIQUE(sport_id, name)
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_teams_name ON teams (name);")

            # 5. players
            conn.execute("""
                CREATE TABLE IF NOT EXISTS players (
                    id TEXT PRIMARY KEY,
                    team_id TEXT REFERENCES teams(id) ON DELETE SET NULL,
                    name TEXT NOT NULL,
                    position TEXT,
                    nationality TEXT,
                    photo_url TEXT,
                    source_provider TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
            """)

            # 6. matches
            conn.execute("""
                CREATE TABLE IF NOT EXISTS matches (
                    id TEXT PRIMARY KEY,
                    sport_id TEXT NOT NULL REFERENCES sports(id) ON DELETE CASCADE,
                    competition_id TEXT NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
                    season_id TEXT REFERENCES seasons(id) ON DELETE SET NULL,
                    home_team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
                    away_team_id TEXT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
                    utc_kickoff TEXT NOT NULL,
                    status TEXT NOT NULL,
                    matchday INTEGER,
                    round_label TEXT,
                    current_minute TEXT,
                    is_sample_data INTEGER NOT NULL DEFAULT 0,
                    source_provider TEXT NOT NULL,
                    source_match_id TEXT,
                    last_synced_at TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    UNIQUE(competition_id, home_team_id, away_team_id, utc_kickoff)
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_matches_kickoff ON matches (utc_kickoff);")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_matches_status ON matches (status);")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_matches_comp ON matches (competition_id);")

            # 7. results
            conn.execute("""
                CREATE TABLE IF NOT EXISTS results (
                    id TEXT PRIMARY KEY,
                    match_id TEXT NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
                    home_score INTEGER,
                    away_score INTEGER,
                    home_halftime_score INTEGER,
                    away_halftime_score INTEGER,
                    home_extratime_score INTEGER,
                    away_extratime_score INTEGER,
                    home_penalties_score INTEGER,
                    away_penalties_score INTEGER,
                    winner_team_id TEXT REFERENCES teams(id) ON DELETE SET NULL,
                    created_at TEXT NOT NULL
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_results_match ON results (match_id);")

            # 8. match_statistics
            conn.execute("""
                CREATE TABLE IF NOT EXISTS match_statistics (
                    id TEXT PRIMARY KEY,
                    match_id TEXT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
                    metric_name TEXT NOT NULL,
                    home_value REAL,
                    away_value REAL,
                    raw_unit TEXT,
                    created_at TEXT NOT NULL,
                    UNIQUE(match_id, metric_name)
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_stats_match ON match_statistics (match_id);")

            # 9. data_sources
            conn.execute("""
                CREATE TABLE IF NOT EXISTS data_sources (
                    provider_id TEXT PRIMARY KEY,
                    display_name TEXT NOT NULL,
                    is_enabled INTEGER NOT NULL DEFAULT 1,
                    policy_status TEXT NOT NULL DEFAULT 'ACTIVE',
                    rate_limit_per_minute INTEGER,
                    created_at TEXT NOT NULL
                );
            """)

            # 10. sync_state
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sync_state (
                    key TEXT PRIMARY KEY,
                    provider_id TEXT NOT NULL REFERENCES data_sources(provider_id),
                    last_synced_at TEXT NOT NULL,
                    records_synced INTEGER NOT NULL DEFAULT 0,
                    status TEXT NOT NULL,
                    error_message TEXT
                );
            """)

            # 11. sync_logs
            conn.execute("""
                CREATE TABLE IF NOT EXISTS sync_logs (
                    id TEXT PRIMARY KEY,
                    provider_id TEXT NOT NULL REFERENCES data_sources(provider_id),
                    status TEXT NOT NULL,
                    records_synced INTEGER NOT NULL DEFAULT 0,
                    duration_ms INTEGER NOT NULL DEFAULT 0,
                    started_at TEXT NOT NULL,
                    finished_at TEXT NOT NULL,
                    error_message TEXT,
                    details_json TEXT
                );
            """)
            conn.execute("CREATE INDEX IF NOT EXISTS idx_sync_logs_provider ON sync_logs (provider_id);")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_sync_logs_started ON sync_logs (started_at);")

            # Default Sources registration
            now_iso = datetime.now(timezone.utc).isoformat()
            default_sources = [
                ("openfootball", "OpenFootball (Domaine Public CC0)", 1, "ACTIVE", None),
                ("thesportsdb", "TheSportsDB API (V1 Test)", 1, "ACTIVE", 100),
                ("football_data_org", "Football-Data.org (Plan Gratuit)", 1, "ACTIVE", 10),
                ("openligadb", "OpenLigaDB (REST API Open Data)", 1, "ACTIVE", 60),
                ("football_data_co_uk", "Football-Data.co.uk (CSV)", 1, "ACTIVE", 30),
                ("melbet_restricted", "MelBet (Désactivé par politique)", 0, "DISABLED_BY_POLICY", None),
            ]
            for pid, name, enabled, policy, rate in default_sources:
                conn.execute("""
                    INSERT OR IGNORE INTO data_sources (provider_id, display_name, is_enabled, policy_status, rate_limit_per_minute, created_at)
                    VALUES (?, ?, ?, ?, ?, ?);
                """, (pid, name, enabled, policy, rate, now_iso))

    def upsert_sport(self, sport: NormalizedSport) -> str:
        """Upserts a sport and returns its canonical id (reusing existing sport if matching code or id)."""
        now_iso = datetime.now(timezone.utc).isoformat()
        with self.get_connection() as conn:
            row = conn.execute("SELECT id FROM sports WHERE id = ? OR code = ?;", (sport.id, sport.code)).fetchone()
            if row:
                canonical_id = row["id"]
                conn.execute("""
                    UPDATE sports SET
                        name = ?,
                        icon_ref = coalesce(?, icon_ref),
                        source_provider = ?
                    WHERE id = ?;
                """, (sport.name, sport.icon_ref, sport.source_provider, canonical_id))
                return canonical_id
            else:
                conn.execute("""
                    INSERT INTO sports (id, name, code, icon_ref, source_provider, created_at)
                    VALUES (?, ?, ?, ?, ?, ?);
                """, (sport.id, sport.name, sport.code, sport.icon_ref, sport.source_provider, now_iso))
                return sport.id

    def upsert_competition(self, comp: NormalizedCompetition) -> None:
        now_iso = datetime.now(timezone.utc).isoformat()
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO competitions (id, sport_id, name, code, country, country_code, badge_url, tier, source_provider, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    code = excluded.code,
                    country = excluded.country,
                    country_code = excluded.country_code,
                    badge_url = excluded.badge_url,
                    tier = excluded.tier,
                    source_provider = excluded.source_provider;
            """, (comp.id, comp.sport_id, comp.name, comp.code, comp.country, comp.country_code, comp.badge_url, comp.tier, comp.source_provider, now_iso))

    def upsert_season(self, season: NormalizedSeason) -> None:
        now_iso = datetime.now(timezone.utc).isoformat()
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO seasons (id, competition_id, year_label, start_date, end_date, is_current, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(competition_id, year_label) DO UPDATE SET
                    is_current = excluded.is_current,
                    start_date = excluded.start_date,
                    end_date = excluded.end_date;
            """, (season.id, season.competition_id, season.year_label, season.start_date, season.end_date, 1 if season.is_current else 0, now_iso))

    def upsert_team(self, team: NormalizedTeam) -> None:
        now_iso = datetime.now(timezone.utc).isoformat()
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO teams (id, sport_id, name, short_name, tla, badge_url, country, elo_rating, source_provider, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    name = excluded.name,
                    short_name = excluded.short_name,
                    badge_url = excluded.badge_url,
                    country = excluded.country,
                    source_provider = excluded.source_provider;
            """, (team.id, team.sport_id, team.name, team.short_name, team.tla, team.badge_url, team.country, team.elo_rating, team.source_provider, now_iso))

    def _resolve_team_id(
        self,
        conn: sqlite3.Connection,
        sport_id: str,
        team_id: str,
        team_name: str,
        source_provider: str,
        now_iso: str,
    ) -> str:
        """
        Resolves or inserts a team canonically:
        1. Look up by (sport_id, name)
        2. Look up by id
        3. If not existing, insert with team_id
        Guarantees that the returned ID actually exists in teams table, preventing FK violations.
        """
        row = conn.execute(
            "SELECT id FROM teams WHERE sport_id = ? AND name = ?;",
            (sport_id, team_name),
        ).fetchone()
        if row:
            return row["id"]

        row_by_id = conn.execute(
            "SELECT id FROM teams WHERE id = ?;",
            (team_id,),
        ).fetchone()
        if row_by_id:
            return row_by_id["id"]

        conn.execute(
            """
            INSERT INTO teams (id, sport_id, name, source_provider, created_at)
            VALUES (?, ?, ?, ?, ?);
            """,
            (team_id, sport_id, team_name, source_provider, now_iso),
        )
        return team_id

    def save_matches_batch(self, matches: List[NormalizedMatch]) -> int:
        """
        Idempotent transactional batch save for matches, results and statistics.
        Validates data before insertion, detects duplicates, rolls back atomically on failure,
        and preserves existing data.
        """
        if not matches:
            return 0

        valid_matches, rejected = DataValidator.filter_and_sanitize(matches)
        if rejected:
            logger.warning(
                f"DataValidator rejected {len(rejected)} match records: "
                f"{[r[1] for r in rejected[:3]]}"
            )
        if not valid_matches:
            return 0

        now_iso = datetime.now(timezone.utc).isoformat()
        saved_count = 0

        conn = self.get_connection()
        try:
            conn.isolation_level = None
            conn.execute("BEGIN IMMEDIATE TRANSACTION;")
            for m in valid_matches:
                # 1. Resolve canonical teams first to satisfy FK
                resolved_home_id = self._resolve_team_id(
                    conn, m.sport_id, m.home_team_id, m.home_team_name, m.source_provider, now_iso
                )
                resolved_away_id = self._resolve_team_id(
                    conn, m.sport_id, m.away_team_id, m.away_team_name, m.source_provider, now_iso
                )

                # 2. Check if match already exists by ID or by composite natural key
                iso_z = m.utc_kickoff if m.utc_kickoff.endswith("Z") else f"{m.utc_kickoff}Z"
                iso_offset = m.utc_kickoff.replace("Z", "+00:00")

                existing_row = conn.execute("""
                    SELECT id FROM matches 
                    WHERE id = ? 
                       OR (competition_id = ? AND home_team_id = ? AND away_team_id = ? 
                           AND (utc_kickoff = ? OR utc_kickoff = ? OR utc_kickoff = ?));
                """, (
                    m.id,
                    m.competition_id, resolved_home_id, resolved_away_id,
                    m.utc_kickoff, iso_z, iso_offset
                )).fetchone()

                if existing_row:
                    actual_match_id = existing_row["id"]
                    conn.execute("""
                        UPDATE matches SET
                            status = ?,
                            matchday = coalesce(?, matchday),
                            round_label = coalesce(?, round_label),
                            current_minute = ?,
                            last_synced_at = ?,
                            source_provider = ?
                        WHERE id = ?;
                    """, (
                        m.status, m.matchday, m.round_label, m.current_minute,
                        now_iso, m.source_provider, actual_match_id
                    ))
                else:
                    actual_match_id = m.id
                    conn.execute("""
                        INSERT INTO matches (
                            id, sport_id, competition_id, season_id, home_team_id, away_team_id,
                            utc_kickoff, status, matchday, round_label, current_minute,
                            is_sample_data, source_provider, source_match_id, last_synced_at, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
                    """, (
                        m.id, m.sport_id, m.competition_id, m.season_id, resolved_home_id, resolved_away_id,
                        m.utc_kickoff, m.status, m.matchday, m.round_label, m.current_minute,
                        1 if m.is_sample_data else 0, m.source_provider, m.source_match_id,
                        now_iso, now_iso
                    ))
                saved_count += 1

                # 3. Upsert result if available
                if m.result:
                    res = m.result
                    winner_id = None
                    if res.winner_team_id:
                        if res.winner_team_id == m.home_team_id:
                            winner_id = resolved_home_id
                        elif res.winner_team_id == m.away_team_id:
                            winner_id = resolved_away_id
                        else:
                            winner_id = res.winner_team_id

                    conn.execute("""
                        INSERT INTO results (
                            id, match_id, home_score, away_score,
                            home_halftime_score, away_halftime_score,
                            home_extratime_score, away_extratime_score,
                            home_penalties_score, away_penalties_score,
                            winner_team_id, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT(match_id) DO UPDATE SET
                            home_score = excluded.home_score,
                            away_score = excluded.away_score,
                            home_halftime_score = coalesce(excluded.home_halftime_score, results.home_halftime_score),
                            away_halftime_score = coalesce(excluded.away_halftime_score, results.away_halftime_score),
                            winner_team_id = excluded.winner_team_id;
                    """, (
                        f"res_{actual_match_id}", actual_match_id,
                        res.home_score, res.away_score,
                        res.home_halftime_score, res.away_halftime_score,
                        res.home_extratime_score, res.away_extratime_score,
                        res.home_penalties_score, res.away_penalties_score,
                        winner_id, now_iso
                    ))

                # 4. Upsert statistics if available
                for stat in m.statistics:
                    conn.execute("""
                        INSERT INTO match_statistics (
                            id, match_id, metric_name, home_value, away_value, raw_unit, created_at
                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT(match_id, metric_name) DO UPDATE SET
                            home_value = excluded.home_value,
                            away_value = excluded.away_value;
                    """, (
                        f"stat_{actual_match_id}_{stat.metric_name}", actual_match_id,
                        stat.metric_name, stat.home_value, stat.away_value, stat.raw_unit, now_iso
                    ))

            conn.execute("COMMIT;")
        except Exception as e:
            conn.execute("ROLLBACK;")
            logger.error(f"Transaction aborted and rolled back during save_matches_batch: {e}")
            raise
        finally:
            conn.close()

        return saved_count

    def record_sync_state(self, report: SyncReport) -> None:
        """Records synchronization run in sync_state and sync_logs tables."""
        now_iso = report.finished_at.isoformat()
        with self.get_connection() as conn:
            conn.execute("""
                INSERT INTO sync_state (key, provider_id, last_synced_at, records_synced, status, error_message)
                VALUES (?, ?, ?, ?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET
                    last_synced_at = excluded.last_synced_at,
                    records_synced = excluded.records_synced,
                    status = excluded.status,
                    error_message = excluded.error_message;
            """, (report.key, report.provider_id, now_iso, report.records_synced, report.status, report.error_message))

            details_str = json.dumps(report.details) if report.details else None
            log_id = f"log_{report.provider_id}_{int(report.started_at.timestamp())}_{report.duration_ms}"
            conn.execute("""
                INSERT OR REPLACE INTO sync_logs (
                    id, provider_id, status, records_synced, duration_ms, started_at, finished_at, error_message, details_json
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
            """, (
                log_id,
                report.provider_id,
                report.status,
                report.records_synced,
                report.duration_ms,
                report.started_at.isoformat(),
                now_iso,
                report.error_message,
                details_str,
            ))

    def get_sync_logs(self, limit: int = 20) -> List[Dict[str, Any]]:
        """Returns recent sync log entries for local observability."""
        with self.get_connection() as conn:
            rows = conn.execute(
                "SELECT * FROM sync_logs ORDER BY started_at DESC LIMIT ?;",
                (limit,),
            ).fetchall()
            return [dict(r) for r in rows]

    def get_summary_stats(self) -> Dict[str, Any]:
        """Returns statistics of records currently in SQLite."""
        with self.get_connection() as conn:
            sports_cnt = conn.execute("SELECT COUNT(*) FROM sports;").fetchone()[0]
            comps_cnt = conn.execute("SELECT COUNT(*) FROM competitions;").fetchone()[0]
            teams_cnt = conn.execute("SELECT COUNT(*) FROM teams;").fetchone()[0]
            matches_cnt = conn.execute("SELECT COUNT(*) FROM matches;").fetchone()[0]
            results_cnt = conn.execute("SELECT COUNT(*) FROM results;").fetchone()[0]
            stats_cnt = conn.execute("SELECT COUNT(*) FROM match_statistics;").fetchone()[0]
            
            # Group by source
            sources_breakdown = {}
            for row in conn.execute("SELECT source_provider, COUNT(*) as cnt FROM matches GROUP BY source_provider;"):
                sources_breakdown[row["source_provider"]] = row["cnt"]
                
            # Latest sync states
            sync_states = []
            for row in conn.execute("SELECT * FROM sync_state ORDER BY last_synced_at DESC LIMIT 10;"):
                sync_states.append(dict(row))

            return {
                "sports": sports_cnt,
                "competitions": comps_cnt,
                "teams": teams_cnt,
                "matches": matches_cnt,
                "results": results_cnt,
                "match_statistics": stats_cnt,
                "matches_by_provider": sources_breakdown,
                "recent_sync_states": sync_states,
            }
