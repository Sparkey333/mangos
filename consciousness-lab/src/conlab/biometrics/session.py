"""Recording a biometric session end-to-end.

Ties a source (sim or Muse) to the database: opens a session row, streams
band samples into ``session_metrics``, then closes it and returns a
summary. This is the function the CLI's ``record`` command calls.
"""

from __future__ import annotations

from dataclasses import dataclass

from ..db import Storage
from .muse import BaseSource, get_source


@dataclass
class RecordResult:
    session_id: int
    samples: int
    summary: dict[str, float]


def record_session(
    store: Storage,
    *,
    subject: str,
    seconds: int = 30,
    device: str = "sim",
    protocol: str = "",
    notes: str = "",
    source: BaseSource | None = None,
) -> RecordResult:
    src = source or get_source(device)
    session_id = store.start_session(
        subject=subject, device=device, protocol=protocol, notes=notes
    )
    n = 0
    src.connect()
    try:
        for sample in src.read(seconds):
            store.add_metrics(session_id, sample.as_metric_rows())
            n += 1
    finally:
        src.disconnect()
        store.end_session(session_id)
    return RecordResult(
        session_id=session_id,
        samples=n,
        summary=store.session_summary(session_id),
    )
