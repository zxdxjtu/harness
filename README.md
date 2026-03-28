# Harness — Spec-Driven Development Framework

A Claude Code plugin for structured **Spec → Test → Implement → Verify** development with adversarial evaluation, module stewardship, and self-evolution.

## Install

```bash
/plugin marketplace add zxdxjtu/harness
```

## Quick Start

```bash
# 说一句你要做什么，Agent 会引导你完成整个流程
/proposal "Add user authentication with JWT"

# 之后每步只需说"继续"，Agent 自动推进
# 或随时查看进度
/harness-status
```

## 核心特性

- **流程自适应** — 小需求走快速路径，大需求走完整流程（自动评估）
- **Agent 自动导航** — 每步结束后说"继续"即可，无需记命令名
- **对抗式评估** — 独立 Evaluator Agent 多维度打分，GAN 式修复循环
- **模块责任田** — AGENT.md 守护每个模块的边界和质量
- **自进化** — 模板/流程/记忆随迭代优化

## Pipeline

```
按复杂度自适应:

TRIVIAL:  /proposal → implement → verify
SMALL:    /proposal → /tdd-align → implement → /verify
MEDIUM:   /proposal → /tdd-align → /decompose → /sprint → /evaluate → /verify → /archive
LARGE:    /proposal → /spec-review → /tdd-align → /decompose → /sprint → /evaluate → /eval-fix → /verify → /archive

Clone 场景额外: /baseline 采集参考产品基线
```

### Phase 1: 需求设计
- `/sdd-init` — 项目初始化（扫描代码库，生成配置和全量规格）
- `/proposal` — 需求设计（置信度评估 + 对齐检查 + 流程路由）
- `/spec-review` — 多人评审（逐行评论 + 自动 resolution）

### Phase 2: 代码生成
- `/tdd-align` — 三层测试对齐（V1 单元 / V2 集成 / V3 E2E，全部 RED）
- `/decompose` — 任务拆解（原子任务 DAG + 模块责任田 AGENT.md）
- `/sprint` — 自动执行（Stop Hook 驱动 + 三检查点: steward/entropy/evaluator）

### Phase 2.5: 对抗式评估
- `/evaluate` — 多维度评估（JSON 配置驱动，按项目类型选择维度）
- `/eval-fix` — GAN 修复循环（收敛/停滞/回退检测）

### Phase 3: 归档
- `/verify` — 三层验证 + 证据包
- `/archive` — 合并规格、代码审查、原子 commit、推送
- `/evolve` — 自进化分析

## 评估维度（按项目类型）

| 类型 | 核心维度 |
|------|---------|
| fullstack | Spec 合规 35% + 架构对齐 25% + 覆盖率 15% + 代码质量 15% + 安全 10% |
| api-service | 合约合规 35% + 性能 20% + 错误处理 20% + 安全 15% + 代码质量 10% |
| library | API 设计 35% + 覆盖率 25% + 兼容性 20% + 代码质量 15% + 文档 5% |
| clone-visual | 功能完整 40% + 交互一致 25% + 视觉还原 20% + 技术质量 15% |

## Commands

| Command | Description |
|---------|-------------|
| `/sdd-init` | 初始化项目 Harness |
| `/proposal [desc]` | 需求设计（spec + 置信度 + 流程路由） |
| `/spec-review <id>` | 多人评审 spec |
| `/tdd-align <id>` | 三层测试对齐 |
| `/decompose <id>` | 任务拆解 + 模块责任田 |
| `/sprint <id>` | 自动执行（三检查点） |
| `/evaluate <id>` | 多维度对抗评估 |
| `/eval-fix <id>` | GAN 修复循环 |
| `/verify <id>` | 三层验证 + 证据包 |
| `/archive <id>` | 归档提交 + 触发自进化 |
| `/evolve` | 自进化分析 |
| `/baseline <url>` | 采集参考产品基线 |
| `/harness-status` | 查看进度 + 建议下一步 |
| `/cancel-sprint` | 停止 Sprint |
| `/help` | 完整文档 |

## Project State

```
.harness/
├── config.json          # 项目配置
├── full-spec.md         # 全量规格
├── full-design.md       # 全量设计
├── specs/               # Feature 增量 spec
├── designs/             # Feature 增量 design
├── reviews/             # Spec 评审制品
├── tasks.md             # 任务 DAG
├── progress.md          # 进度日志
├── module-graph.json    # 模块依赖图
├── baseline/            # 参考产品基线
├── evidence/FXXX/       # 验证 + 评估证据
└── evolution/           # 自进化数据
```

## License

MIT
