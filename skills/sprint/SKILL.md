---
name: sprint
description: "Execute all tasks with auto-loop until completion — Stop Hook driven"
argument-hint: "<feature-id e.g. F001> [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint.sh:*)"]
---

# Sprint — Auto-Loop Task Execution

Execute the setup script to initialize the sprint loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint.sh" $ARGUMENTS
```

You are now in sprint mode. The Stop Hook will keep you running until all tasks are complete.

## Sprint Execution Protocol

### 1. Read State

Read `.harness/tasks.md` and determine the current wave (first wave with any `pending` tasks).

### 2. Health Check

Before starting any wave:
- Verify the project builds successfully
- Run existing passing tests to confirm no regression
- If health check fails → fix regression first, do NOT start new tasks

### 3. Execute Current Wave

For each `pending` task in the current wave:

**If multiple tasks in same wave** → use Agent tool with `isolation: "worktree"` for parallel execution:

```
Agent(
  subagent_type: "general-purpose",
  isolation: "worktree",
  prompt: "You are an atomic task worker.

  TASK: {task_id} — {task_name}
  TESTS TO PASS: {test_ids}

  Steps:
  1. Read the spec: .harness/specs/{feature}.md
  2. Read the test files, locate {test_ids}
  3. Implement code to make tests pass
  4. Run: [test command] --grep '{task_id}'
  5. If GREEN: commit with 'feat({task_id}): {task_name}'
  6. If RED after 3 attempts: report failure

  RULES:
  - Do NOT modify test files
  - Do NOT modify files outside your task scope
  - Do NOT skip tests"
)
```

**If single task** → execute directly without worktree.

### 4. After Each Wave

1. **Merge**: If worktrees were used, merge all back to main branch
2. **Regression Check**: Run ALL passing tests — if any regression, STOP and fix
3. **Guardian Review** (background):
   ```
   Agent(subagent_type: "code-reviewer", run_in_background: true,
     prompt: "Review git diff HEAD~N: immutability, error handling, naming, no hardcoded values")
   ```
4. **Evaluator Checkpoint** (Clone scenario only — if `.harness/baseline/` exists):
   ```
   Agent(subagent_type: "general-purpose", run_in_background: true,
     prompt: "You are an Evaluator Agent. Quick-check the features completed in this wave
     against the baseline in .harness/baseline/.
     Use Playwright MCP to:
     1. Open the dev product at {dev-url from spec}
     2. Test each newly completed feature against its baseline description
     3. Score functional completeness and interaction consistency (1-10)
     4. Write findings to .harness/evidence/{FXXX}/wave-{N}-eval.md
     If any feature scores < 5, flag it as CRITICAL for the next wave.")
   ```
   - Read the Evaluator's wave-eval results before starting the next wave
   - If CRITICAL issues found → inject fix tasks into the next wave's task list
   - This is the **Sprint Contract** mechanism: Evaluator and Generator align between waves
5. **Update tasks.md**: Change completed task status from `pending` → `completed`
6. **Update progress.md**: Log wave completion with timestamp and Evaluator score (if applicable)
7. **Context Compression**: Compact context to preserve working memory

### 5. Doom Loop Detection

Track in `.harness/sprint-loop.md`:
- If a task fails 3+ times → mark as `failed`, skip it, log to progress
- If consecutive_failures ≥ 3 across tasks → STOP sprint, report to user
- Same file edited > 6 times without test progress → STOP

### 6. Completion

When ALL tasks in tasks.md are `completed`:
1. Run `/verify {feature-id}` (full V1→V2→V3)
2. Update tasks.md: feature status = `verified`
3. Output completion signal:

<promise>ALL_TASKS_DONE</promise>

### 7. If Stopped by Hook (next iteration)

When the Stop Hook feeds this prompt back:
1. Re-read `.harness/tasks.md` for current state
2. Re-read `.harness/sprint-loop.md` for iteration count
3. Determine next wave
4. Continue from Step 2

This creates a self-referential loop where each iteration picks up where the last left off, reading state from files rather than context memory.
