#!/usr/bin/env bash
# Quick run of the macOS app during development (no .app bundle packaging).
#   ./Scripts/run.sh
set -euo pipefail
cd "$(dirname "$0")/.."
swift run AgentDexApp
