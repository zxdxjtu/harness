# Harness 用户指南

> 你只需要记住一个命令：`/harness`

---

## 安装

```bash
# 1. 添加 marketplace
/plugin marketplace add zxdxjtu/harness

# 2. 安装插件
/plugin install harness@harness
```

或者直接运行 `/plugin`，在 Discover 标签页中搜索 harness 安装。

验证：输入 `/help`，看到 Harness 说明即成功。

---

## 快速开始

### 进入新仓库的推荐流程

```bash
# 1. 先让 Harness 了解你的项目（推荐，约 3-5 分钟）
/harness init

# 2. （可选）预填已知的坑，省得 agent 反复踩
#    直接编辑 .harness/pitfalls.md，一行一条：
#    - [模块]: 坑的描述

# 3. 开始做功能
/harness 实现用户登录功能，支持邮箱密码和 GitHub OAuth
```

如果你跳过第 1 步直接 `/harness 需求`，它也会自动触发初始化。但**单独跑一次 init 的好处**是：你可以先审查生成的 `config.yaml` 和 `norms.md`，确保 Harness 对你项目的理解是准确的。

### 最简用法（不想管初始化）

```bash
/harness 实现用户登录功能，支持邮箱密码和 GitHub OAuth
```

就这一行。Harness 会自动完成以下所有步骤：

```
首次使用 → 自动了解你的项目（约 3 分钟）
    ↓
和你讨论需求 → 生成 Spec        ← 你确认一下
    ↓
生成三层测试                      ← 你确认一下
    ↓
分解任务、按 Wave 并行执行         （全自动）
    ↓
三阶段验证 → 输出证据包           （全自动）
    ↓
从失败中学习 → 进化               （全自动）
    ↓
归档任务文件、保留踩坑记录         （全自动）
```

**你全程只需参与 2 次**：确认 Spec + 确认测试合约。

---

## 日常用法

| 你想做什么 | 输入 |
|-----------|------|
| 进入新仓库，先初始化 | `/harness init` |
| 做一个新功能 | `/harness 功能描述` |
| 接着上次的工作 | `/harness` |
| 看看当前状态 | `/harness status` |
| 紧急停止 | `/cancel-sprint` |

就这五个。不需要记别的。

---

## 完整流程详解

### 第一步：项目初始化（`/harness init`）

你可以显式运行 `/harness init`，也可以等第一次 `/harness 需求` 时自动触发。

**推荐单独跑 init 的场景**：
- 进入一个你不熟悉的仓库
- 团队有严格的代码规范/CI 要求
- 你想先审查配置再开始做功能

**初始化深度**（可选）：

| 命令 | 深度 | 耗时 | 适用场景 |
|------|------|------|---------|
| `/harness init` | standard | ~5min | 大多数项目（默认） |
| `/harness init --depth quick` | quick | ~2min | 小项目、快速上手 |
| `/harness init --depth deep` | deep | ~10min | 大型/团队项目 |

**自动检测**：
- 语言/框架（TypeScript + Next.js? Python + FastAPI?）
- 测试框架（Jest? Vitest? Pytest?）
- 包管理器（从 lockfile 判断：pnpm-lock.yaml → pnpm）
- 代码风格（从 ESLint/Prettier/editorconfig 推断）
- 团队约束（从 commitlint、CI 配置、CONTRIBUTING.md 自动提取）

**展示给你确认**：

```
项目: my-app
类型: web-app (TypeScript + Next.js)
包管理器: pnpm (依据: pnpm-lock.yaml)
测试框架: Jest (依据: jest.config.js)

自动发现的约束:
  ✓ 必须使用 pnpm
  ✓ Commit 格式: Conventional Commits
  ✓ 覆盖率要求: ≥85%
  ✓ Node 版本: 20.x

以上准确吗？
```

你只需要说"没问题"或者补充修正。之后不会再问。

**生成的文件**：

| 文件 | 作用 |
|------|------|
| `.harness/config.yaml` | 项目配置（技术栈、测试命令、Sprint 参数等） |
| `.harness/norms.md` | 团队规范文档（Agent 执行时遵守） |
| `.harness/invariants.md` | 不变量注册表（初始从仓库分析，后续自动增长） |
| `.harness/pitfalls.md` | 踩坑记录（可手动预填已知的坑） |
| `.harness/skill-context/` | 上下文碎片（API 约定、测试约定等） |

**init 之后的推荐动作**：
1. 审查 `config.yaml`，修正不准确的地方
2. 在 `pitfalls.md` 里写几条你已知的坑（可选，但能省很多 agent 试错时间）
3. `/harness 功能描述` 开始第一个功能

---

### 第二步：需求 → Spec（你参与）

Harness 根据你的功能描述，和你交互式讨论：

- **用户故事**：谁要做什么、为了什么
- **验收标准**：精确到可写自动化测试（"当 X 时，则 Y"）
- **不变式**：必须永远为真的规则
- **评估标准**：这个功能做得好不好怎么量化衡量

评估标准根据功能性质动态确定：

```
# 认证功能
| 维度 | 权重 |
| 功能正确性 | 45% |
| 安全性 | 35% |
| 性能 | 20% |

# 与 CLI 工具完全不同：
| 维度 | 权重 |
| 功能覆盖 | 50% |
| 错误信息质量 | 25% |
| 文档一致性 | 25% |
```

最后生成零决策点清单——预写 Agent 实现时可能需要问的所有问题（测试数据怎么来、Mock 什么、环境变量）。

**你需要做的**：回答问题 → 审查 Spec → 确认。

---

### 第三步：测试合约（你参与）

Harness 自动从 Spec 生成三层测试：

| 层 | 类型 | 验证什么 |
|----|------|---------|
| V1 | 单元测试 | 纯逻辑（密码校验、Token 生成） |
| V2 | 集成测试 | 模块交互（注册 API → 数据库） |
| V3 | E2E 测试 | 用户流程（打开页面 → 注册 → 进入仪表板） |

所有测试此时都是 **RED**（失败状态），证明测试是有效的。

**你需要做的**：审查测试 → 确认。

确认后 Harness 告诉你：
> "测试合约已锁定。接下来全自动，你可以去做别的事了。"

---

### 第四步：执行（全自动）

Harness 自动完成以下工作，你不需要操作：

**任务分解**：把测试映射为原子任务（每个 ≤ 2 小时），分析依赖，分配并行 Wave。

**Sprint 执行**：
```
Wave 1 (并行):
  ├─ Worker A: 密码验证工具
  ├─ Worker B: bcrypt 封装
  └─ Worker C: OAuth URL 生成
       ↓ 合并 + 回归测试
Wave 2:
  └─ Worker D: 注册 API
       ↓ 合并 + 回归测试
Wave 3:
  └─ Worker E: 完整 OAuth 流程
```

每个 Worker 在独立 Git worktree 中工作，互不干扰。

**内置保护**：
- 任务失败 3 次 → 自动跳过，根因写入 `pitfalls.md`
- 连续 3 个 Wave 失败 → 停止并通知你
- 同一文件编辑 6 次没进展 → 停止

**踩坑自动收集**：每个 Wave 完成后，Harness 自动从失败和重试中提取新坑，追加到 `.harness/pitfalls.md`。下一个 Wave 的 Worker 立即生效。

**Stop Hook 自推进**：Sprint 不需要你按任何键，Stop Hook 自动驱动循环直到完成。

---

### 第五步：验证（全自动）

Sprint 完成后自动运行 V1 → V2 → V3 三阶段验证。

输出证据包：

```
.harness/evidence/F001/
├── verdict.md        ← 最终裁决（PASS/FAIL + AC 状态表）
├── v1-result.md      ← 单元测试结果
├── v2-result.md      ← 集成测试结果
└── v3-result.md      ← E2E 测试结果
```

---

### 第六步：进化（全自动）

Sprint 结束时，Harness **自动**分析本次执行的失败模式：

1. 读取 JSONL 事件追踪（`.harness/traces/events.jsonl`）
2. 统计：错误次数、高频编辑文件、doom loop 触发
3. 发现可归类的失败模式 → 记录到 `.harness/evolution-log.md`
4. 同一模式累计 ≥ 3 次 → **自动生成不变量**，注入后续 Sprint

你不需要运行任何命令。下次 Sprint 执行时，Worker Agent 的 prompt 里已经包含了上次学到的约束。

**越用越好**：第 1 个 Feature 可能需要 30 次迭代，第 5 个可能只需要 15 次。

---

## 克隆场景

如果要参照已有产品开发，多两步：

```bash
# 先采集参照产品的基线
/baseline http://reference-product.com

# 然后正常启动
/harness 克隆参照产品的认证系统

# 开发完成后对标评估
/evaluate F001 --ref-url http://reference-product.com --dev-url http://localhost:3000

# 如果分数不够，自动修复循环
/eval-fix F001 --ref-url http://reference-product.com --dev-url http://localhost:3000
```

评估使用你在 Spec 中定义的维度和权重，Evaluator Agent 独立严格打分。

---

## 新会话恢复

开新终端或新会话时：

```bash
/harness
```

Harness 自动检测当前状态，接着干：
- 有活跃 Sprint → 继续执行
- 有 pending 任务 → 启动 Sprint
- 有 draft Spec → 继续讨论
- 什么都没有 → 问你想做什么

---

## 目录结构

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

**文件生命周期**：Feature 完成后，`tasks.md` 和 `progress.md` 自动归档到 `archive/`，`pitfalls.md` 和 `invariants.md` 永久保留。下一个 feature 从干净状态开始，不会被陈旧计划误导。

**建议 git commit 的文件**：`config.yaml`、`norms.md`、`pitfalls.md`、`invariants.md`、`specs/`

---

## Pitfalls（踩坑记录）

`.harness/pitfalls.md` 是项目级的经验沉淀，**跨 feature 永久保留**。

**格式**：一行一条，精简到一句话
```markdown
# Pitfalls

- [Electron IPC]: 避免依赖 Proxy 对象，IPC 序列化会丢失
- [测试]: mock fetch 时必须同时 mock AbortController
- [SQLite]: WAL 模式下并发写入需要 busy_timeout
```

**自动流转**（你不需要操作）：
- `/proposal` → 读取 pitfalls，相关条目注入 Spec
- `/sprint` worker → 每个 Worker 编码前读取 pitfalls
- Wave 完成后 → 从失败和重试中自动提取新坑
- `/verify` → 验证中发现的非显而易见问题追加

**手动操作**（推荐）：
- 开新项目时，在 `pitfalls.md` 里预写几条已知的坑
- Feature 完成后，审阅自动收集的 pitfalls，去重保留有价值的

**与 invariants 的区别**：

| | pitfalls.md | invariants.md |
|---|---|---|
| 门槛 | 即时记录 | 同一模式 3 次失败才提升 |
| 格式 | 一行一条 | 结构化（规则+证据+检测方法） |
| 本质 | 经验直觉 | 验证过的规律 |

pitfalls 可能在多次验证后被 evolve 引擎提升为 invariant。

---

## FAQ

**Q: 进入新仓库应该先做什么？**
推荐先 `/harness init`，让 Harness 了解你的项目。然后可以在 `.harness/pitfalls.md` 里预填已知的坑。之后 `/harness 功能描述` 开始做功能。

**Q: 可以跳过初始化直接用吗？**
可以。`/harness 需求` 会在首次使用时自动触发初始化。但单独跑 init 的好处是你可以先审查配置。

**Q: Sprint 跑到一半我关掉了终端怎么办？**
没关系。重新打开，输入 `/harness`，它会从 `.harness/tasks.md` 恢复状态继续。

**Q: 做完一个 feature 后 tasks.md 去哪了？**
自动归档到 `.harness/archive/{feature-id}-tasks.md`。这样下一个 feature 从干净状态开始，不会被陈旧计划误导。`pitfalls.md` 和 `invariants.md` 永久保留。

**Q: pitfalls.md 会不会越来越长？**
会。建议每做完几个 feature 审阅一次，删掉已经不适用的、或者已经被提升为 invariant 的条目。

**Q: 进化是怎么自动发生的？**
Sprint 结束时 Stop Hook 自动分析 JSONL 追踪日志。同一失败模式出现 3 次后自动提升为不变量，注入到下次 Sprint 的 Worker prompt 中。

**Q: 我想手动看进化状态？**
`/harness evolve` 可以触发一次完整的进化分析。但正常情况不需要。

**Q: 高级用户想精细控制怎么办？**
底层子命令全部可用：`/proposal`、`/tdd-align`、`/decompose`、`/sprint`、`/verify`、`/harness-init`。`/harness` 只是编排它们的入口。
