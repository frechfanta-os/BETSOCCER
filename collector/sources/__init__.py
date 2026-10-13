"""
Sources package for BETSOCCER Crawl4AI Autonomous Collector.
"""
from .base import BaseSource
from .openligadb_source import OpenLigaDbSource
from .footballdata_fixtures_source import FootballDataFixturesSource
from .thesportsdb_source import TheSportsDbSource

__all__ = [
    "BaseSource",
    "OpenLigaDbSource",
    "FootballDataFixturesSource",
    "TheSportsDbSource",
]
