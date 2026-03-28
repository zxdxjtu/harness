---
name: harness-status
description: "Restore state, show progress visualization, health check, suggest next step"
---

# Harness Status — Context Recovery & Progress Visualization

Recover context, display visual progress, and determine the current development phase.

## Step 1: Check Harness State

```bash
test -d .harness && echo "HARNESS_EXISTS" || echo "NO_HARNESS"
```

If no `.harness/` directory exists → "Harness 未初始化。运行 `/sdd-init` 开始，或 `/proposal` 快速开始一个 Feature。"

## Step 2: Read State Files

1. Read config: `cat .harness/config.json 2>/dev/null`
2. List all specs: `ls .harness/specs/ 2>/dev/null`
3. Read tasks: `cat .harness/tasks.md 2>/dev/null`
4. Read progress (last 50 lines): `tail -50 .harness/progress.md 2>/dev/null`
5. Check sprint loop: `cat .harness/sprint-loop.md 2>/dev/null`
6. Check module graph: `cat .harness/module-graph.json 2>/dev/null`
7. Check evolution data: `wc -l .harness/evolution/memory.jsonl 2>/dev/null`
8. Recent git history: `git log --oneline -20`

## Step 3: Progress Visualization

For each feature, display a visual progress bar based on the spec's `flow` field:

```
📋 SDD 状态概览
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature F001: 用户登录
  复杂度: medium | 评估维度: fullstack
  ✅ proposal → ✅ tdd-align → ✅ decompose → 🔵 sprint → ⬜ evaluate → ⬜ verify
  Sprint: Wave 2/4 | 任务: 5/12 完成 | 迭代: 3

Feature F002: 支付集成
  复杂度: large | 评估维度: fullstack
  ✅ proposal → ⬜ spec-review → ⬜ tdd-align → ...
  等待: spec-review

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If no `flow` field exists in the spec (older format), use the phase detection from Step 4.

## Step 4: Determine Phase (Fallback for specs without flow field)

| State | Current Phase | Next Step |
|-------|--------------|-----------|
| No specs | 初始化 | `/sdd-init` 或 `/proposal` |
| Spec approved, no tests | 测试对齐 | `/tdd-align FXXX` |
| Tests exist, no task decomposition | 任务拆解 | `/decompose FXXX` |
| Tasks decomposed, pending tasks | Sprint | `/sprint FXXX` |
| All tasks done, not evaluated | 评估 | `/evaluate FXXX` |
| Evaluated, score < 7 | 修复循环 | `/eval-fix FXXX` |
| All tasks done, not verified | 验证 | `/verify FXXX` |
| Feature verified | 归档 | `/archive FXXX` |
| Feature archived | 完成 | 开始下一个 Feature |

## Step 5: Module Stewardship Status

If `.harness/module-graph.json` exists, show:

```
📦 模块责任田
| Module | AGENT.md | 最近检查 | 状态 |
|--------|----------|---------|------|
| src/auth | ✅ | Wave 2 | 健康 |
| src/api | ✅ | Wave 2 | 1 HIGH issue |
| src/utils | ❌ | - | 未配置 |
```

## Step 6: Evolution Status

If `.harness/evolution/memory.jsonl` exists:

```
📈 自进化
- 已完成迭代: {N}
- 模板版本: v{N}
- 上次进化: {date}
```

## Step 7: Health Check

- Dependencies installed?
- Build passes?
- Core tests green?
- If anything fails → **fix regression first**

## Step 8: Suggest Next Action

Based on the analysis, give a clear recommendation:
> "当前最优先的操作是 **{action}**（{reason}）。是否继续？"

If user says yes → execute the suggested action directly (Auto-Navigate).
