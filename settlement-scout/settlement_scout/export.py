"""Export collected/organized data for downstream ML training & analysis.

Produces a clean, structured dump (JSON + flat CSV) of settlements, the profile,
matches, and the action plan. This is the hand-off format for your other Law /
AI projects: each match is a labeled example (settlement features + profile +
eligibility decision + reasons).
"""
from __future__ import annotations

import csv
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from . import config, db
from .matching import match_all
from .schedule import build_plan


def build_dataset() -> dict[str, Any]:
    conn = db.connect()
    try:
        settlements = db.all_settlements(conn)
        profile = db.load_profile(conn) or {}
        matches = [m.to_dict() for m in match_all(settlements, profile, include_not_eligible=True)]
        by_id = {s["id"]: s for s in settlements}
        plan = build_plan(by_id, [m for m in matches if m["status"] != "not_eligible"])
    finally:
        conn.close()

    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "schema_version": 1,
        "settlements": settlements,
        "profile": profile,
        "matches": matches,
        "plan": plan,
    }


def write_json(out_dir: Path | None = None) -> Path:
    out_dir = out_dir or config.EXPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / "dataset.json"
    path.write_text(json.dumps(build_dataset(), indent=2), encoding="utf-8")
    return path


def write_matches_csv(out_dir: Path | None = None) -> Path:
    """Flat, one-row-per-match training table."""
    out_dir = out_dir or config.EXPORT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    data = build_dataset()
    by_id = {s["id"]: s for s in data["settlements"]}
    path = out_dir / "matches.csv"
    cols = ["settlement_id", "title", "category", "kind", "status", "score",
            "claim_required", "claim_deadline", "matched_reasons", "missing_info"]
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for m in data["matches"]:
            s = by_id.get(m["settlement_id"], {})
            w.writerow({
                "settlement_id": m["settlement_id"],
                "title": m["title"],
                "category": s.get("category"),
                "kind": s.get("kind"),
                "status": m["status"],
                "score": m["score"],
                "claim_required": s.get("claim_required"),
                "claim_deadline": s.get("claim_deadline"),
                "matched_reasons": " | ".join(m.get("matched_reasons", [])),
                "missing_info": " | ".join(m.get("missing_info", [])),
            })
    return path
