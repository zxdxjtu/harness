---
description: "Generate three-layer tests from spec — tests are the alignment contract"
argument-hint: "<feature-id e.g. F001>"
---

# TDD Align — Tests as Executable Contract

**Parameter**: $ARGUMENTS — feature ID (e.g. F001)

## Goal

Based on the approved spec, write complete test cases. Tests are the ONLY executable contract between human and agent. Once approved, the agent's sole objective is to make these tests pass.

## Step 1: Read Spec

Read `.harness/specs/$ARGUMENTS*.md`. Extract all AC (Acceptance Criteria) and INV (Invariants).

If spec status is not `approved`, STOP and tell user to run `/proposal` first.

## Step 2: Detect Test Framework

Auto-detect the project's test framework:
- Check `package.json` for jest/vitest/mocha
- Check for `pytest.ini`, `setup.cfg`, `pyproject.toml` for pytest
- Check for `*_test.go` files for Go
- Check for `Cargo.toml` for Rust
- Fall back to asking the user

## Step 3: Generate Three-Layer Tests

For each AC-N, generate:

- **V1 Unit Test**: Pure logic validation (data transforms, validation rules, computations)
- **V2 Integration Test**: Module interaction (state management, API calls, event flow)
- **V3 E2E Test**: User perspective (operation flow, UI state, screenshots)

For each INV-N, generate V1 invariant tests.

### Naming Convention

```
[F001] Feature Name
  [AC-1] Acceptance Criteria Description
    [T001-V1] should... (unit)
    [T002-V2] should... (integration)
    [T003-V3] should... (e2e)
  [AC-2] ...
    [T004-V1] should...
  [INV-1] Invariant Description
    [T010-V1] must always...
```

## Step 4: Test Quality Requirements

- Each test has exactly one assertion focus
- Test descriptions express expected behavior in plain language
- Boundary cases covered: null, empty, extreme values, error inputs
- Test IDs are globally unique — they will directly map to atomic task IDs
- Every test must be independently runnable

## Step 5: Confirm All RED

Run all tests. Confirm ALL FAIL. This proves tests are valid — they don't accidentally pass without implementation.

## Step 6: Output

- Test files written to project's test directory
- Output test case list: each test's ID + description + layer
- Update `.harness/progress.md` with test alignment results
- Wait for human approval

**Key Principle**: Once human approves these tests, they become the SOLE standard for implementation. The agent's goal is to make them GREEN.

## Next Step
After approval, tell the user to run: `/decompose $ARGUMENTS`
