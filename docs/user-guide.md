# Harness 用户指南

> 你只需要记住一个命令：`/harness`

---

## 安装

```bash
/install-plugin zxdxjtu/harness
```

验证：输入 `/help`，看到 Harness 说明即成功。

---

## 快速开始

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
```

**你全程只需参与 2 次**：确认 Spec + 确认测试合约。

---

## 日常用法

| 你想做什么 | 输入 |
|-----------|------|
| 做一个新功能 | `/harness 功能描述` |
| 接着上次的工作 | `/harness` |
| 看看当前状态 | `/harness status` |
| 紧急停止 | `/cancel-sprint` |

就这四个。不需要记别的。

---

## 完整流程详解

### 第一步：项目初始化（自动，首次使用）

当你第一次对一个项目运行 `/harness` 时，它会自动花几分钟了解你的项目：

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

生成的配置保存在 `.harness/config.yaml`，后续所有流程自动读取。

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
- 任务失败 3 次 → 自动跳过
- 连续 3 个 Wave 失败 → 停止并通知你
- 同一文件编辑 6 次没进展 → 停止

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
├── config.yaml          # 项目配置（自动生成）
├── norms.md             # 团队规范（自动生成）
├── invariants.md        # 学到的约束（自动增长）
├── specs/               # 功能规格
├── tasks.md             # 任务 DAG
├── progress.md          # 进度日志
├── evidence/            # 验证证据
├── traces/              # JSONL 事件追踪
├── skill-context/       # 上下文注入碎片
└── evolution-log.md     # 进化历史
```

---

## FAQ

**Q: 可以跳过初始化直接用吗？**
可以。`/harness` 会用默认配置运行。但初始化后 Sprint 的准确度更高。

**Q: Sprint 跑到一半我关掉了终端怎么办？**
没关系。重新打开，输入 `/harness`，它会从 `.harness/tasks.md` 恢复状态继续。

**Q: 进化是怎么自动发生的？**
Sprint 结束时 Stop Hook 自动分析 JSONL 追踪日志。同一失败模式出现 3 次后自动提升为不变量，注入到下次 Sprint 的 Worker prompt 中。灵感来自 [EvoMap/evolver](https://github.com/EvoMap/evolver) 的 daemon loop 模式。

**Q: 我想手动看进化状态？**
`/harness evolve` 可以触发一次完整的进化分析。但正常情况不需要。

**Q: 高级用户想精细控制怎么办？**
底层子命令全部可用：`/proposal`、`/tdd-align`、`/decompose`、`/sprint`、`/verify`。`/harness` 只是编排它们的入口。
