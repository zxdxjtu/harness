#!/bin/bash

# Harness Sprint Setup Script
# Creates state file for sprint loop execution

set -euo pipefail

# Parse arguments
FEATURE_ID=""
MAX_ITERATIONS=30
PROMPT_PARTS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      cat << 'HELP_EOF'
Harness Sprint — Auto-loop task execution

USAGE:
  /sprint <feature-id> [OPTIONS]

ARGUMENTS:
  feature-id    Feature ID (e.g. F001)

OPTIONS:
  --max-iterations <n>    Max iterations before auto-stop (default: 30)
  -h, --help              Show this help message

EXAMPLES:
  /sprint F001
  /sprint F001 --max-iterations 50

STOPPING:
  Sprint stops when:
  - All tasks in .harness/tasks.md are completed
  - Max iterations reached
  - 3+ consecutive failures detected (doom loop)
  - User runs /cancel-sprint
HELP_EOF
      exit 0
      ;;
    --max-iterations)
      if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-iterations requires a positive integer" >&2
        exit 1
      fi
      MAX_ITERATIONS="$2"
      shift 2
      ;;
    *)
      if [[ -z "$FEATURE_ID" ]]; then
        FEATURE_ID="$1"
      fi
      shift
      ;;
  esac
done

# Validate feature ID
if [[ -z "$FEATURE_ID" ]]; then
  echo "Error: No feature ID provided" >&2
  echo "Usage: /sprint <feature-id> [--max-iterations N]" >&2
  exit 1
fi

# Validate .harness/tasks.md exists
if [[ ! -f ".harness/tasks.md" ]]; then
  echo "Error: .harness/tasks.md not found" >&2
  echo "Run /decompose $FEATURE_ID first to create the task DAG" >&2
  exit 1
fi

# Create sprint loop state file
mkdir -p .harness

cat > .harness/sprint-loop.md <<EOF
---
active: true
session_id: ${CLAUDE_CODE_SESSION_ID:-unknown}
feature: $FEATURE_ID
iteration: 1
max_iterations: $MAX_ITERATIONS
current_wave: 1
consecutive_failures: 0
started_at: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
---

Execute sprint for feature $FEATURE_ID. Read .harness/tasks.md for task list. Execute pending tasks wave by wave. Use Agent(worktree) for parallel tasks. Run regression tests after each wave. Update tasks.md and progress.md. When all tasks are completed, run /verify $FEATURE_ID and output <promise>ALL_TASKS_DONE</promise>.
EOF

# Count tasks
TOTAL=$(grep -c '| T[0-9]' .harness/tasks.md 2>/dev/null || echo 0)
PENDING=$(grep -c '| pending |' .harness/tasks.md 2>/dev/null || echo 0)

cat <<EOF
Sprint loop activated for $FEATURE_ID

  Tasks: $PENDING pending / $TOTAL total
  Max iterations: $MAX_ITERATIONS
  Stop hook: active (will prevent exit until all tasks complete)

  Doom loop protection:
    - Task fails 3x → skip and report
    - 3+ consecutive failures → stop sprint
    - Same file edited 6x without progress → stop

  To cancel: /cancel-sprint
  To check status: /harness-status

Starting sprint execution...
EOF
