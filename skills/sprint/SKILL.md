---
name: sprint
description: "Execute all tasks with auto-loop, steward/entropy/evaluator checkpoints — Stop Hook driven"
argument-hint: "<feature-id e.g. F001> [--max-iterations N]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint.sh:*)"]
---

# Sprint — Auto-Loop Task Execution with Guardian Checkpoints

Execute the setup script to initialize the sprint loop:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-sprint.sh" $ARGUMENTS
```

You are now in sprint mode. The Stop Hook will keep you running until all tasks are complete.

## Sprint Execution Protocol

### 1. Read State

Read `.harness/tasks.md` and determine the current wave (first wave with any `pending` tasks).
Read `.harness/config.json` to know if stewardship and entropy cleanup are enabled.
Read the spec to check the `flow` field and `scenario`.

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
  MODULE: {module_name} (see AGENT.md at {agent_md_path} for boundaries)

  Steps:
  1. Read the spec: .harness/specs/{feature}.md
  2. Read the test files, locate {test_ids}
  3. Read the module's AGENT.md for boundaries and quality standards
  4. Implement code to make tests pass
  5. Run: [test command] --grep '{task_id}'
  6. If GREEN: commit with 'feat({task_id}): {task_name}'
  7. If RED after 3 attempts: report failure

  RULES:
  - Do NOT modify test files
  - Do NOT modify files outside your task's module scope (check AGENT.md Owns)
  - Do NOT introduce forbidden dependencies (check AGENT.md Forbidden Dependencies)
  - Do NOT skip tests"
)
```

**If single task** → execute directly without worktree.

### 4. After Each Wave — Three Guardian Checkpoints

After all tasks in the wave are complete:

#### 4.1 Merge & Regression

1. **Merge**: If worktrees were used, merge all back to main branch
2. **Regression Check**: Run ALL passing tests — if any regression, STOP and fix

#### 4.2 Steward Checkpoint (if `stewardship_enabled` in config)

Launch module guardian check:

```
Agent(subagent_type: "general-purpose", run_in_background: true,
  prompt: "Execute the steward protocol for feature {FXXX}, wave {N}.

  Read each affected module's AGENT.md.
  Check: ownership, dependency direction, interface contracts, quality standards.
  Write report to .harness/evidence/{FXXX}/steward-wave-{N}.md

  If CRITICAL issues found, report immediately.
  See the steward skill instructions for full protocol.")
```

Read the steward report:
- **CRITICAL issues** → STOP sprint, fix before continuing
- **HIGH issues** → Log, must fix before feature completion
- **MEDIUM** → Log for entropy cleanup

#### 4.3 Entropy Cleanup (if `entropy_cleanup_enabled` in config)

Launch cleanup agent:

```
Agent(subagent_type: "general-purpose", run_in_background: true,
  prompt: "Execute the entropy cleanup protocol for feature {FXXX}, wave {N}.

  Scan changed files for: debug artifacts, orphan files, style violations, git hygiene.
  Auto-fix safe issues (formatting, obvious debug statements).
  Write report to .harness/evidence/{FXXX}/entropy-cleanup-wave-{N}.md

  See the entropy-clean skill instructions for full protocol.")
```

#### 4.4 Evaluator Checkpoint (if `evaluate` is in the feature's flow)

Launch evaluator for quick dimensional assessment:

```
Agent(subagent_type: "general-purpose", run_in_background: true,
  prompt: "You are an Evaluator Agent. Quick-check the features completed in this wave.

  Read .harness/config.json for eval_dimensions profile.
  Load the dimension profile from templates/eval-dimensions/{profile}.json.

  For dimensions with method 'automated':
    Run the relevant tests/tools and score.

  For dimensions with method 'agent-review':
    Quick review the wave's changes against the spec.

  For dimensions with method 'playwright' (clone scenario):
    Test newly completed features against baseline.

  Score each dimension 1-10.
  If any dimension scores < 5, flag it as CRITICAL for the next wave.
  Write findings to .harness/evidence/{FXXX}/wave-{N}-eval.md")
```

Read Evaluator results:
- **CRITICAL scores (<5)** → Inject fix tasks into the next wave's task list
- This is the **Sprint Contract** mechanism

#### 4.5 Update State

1. **Update tasks.md**: Change completed task status from `pending` → `completed`
2. **Update progress.md**: Log wave completion with timestamp, steward results, evaluator score
3. **Context Compression**: Compact context to preserve working memory

### 5. Doom Loop Detection

Track in `.harness/sprint-loop.md`:
- If a task fails 3+ times → mark as `failed`, skip it, log to progress
- If consecutive_failures ≥ 3 across tasks → STOP sprint, report to user
- Same file edited > 6 times without test progress → STOP

### 6. Completion

When ALL tasks in tasks.md are `completed`:
1. Run the full evaluation protocol (if `evaluate` is in the flow)
2. Update tasks.md: feature status = `verified`
3. Output completion signal:

<promise>ALL_TASKS_DONE</promise>

### 7. If Stopped by Hook (next iteration)

When the Stop Hook feeds this prompt back:
1. Re-read `.harness/tasks.md` for current state
2. Re-read `.harness/sprint-loop.md` for iteration count
3. Determine next wave
4. Continue from Step 2

## Next Step — Auto-Navigate

When all tasks are done and `<promise>ALL_TASKS_DONE</promise>` is output:

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal → ✅ tdd-align → ✅ decompose → ✅ sprint → ⬜ {next}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Sprint 完成: {N} 个任务，{M} 个 Wave
守护报告: {steward summary}
```

Read the `flow` field and navigate to the next phase:
> "Sprint 完成，{N} 个任务全部通过。下一步是 **{next phase}**（{description}）。是否继续？"
