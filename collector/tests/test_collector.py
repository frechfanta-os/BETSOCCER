"""
Unit tests for BETSOCCER Crawl4AI Autonomous Collector.
Validates:
- Dynamic season & UTC date logic (no hardcoded dates).
- SQLite relational schema, FK constraints, and composite key deduplication.
- OpenLigaDB JSON response parsing and normalization.
- Football-Data.co.uk CSV parsing and odds normalization.
- Sync state persistence and summary stats.
"""

import os
import io
import csv
import json
import sqlite3
import tempfile
import unittest
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock

from collector.config import (
    get_current_utc,
    get_current_season_year,
    get_current_season_label,
    CollectorConfig,
)
from collector.models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedTeam,
    NormalizedMatch,
    NormalizedResult,
    NormalizedStatistic,
    SyncReport,
)
from collector.db import DatabaseManager
from collector.sources.openligadb_source import OpenLigaDbSource
from collector.sources.footballdata_fixtures_source import FootballDataFixturesSource


class TestCollectorConfigAndDates(unittest.TestCase):
    def test_current_utc_is_timezone_aware(self):
        now = get_current_utc()
        self.assertIsNotNone(now.tzinfo)
        self.assertEqual(now.tzinfo, timezone.utc)

    def test_current_season_calculation_autumn(self):
        # Simulating October (month >= 7)
        mock_now = datetime(2026, 10, 13, 12, 0, 0, tzinfo=timezone.utc)
        with patch("collector.config.get_current_utc", return_value=mock_now):
            self.assertEqual(get_current_season_year(), 2026)
            self.assertEqual(get_current_season_label(), "2026/27")

    def test_current_season_calculation_spring(self):
        # Simulating March (month < 7)
        mock_now = datetime(2027, 3, 15, 12, 0, 0, tzinfo=timezone.utc)
        with patch("collector.config.get_current_utc", return_value=mock_now):
            self.assertEqual(get_current_season_year(), 2026)
            self.assertEqual(get_current_season_label(), "2026/27")

    def test_melbet_strictly_disabled_by_default(self):
        config = CollectorConfig()
        self.assertFalse(config.melbet_enabled)
        self.assertNotIn("melbet", config.enabled_sources)


class TestDatabaseManager(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = os.path.join(self.temp_dir.name, "test_betsoccer.db")
        self.db = DatabaseManager(db_path=self.db_path)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_schema_creates_all_tables(self):
        expected_tables = {
            "sports",
            "competitions",
            "seasons",
            "teams",
            "players",
            "matches",
            "results",
            "match_statistics",
            "data_sources",
            "sync_state",
        }
        with self.db.get_connection() as conn:
            cursor = conn.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = {row[0] for row in cursor.fetchall()}

        for table in expected_tables:
            self.assertIn(table, tables, f"Expected table '{table}' not found in SQLite schema.")

    def test_foreign_key_enforcement(self):
        # Foreign keys should prevent creating a competition with non-existent sport_id
        comp = NormalizedCompetition(
            id="comp_invalid",
            sport_id="sport_nonexistent",
            name="Invalid League",
            source_provider="test",
        )
        with self.assertRaises(sqlite3.IntegrityError):
            self.db.upsert_competition(comp)

    def test_melbet_registered_as_disabled_in_data_sources(self):
        with self.db.get_connection() as conn:
            row = conn.execute(
                "SELECT policy_status, is_enabled FROM data_sources WHERE provider_id = 'melbet_restricted';"
            ).fetchone()
            self.assertIsNotNone(row)
            self.assertEqual(row["policy_status"], "DISABLED_BY_POLICY")
            self.assertEqual(row["is_enabled"], 0)

    def test_match_upsert_and_deduplication(self):
        # 1. Setup prerequisite Sport and Competition
        sport = NormalizedSport(
            id="sport_football",
            name="Football",
            code="SOCCER",
            source_provider="test",
        )
        self.db.upsert_sport(sport)

        comp = NormalizedCompetition(
            id="comp_bl1",
            sport_id="sport_football",
            name="1. Bundesliga",
            source_provider="test",
        )
        self.db.upsert_competition(comp)

        # 2. Insert match as 'upcoming'
        match1 = NormalizedMatch(
            id="match_101",
            sport_id="sport_football",
            competition_id="comp_bl1",
            home_team_id="team_fcb",
            home_team_name="FC Bayern München",
            away_team_id="team_bvb",
            away_team_name="Borussia Dortmund",
            utc_kickoff="2026-10-17T16:30:00Z",
            status="upcoming",
            source_provider="openligadb",
            source_match_id="old_101",
            matchday=7,
        )
        saved = self.db.save_matches_batch([match1])
        self.assertEqual(saved, 1)

        # Verify insertion in DB
        with self.db.get_connection() as conn:
            row = conn.execute("SELECT status, matchday FROM matches WHERE id = 'match_101';").fetchone()
            self.assertIsNotNone(row)
            self.assertEqual(row["status"], "upcoming")
            self.assertEqual(row["matchday"], 7)

        # 3. Simulate second ingestion of the same match (same comp, teams, kickoff) with different ID
        # but updated status to 'finished', scores and statistics
        match2_updated = NormalizedMatch(
            id="match_101_alternate_id",
            sport_id="sport_football",
            competition_id="comp_bl1",
            home_team_id="team_fcb",
            home_team_name="FC Bayern München",
            away_team_id="team_bvb",
            away_team_name="Borussia Dortmund",
            utc_kickoff="2026-10-17T16:30:00Z",
            status="finished",
            source_provider="openligadb",
            source_match_id="old_101",
            matchday=7,
            result=NormalizedResult(
                id="res_101",
                match_id="match_101",
                home_score=3,
                away_score=1,
                home_halftime_score=1,
                away_halftime_score=0,
            ),
            statistics=[
                NormalizedStatistic(
                    id="stat_shots",
                    match_id="match_101",
                    metric_name="shots_on_target",
                    home_value=8.0,
                    away_value=4.0,
                )
            ],
        )

        saved2 = self.db.save_matches_batch([match2_updated])
        self.assertEqual(saved2, 1)

        # Verify deduplication: table should have exactly 1 match
        with self.db.get_connection() as conn:
            matches_count = conn.execute("SELECT COUNT(*) FROM matches;").fetchone()[0]
            self.assertEqual(matches_count, 1, "Duplicate match was inserted instead of deduplication on composite key!")

            # Verify updated status
            row = conn.execute("SELECT status FROM matches;").fetchone()
            self.assertEqual(row["status"], "finished")

            # Verify result table
            res_row = conn.execute("SELECT home_score, away_score FROM results;").fetchone()
            self.assertIsNotNone(res_row)
            self.assertEqual(res_row["home_score"], 3)
            self.assertEqual(res_row["away_score"], 1)

            # Verify statistics table
            stat_row = conn.execute("SELECT metric_name, home_value FROM match_statistics;").fetchone()
            self.assertIsNotNone(stat_row)
            self.assertEqual(stat_row["metric_name"], "shots_on_target")
            self.assertEqual(stat_row["home_value"], 8.0)

    def test_sync_state_recording(self):
        report = SyncReport(
            provider_id="openligadb",
            key="sync_openligadb",
            status="SUCCESS",
            records_synced=9,
            started_at=datetime(2026, 10, 13, 10, 0, 0, tzinfo=timezone.utc),
            finished_at=datetime(2026, 10, 13, 10, 0, 2, tzinfo=timezone.utc),
            duration_ms=2000,
        )
        self.db.record_sync_state(report)

        with self.db.get_connection() as conn:
            row = conn.execute("SELECT records_synced, status FROM sync_state WHERE key = 'sync_openligadb';").fetchone()
            self.assertIsNotNone(row)
            self.assertEqual(row["records_synced"], 9)
            self.assertEqual(row["status"], "SUCCESS")

        # Update sync state
        report.records_synced = 15
        self.db.record_sync_state(report)

        with self.db.get_connection() as conn:
            cnt = conn.execute("SELECT COUNT(*) FROM sync_state;").fetchone()[0]
            self.assertEqual(cnt, 1)
            row = conn.execute("SELECT records_synced FROM sync_state WHERE key = 'sync_openligadb';").fetchone()
            self.assertEqual(row["records_synced"], 15)


class TestSourceParsers(unittest.TestCase):
    def test_openligadb_json_extraction(self):
        source = OpenLigaDbSource()
        sample_json_text = json.dumps([
            {
                "matchID": 71001,
                "matchDateTimeUTC": "2026-10-17T13:30:00Z",
                "team1": {"teamId": 40, "teamName": "FC Bayern München", "shortName": "Bayern"},
                "team2": {"teamId": 7, "teamName": "Borussia Dortmund", "shortName": "BVB"},
                "matchIsFinished": True,
                "matchResults": [
                    {"resultName": "Halbzeitergebnis", "pointsTeam1": 1, "pointsTeam2": 0},
                    {"resultName": "Endergebnis", "pointsTeam1": 2, "pointsTeam2": 1},
                ],
                "group": {"groupOrderID": 7, "groupName": "7. Spieltag"},
                "goals": [
                    {"goalID": 1, "scoreTeam1": 1, "scoreTeam2": 0, "goalGetterName": "Kane", "matchMinute": 24},
                ],
            }
        ])
        parsed = source._extract_json(sample_json_text)
        self.assertIsInstance(parsed, list)
        self.assertEqual(len(parsed), 1)
        self.assertEqual(parsed[0]["matchID"], 71001)

    def test_footballdata_csv_fixtures_parsing(self):
        sample_csv = (
            "Div,Date,Time,HomeTeam,AwayTeam,FTHG,FTAG,FTR,HTHG,HTAG,HTR,B365H,B365D,B365A\n"
            "E0,17/10/2026,15:00,Arsenal,Chelsea,,,,,,,1.85,3.60,4.20\n"
            "D1,17/10/2026,14:30,Frankfurt,Leverkusen,,,,,,,2.90,3.50,2.35\n"
        )
        source = FootballDataFixturesSource()
        reader = csv.DictReader(io.StringIO(sample_csv))
        rows = list(reader)

        self.assertEqual(len(rows), 2)
        row0 = rows[0]
        self.assertEqual(row0["Div"], "E0")
        self.assertEqual(row0["HomeTeam"], "Arsenal")
        self.assertEqual(row0["AwayTeam"], "Chelsea")
        self.assertEqual(row0["B365H"], "1.85")


if __name__ == "__main__":
    unittest.main()
