---
name: decompose
description: "Decompose tests into atomic task DAG with wave-based parallel execution and module stewardship"
argument-hint: "<feature-id e.g. F001>"
---

# Decompose — Atomic Task DAG + Module Stewardship

**Parameter**: $ARGUMENTS — feature ID (e.g. F001)

## Precondition

- Spec must be `approved` (or `reviewed` if spec-review was in the flow)
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

## Step 5: Module Stewardship Analysis

Analyze which code modules each task will touch:

1. **Identify module boundaries**: Based on directory structure, package boundaries, or `.harness/full-design.md`
2. **Map tasks to modules**: For each task, determine which module(s) it affects
3. **Generate AGENT.md files**: For each affected module that doesn't already have one:

Read the template from the harness plugin's `templates/agent-md-template.md` and generate a module-specific AGENT.md:

```markdown
# Module: {module-name}
## Path: {relative/path}
## Last Updated: {ISO timestamp}

## Responsibilities
{derived from code analysis and design doc}

## Boundaries
- **Owns**: {files in this directory}
- **Depends On**: {modules imported by this module}
- **Depended By**: {modules that import this module}
- **Forbidden Dependencies**: {inferred from architecture — e.g. UI modules should not import from CLI}

## Quality Standards
{derived from project config and existing linting rules}

## Interface Contract
- **Exports**: {detected public API}
- **Data Flow**: {input/output shapes}

## Change History
| Date | Change | Impact | Reviewer |
|------|--------|--------|----------|
```

Place AGENT.md in the actual module directory (e.g. `src/auth/AGENT.md`).

4. **Generate module dependency graph**: Write `.harness/module-graph.json`:

```json
{
  "modules": {
    "src/auth": {
      "agent_md": "src/auth/AGENT.md",
      "depends_on": ["src/db", "src/config"],
      "depended_by": ["src/api", "src/middleware"],
      "forbidden": ["src/ui"]
    }
  },
  "last_updated": "{ISO timestamp}"
}
```

5. **Add stewardship metadata to tasks**: Each task entry includes which module(s) it touches.

## Step 6: Write tasks.md

Write to `.harness/tasks.md`:

```markdown
# Tasks — $ARGUMENTS

## DAG Visualization
Wave 1: [T001] [T002] [T005]     ← parallel, no dependencies
Wave 2: [T003] [T006]            ← depends on Wave 1
Wave 3: [T004]                   ← depends on Wave 2
Wave 4: [T007] [T008]            ← E2E verification

## Task List

| ID | Name | Wave | Status | Tests | Retries | BlockedBy | Files | Modules |
|----|------|------|--------|-------|---------|-----------|-------|---------|
| T001 | desc | 1 | pending | T001-V1 | 0 | - | src/... | src/auth |
| T002 | desc | 1 | pending | T002-V1 | 0 | - | src/... | src/db |
| T003 | desc | 2 | pending | T003-V1,V2 | 0 | T001 | src/... | src/auth, src/api |

## Module Stewardship
| Module | AGENT.md | Tasks Affecting | Guardian Active |
|--------|----------|----------------|-----------------|
| src/auth | src/auth/AGENT.md | T001, T003 | Yes |
| src/db | src/db/AGENT.md | T002 | Yes |

## Summary
- Total tasks: N
- Waves: M
- Modules affected: K
- AGENT.md files generated: J
- Estimated parallel speedup: Nx → Mx
```

## Step 7: Update Progress

Append to `.harness/progress.md`:
```
## [timestamp] Task Decomposition — $ARGUMENTS
- Total tasks: N
- Waves: M
- Modules with stewardship: K
- Status: awaiting human approval
```

## Step 8: Request Approval

Present the DAG and module stewardship plan to the user. Ask:
> "任务拆解完成：{N} 个原子任务，分 {M} 个 Wave，涉及 {K} 个模块（已生成 AGENT.md）。任务依赖关系是否正确？有需要拆分或合并的任务吗？"

**Do NOT proceed until approved.**

## Next Step — Auto-Navigate

1. Read the `flow` field from the spec
2. Display progress visualization:

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal  →  ✅ tdd-align  →  ✅ decompose  →  ⬜ sprint  →  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前阶段: decompose (任务拆解 + 责任田) ✅ 已完成
下一阶段: sprint (自动执行)
```

3. Ask: "任务拆解完成，共 {N} 个原子任务分 {M} 个 Wave。下一步是 **Sprint 自动执行**（按 Wave 并行开发，每 Wave 后触发模块守护和评估检查）。是否继续？"
4. If user confirms → execute sprint logic directly
