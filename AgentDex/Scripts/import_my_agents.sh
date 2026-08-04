#!/usr/bin/env bash
#
# Convenience wrapper: scan your Claude Code agents + project logs and generate a
# roster the app will pick up automatically. Edit the paths below to taste.
#
#   ./Scripts/import_my_agents.sh [project-name]
#
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="${1:-mangos}"

# Common Claude Code locations. Missing paths are simply skipped by the importer.
AGENT_DIRS=(
  "$HOME/.claude/agents"
  "./.claude/agents"
)
LOG_PATHS=(
  "$HOME/.claude/projects"
  "$HOME/.claude/history"
)

ARGS=()
for d in "${AGENT_DIRS[@]}"; do [ -e "$d" ] && ARGS+=(--agents "$d"); done
for l in "${LOG_PATHS[@]}"; do [ -e "$l" ] && ARGS+=(--logs "$l"); done

if [ ${#ARGS[@]} -eq 0 ]; then
  echo "No agent dirs or logs found. Point the importer at your paths, e.g.:"
  echo "  swift run agentdex-import --agents ~/.claude/agents --logs ~/.claude/projects --project $PROJECT"
  exit 1
fi

echo "==> importing agents for project '$PROJECT'…"
swift run agentdex-import "${ARGS[@]}" --project "$PROJECT"
echo ""
echo "Roster written to the shared AgentDex config dir. Launch the app to see your"
echo "own daemons — or re-run with --print to preview the JSON first."
