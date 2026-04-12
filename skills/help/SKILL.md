---
name: help
description: "Explain Harness plugin and available commands"
---

# Harness — Spec-Driven Development Plugin

Explain the following to the user:

## What is Harness?

Harness 是一个自进化的 AI 辅助开发框架。你只需要告诉它做什么，它会自动走完 Spec → 测试 → 分解 → 执行 → 验证的全流程。

## 你只需要记住一个命令

```
/harness 实现用户登录功能
```

Harness 会自动：
1. 了解你的项目（首次使用时）
2. 和你讨论需求、生成 Spec（需要你确认）
3. 生成测试合约（需要你确认）
4. 分解任务、按 Wave 并行执行（全自动）
5. 三阶段验证并输出证据（全自动）
6. 从失败中学习，下次做得更好（全自动）

整个过程你只需要参与 **2 次**：确认 Spec + 确认测试。

## 用法

| 命令 | 作用 |
|------|------|
| `/harness 功能描述` | 从想法到交付，全流程 |
| `/harness status` | 查看状态，接着干 |
| `/harness init` | 仅初始化（了解项目和团队规范） |
| `/harness evolve` | 手动看一下进化状态 |
| `/harness` | 自动判断该做什么 |
| `/cancel-sprint` | 紧急停止正在跑的 Sprint |

## 核心原则

1. **Spec → Test → Code** — 测试是人和 AI 的对齐合约
2. **原子任务** — 每个任务独立可测、可并行
3. **闭环验证** — 有证据才算完成
4. **自进化** — Sprint 失败自动沉淀为不变量，下次避免
5. **对抗分离** — 写代码的和审代码的不是同一个 Agent
6. **Pitfalls 记忆** — 模型不需要项目变迁历史，只需要"现状"和"哪些坑别踩"

## 自进化机制

**你不需要手动触发进化。** Harness 在以下时机自动学习：

- **Sprint 完成时**：分析 JSONL 追踪日志，提取失败模式
- **任务失败时**：记录结构化失败原因
- **同一模式出现 3 次**：自动提升为不变量，注入后续 Sprint

进化结果保存在 `.harness/invariants.md` 和 `.harness/evolution-log.md`。

## 高级用法

以下命令供了解内部机制的用户使用，普通使用不需要：

| 命令 | 作用 | 何时需要 |
|------|------|---------|
| `/proposal` | 单独编写 Spec | 想精细控制需求阶段 |
| `/tdd-align F001` | 单独生成测试 | 想单独审查测试 |
| `/decompose F001` | 单独分解任务 | 想调整任务粒度 |
| `/sprint F001` | 单独跑 Sprint | 想从中间阶段继续 |
| `/verify F001` | 单独跑验证 | 想重新验证 |
| `/adversarial-review F001` | 对抗式代码审查 | 想在合并前深度审查 |
| `/baseline <url>` | 采集参照产品基线 | 克隆场景 |
| `/evaluate F001` | 对标评估 | 克隆场景 |
| `/eval-fix F001` | GAN 修复循环 | 克隆场景评分不够 |

## 项目状态目录

所有状态保存在 `.harness/`，可 gitignore 或 commit：

```
.harness/
├── config.yaml          # 项目配置（项目级，永久保留）
├── norms.md             # 团队规范（项目级）
├── pitfalls.md          # 踩坑记录（项目级，跨 feature 持久保留）
├── invariants.md        # 学到的约束（项目级，自动增长）
├── specs/               # 功能规格（项目级）
├── evidence/            # 验证证据（项目级）
├── traces/              # JSONL 事件追踪（项目级）
├── skill-context/       # 上下文注入碎片（项目级）
├── evolution-log.md     # 进化历史（项目级）
├── tasks.md             # 任务 DAG（Feature 级，完成后归档）
├── progress.md          # 进度日志（Feature 级，完成后归档）
├── archive/             # 已归档的 tasks/progress
└── sprint-loop.md       # Sprint 运行状态（Session 级，自动清理）
```

**建议 commit**: `pitfalls.md`、`invariants.md`、`specs/`、`config.yaml`、`norms.md`

## Pitfalls 机制

`.harness/pitfalls.md` 是轻量级的项目踩坑记录，与 invariants（重量级不变量）互补：

| | pitfalls.md | invariants.md |
|---|---|---|
| **门槛** | 即时记录，无需验证 | 同一模式 3 次失败才提升 |
| **格式** | 一行一条 | 结构化（规则+证据+检测方法） |
| **维护** | 自动收集 + 手动编辑 | 自进化引擎自动管理 |
| **本质** | 经验直觉 | 验证过的规律 |

**自动流转**: `/proposal` 读取 → worker 读取 → wave 完成后收集 → 失败时提取 → `/verify` 收集

**手动编辑**: 随时可以直接编辑 `.harness/pitfalls.md`，格式：`- [模块]: 一句话描述`

## 文件生命周期

Feature 完成后，harness 自动清理：
- `tasks.md`、`progress.md` → 归档到 `archive/`
- `decisions/`、`attempts/`、`research/` → 删除
- `pitfalls.md`、`invariants.md`、`specs/`、`evidence/` → **永久保留**

这样下一个 feature 从干净状态开始，不会被陈旧 plan 误导。

## 提示

- 描述需求时尽量具体："实现邮箱密码登录，支持 GitHub OAuth"
- 测试审查环节多花 2 分钟看清楚——测试是合约
- Sprint 跑起来后你可以去做别的事
- 新会话输入 `/harness` 即可恢复上下文
- 开新项目时先在 `pitfalls.md` 里写几条已知坑，能省很多 agent 试错时间
- Feature 完成后检查自动收集的 pitfalls，去重保留有价值的
