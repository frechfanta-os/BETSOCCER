"""
Phase 4.1 Unit Tests: Crawl4AI Scraping Diagnostic, Data Recovery & MelBet Connector Audit.

Validates the 10 targeted test scenarios:
1. HTML table extraction from valid fixture.
2. JSON-LD SportsEvent extraction from valid fixture.
3. Empty HTML content handling.
4. Altered or corrupted HTML structure resilience.
5. Network timeout and retry mechanism simulation.
6. Kickoff date normalization across diverse formats into UTC ISO-8601.
7. Score parsing, formatting variations, and negative score rejection.
8. Team canonical resolution avoiding SQLite FK violations.
9. Composite key deduplication and idempotent persistence.
10. MelBet connector configurable status, robots.txt restriction, and zero-odds policy enforcement.
"""

import os
import unittest
import tempfile
import sqlite3
import asyncio
from datetime import datetime, timezone
from unittest.mock import patch, MagicMock, AsyncMock

from collector.sources.html_scraper import HtmlSportsParser, HtmlScraperSource
from collector.sources.melbet_source import MelbetSource
from collector.connectors import ConnectorAccessStatus, ConnectorRegistry
from collector.models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedTeam,
    NormalizedMatch,
    NormalizedResult,
    SyncReport,
)
from collector.db import DatabaseManager
from collector.validator import DataValidator


class TestPhase41ScrapingAndConnectors(unittest.TestCase):
    def setUp(self):
        self.fixture_path = os.path.join(
            os.path.dirname(__file__), "fixtures", "sample_matches.html"
        )
        with open(self.fixture_path, "r", encoding="utf-8") as f:
            self.fixture_html = f.read()

        self.temp_dir = tempfile.TemporaryDirectory()
        self.db_path = os.path.join(self.temp_dir.name, "test_p4_1.db")
        self.db = DatabaseManager(db_path=self.db_path)

        # Prepopulate Sport and Competition in DB
        self.sport = NormalizedSport(
            id="sport_football",
            name="Football",
            code="SOCCER",
            source_provider="test",
        )
        self.db.upsert_sport(self.sport)

        self.competition = NormalizedCompetition(
            id="comp_pl",
            sport_id="sport_football",
            name="Premier League",
            code="PL",
            source_provider="test",
        )
        self.db.upsert_competition(self.competition)

    def tearDown(self):
        self.temp_dir.cleanup()

    # Scenario 1: HTML table extraction from valid fixture
    def test_01_html_table_extraction(self):
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(self.fixture_html, "html.parser")
        matches = HtmlSportsParser.extract_from_tables(
            soup=soup,
            sport_id="sport_football",
            competition_id="comp_pl",
            season_id="season_2026",
            provider_id="html_test",
        )
        self.assertEqual(len(matches), 3)

        # Match 1: Manchester City vs Liverpool (2-0, finished)
        m1 = matches[0]
        self.assertEqual(m1.home_team_name, "Manchester City")
        self.assertEqual(m1.away_team_name, "Liverpool")
        self.assertEqual(m1.status, "finished")
        self.assertEqual(m1.utc_kickoff, "2026-10-17T15:00:00Z")
        self.assertIsNotNone(m1.result)
        self.assertEqual(m1.result.home_score, 2)
        self.assertEqual(m1.result.away_score, 0)
        self.assertEqual(m1.result.winner_team_id, "team_manchester_city")

        # Match 2: Real Madrid vs Barcelona (1-1, finished)
        m2 = matches[1]
        self.assertEqual(m2.home_team_name, "Real Madrid")
        self.assertEqual(m2.away_team_name, "Barcelona")
        self.assertEqual(m2.status, "finished")
        self.assertIsNotNone(m2.result)
        self.assertEqual(m2.result.home_score, 1)
        self.assertEqual(m2.result.away_score, 1)
        self.assertIsNone(m2.result.winner_team_id)  # Draw

        # Match 3: Bayern Munich vs Borussia Dortmund (upcoming)
        m3 = matches[2]
        self.assertEqual(m3.home_team_name, "Bayern Munich")
        self.assertEqual(m3.away_team_name, "Borussia Dortmund")
        self.assertEqual(m3.status, "upcoming")
        self.assertIsNone(m3.result)

    # Scenario 2: JSON-LD SportsEvent extraction from valid fixture
    def test_02_json_ld_sportsevent_extraction(self):
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(self.fixture_html, "html.parser")
        matches = HtmlSportsParser.extract_from_json_ld(
            soup=soup,
            sport_id="sport_football",
            competition_id="comp_pl",
            season_id="season_2026",
            provider_id="html_test",
        )
        self.assertEqual(len(matches), 1)
        m = matches[0]
        self.assertEqual(m.home_team_name, "Arsenal")
        self.assertEqual(m.away_team_name, "Chelsea")
        self.assertEqual(m.utc_kickoff, "2026-10-18T16:30:00Z")
        self.assertEqual(m.status, "finished")
        self.assertIsNotNone(m.result)
        self.assertEqual(m.result.home_score, 3)
        self.assertEqual(m.result.away_score, 1)
        self.assertEqual(m.result.winner_team_id, "team_arsenal")

    # Scenario 3: Empty HTML content handling
    def test_03_empty_html_content_handling(self):
        matches_empty = HtmlSportsParser.parse_html(
            html_content="",
            sport_id="sport_football",
            competition_id="comp_pl",
            season_id="season_2026",
        )
        self.assertEqual(matches_empty, [])

        matches_whitespace = HtmlSportsParser.parse_html(
            html_content="   \n\t  ",
            sport_id="sport_football",
            competition_id="comp_pl",
            season_id="season_2026",
        )
        self.assertEqual(matches_whitespace, [])

    # Scenario 4: Altered or corrupted HTML structure resilience
    def test_04_corrupted_html_resilience(self):
        corrupted_html = """
        <html><body>
          <table class="matches-table">
            <tr><th>Missing</th><th>Headers</th></tr>
            <tr class="match-row"><td>Only one td</td></tr>
            <tr class="match-row"><td class="broken">No teams</td><td>2026-10-20</td></tr>
            <tr class="match-row">
              <td class="match-date">2026-10-21</td>
              <td class="match-time">20:45</td>
              <td class="home-team">Inter Milan</td>
              <td class="match-score">2 - 1</td>
              <td class="away-team">Juventus</td>
              <td class="match-status">Finished</td>
            </tr>
          </table>
        </body></html>
        """
        matches = HtmlSportsParser.parse_html(
            html_content=corrupted_html,
            sport_id="sport_football",
            competition_id="comp_pl",
            season_id="season_2026",
        )
        # Should gracefully skip malformed rows and safely extract the valid one
        self.assertEqual(len(matches), 1)
        self.assertEqual(matches[0].home_team_name, "Inter Milan")
        self.assertEqual(matches[0].away_team_name, "Juventus")

    # Scenario 5: Network timeout and retry mechanism simulation
    def test_05_network_retry_and_timeout_simulation(self):
        source = HtmlScraperSource(
            urls=["https://test.invalid/matches.html"],
            max_retries=2,
            rate_limit_delay=0.01,
        )

        crawler_mock = MagicMock()
        crawler_mock.arun = AsyncMock(
            return_value=MagicMock(success=False, error_message="net::ERR_CONNECTION_TIMED_OUT")
        )

        async def run_collect():
            return await source.collect(crawler_mock)

        sports, comps, seasons, matches, report = asyncio.run(run_collect())
        self.assertEqual(len(matches), 0)
        self.assertEqual(report.status, "ERROR")
        self.assertIn("ERR_CONNECTION_TIMED_OUT", report.error_message)

    # Scenario 6: Kickoff date normalization across diverse formats
    def test_06_kickoff_date_normalization(self):
        # 1. ISO string with Z
        self.assertEqual(
            HtmlSportsParser.parse_kickoff("2026-10-18T16:30:00Z"),
            "2026-10-18T16:30:00Z",
        )
        # 2. ISO string with +02:00 offset
        self.assertEqual(
            HtmlSportsParser.parse_kickoff("2026-10-18T18:30:00+02:00"),
            "2026-10-18T16:30:00Z",
        )
        # 3. YYYY-MM-DD + HH:MM
        self.assertEqual(
            HtmlSportsParser.parse_kickoff("2026-10-17", "15:00"),
            "2026-10-17T15:00:00Z",
        )
        # 4. DD/MM/YYYY + HH:MM
        self.assertEqual(
            HtmlSportsParser.parse_kickoff("17/10/2026", "20:45"),
            "2026-10-17T20:45:00Z",
        )
        # 5. DD.MM.YYYY
        self.assertEqual(
            HtmlSportsParser.parse_kickoff("18.10.2026"),
            "2026-10-18T00:00:00Z",
        )
        # 6. Invalid string returns None
        self.assertIsNone(HtmlSportsParser.parse_kickoff("invalid-date-string"))

    # Scenario 7: Score parsing, formatting variations, and negative score rejection
    def test_07_score_parsing_and_validation(self):
        # Formatting variations
        self.assertEqual(HtmlSportsParser.parse_score("2 - 0"), (2, 0))
        self.assertEqual(HtmlSportsParser.parse_score("1:1"), (1, 1))
        self.assertEqual(HtmlSportsParser.parse_score("3-2"), (3, 2))
        self.assertEqual(HtmlSportsParser.parse_score("  0 : 4  "), (0, 4))
        self.assertEqual(HtmlSportsParser.parse_score("-"), (None, None))
        self.assertEqual(HtmlSportsParser.parse_score("vs"), (None, None))
        self.assertEqual(HtmlSportsParser.parse_score("TBD"), (None, None))

        # Negative score rejected by DataValidator
        match = NormalizedMatch(
            id="m_neg",
            sport_id="sport_football",
            competition_id="comp_pl",
            home_team_id="team_h",
            home_team_name="Home Team",
            away_team_id="team_a",
            away_team_name="Away Team",
            utc_kickoff="2026-10-18T15:00:00Z",
            status="finished",
            source_provider="test",
            result=NormalizedResult(
                id="res_neg",
                match_id="m_neg",
                home_score=-1,
                away_score=2,
            ),
        )
        is_valid, reason = DataValidator.validate_match(match)
        self.assertFalse(is_valid)
        self.assertIn("negative home score", reason)

    # Scenario 8: Team canonical resolution avoiding SQLite FK violations
    def test_08_team_canonical_resolution_and_fk_integrity(self):
        # Insert pre-existing canonical team
        canonical_team = NormalizedTeam(
            id="team_liverpool_fc",
            sport_id="sport_football",
            name="Liverpool",
            source_provider="thesportsdb",
        )
        self.db.upsert_team(canonical_team)

        # Ingest match where Liverpool has alternative source ID "team_liverpool"
        match = NormalizedMatch(
            id="m_lfc_mcfc",
            sport_id="sport_football",
            competition_id="comp_pl",
            home_team_id="team_liverpool",
            home_team_name="Liverpool",
            away_team_id="team_manchester_city",
            away_team_name="Manchester City",
            utc_kickoff="2026-10-18T17:30:00Z",
            status="finished",
            source_provider="html_scraper",
            result=NormalizedResult(
                id="res_lfc_mcfc",
                match_id="m_lfc_mcfc",
                home_score=1,
                away_score=0,
                winner_team_id="team_liverpool",
            ),
        )
        saved = self.db.save_matches_batch([match])
        self.assertEqual(saved, 1)

        # Confirm home_team_id was mapped to canonical ID "team_liverpool_fc"
        with self.db.get_connection() as conn:
            row = conn.execute(
                "SELECT home_team_id FROM matches WHERE id = 'm_lfc_mcfc';"
            ).fetchone()
            self.assertEqual(row["home_team_id"], "team_liverpool_fc")

            # Check foreign key integrity
            fks = conn.execute("PRAGMA foreign_key_check;").fetchall()
            self.assertEqual(len(fks), 0)

    # Scenario 9: Composite key deduplication and idempotent persistence
    def test_09_composite_key_deduplication_and_idempotence(self):
        # Ingest match twice with slight updates (e.g. from upcoming to finished)
        m_upcoming = NormalizedMatch(
            id="m_dedup_1",
            sport_id="sport_football",
            competition_id="comp_pl",
            home_team_id="team_tottenham",
            home_team_name="Tottenham Hotspur",
            away_team_id="team_newcastle",
            away_team_name="Newcastle United",
            utc_kickoff="2026-10-19T19:00:00Z",
            status="upcoming",
            source_provider="html_source_a",
        )
        self.db.save_matches_batch([m_upcoming])

        # Second ingestion has alternate match ID but same comp, teams, and kickoff
        m_finished = NormalizedMatch(
            id="m_dedup_2_alternate",
            sport_id="sport_football",
            competition_id="comp_pl",
            home_team_id="team_tottenham",
            home_team_name="Tottenham Hotspur",
            away_team_id="team_newcastle",
            away_team_name="Newcastle United",
            utc_kickoff="2026-10-19T19:00:00Z",
            status="finished",
            source_provider="html_source_b",
            result=NormalizedResult(
                id="res_dedup_2",
                match_id="m_dedup_1",
                home_score=2,
                away_score=1,
            ),
        )
        self.db.save_matches_batch([m_finished])

        with self.db.get_connection() as conn:
            # Count must be exactly 1
            count = conn.execute(
                "SELECT COUNT(*) FROM matches WHERE home_team_id = 'team_tottenham';"
            ).fetchone()[0]
            self.assertEqual(count, 1)

            # Status must be updated to finished
            status = conn.execute(
                "SELECT status FROM matches WHERE home_team_id = 'team_tottenham';"
            ).fetchone()[0]
            self.assertEqual(status, "finished")

    # Scenario 10: MelBet connector configurable status & policy rejection
    def test_10_melbet_connector_audit_and_refusal(self):
        melbet = MelbetSource()
        self.assertFalse(melbet.is_enabled)
        self.assertEqual(
            melbet.access_status, ConnectorAccessStatus.RESTRICTED_BY_ROBOTS_TXT
        )

        audit_record = melbet.audit_status()
        self.assertEqual(audit_record["provider_id"], "melbet_restricted")
        self.assertFalse(audit_record["is_enabled"])
        self.assertEqual(
            audit_record["access_status"], "RESTRICTED_BY_ROBOTS_TXT"
        )
        self.assertIn("DISABLED_BY_POLICY", audit_record["reason"])

        # Execute collect: must cleanly refuse and return DISABLED report
        crawler_mock = MagicMock()
        sports, comps, seasons, matches, report = asyncio.run(
            melbet.collect(crawler_mock)
        )
        self.assertEqual(len(matches), 0)
        self.assertEqual(report.status, "DISABLED")
        self.assertEqual(report.records_synced, 0)
        self.assertIn("DISABLED_BY_POLICY", report.error_message)

        # Configurable MelBet test
        configurable_melbet = MelbetSource(
            is_enabled=False,
            access_status=ConnectorAccessStatus.DISABLED_BY_POLICY,
            custom_reason="Enforcing zero-odds betting policy",
        )
        self.assertEqual(
            configurable_melbet.access_status, ConnectorAccessStatus.DISABLED_BY_POLICY
        )
        self.assertEqual(
            configurable_melbet.custom_reason, "Enforcing zero-odds betting policy"
        )


if __name__ == "__main__":
    unittest.main()
