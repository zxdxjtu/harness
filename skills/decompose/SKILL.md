---
name: decompose
description: "Decompose tests into atomic task DAG with wave-based parallel execution"
argument-hint: "<feature-id e.g. F001>"
---

# Decompose — Atomic Task DAG

**Parameter**: $ARGUMENTS — feature ID (e.g. F001)

## Precondition

- Spec must be `approved`
- Test files must exist and ALL be RED

## Step 1: Analyze Test Cases

Read all test files for this feature. List every test ID.

## Step 2: Build Atomic Tasks

Map each test ID (or group of closely related tests) to one atomic task.

Each task must satisfy:
- **≤ 2 hours** of agent work
- **One clear completion criterion**: corresponding tests go from RED → GREEN
- **Explicit inputs**: which task outputs (files, interfaces) are required
- **Explicit outputs**: which files are produced + which tests turn green
- **Independently verifiable**: can run the test in isolation

## Step 3: Analyze Dependencies

Determine task ordering:
- Type/interface definitions → implementations using those types
- Data layer → business logic → UI layer
- Unit test tasks → integration test tasks → E2E test tasks

## Step 4: Assign Waves

- No dependencies → Wave 1 (parallel)
- Depends on Wave 1 → Wave 2 (parallel)
- ... and so on

## Step 5: Write tasks.md

Write to `.harness/tasks.md`:

```markdown
# Tasks — $ARGUMENTS

## DAG Visualization
Wave 1: [T001] [T002] [T005]     ← parallel, no dependencies
Wave 2: [T003] [T006]            ← depends on Wave 1
Wave 3: [T004]                   ← depends on Wave 2
Wave 4: [T007] [T008]            ← E2E verification

## Task List

| ID | Name | Wave | Status | Tests | Retries | BlockedBy | Files |
|----|------|------|--------|-------|---------|-----------|-------|
| T001 | desc | 1 | pending | T001-V1 | 0 | - | src/... |
| T002 | desc | 1 | pending | T002-V1 | 0 | - | src/... |
| T003 | desc | 2 | pending | T003-V1,V2 | 0 | T001 | src/... |

## Summary
- Total tasks: N
- Waves: M
- Estimated parallel speedup: Nx → Mx
```

## Step 6: Update Progress

Append to `.harness/progress.md`:
```
## [timestamp] Task Decomposition — $ARGUMENTS
- Total tasks: N
- Waves: M
- Status: awaiting human approval
```

## Step 7: Request Approval

Present the DAG to the user. Ask:
> "Does this task breakdown make sense? Are dependencies correct? Any tasks that should be split or merged?"

**Do NOT proceed until approved.**

## Next Step
After approval, tell the user to run: `/sprint $ARGUMENTS`
