"""
HTTP Cache Manager for BETSOCCER Autonomous Collector.
Implements RFC 7234 / RFC 7232 conditional requests (ETag, Last-Modified)
to minimize redundant requests and respect API / bandwidth quotas.
"""

import os
import json
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger("betsoccer.collector.cache")


class HttpCacheManager:
    """Manages local HTTP cache with ETag and Last-Modified conditional headers."""

    def __init__(self, cache_file: str = ".http_cache.json"):
        self.cache_file = cache_file
        self._cache: Dict[str, Dict[str, Any]] = self._load()

    def _load(self) -> Dict[str, Dict[str, Any]]:
        if os.path.exists(self.cache_file):
            try:
                with open(self.cache_file, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                logger.warning(f"Failed to read HTTP cache from {self.cache_file}: {e}")
        return {}

    def _save(self) -> None:
        try:
            with open(self.cache_file, "w", encoding="utf-8") as f:
                json.dump(self._cache, f, indent=2)
        except Exception as e:
            logger.warning(f"Failed to save HTTP cache to {self.cache_file}: {e}")

    def get_conditional_headers(self, url: str) -> Dict[str, str]:
        """Returns conditional headers (If-None-Match, If-Modified-Since) if cached."""
        entry = self._cache.get(url)
        if not entry:
            return {}
        headers = {}
        if entry.get("etag"):
            headers["If-None-Match"] = entry["etag"]
        if entry.get("last_modified"):
            headers["If-Modified-Since"] = entry["last_modified"]
        return headers

    def get_cached_content(self, url: str) -> Optional[str]:
        """Retrieves cached payload if available."""
        entry = self._cache.get(url)
        return entry.get("content") if entry else None

    def store_response(
        self,
        url: str,
        content: str,
        etag: Optional[str] = None,
        last_modified: Optional[str] = None,
    ) -> None:
        """Stores or updates cached response with HTTP validators."""
        self._cache[url] = {
            "content": content,
            "etag": etag,
            "last_modified": last_modified,
        }
        self._save()

    def clear(self) -> None:
        """Clears local cache."""
        self._cache.clear()
        if os.path.exists(self.cache_file):
            try:
                os.remove(self.cache_file)
            except OSError:
                pass
