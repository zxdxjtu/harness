---
name: sdd-init
description: "Initialize SDD harness for a project — scan codebase, generate config, full-spec, full-design"
argument-hint: "[--type fullstack|api|library|clone|mobile]"
---

# SDD Init — Project Initialization

You are initializing the SDD (Spec-Driven Development) harness for this project. This is a one-time setup that scans the codebase and creates the foundational documents.

**Parameter**: $ARGUMENTS — optional project type override

## Step 1: Check Existing State

```bash
ls .harness/config.json 2>/dev/null
```

If `.harness/config.json` already exists:
- Read it and show current configuration to user
- Ask if they want to re-initialize (this will overwrite existing config)
- If no → exit with "Harness already initialized. Run `/proposal` to start a new feature."

## Step 2: Create Directory Structure

```bash
mkdir -p .harness/specs .harness/designs .harness/evidence .harness/reviews .harness/evolution
```

## Step 3: Scan Codebase & Detect Project Type

Analyze the repository to auto-detect:

1. **Project type**: Check for indicators:
   - `package.json` with both client/server dirs → `fullstack`
   - `package.json` with express/fastify/koa → `api`
   - `package.json` with `main`/`exports` fields, no server → `library`
   - `.harness/baseline/` exists → `clone`
   - `pubspec.yaml` or React Native config → `mobile`
   - `setup.py` / `pyproject.toml` with FastAPI/Django → `api`
   - `go.mod` with net/http → `api`

2. **Tech stack**: List languages, frameworks, databases detected

3. **Test framework**: Check for jest, vitest, mocha, pytest, go test, etc.

4. **Build/lint commands**: Read package.json scripts, Makefile, etc.

If `$ARGUMENTS` includes `--type`, use that override instead of auto-detection.

Present findings to user via AskUserQuestion:
- "检测到项目类型: {type}，技术栈: {stack}。是否正确？"
- Let user confirm or override

## Step 4: Generate config.json

Write `.harness/config.json`:

```json
{
  "project_type": "{detected or user-specified}",
  "tech_stack": ["{list of detected technologies}"],
  "eval_dimensions": "{project_type mapping: fullstack→fullstack, api→api-service, library→library, clone→clone-visual}",
  "test_framework": "{detected}",
  "test_command": "{detected, e.g. npm test}",
  "build_command": "{detected, e.g. npm run build}",
  "lint_command": "{detected, e.g. npm run lint}",
  "dev_url": "{if applicable, e.g. http://localhost:3000}",
  "stewardship_enabled": true,
  "entropy_cleanup_enabled": true,
  "evolution": {
    "spec_template_version": 1,
    "iteration_count": 0
  }
}
```

## Step 5: Generate Full Spec (Baseline)

Scan the codebase and generate `.harness/full-spec.md` — a high-level specification of the EXISTING project:

```markdown
# Project Specification — {project name}
## Generated: {ISO timestamp}
## Status: baseline

## Overview
{1-2 paragraph description of what this project does, based on README, code structure, and key files}

## Module Inventory
| Module | Path | Responsibility | Key Dependencies |
|--------|------|---------------|-----------------|
{one row per top-level module/directory}

## Existing Features
{List of existing features/capabilities detected from code, routes, components, etc.}

## Architecture Summary
{High-level architecture: monolith/microservice, frontend framework, backend framework, DB, etc.}

## Conventions Detected
- Naming: {camelCase/snake_case/etc.}
- File organization: {by feature/by type}
- Error handling pattern: {detected pattern}
- State management: {if applicable}
```

## Step 6: Generate Full Design (Baseline)

Generate `.harness/full-design.md` — a high-level design document of the existing architecture:

```markdown
# Project Design — {project name}
## Generated: {ISO timestamp}
## Status: baseline

## Architecture Diagram
{ASCII diagram of major components and their relationships}

## Module Dependency Graph
{ASCII diagram showing module dependencies}

## Data Model Summary
{Key entities and their relationships, if detectable}

## API Surface
{List of routes/endpoints/public APIs, if applicable}
```

## Step 7: Present Summary

Show the user:
1. Config summary (project type, tech stack, eval dimensions)
2. Module count and key modules found
3. Existing feature count

Then:

```
📋 SDD Harness 初始化完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ 项目配置: .harness/config.json
✅ 全量规格: .harness/full-spec.md
✅ 全量设计: .harness/full-design.md
✅ 评估维度: {eval_dimensions} ({N} 个维度)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask: "初始化完成。是否要开始一个新 Feature？（我会引导你进入需求设计阶段）"

If user confirms → execute `/proposal` logic directly (Auto-Navigate).
