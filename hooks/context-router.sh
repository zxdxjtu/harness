#!/bin/bash

# Harness Context Router (PostToolUse for Edit|Write)
# When a file is edited, inject relevant context fragments automatically.
# This gives the Agent "position sense" — awareness of related constraints.

set -euo pipefail

HOOK_INPUT=$(cat)

CONFIG_FILE=".harness/config.yaml"
INVARIANTS_FILE=".harness/invariants.md"
CONTEXT_DIR=".harness/skill-context"
INJECTED_FILE=".harness/.injected-context"

# Skip if no config
if [[ ! -f "$CONFIG_FILE" ]]; then
  exit 0
fi

# Get the edited file path
FILE_PATH=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // ""')
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Initialize injection tracking (deduplication within session)
# Reset if file is older than 2 hours (proxy for new session)
if [[ -f "$INJECTED_FILE" ]]; then
  FILE_AGE=$(( $(date +%s) - $(stat -f %m "$INJECTED_FILE" 2>/dev/null || stat -c %Y "$INJECTED_FILE" 2>/dev/null || echo 0) ))
  if [[ $FILE_AGE -gt 7200 ]]; then
    rm -f "$INJECTED_FILE"
  fi
fi
touch "$INJECTED_FILE"

# Determine relevant context based on file path patterns
CONTEXT_FRAGMENTS=""

# API routes → inject API conventions
if echo "$FILE_PATH" | grep -qiE '(routes?|controllers?|handlers?|endpoints?|api)'; then
  CONTEXT_FRAGMENTS="$CONTEXT_FRAGMENTS api-conventions"
fi

# Database files → inject schema conventions
if echo "$FILE_PATH" | grep -qiE '(models?|schema|migration|db|database|orm|prisma|drizzle)'; then
  CONTEXT_FRAGMENTS="$CONTEXT_FRAGMENTS schema-conventions"
fi

# Test files → inject test conventions
if echo "$FILE_PATH" | grep -qiE '(test|spec|__tests__|\.test\.|\.spec\.)'; then
  CONTEXT_FRAGMENTS="$CONTEXT_FRAGMENTS test-conventions"
fi

# Auth files → inject security constraints
if echo "$FILE_PATH" | grep -qiE '(auth|login|session|token|credential|password|jwt|oauth)'; then
  CONTEXT_FRAGMENTS="$CONTEXT_FRAGMENTS security-constraints"
fi

# Config/env files → inject env conventions
if echo "$FILE_PATH" | grep -qiE '(config|\.env|settings|constants)'; then
  CONTEXT_FRAGMENTS="$CONTEXT_FRAGMENTS config-conventions"
fi

# UI components → inject UI conventions
if echo "$FILE_PATH" | grep -qiE '(component|page|view|layout|widget)\.(tsx?|jsx?|vue|svelte)'; then
  CONTEXT_FRAGMENTS="$CONTEXT_FRAGMENTS ui-conventions"
fi

# No relevant fragments → skip
if [[ -z "$CONTEXT_FRAGMENTS" ]]; then
  exit 0
fi

# Build context message (deduplicated)
MESSAGE=""
for FRAGMENT in $CONTEXT_FRAGMENTS; do
  # Skip if already injected this session
  if grep -q "^$FRAGMENT$" "$INJECTED_FILE" 2>/dev/null; then
    continue
  fi

  # Mark as injected
  echo "$FRAGMENT" >> "$INJECTED_FILE"

  # Load fragment content
  FRAGMENT_FILE="$CONTEXT_DIR/${FRAGMENT}.md"
  if [[ -f "$FRAGMENT_FILE" ]]; then
    CONTENT=$(cat "$FRAGMENT_FILE")
    MESSAGE="$MESSAGE\n---\n## ⚡ Context: $FRAGMENT\n$CONTENT\n"
  fi
done

# Load invariants relevant to this file type
if [[ -f "$INVARIANTS_FILE" ]]; then
  # Check if any invariant mentions this file's module/directory
  FILE_DIR=$(dirname "$FILE_PATH" | sed 's|.*/||')
  RELEVANT_INVS=$(grep -A 3 "注入目标:" "$INVARIANTS_FILE" 2>/dev/null | grep -B 1 -i "$FILE_DIR" | grep "###" || true)
  if [[ -n "$RELEVANT_INVS" ]]; then
    if ! grep -q "invariants-$FILE_DIR" "$INJECTED_FILE" 2>/dev/null; then
      echo "invariants-$FILE_DIR" >> "$INJECTED_FILE"
      MESSAGE="$MESSAGE\n---\n## ⚠️ 相关不变量\n$RELEVANT_INVS\n请在编辑时遵守以上不变量。\n"
    fi
  fi
fi

# Output context as description (shown to user as advisory in PostToolUse)
# Claude Code PostToolUse hooks can output text to stderr for display
# but for reliable Agent awareness, we write to a temp file that the Agent can read
if [[ -n "$MESSAGE" ]]; then
  echo -e "$MESSAGE" >&2
  # Also append to a context hints file that Skills can read
  echo -e "\n$(date -u +%Y-%m-%dT%H:%M:%SZ) | Editing: $FILE_PATH$MESSAGE" >> ".harness/.context-hints"
fi

exit 0
