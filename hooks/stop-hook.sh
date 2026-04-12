#!/bin/bash

# Harness Sprint Stop Hook
# Prevents session exit when a sprint loop is active
# Feeds the sprint prompt back to continue execution

set -euo pipefail

HOOK_INPUT=$(cat)

SPRINT_STATE=".harness/sprint-loop.md"
EVOLUTION_LOG=".harness/evolution-log.md"
INVARIANTS_FILE=".harness/invariants.md"
TRACES_FILE=".harness/traces/events.jsonl"

# ─── Auto-evolution: runs when sprint completes ───
# Observe → diagnose → evolve, embedded in sprint lifecycle.
run_auto_evolution() {
  local feature="$1"
  local iterations="$2"

  # Skip if no traces
  [[ -f "$TRACES_FILE" ]] || return 0

  local NOW
  NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  # ── Observe: collect failure signals ──
  local ERROR_COUNT=0
  local LOOP_FILES=""
  local FAILED_TASKS=0

  ERROR_COUNT=$(jq 'select(.is_error == true)' "$TRACES_FILE" 2>/dev/null | wc -l | tr -d ' ')

  # Files edited 5+ times (potential loop indicator)
  LOOP_FILES=$(jq -r 'select(.event_type == "file_modify") | .input' "$TRACES_FILE" 2>/dev/null \
    | sort | uniq -c | sort -rn | awk '$1 >= 5 {print $1 "x " $2}' | head -5)

  if [[ -f ".harness/tasks.md" ]]; then
    FAILED_TASKS=$(grep -c '| failed |' .harness/tasks.md 2>/dev/null || echo 0)
  fi

  # ── Diagnose: classify patterns ──
  local PATTERNS=""
  local PATTERN_COUNT=0

  if [[ -n "$LOOP_FILES" ]]; then
    PATTERNS="${PATTERNS}file-loop: ${LOOP_FILES}\n"
    PATTERN_COUNT=$((PATTERN_COUNT + 1))
  fi

  if [[ $FAILED_TASKS -gt 0 ]]; then
    PATTERNS="${PATTERNS}failed-tasks: ${FAILED_TASKS} tasks failed\n"
    PATTERN_COUNT=$((PATTERN_COUNT + 1))
  fi

  if [[ $ERROR_COUNT -gt 10 ]]; then
    PATTERNS="${PATTERNS}high-error-rate: ${ERROR_COUNT} tool errors\n"
    PATTERN_COUNT=$((PATTERN_COUNT + 1))
  fi

  # ── Evolve: append to evolution log ──
  mkdir -p "$(dirname "$EVOLUTION_LOG")"

  cat >> "$EVOLUTION_LOG" <<EVOLOG

## $NOW — Sprint 完成自动进化 ($feature)

- 迭代次数: $iterations
- 错误事件: $ERROR_COUNT
- 失败任务: $FAILED_TASKS
- 发现模式: $PATTERN_COUNT 个
EVOLOG

  if [[ -n "$LOOP_FILES" ]]; then
    echo "- 高频编辑文件:" >> "$EVOLUTION_LOG"
    echo -e "$LOOP_FILES" | while read -r line; do
      echo "  - $line" >> "$EVOLUTION_LOG"
    done
  fi

  # ── Promote to invariant if pattern seen 3+ times ──
  if [[ -f "$EVOLUTION_LOG" ]] && [[ -f "$INVARIANTS_FILE" ]]; then
    # Count how many times "file-loop" pattern appears across sprints
    local LOOP_HISTORY
    LOOP_HISTORY=$(grep -c "file-loop:" "$EVOLUTION_LOG" 2>/dev/null || echo 0)

    if [[ $LOOP_HISTORY -ge 3 ]]; then
      if ! grep -q "INV-AUTO-LOOP" "$INVARIANTS_FILE" 2>/dev/null; then
        cat >> "$INVARIANTS_FILE" <<INVEOF

### INV-AUTO-LOOP: 高频文件编辑检测
- **规则**: 同一文件被编辑 5 次以上时，停下来重新审视方案，不要继续硬调
- **来源**: 自动进化（$LOOP_HISTORY 次 Sprint 观测到此模式）
- **注入目标**: sprint
- **动作**: 编辑文件前检查是否已经反复修改，如果是则换一个实现思路
INVEOF
        echo "- **新增不变量**: INV-AUTO-LOOP (高频编辑检测)" >> "$EVOLUTION_LOG"
      fi
    fi
  fi

  # Summary line to progress
  if [[ -f ".harness/progress.md" ]]; then
    echo "$NOW Evolution: $PATTERN_COUNT patterns, $ERROR_COUNT errors, $FAILED_TASKS failed tasks" >> .harness/progress.md
  fi

  echo "Evolution: analyzed sprint ($PATTERN_COUNT patterns detected)" >&2
}

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
    run_auto_evolution "$FEATURE" "$ITERATION"
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
    run_auto_evolution "$FEATURE" "$ITERATION"
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
