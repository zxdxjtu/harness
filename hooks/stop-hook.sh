#!/bin/bash

# Harness Sprint Stop Hook
# Prevents session exit when a sprint loop is active
# Feeds the sprint prompt back to continue execution

set -euo pipefail

HOOK_INPUT=$(cat)

SPRINT_STATE=".harness/sprint-loop.md"

# No active sprint → allow exit
if [[ ! -f "$SPRINT_STATE" ]]; then
  exit 0
fi

# Parse frontmatter
FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SPRINT_STATE")
ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//')
MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//')
FEATURE=$(echo "$FRONTMATTER" | grep '^feature:' | sed 's/feature: *//')
CONSECUTIVE_FAILURES=$(echo "$FRONTMATTER" | grep '^consecutive_failures:' | sed 's/consecutive_failures: *//')
CURRENT_WAVE=$(echo "$FRONTMATTER" | grep '^current_wave:' | sed 's/current_wave: *//')

# Session isolation
STATE_SESSION=$(echo "$FRONTMATTER" | grep '^session_id:' | sed 's/session_id: *//' || true)
HOOK_SESSION=$(echo "$HOOK_INPUT" | jq -r '.session_id // ""')
if [[ -n "$STATE_SESSION" ]] && [[ "$STATE_SESSION" != "unknown" ]] && [[ "$STATE_SESSION" != "$HOOK_SESSION" ]]; then
  exit 0
fi

# Validate numeric fields
for field in ITERATION MAX_ITERATIONS CONSECUTIVE_FAILURES; do
  val="${!field}"
  if [[ ! "$val" =~ ^[0-9]+$ ]]; then
    echo "Sprint loop: corrupted state ($field=$val), stopping." >&2
    rm "$SPRINT_STATE"
    exit 0
  fi
done

# Max iterations check
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "Sprint: Max iterations ($MAX_ITERATIONS) reached for $FEATURE."
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Sprint stopped: max iterations reached (iteration $ITERATION)" >> .harness/progress.md
  rm "$SPRINT_STATE"
  exit 0
fi

# Doom loop check
if [[ $CONSECUTIVE_FAILURES -ge 3 ]]; then
  echo "Sprint: Doom loop detected ($CONSECUTIVE_FAILURES consecutive failures). Stopping."
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) Sprint stopped: doom loop ($CONSECUTIVE_FAILURES consecutive failures)" >> .harness/progress.md
  rm "$SPRINT_STATE"
  exit 0
fi

# Check completion via transcript
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')
if [[ -f "$TRANSCRIPT_PATH" ]]; then
  set +e
  LAST_OUTPUT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -n 50 | jq -rs '
    map(.message.content[]? | select(.type == "text") | .text) | last // ""
  ' 2>/dev/null)
  set -e

  # Check for completion promise
  if echo "$LAST_OUTPUT" | grep -q '<promise>ALL_TASKS_DONE</promise>'; then
    echo "Sprint complete: all tasks done for $FEATURE."
    rm "$SPRINT_STATE"
    exit 0
  fi
fi

# Check tasks.md for completion
if [[ -f ".harness/tasks.md" ]]; then
  PENDING=$(grep -c '| pending |' .harness/tasks.md 2>/dev/null || echo 0)
  COMPLETED=$(grep -c '| completed |' .harness/tasks.md 2>/dev/null || echo 0)
  FAILED=$(grep -c '| failed |' .harness/tasks.md 2>/dev/null || echo 0)
  TOTAL=$((PENDING + COMPLETED + FAILED))

  if [[ $PENDING -eq 0 ]] && [[ $TOTAL -gt 0 ]]; then
    echo "Sprint: All tasks resolved ($COMPLETED completed, $FAILED failed)."
    rm "$SPRINT_STATE"
    exit 0
  fi
fi

# Not complete — continue loop
NEXT_ITERATION=$((ITERATION + 1))

# Extract prompt from state file
PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' "$SPRINT_STATE")

if [[ -z "$PROMPT_TEXT" ]]; then
  echo "Sprint loop: no prompt in state file, stopping." >&2
  rm "$SPRINT_STATE"
  exit 0
fi

# Update iteration counter
TEMP_FILE="${SPRINT_STATE}.tmp.$$"
sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$SPRINT_STATE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$SPRINT_STATE"

# Build system message
SYSTEM_MSG="Sprint iteration $NEXT_ITERATION | Feature: $FEATURE | Wave: $CURRENT_WAVE | Pending: ${PENDING:-?} tasks | To stop: /cancel-sprint"

jq -n \
  --arg prompt "$PROMPT_TEXT" \
  --arg msg "$SYSTEM_MSG" \
  '{
    "decision": "block",
    "reason": $prompt,
    "systemMessage": $msg
  }'

exit 0
