"""Eligibility matching engine.

Evaluates each settlement's structured eligibility criteria against a user
profile and returns a status (eligible / possible / not_eligible) with
human-readable reasons. Designed to be transparent: every decision is
explainable, which matters both for the user and for downstream ML training.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date
from typing import Any, Optional

MATCH = "match"
NO_MATCH = "no_match"
UNKNOWN = "unknown"

ELIGIBLE = "eligible"
POSSIBLE = "possible"
NOT_ELIGIBLE = "not_eligible"


def _parse(d: Optional[str]) -> Optional[date]:
    if not d:
        return None
    try:
        y, m, day = (int(x) for x in d.split("-"))
        return date(y, m, day)
    except (ValueError, AttributeError):
        return None


def _ranges_overlap(a_from, a_to, b_from, b_to) -> bool:
    """Inclusive overlap of two date ranges; open ends treated as infinite."""
    a_from = a_from or date.min
    a_to = a_to or date.max
    b_from = b_from or date.min
    b_to = b_to or date.max
    return a_from <= b_to and b_from <= a_to


@dataclass
class CriterionResult:
    label: str
    status: str
    required: bool
    detail: str = ""


@dataclass
class MatchResult:
    settlement_id: str
    title: str
    status: str
    score: float
    criteria: list[CriterionResult] = field(default_factory=list)

    @property
    def matched_reasons(self) -> list[str]:
        return [c.label for c in self.criteria if c.status == MATCH]

    @property
    def missing_info(self) -> list[str]:
        return [c.label for c in self.criteria if c.status == UNKNOWN]

    def to_dict(self) -> dict[str, Any]:
        return {
            "settlement_id": self.settlement_id,
            "title": self.title,
            "status": self.status,
            "score": round(self.score, 3),
            "criteria": [
                {"label": c.label, "status": c.status, "required": c.required, "detail": c.detail}
                for c in self.criteria
            ],
            "matched_reasons": self.matched_reasons,
            "missing_info": self.missing_info,
        }


def _named_entries(profile: dict, field_name: str) -> list[dict]:
    entries = profile.get(field_name) or []
    out = []
    for e in entries:
        if isinstance(e, dict):
            out.append(e)
        elif isinstance(e, str):
            out.append({"name": e})
    return out


def evaluate_criterion(crit: dict, profile: dict) -> CriterionResult:
    op = crit.get("op")
    fld = crit.get("field")
    val = crit.get("value")
    label = crit.get("label", f"{fld} {op} {val}")
    required = bool(crit.get("required", True))

    def res(status, detail=""):
        return CriterionResult(label=label, status=status, required=required, detail=detail)

    if op in ("overlaps_dates", "contains"):
        entries = _named_entries(profile, fld)
        if not entries:
            return res(UNKNOWN, f"No {fld} on file")
        target = str(val).lower()
        named = [e for e in entries if target in str(e.get("name", "")).lower()]
        if not named:
            return res(NO_MATCH, f"{val} not among your {fld}")
        if op == "contains":
            return res(MATCH, f"Matched {val}")
        cr = crit.get("date_range") or [None, None]
        c_from, c_to = _parse(cr[0]), _parse(cr[1])
        any_unknown = False
        for e in named:
            e_from, e_to = _parse(e.get("from")), _parse(e.get("to"))
            if e_from is None and e_to is None:
                any_unknown = True
                continue
            if _ranges_overlap(e_from, e_to, c_from, c_to):
                return res(MATCH, f"Your dates overlap the class window")
        if any_unknown:
            return res(UNKNOWN, "Add your start/end dates to confirm window")
        return res(NO_MATCH, "Your dates fall outside the class window")

    if op == "state_in":
        states = _named_entries(profile, "states")
        if not states:
            return res(UNKNOWN, "No states on file")
        codes = {str(s.get("state", s.get("name", ""))).upper() for s in states}
        return res(MATCH, f"You lived in {val}") if str(val).upper() in codes \
            else res(NO_MATCH, f"No {val} residence on file")

    if op == "has":
        vals = profile.get(fld) or []
        flat = [str(v.get("name", v)) if isinstance(v, dict) else str(v) for v in vals]
        return res(MATCH) if str(val) in flat else res(UNKNOWN, f"Set flag '{val}' if true")

    if op == "any":
        vals = profile.get(fld) or []
        return res(MATCH, f"{len(vals)} on file") if vals else res(UNKNOWN, f"Add {fld} if applicable")

    if op == "equals":
        return res(MATCH) if str(profile.get(fld)) == str(val) else res(NO_MATCH)

    return res(UNKNOWN, f"Unsupported op '{op}'")


def match_settlement(settlement: dict, profile: dict) -> MatchResult:
    crits = [evaluate_criterion(c, profile) for c in settlement.get("eligibility", [])]
    required = [c for c in crits if c.required]

    if any(c.status == NO_MATCH for c in required):
        status = NOT_ELIGIBLE
    elif required and all(c.status == MATCH for c in required):
        status = ELIGIBLE
    elif any(c.status == MATCH for c in crits) and not any(c.status == NO_MATCH for c in required):
        status = POSSIBLE
    else:
        status = POSSIBLE if any(c.status == UNKNOWN for c in required) else NOT_ELIGIBLE

    total = max(len(crits), 1)
    matched = sum(1 for c in crits if c.status == MATCH)
    unknown = sum(1 for c in crits if c.status == UNKNOWN)
    score = (matched + 0.4 * unknown) / total
    if status == NOT_ELIGIBLE:
        score = 0.0

    return MatchResult(
        settlement_id=settlement.get("id", ""),
        title=settlement.get("title", ""),
        status=status,
        score=score,
        criteria=crits,
    )


def match_all(settlements: list[dict], profile: dict, include_not_eligible: bool = False) -> list[MatchResult]:
    results = [match_settlement(s, profile) for s in settlements]
    if not include_not_eligible:
        results = [r for r in results if r.status != NOT_ELIGIBLE]
    results.sort(key=lambda r: ({ELIGIBLE: 0, POSSIBLE: 1, NOT_ELIGIBLE: 2}[r.status], -r.score))
    return results
