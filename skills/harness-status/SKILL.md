---
name: harness-status
description: "Restore state, health check, determine current phase, suggest next step"
---

# Harness Status

Recover context and determine the current development phase.

## Step 1: Check Harness State

```bash
test -d .harness && echo "HARNESS_EXISTS" || echo "NO_HARNESS"
```

If no `.harness/` directory exists, tell the user to start with `/proposal`.

## Step 1.5: Check Configuration

```bash
test -f .harness/config.yaml && echo "CONFIG_EXISTS" || echo "NO_CONFIG"
```

If no config exists, suggest running `/harness-init` first for optimal experience.

## Step 2: Read State Files

1. List all specs: `ls .harness/specs/ 2>/dev/null`
2. Read config: Read `.harness/config.yaml` (if exists) for project context
3. Read tasks: Read `.harness/tasks.md` (if exists)
4. Read progress (last 50 lines): Read `.harness/progress.md` offset from end
5. Check sprint loop: Read `.harness/sprint-loop.md` (if exists)
6. Check invariants: Read `.harness/invariants.md` (if exists) for learned constraints
7. Check traces: Count events in `.harness/traces/events.jsonl` (if exists)
8. Recent git history: `git log --oneline -20`

## Step 3: Output Summary

For each feature, report:
- Spec status (draft/approved/tests-aligned)
- Test status (how many RED/GREEN)
- Task status (pending/in_progress/completed/failed counts per wave)
- Sprint loop status (active/inactive, iteration count)

## Step 4: Determine Phase

| State | Current Phase | Next Step |
|-------|--------------|-----------|
| No specs | Phase 1 | `/proposal` |
| Spec approved, no tests | Phase 2 | `/tdd-align FXXX` |
| Tests exist, no task decomposition | Pre-Phase 3 | `/decompose FXXX` |
| Tasks decomposed, pending tasks exist | Phase 3 | `/sprint FXXX` |
| All tasks done, not verified | Phase 4 | `/verify FXXX` |
| Feature verified | Complete | Start next feature |

## Step 5: Health Check

- Dependencies installed? (`npm ci` / `pip install` / etc.)
- Build passes?
- Core tests green?
- If anything fails → **fix regression first**

## Step 6: Evolution Suggestions

Based on project state, suggest evolution actions:

| Condition | Suggestion |
|-----------|-----------|
| 3+ features completed, evolution log empty | "建议运行 `/harness evolve` 分析失败模式、发现可封装的重复工作" |
| No config.yaml | "建议运行 `/harness init` 适配项目规范" |
| Sprint had failures | "建议运行 `/harness evolve` 分析失败原因" |
| Eval scores trending down | "建议运行 `/adversarial-review` 深度审查" |

## Step 7: Output Plan

State clearly:
- Current phase
- Project configuration status (initialized? norms? invariants?)
- Specific goal for this session
- Which tasks/waves to work on
- Verification method
- Evolution status (invariants count, last evolution date)
