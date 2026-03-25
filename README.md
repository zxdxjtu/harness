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
Standard:
/proposal → /tdd-align → /decompose → /sprint → /verify
   Spec       Tests        Tasks       Execute    Verify
  (human)    (human)      (human)      (auto)    (auto)

Clone/Replicate (with adversarial evaluation):
/baseline → /proposal → ... → /sprint → /evaluate → /eval-fix
  Capture     Spec              Execute   Evaluate    Fix Loop
  (auto)     (human)            (auto)    (Evaluator) (GAN loop)
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

### Adversarial Evaluation (Clone scenarios)

Inspired by [GAN-style adversarial design](https://www.anthropic.com/engineering/harness-design-long-running-apps) — separate Generator and Evaluator agents to prevent self-assessment bias.

**`/baseline <url>`** — Evaluator Agent explores the reference product via Playwright MCP, captures screenshots, interaction flows, and visual specs into `.harness/baseline/`.

**`/evaluate <id> --ref-url <url> --dev-url <url>`** — Independent Evaluator compares reference vs development product across 4 dimensions:

| Dimension | Weight |
|-----------|--------|
| Functional Completeness | 40% |
| Interaction Consistency | 25% |
| Visual Fidelity | 20% |
| Technical Quality | 15% |

**`/eval-fix <id>`** — GAN-style fix loop: Generator fixes gaps → Evaluator re-scores → repeat until convergence or stagnation.

## Commands

| Command | Description |
|---------|-------------|
| `/proposal [desc]` | Start new feature (interactive spec generation) |
| `/tdd-align <id>` | Generate three-layer tests from spec |
| `/decompose <id>` | Break into atomic task DAG |
| `/sprint <id>` | Auto-loop execute all tasks |
| `/verify <id>` | Three-stage verification |
| `/harness-status` | Check current state and next step |
| `/baseline <url>` | Capture reference product baseline (Playwright MCP) |
| `/evaluate <id>` | Adversarial comparison: reference vs dev product |
| `/eval-fix <id>` | GAN-style fix-evaluate loop until convergence |
| `/cancel-sprint` | Stop active sprint loop |
| `/help` | Show documentation |

## Project State

Harness stores state in `.harness/` (auto-created):

```
.harness/
├── specs/          # Feature specifications
├── designs/        # Design documents
├── baseline/       # Reference product baseline (clone scenarios)
│   ├── baseline-report.md
│   ├── screenshots/
│   └── features/
├── tasks.md        # Task DAG
├── progress.md     # Progress log
├── evidence/       # Verification + evaluation evidence
│   └── FXXX/
│       ├── eval-report.md
│       ├── eval-screenshots/
│       └── eval-loop-state.md
└── sprint-loop.md  # Sprint state (runtime)
```

Add `.harness/` to `.gitignore` or commit it — your choice.

## Use Cases

- **New projects**: Full pipeline from idea to delivery
- **Cloning products**: Baseline capture → spec → pipeline → adversarial evaluation
- **Incremental features**: Add features to existing codebases

## Core Principles

1. **Spec → Test → Code** — Tests are the alignment contract
2. **Atomic Tasks** — Each independently implementable and testable
3. **Closed-Loop Verification** — Evidence-driven delivery
4. **Context Discipline** — File system as lossless memory

## License

MIT
