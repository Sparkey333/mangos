"""Command-line interface for Settlement Scout.

Examples:
  python -m settlement_scout.cli ingest
  python -m settlement_scout.cli load-profile data/example_profile.json
  python -m settlement_scout.cli match
  python -m settlement_scout.cli plan
  python -m settlement_scout.cli draft invitation-homes-mn-lease-credit-2026 --kind claim_inquiry
  python -m settlement_scout.cli export
  python -m settlement_scout.cli serve
"""
from __future__ import annotations

import argparse
import json
import sys

from . import db, export, ingest
from .drafting import generate
from .matching import match_all
from .schedule import build_plan


def _load(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def cmd_ingest(args):
    counts = ingest.run(enable_live=args.live)
    print("Ingested:", ", ".join(f"{k}={v}" for k, v in counts.items()))


def cmd_load_profile(args):
    profile = _load(args.path)
    conn = db.connect()
    try:
        db.save_profile(conn, profile)
    finally:
        conn.close()
    print(f"Saved profile for: {profile.get('name', '(unnamed)')}")


def _ctx():
    conn = db.connect()
    try:
        settlements = db.all_settlements(conn)
        profile = db.load_profile(conn) or {}
    finally:
        conn.close()
    return settlements, profile


def cmd_match(args):
    settlements, profile = _ctx()
    if not profile:
        print("No profile loaded. Run: load-profile <file.json>", file=sys.stderr)
        return 1
    results = match_all(settlements, profile, include_not_eligible=args.all)
    conn = db.connect()
    try:
        for r in results:
            db.save_match(conn, r.to_dict())
    finally:
        conn.close()
    for r in results:
        print(f"[{r.status.upper():12}] {r.title}  (score {r.score:.2f})")
        for reason in r.matched_reasons:
            print(f"      ✓ {reason}")
        for miss in r.missing_info:
            print(f"      ? {miss}")
    return 0


def cmd_plan(args):
    settlements, profile = _ctx()
    by_id = {s["id"]: s for s in settlements}
    matches = [m.to_dict() for m in match_all(settlements, profile)]
    plan = build_plan(by_id, matches)
    lo, hi = plan["estimated_total_recovery_usd"]
    print(f"PLAN — {plan['task_count']} actions, est. recovery ${lo}-${hi}\n")
    for t in plan["tasks"]:
        print(f"• [{t['urgency']}] {t['title']}  ({t['status']})")
        print(f"    {t['official_url']}")
        for step in t["steps"]:
            print(f"      - {step}")
        for s in t["schedule"]:
            print(f"      → {s['when']}: {s['do']}")
        print()


def cmd_draft(args):
    settlements, profile = _ctx()
    by_id = {s["id"]: s for s in settlements}
    s = by_id.get(args.settlement_id)
    if not s:
        print(f"Unknown settlement id: {args.settlement_id}", file=sys.stderr)
        return 1
    matches = [m.to_dict() for m in match_all(settlements, profile, include_not_eligible=True)]
    reasons = next((m["matched_reasons"] for m in matches if m["settlement_id"] == s["id"]), [])
    draft = generate(args.kind, s, profile, channel=args.channel, matched_reasons=reasons)
    print(f"--- {draft['channel'].upper()} DRAFT (review before sending) ---")
    print(f"Subject: {draft['subject']}\n")
    print(draft["body"])
    return 0


def cmd_export(args):
    j = export.write_json()
    c = export.write_matches_csv()
    print(f"Wrote {j}\nWrote {c}")


def cmd_serve(args):
    from .server import serve
    serve(port=args.port)


def build_parser():
    p = argparse.ArgumentParser(prog="settlement-scout", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("ingest", help="Load settlements from sources into the DB")
    s.add_argument("--live", action="store_true", help="Also run opt-in live web adapters")
    s.set_defaults(func=cmd_ingest)

    s = sub.add_parser("load-profile", help="Load a profile JSON file")
    s.add_argument("path")
    s.set_defaults(func=cmd_load_profile)

    s = sub.add_parser("match", help="Match settlements against the profile")
    s.add_argument("--all", action="store_true", help="Include not-eligible")
    s.set_defaults(func=cmd_match)

    s = sub.add_parser("plan", help="Build a prioritized action plan + schedule")
    s.set_defaults(func=cmd_plan)

    s = sub.add_parser("draft", help="Draft outreach for a settlement")
    s.add_argument("settlement_id")
    s.add_argument("--kind", default="claim_inquiry", choices=["claim_inquiry", "records_request"])
    s.add_argument("--channel", default="email", choices=["email", "letter"])
    s.set_defaults(func=cmd_draft)

    s = sub.add_parser("export", help="Export dataset for ML/training")
    s.set_defaults(func=cmd_export)

    s = sub.add_parser("serve", help="Run the web UI + API")
    s.add_argument("--port", type=int, default=8765)
    s.set_defaults(func=cmd_serve)
    return p


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args) or 0


if __name__ == "__main__":
    raise SystemExit(main())
