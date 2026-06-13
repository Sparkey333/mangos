"""Example LIVE adapter (opt-in) for an open-settlements listing page.

Disabled by default. It demonstrates the polite-scraping contract:
  * honor robots.txt via check_robots()
  * identify with a descriptive User-Agent
  * degrade gracefully (return [] on any failure) so ingestion never crashes

Parsing real HTML into the structured eligibility schema requires
source-specific rules and human review — a listing rarely encodes machine
readable eligibility windows. Treat live output as *candidates* to be curated,
not as auto-trusted matches.
"""
from __future__ import annotations

import urllib.request

from .base import USER_AGENT, SourceAdapter, check_robots

LISTING_URL = "https://www.classaction.org/open-lawsuit-settlements"


class ClassActionOrgAdapter(SourceAdapter):
    name = "classaction_org"

    def __init__(self, enabled: bool = False, url: str = LISTING_URL):
        self.enabled = enabled
        self.url = url

    def fetch(self) -> list[dict]:
        if not self.enabled:
            return []
        if not check_robots(self.url):
            return []
        try:
            req = urllib.request.Request(self.url, headers={"User-Agent": USER_AGENT})
            with urllib.request.urlopen(req, timeout=15) as resp:
                html = resp.read().decode("utf-8", "replace")
        except Exception:
            return []
        # Real implementation: parse `html` into candidate records and queue them
        # for human curation. Returning [] keeps the contract honest until parsing
        # rules + review are added.
        _ = html
        return []
