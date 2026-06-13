"""Paths and shared config."""
from __future__ import annotations

import os
from pathlib import Path

PKG_DIR = Path(__file__).resolve().parent
ROOT_DIR = PKG_DIR.parent
DATA_DIR = ROOT_DIR / "data"
SEED_FILE = DATA_DIR / "seed_settlements.json"
WEB_DIR = PKG_DIR / "web"

DB_PATH = Path(os.environ.get("SETTLEMENT_SCOUT_DB", DATA_DIR / "scout.db"))
PROFILE_PATH = Path(os.environ.get("SETTLEMENT_SCOUT_PROFILE", DATA_DIR / "profile.json"))
EXPORT_DIR = ROOT_DIR / "exports"

# Sender identity used when drafting outreach. Override via env.
USER_FULL_NAME = os.environ.get("SCOUT_USER_NAME", "[Your Full Name]")
USER_EMAIL = os.environ.get("SCOUT_USER_EMAIL", "[your@email.com]")
USER_ADDRESS = os.environ.get("SCOUT_USER_ADDRESS", "[Your Mailing Address]")
