---
name: help
description: "Explain Harness SDD framework and available commands"
---

# Harness — Spec-Driven Development Framework

Explain the following to the user:

## What is Harness?

Harness 是一个 Spec-Driven Development (SDD) 框架，用于 AI 辅助软件工程。它通过结构化流程确保高质量、可验证的代码交付。

**核心特性**:
- 流程复杂度自适应 — 小需求走快速路径，大需求走完整流程
- Agent 主导流程推进 — 你只需说"继续"，无需记住命令名
- 对抗式评估 — 独立 Evaluator Agent 客观打分，GAN 式修复循环
- 模块责任田 — 每个代码模块有 AGENT.md 守护边界和质量
- 自进化 — 模板、流程、记忆随迭代自动优化

## SDD 流程

```
📌 完整流程 (LARGE):
/sdd-init → /proposal → /spec-review → /tdd-align → /decompose → /sprint → /evaluate → /eval-fix → /verify → /archive → /evolve

📌 标准流程 (MEDIUM):
/proposal → /tdd-align → /decompose → /sprint → /evaluate → /verify → /archive

📌 快速流程 (SMALL):
/proposal → /tdd-align → 直接实现 → /verify

📌 最简流程 (TRIVIAL):
/proposal → 直接实现 → /verify(轻量)
```

**你不需要手动输入这些命令。** Proposal 完成后会自动评估复杂度，推荐合适的流程，并在每步结束后自动引导你进入下一步。

## 可用命令

### 核心流程

| 命令 | 作用 | 人工审批 |
|------|------|---------|
| `/sdd-init` | 初始化项目 Harness（扫描代码库，生成配置） | ✅ 确认配置 |
| `/proposal [描述]` | 需求设计（交互式生成 spec + 置信度评估 + 流程路由） | ✅ 审批 spec |
| `/spec-review <F001>` | 多人评审 spec（逐行评论 + resolution） | ✅ 处理评论 |
| `/tdd-align <F001>` | TDD 测试对齐（三层测试，全部 RED） | ✅ 审批测试 |
| `/decompose <F001>` | 任务拆解（原子任务 DAG + 模块责任田 AGENT.md） | ✅ 审批任务 |
| `/sprint <F001>` | 自动执行（Stop Hook 驱动，Wave 并行，三检查点） | 自动 |
| `/evaluate <F001>` | 对抗式评估（多维度打分，按项目类型配置） | 自动 |
| `/eval-fix <F001>` | GAN 修复循环（修复 → 重评 → 收敛） | 自动 |
| `/verify <F001>` | 三层验证（V1→V2→V3 + 证据包） | 自动 |
| `/archive <F001>` | 归档提交（合并 spec、代码审查、原子 commit） | ✅ 确认推送 |
| `/evolve` | 自进化分析（模板/流程/记忆优化建议） | ✅ 选择应用 |

### 辅助命令

| 命令 | 作用 |
|------|------|
| `/harness-status` | 查看当前状态、进度可视化、建议下一步 |
| `/baseline <url>` | 采集参考产品基线（Clone 场景） |
| `/cancel-sprint` | 停止活跃的 Sprint 循环 |

### 隐藏命令（Sprint 期间自动触发）

| 命令 | 作用 |
|------|------|
| `/steward` | 模块守护者 — 检查代码变更是否违反 AGENT.md 边界 |
| `/entropy-clean` | 熵增清理 — 移除调试残留、强制风格、git 卫生 |

## 核心原则

1. **Spec → Test → Code** — 测试是对齐契约，代码是产物
2. **流程自适应** — 小需求不走大流程，复杂度由 Agent 评估 + 用户确认
3. **原子任务** — 每个任务独立可实现、可测试、可合并
4. **对抗式评估** — 独立 Evaluator 防止自评偏差，维度按项目类型配置
5. **模块责任田** — AGENT.md 定义边界和质量标准，变更时自动守护
6. **自进化** — 模板、流程、记忆随迭代优化
7. **上下文管理** — 文件系统作为无损记忆，主动压缩

## 项目状态目录

```
.harness/
├── config.json          # 项目配置（类型、评估维度、命令）
├── full-spec.md         # 全量规格（持续演进）
├── full-design.md       # 全量设计（持续演进）
├── specs/               # Feature 增量 spec
├── designs/             # Feature 增量 design
├── reviews/             # Spec 评审制品
├── tasks.md             # 任务 DAG
├── progress.md          # 进度日志
├── module-graph.json    # 模块依赖图
├── baseline/            # 参考产品基线（Clone 场景）
├── evidence/            # 验证 + 评估证据
│   └── FXXX/
│       ├── eval-report.md           # 评估报告
│       ├── steward-wave-N.md        # 模块守护报告
│       ├── entropy-cleanup-wave-N.md # 清理报告
│       └── verdict.md               # 最终判定
├── evolution/           # 自进化数据
│   ├── memory.jsonl     # 迭代记忆
│   ├── interventions.jsonl
│   └── guardian-findings.jsonl
└── sprint-loop.md       # Sprint 运行态（运行时）
```

## 快速开始

1. 对新项目说 "我要做一个 XXX 功能"
2. Agent 会引导你完成整个 SDD 流程
3. 每步结束后说"继续"即可进入下一步
4. 随时说 `/harness-status` 查看进度
