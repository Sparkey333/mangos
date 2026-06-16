# Consciousness Lab (`conlab`)

A grounded, **local-first** research toolkit for two concrete jobs:

1. **Collect & organize declassified documents** — the CIA FOIA reading
   room (CREST), the FBI Vault, the National Archives — including the
   genuinely real 1983 CIA *Analysis and Assessment of the Gateway
   Process* report, the STAR GATE remote-viewing collection, and MKULTRA
   records. These are public-domain. Reading and archiving them is legal.
2. **Record your own biometrics** — EEG band power from a Muse headband,
   plus heart rate — into a structured, searchable store so you can run
   honest *before/after* experiments on yourself (and on Ball).

It is deliberately small, runs on the **Python standard library only**
(no install needed to start), and keeps your data in one SQLite file you
own. Hardware and scraping are optional add-ons.

## The one rule that keeps this credible

**Raw measurement and interpretation live in separate layers.**

- `documents`, `sessions`, `session_metrics` = facts you can verify.
- `tags` (themes, *symbolic* parallels, *centers*/chakras) = your
  interpretations, always labeled as such, never overwriting the data.

This is what lets the project stay honest if you ever publish. "Crown
chakra ↔ gamma" is stored as a **hypothesis to test against your own
recordings**, not asserted as fact. See [`docs/ETHICS.md`](docs/ETHICS.md).

## Quick start (zero dependencies)

```bash
cd consciousness-lab
export PYTHONPATH=src

python -m conlab init                 # create the local database
python -m conlab docs seed            # load the verified anchor documents
python -m conlab docs list            # see them
python -m conlab docs search gateway process   # get archive search links

# Record a 30s session with the built-in simulator (no hardware yet):
python -m conlab record --subject me --seconds 30 --protocol gateway-focus

python -m conlab centers              # the testable "centers" hypothesis table
python -m conlab journal "Session notes go here" --subject me
python -m conlab status
```

Data lives in `~/.conlab/` by default (override with `CONLAB_HOME`).
Nothing leaves your machine unless *you* add code that uploads it.

## Install (optional)

```bash
pip install -e .              # adds the `conlab` command
pip install -e ".[hardware]"  # + BrainFlow for a real Muse headband
pip install -e ".[dev]"       # + pytest
pytest
```

## Layout

```
consciousness-lab/
├── src/conlab/
│   ├── cli.py            # command-line interface
│   ├── config.py         # where data lives
│   ├── db.py             # SQLite storage (the schema)
│   ├── documents/        # declassified-doc sources + collector
│   ├── biometrics/       # Muse adapter + simulator + session recorder
│   └── analysis/         # interpretation layer (themes/symbolic/centers)
├── docs/
│   ├── GATEWAY.md            # what the Gateway Process actually is
│   ├── HARDWARE_MUSE_RPI.md  # hacking the Muse with a Raspberry Pi
│   ├── ROADMAP.md            # realistic phases, not hype
│   └── ETHICS.md             # honesty + privacy + "should I sell this"
└── tests/
```

## Where this is honest with you

The measurable parts here are real and worth doing. The big framing words
in the original vision — "unified theory", "event horizon", "a new form" —
are aspirations, not deliverables. The way you get anywhere near them is
exactly this: small, repeatable measurements you actually log. Start by
collecting 10 good sessions and reading the primary Gateway document. See
[`docs/ROADMAP.md`](docs/ROADMAP.md) for an honest timeline.
