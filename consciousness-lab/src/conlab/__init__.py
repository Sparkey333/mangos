"""Consciousness Lab (conlab).

A grounded, local-first research toolkit for two things:

1. Collecting and organizing *declassified* government documents
   (CIA CREST / FOIA reading room, FBI Vault) — including the real
   1983 CIA "Gateway Process" assessment.
2. Recording your own biometric data (EEG via a Muse headband,
   heart rate) into a structured, searchable store so you can run
   honest before/after experiments on yourself.

Design principles:
- Local-first. Everything lives in a SQLite file you own. Nothing
  is uploaded anywhere unless you write code to do so.
- Honest layering. Raw measurements (documents, EEG band powers,
  HR) are kept separate from interpretation (themes, "chakra"
  mappings, symbolic tags). The interpretation layer is clearly
  labeled as interpretation, never asserted as fact.
- Runs with zero dependencies for the core. Hardware and scraping
  extras are optional and degrade gracefully.
"""

__version__ = "0.1.0"
