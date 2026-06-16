"""Configuration and paths for Consciousness Lab.

Resolution order for the data directory:
1. ``CONLAB_HOME`` environment variable, if set.
2. ``~/.conlab`` otherwise.

The data directory holds the SQLite database and any downloaded
document files. It is created on demand.
"""

from __future__ import annotations

import os
from pathlib import Path


def data_home() -> Path:
    """Return the base data directory, creating it if needed."""
    env = os.environ.get("CONLAB_HOME")
    base = Path(env).expanduser() if env else Path.home() / ".conlab"
    base.mkdir(parents=True, exist_ok=True)
    return base


def db_path() -> Path:
    """Path to the SQLite database file."""
    return data_home() / "conlab.sqlite3"


def documents_dir() -> Path:
    """Directory where downloaded document files are stored."""
    d = data_home() / "documents"
    d.mkdir(parents=True, exist_ok=True)
    return d
