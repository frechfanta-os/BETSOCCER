"""
Command-line interface for the BETSOCCER Crawl4AI Autonomous Collector.
Executable directly on Linux/PRoot:
  python3 -m collector.main --once
"""

import sys
import time
import asyncio
import logging
import argparse
from datetime import datetime, timezone

from .config import CollectorConfig, DEFAULT_CONFIG
from .collector import AutonomousCollector
from .db import DatabaseManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("betsoccer.collector.cli")


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="BETSOCCER Crawl4AI Autonomous Sports Data Collector",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--db",
        type=str,
        default="betsoccer.db",
        help="Path to the SQLite database file",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Crawl and parse data without persisting to SQLite",
    )
    parser.add_argument(
        "--once",
        action="store_true",
        default=True,
        help="Run a single collection cycle and exit",
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=0,
        help="Run continuously with the specified interval in seconds (0 = run once)",
    )
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Display verification of current data in database and exit",
    )
    return parser


async def run_collector_loop(config: CollectorConfig, interval: int, dry_run: bool) -> None:
    collector = AutonomousCollector(config=config)

    while True:
        try:
            summary = await collector.run_sync_cycle(dry_run=dry_run)
            print("\n" + "=" * 60)
            print("CRAWL4AI COLLECTION CYCLE SUMMARY")
            print("=" * 60)
            print(f"Cycle Start:    {summary['cycle_start']}")
            print(f"Cycle End:      {summary['cycle_end']}")
            print(f"Total Duration: {summary['duration_seconds']}s")
            print(f"Matches Synced: {summary['total_matches_synced']}")
            print("\nSources Breakdown:")
            for rep in summary["reports"]:
                status_icon = "✓" if rep["status"] == "SUCCESS" else ("⚠" if rep["status"] == "PARTIAL" else "✗")
                print(f"  {status_icon} {rep['provider']:<22} Status: {rep['status']:<8} Records: {rep['records']:<5} ({rep['duration_ms']}ms)")
                if rep["error"]:
                    print(f"      Error: {rep['error']}")

            if not dry_run and summary.get("db_stats"):
                st = summary["db_stats"]
                print("\nSQLite Database Totals:")
                print(f"  Sports:       {st.get('sports')}")
                print(f"  Competitions: {st.get('competitions')}")
                print(f"  Teams:        {st.get('teams')}")
                print(f"  Matches:      {st.get('matches')}")
                print(f"  Results:      {st.get('results')}")
                print(f"  Statistics:   {st.get('match_statistics')}")
                print("  Matches by Provider:")
                for prov, cnt in st.get("matches_by_provider", {}).items():
                    print(f"    - {prov}: {cnt}")
            print("=" * 60 + "\n")

        except Exception as e:
            logger.error(f"Error during collection cycle: {e}", exc_info=True)

        if interval <= 0:
            break

        logger.info(f"Sleeping for {interval} seconds before next autonomous cycle...")
        await asyncio.sleep(interval)


def print_verification(db_path: str) -> None:
    db = DatabaseManager(db_path=db_path)
    stats = db.get_summary_stats()
    print("\n" + "=" * 60)
    print(f"BETSOCCER DATABASE VERIFICATION ({db_path})")
    print("=" * 60)
    print(f"Sports:       {stats.get('sports')}")
    print(f"Competitions: {stats.get('competitions')}")
    print(f"Teams:        {stats.get('teams')}")
    print(f"Matches:      {stats.get('matches')}")
    print(f"Results:      {stats.get('results')}")
    print(f"Statistics:   {stats.get('match_statistics')}")
    print("\nMatches by Provider:")
    for prov, cnt in stats.get("matches_by_provider", {}).items():
        print(f"  - {prov}: {cnt}")
    print("\nRecent Sync States:")
    for row in stats.get("recent_sync_states", []):
        print(f"  - {row.get('key')} | Provider: {row.get('provider_id')} | Synced: {row.get('records_synced')} | Status: {row.get('status')} | {row.get('last_synced_at')}")
    print("=" * 60 + "\n")


def main() -> None:
    parser = build_arg_parser()
    args = parser.parse_args()

    if args.verify:
        print_verification(args.db)
        return

    config = CollectorConfig(db_path=args.db)
    interval = args.interval if args.interval > 0 else 0

    asyncio.run(run_collector_loop(config=config, interval=interval, dry_run=args.dry_run))


if __name__ == "__main__":
    main()
