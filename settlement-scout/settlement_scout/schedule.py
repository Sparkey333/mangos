"""Turn matched settlements into a prioritized action plan + tentative schedule.

Deadlines drive urgency. Auto-payment settlements need no filing but still get
a 'verify address / watch for check' task.
"""
from __future__ import annotations

from datetime import date, datetime, timedelta
from typing import Any, Optional


def _parse(d: Optional[str]) -> Optional[date]:
    if not d:
        return None
    try:
        return datetime.strptime(d, "%Y-%m-%d").date()
    except ValueError:
        return None


def _urgency(deadline: Optional[date], today: date) -> tuple[int, str]:
    if deadline is None:
        return (3, "no deadline")
    days = (deadline - today).days
    if days < 0:
        return (4, f"closed {abs(days)}d ago")
    if days <= 14:
        return (0, f"{days}d left — URGENT")
    if days <= 45:
        return (1, f"{days}d left — soon")
    return (2, f"{days}d left")


def build_plan(settlements_by_id: dict[str, dict], matches: list[dict], today: Optional[date] = None) -> dict[str, Any]:
    today = today or date.today()
    tasks: list[dict] = []

    for m in matches:
        if m["status"] == "not_eligible":
            continue
        s = settlements_by_id.get(m["settlement_id"])
        if not s:
            continue
        deadline = _parse(s.get("claim_deadline"))
        rank, urgency = _urgency(deadline, today)

        if s.get("auto_payment"):
            steps = [
                "Confirm your mailing address is current with the settlement administrator",
                "Watch for an automatic check; do NOT pay any fee to 'release' it",
            ]
            channel = "verify_address"
        else:
            steps = [
                "Open the official settlement site and read the claim form",
                "Gather proof (lease, receipts, screenshots, breach letters)",
                "Submit the claim before the deadline; save the confirmation number",
            ]
            channel = "file_claim"

        # tentative schedule: work backward from deadline, else a default cadence
        if deadline and deadline >= today:
            prep_by = max(today, deadline - timedelta(days=7))
            schedule = [
                {"when": today.isoformat(), "do": "Review eligibility & gather documents"},
                {"when": prep_by.isoformat(), "do": "Complete and review the claim form"},
                {"when": deadline.isoformat(), "do": "FINAL: submit / postmark by this date"},
            ]
        else:
            schedule = [{"when": today.isoformat(), "do": steps[0]}]

        tasks.append({
            "settlement_id": s["id"],
            "title": s["title"],
            "status": m["status"],
            "urgency": urgency,
            "_rank": rank,
            "claim_deadline": s.get("claim_deadline"),
            "official_url": s.get("official_url"),
            "estimated_payout_usd": s.get("estimated_payout_usd"),
            "recommended_channel": channel,
            "steps": steps,
            "schedule": schedule,
            "matched_reasons": m.get("matched_reasons", []),
            "missing_info": m.get("missing_info", []),
        })

    tasks.sort(key=lambda t: (t["_rank"], -(matches_score(matches, t["settlement_id"]))))
    for t in tasks:
        t.pop("_rank", None)

    low = sum((t["estimated_payout_usd"] or [0, 0])[0] for t in tasks if t["estimated_payout_usd"])
    high = sum((t["estimated_payout_usd"] or [0, 0])[1] for t in tasks if t["estimated_payout_usd"])

    return {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "task_count": len(tasks),
        "estimated_total_recovery_usd": [low, high],
        "tasks": tasks,
    }


def matches_score(matches: list[dict], sid: str) -> float:
    for m in matches:
        if m["settlement_id"] == sid:
            return m.get("score", 0.0)
    return 0.0
