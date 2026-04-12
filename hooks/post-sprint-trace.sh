#!/bin/bash

# Harness Sprint Trace Hook (PostToolUse)
# Records structured JSONL events after each tool use during sprint
# Enables: session replay, performance analysis, failure pattern detection

set -euo pipefail

HOOK_INPUT=$(cat)

TRACE_DIR=".harness/traces"
TRACE_FILE="$TRACE_DIR/events.jsonl"

# Only trace during active sprint
if [[ ! -f ".harness/sprint-loop.md" ]]; then
  exit 0
fi

# Ensure trace directory exists
mkdir -p "$TRACE_DIR"

# Extract tool info from hook input
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // "unknown"')
TOOL_INPUT=$(echo "$HOOK_INPUT" | jq -r '.tool_input // {} | tostring' | head -c 500)
TOOL_RESULT_STATUS=$(echo "$HOOK_INPUT" | jq -r '.tool_result.is_error // false')
SESSION_ID=$(echo "$HOOK_INPUT" | jq -r '.session_id // "unknown"')
# macOS BSD date doesn't support %N; GNU date does
if date --version >/dev/null 2>&1; then
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
else
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
fi

# Parse sprint state
SPRINT_STATE=".harness/sprint-loop.md"
if [[ -f "$SPRINT_STATE" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SPRINT_STATE" 2>/dev/null || true)
  FEATURE=$(echo "$FRONTMATTER" | grep '^feature:' | sed 's/feature: *//' || echo "unknown")
  ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "0")
  WAVE=$(echo "$FRONTMATTER" | grep '^current_wave:' | sed 's/current_wave: *//' || echo "0")
else
  FEATURE="unknown"
  ITERATION="0"
  WAVE="0"
fi

# Detect special events
EVENT_TYPE="tool_use"

# Detect test execution
if [[ "$TOOL_NAME" == "Bash" ]]; then
  TOOL_CMD=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // ""')
  if echo "$TOOL_CMD" | grep -qiE '(npm test|jest|vitest|pytest|go test|cargo test|npx playwright)'; then
    EVENT_TYPE="test_run"
  fi
  if echo "$TOOL_CMD" | grep -qiE '(git commit|git merge)'; then
    EVENT_TYPE="git_operation"
  fi
fi

# Detect file modifications
if [[ "$TOOL_NAME" == "Edit" ]] || [[ "$TOOL_NAME" == "Write" ]]; then
  EVENT_TYPE="file_modify"
  FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // ""')
  TOOL_INPUT="$FILE_PATH"
fi

# Append JSONL event (atomic write)
EVENT=$(jq -cn \
  --arg ts "$TIMESTAMP" \
  --arg sid "$SESSION_ID" \
  --arg type "$EVENT_TYPE" \
  --arg tool "$TOOL_NAME" \
  --arg input "$TOOL_INPUT" \
  --argjson error "$TOOL_RESULT_STATUS" \
  --arg feature "$FEATURE" \
  --arg iter "$ITERATION" \
  --arg wave "$WAVE" \
  '{
    ts: $ts,
    session_id: $sid,
    event_type: $type,
    tool: $tool,
    input: $input,
    is_error: $error,
    feature: $feature,
    iteration: ($iter | tonumber),
    wave: ($wave | tonumber)
  }'
)

echo "$EVENT" >> "$TRACE_FILE"

# Track edit frequency for loop detection
if [[ "$EVENT_TYPE" == "file_modify" ]]; then
  EDIT_COUNT_FILE="$TRACE_DIR/.edit-counts"
  touch "$EDIT_COUNT_FILE"

  # Count edits to this file in current session
  FILE_EDITS=$(grep -c "\"input\":\"$FILE_PATH\"" "$TRACE_FILE" 2>/dev/null || echo "0")

  if [[ $FILE_EDITS -ge 6 ]]; then
    echo "⚠️ 同文件编辑 $FILE_EDITS 次: $FILE_PATH — 可能陷入循环" >&2
  fi
fi

exit 0
