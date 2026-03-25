---
description: "Start a new feature proposal — guided spec + design generation"
argument-hint: "[feature description]"
---

# Proposal — Spec-Driven Development Entry Point

You are guiding the user through a structured proposal process. The goal is to produce a complete, unambiguous spec that an AI agent can execute without asking questions.

## Step 1: Initialize

Create `.harness/` directory if it doesn't exist:
```bash
mkdir -p .harness/specs .harness/designs .harness/evidence
```

Determine the next feature ID by checking existing specs:
```bash
ls .harness/specs/ 2>/dev/null | grep -oP 'F\d+' | sort -t'F' -k2 -n | tail -1
```
If none exist, start with F001.

## Step 2: Understand the Scenario

Ask the user (via AskUserQuestion) which scenario applies:

1. **New Project** — Building from scratch
2. **Clone/Replicate** — Replicating an existing product
3. **Incremental** — Adding features to an existing codebase

This determines what additional context is needed.

## Step 2.5: Baseline Capture (Clone scenario only)

If the user selected **Clone/Replicate**:

1. Ask for the reference product URL (local or remote)
2. Suggest running `/baseline <url>` to capture a comprehensive baseline first
3. If baseline already exists (`.harness/baseline/baseline-report.md`), read it and use it to inform the spec
4. If user wants to skip baseline → warn that clone fidelity may suffer without Evaluator-generated baseline

After baseline is captured, the spec should reference:
- `.harness/baseline/baseline-report.md` for product overview
- `.harness/baseline/features/*.md` for individual feature details
- `.harness/baseline/screenshots/` for visual reference

## Step 3: Gather Requirements

Based on the user's input and `$ARGUMENTS`, conduct an interactive dialogue to clarify:

1. **User Story**: As [role], I need [capability], so that [value]
2. **Acceptance Criteria**: Concrete, testable conditions (use "When X, then Y" format)
3. **Invariants**: Rules that must always hold true
4. **Technical Constraints**: Dependencies, platform requirements, performance targets
5. **For Clone scenario**: Reference baseline report, UI fidelity requirements, Evaluator comparison criteria
6. **For Incremental scenario**: Which existing modules are affected

Keep asking until ALL acceptance criteria are precise enough to write automated tests for. No vague words like "should", "probably", "try to".

## Step 4: Zero-Decision-Point Checklist

Pre-answer every question the implementing agent might ask:
- Test data: how to generate or where to find
- Mock strategy: which external calls to mock
- Environment variables needed
- Known pitfalls and their mitigations
- File naming conventions to follow
- Which existing code patterns to match
- **For Clone scenario**:
  - Reference product URL: [url]
  - Development product URL: [url, e.g. http://localhost:3000]
  - Baseline path: `.harness/baseline/`
  - Evaluator comparison criteria: [which dimensions matter most]
  - Acceptable fidelity threshold: [score out of 10, default 7]

## Step 5: Generate Spec

Write the spec to `.harness/specs/FXXX-[name].md`:

```markdown
# Feature: [Name]
## ID: FXXX | Status: draft | Priority: [P0/P1/P2]

## User Story
As [role], I need [capability], so that [value]

## Acceptance Criteria
- AC-1: When [condition], then [result]
- AC-2: When [condition], then [result]

## Invariants
- INV-1: [rule that must always hold]

## Technical Constraints
- Platform: [requirements]
- Dependencies: [list with versions]
- Performance: [targets]

## Zero-Decision-Point Checklist
- Test data: [path or generation method]
- Mock strategy: [what to mock]
- Environment: [KEY=VALUE]
- Known pitfalls: [issue → mitigation]
- Code patterns: [which existing patterns to follow]

## Design Notes
[Architecture decisions, data flow, component structure]
```

## Step 6: Generate Design (optional)

If the feature is non-trivial, also generate `.harness/designs/FXXX-[name].md` with:
- Component/module breakdown
- Data flow diagram (ASCII)
- API contracts
- State management approach

## Step 7: Request Approval

Present the spec to the user. Explicitly ask:
> "This spec defines N acceptance criteria and M invariants. Can an agent implement this without asking you any questions? If not, what's missing?"

**Do NOT proceed until the user approves.** Update spec status to `approved` after approval.

## Next Step

After approval:
- **Clone scenario**: Tell the user the recommended flow is:
  `/tdd-align FXXX` → `/decompose` → `/sprint` → `/evaluate FXXX` → `/eval-fix FXXX` (if needed)
- **Other scenarios**: Tell the user to run: `/tdd-align FXXX`
