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


    def test_team_canonical_resolution_avoids_fk_violation(self):
        # Setup Sport & Comp
        sport = NormalizedSport(id="sport_football", name="Football", code="SOCCER", source_provider="test")
        self.db.upsert_sport(sport)
        comp = NormalizedCompetition(id="comp_pl", sport_id="sport_football", name="Premier League", source_provider="test")
        self.db.upsert_competition(comp)

        # Team inserted with ID 'team_arsenal_fc'
        self.db.upsert_team(NormalizedTeam(id="team_arsenal_fc", sport_id="sport_football", name="Arsenal", source_provider="tsdb"))

        # Ingest a match where home_team_id is 'team_arsenal' (different id, same name)
        match = NormalizedMatch(
            id="match_ars_che",
            sport_id="sport_football",
            competition_id="comp_pl",
            home_team_id="team_arsenal",
            home_team_name="Arsenal",
            away_team_id="team_chelsea",
            away_team_name="Chelsea",
            utc_kickoff="2026-10-18T15:00:00Z",
            status="finished",
            source_provider="fduk",
            source_match_id="fduk_1",
            result=NormalizedResult(
                id="res_ars_che",
                match_id="match_ars_che",
                home_score=2,
                away_score=0,
                winner_team_id="team_arsenal",
            ),
        )
        saved = self.db.save_matches_batch([match])
        self.assertEqual(saved, 1)

        # Confirm match home_team_id was resolved canonically to team_arsenal_fc
        with self.db.get_connection() as conn:
            row = conn.execute("SELECT home_team_id FROM matches WHERE id = 'match_ars_che';").fetchone()
            self.assertEqual(row["home_team_id"], "team_arsenal_fc")
            res_row = conn.execute("SELECT winner_team_id FROM results WHERE match_id = 'match_ars_che';").fetchone()
            self.assertEqual(res_row["winner_team_id"], "team_arsenal_fc")

    def test_idempotent_double_sync(self):
        sport = NormalizedSport(id="sport_football", name="Football", code="SOCCER", source_provider="test")
        self.db.upsert_sport(sport)
        comp = NormalizedCompetition(id="comp_pl", sport_id="sport_football", name="Premier League", source_provider="test")
        self.db.upsert_competition(comp)

        matches = [
            NormalizedMatch(
                id=f"match_{i}",
                sport_id="sport_football",
                competition_id="comp_pl",
                home_team_id=f"team_h_{i}",
                home_team_name=f"Home {i}",
                away_team_id=f"team_a_{i}",
                away_team_name=f"Away {i}",
                utc_kickoff=f"2026-10-{10+i}T15:00:00Z",
                status="finished",
                source_provider="fduk",
                source_match_id=f"src_{i}",
                result=NormalizedResult(
                    id=f"res_{i}",
                    match_id=f"match_{i}",
                    home_score=1,
                    away_score=0,
                ),
            )
            for i in range(5)
        ]

        # First save
        cnt1 = self.db.save_matches_batch(matches)
        self.assertEqual(cnt1, 5)

        # Second save (idempotency check)
        cnt2 = self.db.save_matches_batch(matches)
        self.assertEqual(cnt2, 5)

        with self.db.get_connection() as conn:
            total_matches = conn.execute("SELECT COUNT(*) FROM matches;").fetchone()[0]
            total_results = conn.execute("SELECT COUNT(*) FROM results;").fetchone()[0]
            self.assertEqual(total_matches, 5)
            self.assertEqual(total_results, 5)


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
                    {"resultName": "Halbzeitergebnis", "pointsTeam1": 1, "pointsTeam2": 0, "resultOrderID": 1},
                    {"resultName": "Endergebnis", "pointsTeam1": 2, "pointsTeam2": 1, "resultOrderID": 2},
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

    def test_openligadb_handball_result_normalization(self):
        source = OpenLigaDbSource()
        item = {
            "matchID": 901,
            "matchDateTimeUTC": "2023-09-01T17:00:00Z",
            "team1": {"teamId": 10, "teamName": "THW Kiel"},
            "team2": {"teamId": 20, "teamName": "SG Flensburg-Handewitt"},
            "matchIsFinished": True,
            "matchResults": [
                {"resultName": "Endergebnis", "pointsTeam1": 28, "pointsTeam2": 26, "resultOrderID": 1}
            ],
        }
        match = source._normalize_match(item, "sport_handball", "comp_old_hbl", "season_2023")
        self.assertIsNotNone(match)
        self.assertEqual(match.status, "finished")
        self.assertIsNotNone(match.result)
        self.assertEqual(match.result.home_score, 28)
        self.assertEqual(match.result.away_score, 26)
        self.assertEqual(match.result.winner_team_id, "team_thw_kiel")

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

    def test_footballdata_historical_row_normalization(self):
        from collector.sources.footballdata_historical_source import FootballDataHistoricalSource
        source = FootballDataHistoricalSource()
        row = {
            "Div": "E0",
            "Date": "11/08/2023",
            "Time": "20:00",
            "HomeTeam": "Burnley",
            "AwayTeam": "Man City",
            "FTHG": "0",
            "FTAG": "3",
            "FTR": "A",
            "HTHG": "0",
            "HTAG": "2",
            "HTR": "A",
            "Referee": "C Pawson",
            "HS": "6",
            "AS": "17",
            "HST": "1",
            "AST": "8",
            "HF": "11",
            "AF": "8",
            "HC": "6",
            "AC": "5",
            "HY": "0",
            "AY": "0",
            "HR": "1",
            "AR": "0",
        }
        match = source._normalize_csv_row(row, "sport_football", "comp_fduk_e0", "season_e0_2023", "E0")
        self.assertIsNotNone(match)
        self.assertEqual(match.status, "finished")
        self.assertEqual(match.utc_kickoff, "2023-08-11T20:00:00Z")
        self.assertIsNotNone(match.result)
        self.assertEqual(match.result.home_score, 0)
        self.assertEqual(match.result.away_score, 3)
        self.assertEqual(match.result.home_halftime_score, 0)
        self.assertEqual(match.result.away_halftime_score, 2)
        self.assertEqual(match.result.winner_team_id, "team_man_city")

        # Verify statistics extracted
        stats_by_name = {s.metric_name: s for s in match.statistics}
        self.assertIn("shots", stats_by_name)
        self.assertEqual(stats_by_name["shots"].home_value, 6.0)
        self.assertEqual(stats_by_name["shots"].away_value, 17.0)
        self.assertIn("shots_on_target", stats_by_name)
        self.assertEqual(stats_by_name["shots_on_target"].away_value, 8.0)
        self.assertIn("red_cards", stats_by_name)
        self.assertEqual(stats_by_name["red_cards"].home_value, 1.0)
        self.assertIn("referee_assigned", stats_by_name)
        self.assertEqual(stats_by_name["referee_assigned"].raw_unit, "C Pawson")


class TestDataValidator(unittest.TestCase):
    def setUp(self):
        from collector.validator import DataValidator
        self.validator = DataValidator

    def _make_valid_match(self):
        return NormalizedMatch(
            id="test_m1",
            sport_id="sport_football",
            competition_id="comp_pl",
            home_team_id="team_ars",
            home_team_name="Arsenal",
            away_team_id="team_che",
            away_team_name="Chelsea",
            utc_kickoff="2026-10-18T15:00:00Z",
            status="finished",
            source_provider="test",
            result=NormalizedResult(
                id="res_m1",
                match_id="test_m1",
                home_score=2,
                away_score=1,
                home_halftime_score=1,
                away_halftime_score=0,
            ),
        )

    def test_valid_match_passes_validation(self):
        m = self._make_valid_match()
        valid, reason = self.validator.validate_match(m)
        self.assertTrue(valid)
        self.assertIsNone(reason)

    def test_empty_required_fields_rejected(self):
        m = self._make_valid_match()
        m.home_team_name = "   "
        valid, reason = self.validator.validate_match(m)
        self.assertFalse(valid)
        self.assertIn("empty home_team_name", reason)

    def test_identical_teams_rejected(self):
        m = self._make_valid_match()
        m.away_team_name = "Arsenal"
        valid, reason = self.validator.validate_match(m)
        self.assertFalse(valid)
        self.assertIn("identical home and away teams", reason)

    def test_invalid_status_rejected(self):
        m = self._make_valid_match()
        m.status = "invalid_status_xyz"
        valid, reason = self.validator.validate_match(m)
        self.assertFalse(valid)
        self.assertIn("invalid status", reason)

    def test_negative_score_rejected(self):
        m = self._make_valid_match()
        m.result.home_score = -1
        valid, reason = self.validator.validate_match(m)
        self.assertFalse(valid)
        self.assertIn("negative home score", reason)

    def test_halftime_score_greater_than_fulltime_rejected(self):
        m = self._make_valid_match()
        m.result.home_score = 1
        m.result.home_halftime_score = 2  # Impossible in football
        valid, reason = self.validator.validate_match(m)
        self.assertFalse(valid)
        self.assertIn("home halftime (2) > fulltime (1)", reason)

    def test_invalid_kickoff_rejected(self):
        m = self._make_valid_match()
        m.utc_kickoff = "not-a-date"
        valid, reason = self.validator.validate_match(m)
        self.assertFalse(valid)
        self.assertIn("Invalid ISO-8601", reason)


class TestHttpCacheManager(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.cache_file = os.path.join(self.temp_dir.name, "test_cache.json")
        from collector.cache import HttpCacheManager
        self.cache = HttpCacheManager(cache_file=self.cache_file)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_cache_store_and_retrieve(self):
        url = "https://example.com/data.csv"
        self.cache.store_response(url, "a,b,c\n1,2,3", etag='"12345"', last_modified="Mon, 12 Oct 2026 10:00:00 GMT")
        
        # Check retrieval
        content = self.cache.get_cached_content(url)
        self.assertEqual(content, "a,b,c\n1,2,3")

        # Check headers
        headers = self.cache.get_conditional_headers(url)
        self.assertEqual(headers.get("If-None-Match"), '"12345"')
        self.assertEqual(headers.get("If-Modified-Since"), "Mon, 12 Oct 2026 10:00:00 GMT")


class TestDatabaseManagerPhase4(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = os.path.join(self.temp_dir.name, "test_p4.db")
        self.db = DatabaseManager(db_path=self.db_path)

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_sync_logs_table_and_persistence(self):
        report = SyncReport(
            provider_id="football_data_co_uk",
            key="sync_test_key",
            status="SUCCESS",
            records_synced=100,
            started_at=datetime(2026, 10, 14, 8, 0, 0, tzinfo=timezone.utc),
            finished_at=datetime(2026, 10, 14, 8, 0, 5, tzinfo=timezone.utc),
            duration_ms=5000,
            details={"leagues": ["E0", "SP1"]},
        )
        self.db.record_sync_state(report)
        logs = self.db.get_sync_logs(limit=10)
        self.assertEqual(len(logs), 1)
        self.assertEqual(logs[0]["provider_id"], "football_data_co_uk")
        self.assertEqual(logs[0]["records_synced"], 100)
        self.assertEqual(logs[0]["duration_ms"], 5000)

    def test_serie_a_and_ligue_1_mappings(self):
        from collector.sources.footballdata_historical_source import HISTORICAL_LEAGUE_MAP
        self.assertIn("I1", HISTORICAL_LEAGUE_MAP)
        self.assertEqual(HISTORICAL_LEAGUE_MAP["I1"]["name"], "Serie A")
        self.assertEqual(HISTORICAL_LEAGUE_MAP["I1"]["country"], "Italy")

        self.assertIn("F1", HISTORICAL_LEAGUE_MAP)
        self.assertEqual(HISTORICAL_LEAGUE_MAP["F1"]["name"], "Ligue 1")
        self.assertEqual(HISTORICAL_LEAGUE_MAP["F1"]["country"], "France")


if __name__ == "__main__":
    unittest.main()

