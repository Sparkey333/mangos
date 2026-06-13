"""Run source adapters and persist their settlements into the DB."""
from __future__ import annotations

from . import db
from .sources import ClassActionOrgAdapter, SeedAdapter, SourceAdapter


def default_sources(enable_live: bool = False) -> list[SourceAdapter]:
    sources: list[SourceAdapter] = [SeedAdapter()]
    if enable_live:
        sources.append(ClassActionOrgAdapter(enabled=True))
    return sources


def run(enable_live: bool = False) -> dict[str, int]:
    conn = db.connect()
    counts: dict[str, int] = {}
    try:
        for src in default_sources(enable_live):
            records = src.fetch()
            for rec in records:
                db.upsert_settlement(conn, rec, source=src.name)
            counts[src.name] = len(records)
    finally:
        conn.close()
    return counts
