"""
Sources package for BETSOCCER Crawl4AI Autonomous Collector.
"""
from .base import BaseSource
from .openligadb_source import OpenLigaDbSource
from .footballdata_fixtures_source import FootballDataFixturesSource
from .footballdata_historical_source import FootballDataHistoricalSource
from .thesportsdb_source import TheSportsDbSource
from .html_scraper import HtmlSportsParser, HtmlScraperSource
from .melbet_source import MelbetSource

__all__ = [
    "BaseSource",
    "OpenLigaDbSource",
    "FootballDataFixturesSource",
    "FootballDataHistoricalSource",
    "TheSportsDbSource",
    "HtmlSportsParser",
    "HtmlScraperSource",
    "MelbetSource",
]
