# Roadmap — honest phases

You asked me to "look ahead a little." Here's a real sequence. The thing
that makes the grand version ("everything linked, automated, a new peak")
even *possible* is doing the small phases in order. Skipping to the end is
how projects like this fizzle. Treat this as a decade-long *era* if you
want — but the next move is always a small, finishable step.

Timeframes are realistic. "By tonight" you can finish Phase 0. The rest is
weeks-to-months of consistent, enjoyable work — not a single sleepless
sprint. Pace it so it stays a journey you actually want to be on.

## Phase 0 — Foundation ✅ (done, today)
- Local SQLite store, CLI, document seeding, biometric simulator,
  interpretation layer, tests. **You can use it right now.**

## Phase 1 — Real documents (this week)
- Use `conlab docs search` → open archive links → `conlab docs add <url>`
  for the 10–20 documents you most care about.
- Read the actual Gateway Process PDF (`docs/GATEWAY.md` has the link).
- Add summaries + theme tags as you go. Goal: a curated, *verified* set,
  not a giant unread pile.

## Phase 2 — Real EEG (1–2 weeks)
- Implement `MuseSource.read()` with BrainFlow band powers
  (`docs/HARDWARE_MUSE_RPI.md`). One function.
- Optionally add a Polar H10 for HRV — highest-value extra signal.
- Record 5–10 baseline sessions so you know your *normal* before testing
  any intervention.

## Phase 3 — Your first honest experiment (2–4 weeks)
- Run the binaural-beat vs silent-control protocol in `GATEWAY.md`.
- Look at whether your own theta/alpha and HRV move, and whether they
  track your subjective ratings. **Write up the result either way.**

## Phase 4 — Analysis & visualization (later)
- Add plots (matplotlib) and simple stats (effect size, not just "it felt
  big"). A small Streamlit/Flask dashboard if you want a UI.
- Correlate `session_metrics` against your `centers` hypotheses — let the
  data confirm or kill each mapping.

## Phase 5 — Presentation / release (only after you have real data)
- If, and only if, you have repeatable findings, *then* think about
  packaging. Lead with method and raw data; keep the mysticism as clearly-
  labeled interpretation. See `docs/ETHICS.md` before monetizing or
  publishing anonymously.

## Things deliberately NOT promised
- A "unified theory of consciousness." Nobody has one; the app's value is
  that it lets you contribute *clean data*, not that it closes the theory.
- That chakra↔brainwave maps are true. They're hypotheses here, on purpose.
- Instant automation of "everything in your life." That's a separate,
  much larger project; don't let it block the focused, finishable work
  above.
