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

## Step 2: Read State Files

1. List all specs: `ls .harness/specs/ 2>/dev/null`
2. Read tasks: `cat .harness/tasks.md 2>/dev/null`
3. Read progress (last 50 lines): `tail -50 .harness/progress.md 2>/dev/null`
4. Check sprint loop: `cat .harness/sprint-loop.md 2>/dev/null`
5. Recent git history: `git log --oneline -20`

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

## Step 6: Output Plan

State clearly:
- Current phase
- Specific goal for this session
- Which tasks/waves to work on
- Verification method
