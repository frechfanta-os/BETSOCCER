"""
Base class for sources using Crawl4AI.
Provides error handling, automatic retries with exponential backoff, and rate limiting.
"""

import asyncio
import logging
from abc import ABC, abstractmethod
from typing import List, Tuple, Optional, Any
from datetime import datetime, timezone

from crawl4ai import AsyncWebCrawler

from ..models import (
    NormalizedSport,
    NormalizedCompetition,
    NormalizedSeason,
    NormalizedMatch,
    SyncReport,
)

logger = logging.getLogger("betsoccer.collector.source")


class BaseSource(ABC):
    def __init__(
        self,
        provider_id: str,
        display_name: str,
        max_retries: int = 3,
        backoff_factor: float = 1.5,
        rate_limit_delay: float = 1.0,
    ):
        self.provider_id = provider_id
        self.display_name = display_name
        self.max_retries = max_retries
        self.backoff_factor = backoff_factor
        self.rate_limit_delay = rate_limit_delay

    @abstractmethod
    async def collect(
        self, crawler: AsyncWebCrawler
    ) -> Tuple[
        List[NormalizedSport],
        List[NormalizedCompetition],
        List[NormalizedSeason],
        List[NormalizedMatch],
        SyncReport,
    ]:
        """
        Executes the collection pipeline using the shared Crawl4AI AsyncWebCrawler.
        Returns: (sports, competitions, seasons, matches, sync_report)
        """
        pass

    async def fetch_with_crawl4ai(
        self, crawler: AsyncWebCrawler, url: str
    ) -> str:
        """
        Fetches a target URL using Crawl4AI with automatic retry and exponential backoff.
        Gracefully handles file downloads (like .csv or raw binary feeds) via streaming HTTP request.
        """
        last_exception = None
        delay = self.rate_limit_delay

        for attempt in range(1, self.max_retries + 1):
            try:
                logger.info(f"[{self.provider_id}] Fetching (attempt {attempt}/{self.max_retries}): {url}")

                # If target is a direct raw data file (CSV, TSV, GZ), use fast non-browser HTTP fetch
                if url.endswith(".csv") or url.endswith(".tsv"):
                    import urllib.request
                    req = urllib.request.Request(
                        url,
                        headers={"User-Agent": "BETSOCCER-Collector/1.0 (+https://github.com/frechfanta-os/BETSOCCER)"}
                    )
                    with urllib.request.urlopen(req, timeout=30) as resp:
                        raw_bytes = resp.read()
                        content = raw_bytes.decode("utf-8-sig", errors="replace")
                        if self.rate_limit_delay > 0:
                            await asyncio.sleep(self.rate_limit_delay)
                        return content

                result = await crawler.arun(url=url)

                if result and result.success:
                    content = result.html or result.markdown or ""
                    if self.rate_limit_delay > 0:
                        await asyncio.sleep(self.rate_limit_delay)
                    return content
                else:
                    error_msg = result.error_message if result else "Empty result"
                    # If error is a download trigger, fallback to direct streaming
                    if "Download is starting" in str(error_msg):
                        import urllib.request
                        req = urllib.request.Request(
                            url,
                            headers={"User-Agent": "BETSOCCER-Collector/1.0 (+https://github.com/frechfanta-os/BETSOCCER)"}
                        )
                        with urllib.request.urlopen(req, timeout=30) as resp:
                            raw_bytes = resp.read()
                            return raw_bytes.decode("utf-8-sig", errors="replace")
                    raise RuntimeError(f"Crawl4AI crawl failed: {error_msg}")

            except Exception as e:
                last_exception = e
                logger.warning(
                    f"[{self.provider_id}] Attempt {attempt} failed for {url}: {e}"
                )
                if attempt < self.max_retries:
                    sleep_time = delay * (self.backoff_factor ** (attempt - 1))
                    logger.info(f"[{self.provider_id}] Retrying in {sleep_time:.1f}s...")
                    await asyncio.sleep(sleep_time)

        raise RuntimeError(
            f"Failed to fetch {url} after {self.max_retries} attempts: {last_exception}"
        )
