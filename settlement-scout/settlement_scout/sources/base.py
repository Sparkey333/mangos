"""Source adapter framework.

A SourceAdapter knows how to fetch a list of settlement records from one source
(a curated JSON file, an RSS feed, an API, or — where permitted — a scrape).

Scraping guardrails baked in:
  * check_robots() honors robots.txt before any fetch
  * a descriptive User-Agent is sent
  * adapters should rate-limit and cache
The shipped adapters use curated/seed data so the app works offline and legally
out of the box. Live HTTP adapters are opt-in.
"""
from __future__ import annotations

import urllib.robotparser
from urllib.parse import urlparse

USER_AGENT = "SettlementScout/0.1 (personal settlement-eligibility research; contact: user)"


class SourceAdapter:
    name = "base"

    def fetch(self) -> list[dict]:
        """Return a list of settlement dicts in the seed schema."""
        raise NotImplementedError


def check_robots(url: str, user_agent: str = USER_AGENT) -> bool:
    """Return True if robots.txt allows fetching `url`. Fails open only on parse
    errors for the robots file itself, fails closed (False) on network refusal."""
    try:
        parts = urlparse(url)
        robots_url = f"{parts.scheme}://{parts.netloc}/robots.txt"
        rp = urllib.robotparser.RobotFileParser()
        rp.set_url(robots_url)
        rp.read()
        return rp.can_fetch(user_agent, url)
    except Exception:
        # Could not read robots.txt — be conservative and disallow live scrape.
        return False
