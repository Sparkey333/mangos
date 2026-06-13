"""Curated seed adapter — loads the hand-verified settlements JSON.

This is the default, always-available source. Curated entries are reviewed by a
human and carry citations, so they are safe to ship and trustworthy to match on.
"""
from __future__ import annotations

import json

from .. import config
from .base import SourceAdapter


class SeedAdapter(SourceAdapter):
    name = "seed"

    def __init__(self, path=None):
        self.path = path or config.SEED_FILE

    def fetch(self) -> list[dict]:
        with open(self.path, "r", encoding="utf-8") as f:
            data = json.load(f)
        return data.get("settlements", [])
