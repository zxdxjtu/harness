---
description: "Explain Harness plugin and available commands"
---

# Harness — Spec-Driven Development Plugin

Explain the following to the user:

## What is Harness?

Harness is a Spec-Driven Development (SDD) framework for AI-assisted software engineering. It enforces a structured pipeline that ensures high-quality, verifiable code delivery:

```
/proposal → /tdd-align → /decompose → /sprint → /verify
   Spec       Tests        Tasks       Execute    Verify
  (human)    (human)      (human)      (auto)    (auto)
```

**Core Principles:**
1. **Spec → Test → Code** — Tests are the alignment contract, code is the artifact
2. **Atomic Tasks** — Each task independently implementable, testable, mergeable
3. **Closed-Loop Verification** — Evidence-driven, no "I think it's done"
4. **Context Discipline** — File system as lossless memory, aggressive compression

## Available Commands

### `/proposal [description]`
Start a new feature. Guides you through requirements gathering and produces a complete spec with zero-decision-point checklist. **Requires human approval.**

### `/tdd-align <feature-id>`
Generate three-layer tests (V1 unit, V2 integration, V3 E2E) from the approved spec. All tests start RED. **Requires human approval.**

### `/decompose <feature-id>`
Break tests into atomic tasks (≤2h each), analyze dependencies, assign execution waves. Produces a task DAG. **Requires human approval.**

### `/sprint <feature-id> [--max-iterations N]`
Execute all tasks automatically. Uses a Stop Hook to loop until all tasks complete. Each wave runs in parallel using worktree-isolated agents. Includes:
- Automatic regression testing after each wave
- Background code quality guardians
- Doom loop detection (stops on repeated failures)
- Context compression between waves

### `/verify <feature-id>`
Run V1→V2→V3 verification and produce an evidence package.

### `/harness-status`
Check current state, determine which phase you're in, suggest next step.

### `/cancel-sprint`
Stop an active sprint loop.

## Project State Directory

Harness stores state in `.harness/` in your project root:
```
.harness/
├── specs/          # Feature specifications
├── designs/        # Design documents
├── tasks.md        # Task DAG (Markdown)
├── progress.md     # Progress log
├── evidence/       # Verification evidence packages
└── sprint-loop.md  # Sprint loop state (runtime only)
```

## When to Use

- **New projects**: Full pipeline from spec to delivery
- **Cloning products**: Spec from reference product, then full pipeline
- **Incremental features**: Add specs for new features in existing codebases

## Tips

- Keep specs precise: "When X, then Y" — no vague language
- Review tests carefully — they ARE the contract
- Trust the sprint loop — it will iterate until complete
- Check `/harness-status` when resuming work in a new session
