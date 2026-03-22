# Harness — Spec-Driven Development Plugin for Claude Code

A Claude Code marketplace plugin that enforces a structured **Spec → Test → Implement → Verify** pipeline for high-quality AI-assisted software engineering.

## Install

```bash
/plugin marketplace add zxdxjtu/harness
```

## Quick Start

```bash
/proposal "Add user authentication with JWT"   # Generate spec + design
/tdd-align F001                                  # Generate tests (all RED)
/decompose F001                                  # Break into atomic tasks
/sprint F001                                     # Auto-execute until done
```

## Pipeline

```
/proposal → /tdd-align → /decompose → /sprint → /verify
   Spec       Tests        Tasks       Execute    Verify
  (human)    (human)      (human)      (auto)    (auto)
```

### Phase 1: Spec (`/proposal`)
Interactive dialogue to produce a complete, unambiguous spec with zero-decision-point checklist. Human approves before proceeding.

### Phase 2: Test Alignment (`/tdd-align`)
Generate three-layer tests from spec:
- **V1**: Unit tests (logic validation)
- **V2**: Integration tests (module interaction)
- **V3**: E2E tests (user perspective)

All tests start RED. Human approves the test contract.

### Phase 3: Decompose (`/decompose`)
Break tests into atomic tasks (≤2h each), analyze dependencies, assign parallel execution waves. Human approves the task DAG.

### Phase 4: Sprint (`/sprint`)
**Automatic loop execution** — powered by a Stop Hook that keeps Claude running until all tasks complete:

- Parallel execution via worktree-isolated agents
- Regression testing after each wave
- Background code quality guardians
- Doom loop detection (stops on repeated failures)
- Context compression between waves

### Phase 5: Verify (`/verify`)
V1 → V2 → V3 staged verification with evidence package.

## Commands

| Command | Description |
|---------|-------------|
| `/proposal [desc]` | Start new feature (interactive spec generation) |
| `/tdd-align <id>` | Generate three-layer tests from spec |
| `/decompose <id>` | Break into atomic task DAG |
| `/sprint <id>` | Auto-loop execute all tasks |
| `/verify <id>` | Three-stage verification |
| `/harness-status` | Check current state and next step |
| `/cancel-sprint` | Stop active sprint loop |
| `/help` | Show documentation |

## Project State

Harness stores state in `.harness/` (auto-created):

```
.harness/
├── specs/          # Feature specifications
├── designs/        # Design documents
├── tasks.md        # Task DAG
├── progress.md     # Progress log
├── evidence/       # Verification evidence
└── sprint-loop.md  # Sprint state (runtime)
```

Add `.harness/` to `.gitignore` or commit it — your choice.

## Use Cases

- **New projects**: Full pipeline from idea to delivery
- **Cloning products**: Spec from reference, then pipeline
- **Incremental features**: Add features to existing codebases

## Core Principles

1. **Spec → Test → Code** — Tests are the alignment contract
2. **Atomic Tasks** — Each independently implementable and testable
3. **Closed-Loop Verification** — Evidence-driven delivery
4. **Context Discipline** — File system as lossless memory

## License

MIT
