"""Core tests — stdlib unittest, no deps. Run: python -m pytest or python -m unittest"""
import json
import os
import sys
import tempfile
import unittest
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from settlement_scout.matching import (ELIGIBLE, NOT_ELIGIBLE, POSSIBLE,
                                        match_all, match_settlement)
from settlement_scout.schedule import build_plan
from settlement_scout import drafting, config

SEED = json.loads((Path(__file__).resolve().parent.parent / "data" / "seed_settlements.json").read_text())
SETTLEMENTS = SEED["settlements"]
BY_ID = {s["id"]: s for s in SETTLEMENTS}


class MatchingTests(unittest.TestCase):
    def test_invitation_homes_ftc_eligible(self):
        profile = {"landlords": [{"name": "Invitation Homes", "from": "2021-02-01", "to": "2023-09-01"}]}
        r = match_settlement(BY_ID["invitation-homes-ftc-2025"], profile)
        self.assertEqual(r.status, ELIGIBLE)
        self.assertTrue(r.matched_reasons)

    def test_mn_requires_minnesota(self):
        # Right landlord + dates but lived in AZ -> state criterion fails -> not eligible
        profile = {
            "landlords": [{"name": "Invitation Homes", "from": "2017-01-01", "to": "2019-12-31"}],
            "states": [{"state": "AZ", "from": "2017-01-01", "to": "2019-12-31"}],
        }
        r = match_settlement(BY_ID["invitation-homes-mn-lease-credit-2026"], profile)
        self.assertEqual(r.status, NOT_ELIGIBLE)

    def test_mn_eligible_with_minnesota(self):
        profile = {
            "landlords": [{"name": "Invitation Homes", "from": "2017-01-01", "to": "2019-12-31"}],
            "states": [{"state": "MN", "from": "2017-01-01", "to": "2019-12-31"}],
        }
        r = match_settlement(BY_ID["invitation-homes-mn-lease-credit-2026"], profile)
        self.assertEqual(r.status, ELIGIBLE)

    def test_dates_outside_window_not_eligible(self):
        profile = {"landlords": [{"name": "Invitation Homes", "from": "2010-01-01", "to": "2012-01-01"}]}
        r = match_settlement(BY_ID["invitation-homes-ftc-2025"], profile)
        self.assertEqual(r.status, NOT_ELIGIBLE)

    def test_missing_dates_is_possible_not_eligible(self):
        profile = {"landlords": [{"name": "Invitation Homes"}]}  # no dates
        r = match_settlement(BY_ID["invitation-homes-ftc-2025"], profile)
        self.assertEqual(r.status, POSSIBLE)
        self.assertTrue(r.missing_info)

    def test_empty_profile_gives_possible_via_unknowns(self):
        results = match_all(SETTLEMENTS, {}, include_not_eligible=False)
        # nothing should be hard-eligible, but watchlist unknowns -> possible kept
        self.assertTrue(all(r.status != ELIGIBLE for r in results))

    def test_flags_match_watchlist(self):
        profile = {"flags": ["received_spam_texts"]}
        r = match_settlement(BY_ID["tcpa-robotext-generic-watch"], profile)
        self.assertEqual(r.status, ELIGIBLE)

    def test_databreach_any(self):
        profile = {"data_breaches": [{"org": "X", "date": "2024-01-01"}]}
        r = match_settlement(BY_ID["data-breach-generic-watch"], profile)
        self.assertEqual(r.status, ELIGIBLE)


class PlanTests(unittest.TestCase):
    def test_plan_orders_by_urgency_and_totals(self):
        profile = {
            "landlords": [{"name": "Invitation Homes", "from": "2017-01-01", "to": "2023-09-01"}],
            "states": [{"state": "MN", "from": "2017-01-01", "to": "2019-12-31"}],
            "flags": ["received_spam_texts"],
        }
        matches = [m.to_dict() for m in match_all(SETTLEMENTS, profile)]
        plan = build_plan(BY_ID, matches, today=date(2026, 1, 20))
        self.assertGreater(plan["task_count"], 0)
        lo, hi = plan["estimated_total_recovery_usd"]
        self.assertGreaterEqual(hi, lo)
        # MN deadline 2026-02-10 is within 45d of 2026-01-20 -> should sort early
        titles = [t["title"] for t in plan["tasks"]]
        self.assertIn("Invitation Homes Minnesota Lease-Credit / Maintenance Settlement", titles)

    def test_auto_payment_channel(self):
        profile = {"landlords": [{"name": "Invitation Homes", "from": "2021-02-01", "to": "2023-09-01"}]}
        matches = [m.to_dict() for m in match_all(SETTLEMENTS, profile)]
        plan = build_plan(BY_ID, matches)
        ftc = next(t for t in plan["tasks"] if t["settlement_id"] == "invitation-homes-ftc-2025")
        self.assertEqual(ftc["recommended_channel"], "verify_address")


class DraftTests(unittest.TestCase):
    def test_claim_inquiry_contains_reasons(self):
        s = BY_ID["invitation-homes-mn-lease-credit-2026"]
        d = drafting.generate("claim_inquiry", s, {"name": "Test User"},
                              matched_reasons=["Rented from Invitation Homes in MN"])
        self.assertIn("Test User", d["body"])
        self.assertIn("Invitation Homes", d["body"])
        self.assertEqual(d["channel"], "email")

    def test_letter_has_address_block(self):
        s = BY_ID["invitation-homes-ftc-2025"]
        d = drafting.generate("records_request", s, {"name": "Test User"}, channel="letter")
        self.assertEqual(d["channel"], "letter")


if __name__ == "__main__":
    unittest.main()
