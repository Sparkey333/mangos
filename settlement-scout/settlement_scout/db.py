"""SQLite persistence for settlements, profile, and saved matches.

Stdlib-only (sqlite3) so the app runs with zero dependencies.
"""
from __future__ import annotations

import json
import sqlite3
from datetime import datetime, timezone
from typing import Any, Optional

from . import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS settlements (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    defendant TEXT,
    category TEXT,
    kind TEXT,
    summary TEXT,
    claim_required INTEGER,
    auto_payment INTEGER,
    claim_deadline TEXT,
    final_approval_hearing TEXT,
    official_url TEXT,
    estimated_payout_low REAL,
    estimated_payout_high REAL,
    raw_json TEXT NOT NULL,
    source TEXT,
    ingested_at TEXT
);

CREATE TABLE IF NOT EXISTS profile (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    raw_json TEXT NOT NULL,
    updated_at TEXT
);

CREATE TABLE IF NOT EXISTS matches (
    settlement_id TEXT,
    status TEXT,
    score REAL,
    raw_json TEXT NOT NULL,
    matched_at TEXT,
    PRIMARY KEY (settlement_id)
);

CREATE TABLE IF NOT EXISTS drafts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    settlement_id TEXT,
    channel TEXT,
    subject TEXT,
    body TEXT,
    created_at TEXT
);
"""


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def connect() -> sqlite3.Connection:
    config.DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(config.DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.executescript(SCHEMA)
    return conn


def upsert_settlement(conn: sqlite3.Connection, s: dict, source: str = "seed") -> None:
    payout = s.get("estimated_payout_usd") or [None, None]
    conn.execute(
        """INSERT INTO settlements
           (id, title, defendant, category, kind, summary, claim_required, auto_payment,
            claim_deadline, final_approval_hearing, official_url,
            estimated_payout_low, estimated_payout_high, raw_json, source, ingested_at)
           VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
           ON CONFLICT(id) DO UPDATE SET
             title=excluded.title, defendant=excluded.defendant, category=excluded.category,
             kind=excluded.kind, summary=excluded.summary, claim_required=excluded.claim_required,
             auto_payment=excluded.auto_payment, claim_deadline=excluded.claim_deadline,
             final_approval_hearing=excluded.final_approval_hearing, official_url=excluded.official_url,
             estimated_payout_low=excluded.estimated_payout_low,
             estimated_payout_high=excluded.estimated_payout_high,
             raw_json=excluded.raw_json, source=excluded.source, ingested_at=excluded.ingested_at""",
        (
            s["id"], s["title"], s.get("defendant"), s.get("category"), s.get("kind"),
            s.get("summary"), int(bool(s.get("claim_required"))), int(bool(s.get("auto_payment"))),
            s.get("claim_deadline"), s.get("final_approval_hearing"), s.get("official_url"),
            payout[0], payout[1], json.dumps(s), source, _now(),
        ),
    )
    conn.commit()


def all_settlements(conn: sqlite3.Connection) -> list[dict]:
    rows = conn.execute("SELECT raw_json FROM settlements ORDER BY claim_deadline IS NULL, claim_deadline").fetchall()
    return [json.loads(r["raw_json"]) for r in rows]


def save_profile(conn: sqlite3.Connection, profile: dict) -> None:
    conn.execute(
        "INSERT INTO profile (id, raw_json, updated_at) VALUES (1, ?, ?) "
        "ON CONFLICT(id) DO UPDATE SET raw_json=excluded.raw_json, updated_at=excluded.updated_at",
        (json.dumps(profile), _now()),
    )
    conn.commit()


def load_profile(conn: sqlite3.Connection) -> Optional[dict]:
    row = conn.execute("SELECT raw_json FROM profile WHERE id = 1").fetchone()
    return json.loads(row["raw_json"]) if row else None


def save_match(conn: sqlite3.Connection, m: dict) -> None:
    conn.execute(
        "INSERT INTO matches (settlement_id, status, score, raw_json, matched_at) VALUES (?,?,?,?,?) "
        "ON CONFLICT(settlement_id) DO UPDATE SET status=excluded.status, score=excluded.score, "
        "raw_json=excluded.raw_json, matched_at=excluded.matched_at",
        (m["settlement_id"], m["status"], m["score"], json.dumps(m), _now()),
    )
    conn.commit()


def all_matches(conn: sqlite3.Connection) -> list[dict]:
    rows = conn.execute("SELECT raw_json FROM matches ORDER BY score DESC").fetchall()
    return [json.loads(r["raw_json"]) for r in rows]


def save_draft(conn: sqlite3.Connection, settlement_id: str, channel: str, subject: str, body: str) -> int:
    cur = conn.execute(
        "INSERT INTO drafts (settlement_id, channel, subject, body, created_at) VALUES (?,?,?,?,?)",
        (settlement_id, channel, subject, body, _now()),
    )
    conn.commit()
    return cur.lastrowid
