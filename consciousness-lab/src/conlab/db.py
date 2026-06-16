"""SQLite storage layer for Consciousness Lab.

One file, owned by you. The schema deliberately separates raw,
verifiable data (documents, biometric metrics) from interpretation
(tags / themes). Tags can be attached to anything but never overwrite
the underlying measurement.
"""

from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Iterator, Optional

from . import config

SCHEMA = """
CREATE TABLE IF NOT EXISTS documents (
    id          INTEGER PRIMARY KEY,
    source      TEXT NOT NULL,            -- e.g. 'cia_crest', 'fbi_vault'
    doc_id      TEXT,                     -- agency document id if known
    title       TEXT NOT NULL,
    url         TEXT,
    agency      TEXT,                     -- 'CIA', 'FBI', ...
    year        INTEGER,
    summary     TEXT,
    local_path  TEXT,                     -- downloaded file, if any
    verified    INTEGER NOT NULL DEFAULT 0,
    fetched_at  TEXT,
    created_at  TEXT NOT NULL,
    UNIQUE(source, doc_id, url)
);

CREATE TABLE IF NOT EXISTS subjects (
    id          INTEGER PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    notes       TEXT,
    created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS sessions (
    id          INTEGER PRIMARY KEY,
    subject_id  INTEGER REFERENCES subjects(id),
    device      TEXT,                     -- 'muse-2', 'sim', ...
    protocol    TEXT,                     -- e.g. 'gateway-focus-10'
    started_at  TEXT NOT NULL,
    ended_at    TEXT,
    notes       TEXT
);

-- Aggregated, human-meaningful numbers per session (band powers, mean HR,
-- HRV, etc). Raw sample streams can get huge; we summarize by default.
CREATE TABLE IF NOT EXISTS session_metrics (
    id          INTEGER PRIMARY KEY,
    session_id  INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    ts          TEXT NOT NULL,
    metric      TEXT NOT NULL,            -- 'alpha', 'theta', 'hr_bpm', ...
    channel     TEXT,                     -- EEG channel or NULL
    value       REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS journal (
    id          INTEGER PRIMARY KEY,
    subject_id  INTEGER REFERENCES subjects(id),
    session_id  INTEGER REFERENCES sessions(id),
    ts          TEXT NOT NULL,
    title       TEXT,
    body        TEXT NOT NULL
);

-- Interpretation layer. 'kind' records what the tag is ABOUT so we never
-- confuse a felt/symbolic label with a measurement.
CREATE TABLE IF NOT EXISTS tags (
    id          INTEGER PRIMARY KEY,
    target_type TEXT NOT NULL,            -- 'document' | 'session' | 'journal'
    target_id   INTEGER NOT NULL,
    tag         TEXT NOT NULL,
    kind        TEXT NOT NULL DEFAULT 'theme',  -- 'theme'|'symbolic'|'center'
    created_at  TEXT NOT NULL,
    UNIQUE(target_type, target_id, tag)
);

CREATE INDEX IF NOT EXISTS idx_metrics_session ON session_metrics(session_id);
CREATE INDEX IF NOT EXISTS idx_tags_target ON tags(target_type, target_id);
"""


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


class Storage:
    """Thin wrapper over a SQLite connection with helpers per table."""

    def __init__(self, path: Optional[Path] = None):
        self.path = Path(path) if path else config.db_path()
        self.conn = sqlite3.connect(self.path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self.conn.executescript(SCHEMA)
        self.conn.commit()

    def close(self) -> None:
        self.conn.close()

    def __enter__(self) -> "Storage":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    @contextmanager
    def _tx(self) -> Iterator[sqlite3.Cursor]:
        cur = self.conn.cursor()
        try:
            yield cur
            self.conn.commit()
        except Exception:
            self.conn.rollback()
            raise

    # -- documents ---------------------------------------------------------
    def add_document(
        self,
        *,
        source: str,
        title: str,
        doc_id: str = "",
        url: str = "",
        agency: str = "",
        year: Optional[int] = None,
        summary: str = "",
        local_path: str = "",
        verified: bool = False,
    ) -> int:
        with self._tx() as cur:
            cur.execute(
                """INSERT OR IGNORE INTO documents
                   (source, doc_id, title, url, agency, year, summary,
                    local_path, verified, fetched_at, created_at)
                   VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
                (source, doc_id, title, url, agency, year, summary,
                 local_path, int(verified), None, now()),
            )
            if cur.lastrowid:
                return cur.lastrowid
            row = cur.execute(
                "SELECT id FROM documents WHERE source=? AND doc_id=? AND url=?",
                (source, doc_id, url),
            ).fetchone()
            return row["id"] if row else 0

    def list_documents(self, agency: str = "", limit: int = 200) -> list[sqlite3.Row]:
        q = "SELECT * FROM documents"
        args: list = []
        if agency:
            q += " WHERE agency = ?"
            args.append(agency)
        q += " ORDER BY (year IS NULL), year DESC, id DESC LIMIT ?"
        args.append(limit)
        return list(self.conn.execute(q, args))

    def mark_verified(self, document_id: int, verified: bool = True) -> None:
        with self._tx() as cur:
            cur.execute(
                "UPDATE documents SET verified=? WHERE id=?",
                (int(verified), document_id),
            )

    # -- subjects & sessions ----------------------------------------------
    def ensure_subject(self, name: str, notes: str = "") -> int:
        with self._tx() as cur:
            cur.execute(
                "INSERT OR IGNORE INTO subjects (name, notes, created_at) VALUES (?,?,?)",
                (name, notes, now()),
            )
            row = cur.execute("SELECT id FROM subjects WHERE name=?", (name,)).fetchone()
            return row["id"]

    def start_session(
        self, *, subject: str, device: str = "sim", protocol: str = "", notes: str = ""
    ) -> int:
        subject_id = self.ensure_subject(subject)
        with self._tx() as cur:
            cur.execute(
                """INSERT INTO sessions (subject_id, device, protocol, started_at, notes)
                   VALUES (?,?,?,?,?)""",
                (subject_id, device, protocol, now(), notes),
            )
            return cur.lastrowid

    def end_session(self, session_id: int) -> None:
        with self._tx() as cur:
            cur.execute(
                "UPDATE sessions SET ended_at=? WHERE id=?", (now(), session_id)
            )

    def add_metrics(
        self, session_id: int, rows: Iterable[tuple[str, Optional[str], float]]
    ) -> int:
        ts = now()
        count = 0
        with self._tx() as cur:
            for metric, channel, value in rows:
                cur.execute(
                    """INSERT INTO session_metrics (session_id, ts, metric, channel, value)
                       VALUES (?,?,?,?,?)""",
                    (session_id, ts, metric, channel, float(value)),
                )
                count += 1
        return count

    def session_summary(self, session_id: int) -> dict[str, float]:
        rows = self.conn.execute(
            """SELECT metric, AVG(value) AS avg_value
               FROM session_metrics WHERE session_id=? GROUP BY metric""",
            (session_id,),
        )
        return {r["metric"]: r["avg_value"] for r in rows}

    # -- journal -----------------------------------------------------------
    def add_journal(
        self,
        *,
        body: str,
        title: str = "",
        subject: str = "",
        session_id: Optional[int] = None,
    ) -> int:
        subject_id = self.ensure_subject(subject) if subject else None
        with self._tx() as cur:
            cur.execute(
                """INSERT INTO journal (subject_id, session_id, ts, title, body)
                   VALUES (?,?,?,?,?)""",
                (subject_id, session_id, now(), title, body),
            )
            return cur.lastrowid

    # -- tags --------------------------------------------------------------
    def tag(
        self, target_type: str, target_id: int, tag: str, kind: str = "theme"
    ) -> None:
        with self._tx() as cur:
            cur.execute(
                """INSERT OR IGNORE INTO tags
                   (target_type, target_id, tag, kind, created_at)
                   VALUES (?,?,?,?,?)""",
                (target_type, target_id, tag, kind, now()),
            )

    def tags_for(self, target_type: str, target_id: int) -> list[sqlite3.Row]:
        return list(
            self.conn.execute(
                "SELECT tag, kind FROM tags WHERE target_type=? AND target_id=?",
                (target_type, target_id),
            )
        )

    def counts(self) -> dict[str, int]:
        out = {}
        for table in ("documents", "subjects", "sessions", "session_metrics",
                      "journal", "tags"):
            out[table] = self.conn.execute(
                f"SELECT COUNT(*) AS n FROM {table}"
            ).fetchone()["n"]
        return out
