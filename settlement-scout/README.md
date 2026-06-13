# ⚖️ Settlement Scout

A one-stop tool to **find, match, plan, and draft outreach** for class-action and
regulatory settlements you may qualify for — built after researching the best
finder apps of 2026 (see [`RECOMMENDATIONS.md`](RECOMMENDATIONS.md)) and designed
to cover the gaps they leave.

It was seeded with the settlements relevant to you — the **Invitation Homes** FTC
junk-fee refund and Minnesota lease-credit settlement, and the **Cash App** TCPA
spam-text settlement (the "FreeCash"-style app suit) — plus reusable watchlists
for recurring TCPA and data-breach cases.

> **Not legal advice.** Informational tool only. Always confirm eligibility and
> deadlines on the **official settlement website** before filing. Drafts are for
> you to review and send yourself — the app never auto-sends anything.

## Why this exists / what's different

Most finder apps just link you to a PDF. Settlement Scout adds the missing pieces:
transparent **explainable matching**, coverage of **regulatory auto-refunds + mail-in
claims**, **deadline-driven schedules**, **drafted outreach**, and a structured
**data export** you own (built to train your other Law / AI projects). Full
comparison in [`RECOMMENDATIONS.md`](RECOMMENDATIONS.md).

## Quick start (zero dependencies — pure Python 3.10+ stdlib)

```bash
cd settlement-scout

# 1. Load curated settlements into the local DB
python3 -m settlement_scout.cli ingest

# 2. Load your profile (copy the example and edit it)
python3 -m settlement_scout.cli load-profile data/example_profile.json

# 3. See what you qualify for, with reasons
python3 -m settlement_scout.cli match

# 4. Get a prioritized action plan + tentative schedule
python3 -m settlement_scout.cli plan

# 5. Draft a claim-membership email (review before sending)
python3 -m settlement_scout.cli draft invitation-homes-mn-lease-credit-2026 --kind claim_inquiry

# 6. Export structured data (JSON + CSV) for your ML/Law projects
python3 -m settlement_scout.cli export

# Or run the web UI:
python3 -m settlement_scout.cli serve   # http://localhost:8765
```

## Your profile

A profile is JSON describing your history. Matching is explainable — each
settlement criterion resolves to ✓ match / ✗ no-match / ? unknown against it.
See [`data/example_profile.json`](data/example_profile.json). Key fields:

| Field | Shape | Used for |
|---|---|---|
| `states` | `[{state, from, to}]` | state-specific classes (e.g. MN, WA) |
| `landlords` | `[{name, from, to, state}]` | rental suits (Invitation Homes) |
| `apps` | `[{name, from, to}]` | app/service suits (Cash App TCPA) |
| `purchases` | `[{category, item, date}]` | product/consumer suits |
| `data_breaches` | `[{org, date}]` | data-breach settlements |
| `flags` | `["received_spam_texts", ...]` | watchlist triggers |

## Architecture

```
settlement_scout/
  matching.py     # explainable eligibility engine (status + reasons + score)
  schedule.py     # deadline-driven action plan & tentative schedule
  drafting.py     # email/letter draft generator (never auto-sends)
  db.py           # SQLite persistence (stdlib sqlite3)
  ingest.py       # run sources -> DB
  export.py       # JSON + CSV dataset export for ML training
  server.py       # stdlib HTTP server: JSON API + web UI
  cli.py          # command-line interface
  sources/        # pluggable source adapters
    seed.py             # curated, cited JSON (default, offline-safe)
    classaction_org.py  # example OPT-IN live adapter (robots.txt-aware)
    base.py             # SourceAdapter contract + robots check
data/
  seed_settlements.json # curated settlements w/ structured eligibility rules
  example_profile.json
tests/
  test_core.py    # matching, planning, drafting (python3 -m unittest)
```

### Adding a settlement
Append a record to `data/seed_settlements.json` with structured `eligibility`
criteria (ops: `overlaps_dates`, `state_in`, `contains`, `has`, `any`, `equals`),
each with a `label`, then re-run `ingest`. The matcher and planner pick it up
automatically.

## Data ownership & ML hand-off
`export` writes `exports/dataset.json` (full structured dump) and
`exports/matches.csv` (one labeled row per match: features + eligibility decision
+ reasons) — ready to feed your other Law / AI projects.

## Legal & ethical guardrails (please read)
- **Not legal advice / not a lawyer.** Confirm everything on official sites.
- **No auto-submission** of legal claims or court filings; **no auto-sending** of
  emails. You stay in the loop.
- **Polite data collection.** Live source adapters honor `robots.txt`, identify
  via User-Agent, and are **opt-in**; shipped data is curated and cited. Respect
  each site's Terms of Service.
- **Beware scams.** Real settlements never charge you to "release" a check.

## Roadmap ideas
- More curated sources + a human-review queue for live-scraped candidates
- Calendar (.ics) export of deadlines; email/SMS reminders
- Document vault (leases, receipts, breach letters) tied to each claim
- Optional AI extraction of eligibility windows from settlement notices (with review)
