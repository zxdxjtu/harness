# Harness Core — 自进化通用内核

> 与业务场景解耦。适用于任何从 0 到 1 的 AI 编码项目。
> 因地制宜：通过 `/harness-init` 学习仓库和团队规范，生成定制化配置。
> 自进化：从 Sprint 失败中自动提取不变量，从工作历史中发现可封装的重复模式。
> 业务相关逻辑通过插件机制加装（见 `harness-plugin-*.md`）。
>
> ### 自进化三要素
> 1. **结晶学习** — 失败 → 模式 → 不变量 → 注入执行层
> 2. **技能发现** — 工作历史 → 重复模式 → 新 Skill
> 3. **上下文路由** — 编辑文件 → 自动注入相关知识碎片

---

## 一、架构总览

```
┌─────────────────────────────────────────────────────────────┐
│                     Harness Core（通用）                      │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Phase 1  │→│ Phase 2  │→│ Phase 3  │→│ Phase 4  │    │
│  │  SPEC    │  │TDD 对齐  │  │IMPLEMENT │  │ VERIFY   │    │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘    │
│       ↑                            ↕              ↓          │
│  ┌──────────┐              ┌──────────────┐ ┌──────────┐    │
│  │ BASELINE │              │  EVALUATOR   │→│ EVAL-FIX │    │
│  │ (Clone)  │              │ (对抗性评估)  │←│ (GAN循环) │    │
│  └──────────┘              └──────────────┘ └──────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  基础设施层                                          │    │
│  │  ┌─────────┐ ┌──────────┐ ┌─────────┐ ┌─────────┐  │    │
│  │  │任务 DAG │ │上下文管理│ │进度恢复 │ │质量门禁│  │    │
│  │  └─────────┘ └──────────┘ └─────────┘ └─────────┘  │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  旁路守护（Sidecar Guardians）                       │    │
│  │  ┌───────────┐ ┌───────────┐ ┌──────────────┐      │    │
│  │  │架构守护   │ │代码质量   │ │回归检测      │      │    │
│  │  │SubAgent   │ │Hook+Lint  │ │PostTest Hook │      │    │
│  │  └───────────┘ └───────────┘ └──────────────┘      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  插件槽位（Pluggable Adapters）                      │    │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐      │    │
│  │  │基线采集插件│ │UI 对比插件 │ │E2E 测试插件│      │    │
│  │  │(业务相关) │ │(业务相关) │ │(业务相关) │      │    │
│  │  └────────────┘ └────────────┘ └────────────┘      │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## 二、Phase 1: SPEC

### 通用流程
1. **需求输入** — 人类描述要做什么
2. **[插件] 基线采集** — 如有参照物，通过插件采集基线
3. **Spec 编写** — Agent 基于输入+基线写 spec
4. **人类审批** — spec 审批标准：Agent 能否在不问问题的情况下执行？

### Spec 模板（通用部分）

```markdown
# Feature: [名称]
## ID: FXXX | 状态: draft | 优先级: PX

## 用户故事
作为 [角色]，我需要 [功能]，以便 [价值]

## 验收标准（必须可执行，不允许 "应该" "大概" "尽量"）
- AC-1: 当 [条件]，则 [结果]
- AC-2: ...

## 不变式（永远为真的规则）
- INV-1: ...

## 技术约束
- 依赖: [外部依赖及版本]

## 零决策点清单
Agent 实现时可能需要问人的信息，全部预写在这里：
- 测试数据: [路径或生成方式]
- Mock 策略: [哪些外部调用需要 mock]
- 环境变量: [KEY=VALUE]
- 已知坑: [此 feature 相关的已知问题及处理方式]

## [插件扩展区]
<!-- 由业务插件在此注入额外字段 -->
```

## 三、Phase 2: TDD 对齐

### 核心机制
测试是人和 Agent 对齐的**唯一可执行契约**。Spec 有歧义，测试没有。

### 流程
```
/tdd-align [feature-id]
  → Agent 为每个 AC 写三层测试（V1/V2/V3），全部 RED
  → 人类审批测试：覆盖完整吗？断言准确吗？边界全了吗？
  → 不对齐 → 修改测试 → 重新审批
  → 对齐 → spec 状态改为 tests-aligned
```

### 测试分层（通用）

| 层 | 类型 | 验证什么 | 运行时机 |
|----|------|---------|---------|
| V1 | 单元 | 纯函数、数据变换、校验 | 每次 commit |
| V2 | 集成 | 模块交互、状态、API | 每个 wave |
| V3 | E2E | 用户完整流程 | feature 完成 |

### 测试命名约定
```
[FXXX] Feature 名 > [AC-N] 验收标准 > [TXXX-VN] 具体测试
```
**关键**: 测试 ID（TXXX）直接映射为原子任务 ID。

## 四、Phase 3: IMPLEMENT

### 4.1 任务分解 `/decompose`

```
输入: tests-aligned 的测试清单
输出: 原子任务 DAG（写入 tasks.md）

规则:
- 每个任务 ≤ 2h Agent 工作量
- 每个任务对应 1~3 个测试 ID（RED → GREEN）
- 依赖通过 blockedBy 显式声明
- 按依赖分配 wave（同 wave 可并行）
```

### 4.2 任务注册表结构

任务存储在 `.harness/tasks.md`（Markdown 表格格式），人类可读且可编辑：

```markdown
# Tasks — F001

| ID | Name | Wave | Status | Tests | Retries | BlockedBy | Files |
|----|------|------|--------|-------|---------|-----------|-------|
| T001 | 实现用户模型 | 1 | pending | T001-V1 | 0 | - | src/models/user.ts |
| T002 | 实现认证逻辑 | 2 | pending | T002-V1,T002-V2 | 0 | T001 | src/auth/login.ts |
```

> **注意**: 之前版本的文档描述了 JSON 格式的任务注册表。
> 实际实现使用 Markdown 表格，因为：(1) 人类可读可编辑；(2) Git diff 友好；(3) 所有 Skill 已基于此格式实现。

### 4.3 Wave 执行模型

```
Wave 1: [T001] [T005] [T010]     ← 并行，无依赖
         ↓       ↓
Wave 2: [T002] [T006]            ← 依赖 Wave 1
              ↓
Wave 3: [T003]                   ← 依赖 Wave 2
         ↓
Wave 4: [T004] [T007]            ← UI 层
              ↓
Wave 5: [T008] [T009]            ← E2E 验证
```

### 4.4 Agent Team 执行 `/sprint`

```
Team Lead（你的 session）
  │
  ├─ 创建 Team + TaskList（带依赖）
  ├─ 按 wave 分配任务给 Worker Agent
  ├─ 监控进度、处理阻塞
  └─ wave 完成 → merge → 回归检查 → 下一 wave

Worker Agent（每任务一个，独立 worktree）
  │
  ├─ 读任务 + 读 spec + 读测试
  ├─ 实现代码，让测试 RED → GREEN
  ├─ 运行测试 + 全量 V1 回归
  ├─ 通过 → commit + 报告完成
  └─ 失败 3 次 → 停止 + 上报
```

### 4.5 Worker Agent Prompt 模板（通用）

```
你是原子任务 Worker，负责 {task_id}: {task_name}

步骤:
1. TaskGet 读取任务详情
2. 读 spec 文件 + 测试文件中 {test_ids} 对应的测试
3. 检查 blockedBy 任务的产物存在
4. 实现代码，让 {test_ids} GREEN
5. 运行: npm test -- --grep "{task_id}"
6. GREEN → 全量 V1 回归 → commit → TaskUpdate completed
7. 失败 3 次 → TaskUpdate 备注原因 → 通知 Team Lead

禁止: 修改测试 | 修改其他任务的文件 | 跳过测试 | 死循环硬调
```

### 4.6 自验证循环（每层自动触发）

```
任务完成 → 跑该任务测试 → 跑全量 V1（确认无回归）
Wave完成 → 跑该 wave 所有测试 → V2 集成测试
Feature完成 → V1 + V2 + V3 + [插件] 业务验证 → 证据包
```

## 五、Phase 4: VERIFY

### 通用验证
| 阶段 | 验证 | 标准 | 证据 |
|------|------|------|------|
| V1 | 全部单元测试 | 100% GREEN + ≥80% 覆盖率 | test-report.json |
| V2 | 全部集成测试 | 100% GREEN | integration-report.json |
| V3 | E2E 用户流程 | 功能正确 | verdict.json |

### [插件] 业务验证
由插件注入额外验证步骤（如截图对比、性能基准）。

### 证据包结构
```
harness/evidence/FXXX/
├── verdict.json          # 最终判定
├── v1-report.json        # 单元测试详情
├── v2-report.json        # 集成测试详情
├── v3-report.json        # E2E 测试详情
├── [插件产物]             # 如 ui-diff.md, screenshots/
└── test-log.txt          # 完整日志
```

## 六、旁路守护系统（Sidecar Guardians）

### 设计理念
守护逻辑与主实现流程解耦，通过 Hook + SubAgent 旁路执行。
主流程不感知守护细节，守护只在违规时介入。

### 6.1 Hook 守护（轻量，同步）

| Hook | 类型 | 守护什么 | 触发 |
|------|------|---------|------|
| `pre-bash.sh` | PreToolUse | 危险命令拦截 | 每次 Bash |
| `pre-write.sh` | PreToolUse | 文件大小门禁 | 每次 Write |
| `post-write.sh` | PostToolUse | 自动格式化 | 每次 Write/Edit |
| `post-test.sh` | PostToolUse | Doom loop 检测 | 每次测试命令 |
| `on-stop.sh` | Stop | 反合理化检查 | Agent 停止时 |

### 6.2 SubAgent 守护（重量，异步/定期）

在 sprint 执行过程中，Team Lead 定期触发守护 SubAgent：

**架构守护 Agent**（每个 wave 完成后触发）:
```
Agent(
  subagent_type: "architect-reviewer",
  prompt: "审查最近 wave 的代码变更，检查:
    1. 模块依赖方向（只能向下）
    2. 无循环依赖
    3. 文件职责单一
    4. 接口一致性
    报告违规项，标注严重级别。",
  run_in_background: true
)
```

**代码质量守护 Agent**（每个 wave 完成后触发）:
```
Agent(
  subagent_type: "code-reviewer",
  prompt: "审查最近 wave 的代码变更，检查:
    1. 不可变模式遵守
    2. 错误处理完整性
    3. 命名一致性
    4. 无硬编码值
    报告问题，区分 CRITICAL / HIGH / MEDIUM。",
  run_in_background: true
)
```

**安全守护 Agent**（涉及认证/数据/网络时触发）:
```
Agent(
  subagent_type: "security-auditor",
  prompt: "审查变更中的安全问题:
    1. 无硬编码密钥
    2. 输入校验完整
    3. 无注入风险
    4. 敏感数据处理正确",
  run_in_background: true
)
```

### 6.3 守护结果处理

```
CRITICAL → 阻断：停止当前 wave，修复后继续
HIGH     → 警告：当前 wave 完成后必须修复
MEDIUM   → 记录：加入 known-issues.md，排期修复
LOW      → 忽略：不阻断流程
```

## 七、上下文生命周期管理

详见 `docs/context-management.md`，核心规则：

1. **60% 红线** — 上下文使用率保持 < 60%
2. **任务完成即压缩** — 每完成一个原子任务，主动 `/compact`
3. **文件系统无损存储** — 决策、方案、中间产物写文件，不留在上下文
4. **SubAgent 隔离** — 探索/调研/审查用 SubAgent，不污染主上下文
5. **恢复靠文件** — tasks.md + progress.txt + git log

## 八、Evaluator 对抗机制

### 设计理念
将生产和评估分离为独立的 Agent 角色。
核心洞察：让同一个 Agent 自评其工作会产生"自信偏差"——Agent 倾向于赞美自己的产出。
分离 Evaluator 后，可以独立调校其严格程度，比让 Generator 自我批评更有效。

### 架构
```
┌──────────────┐     ┌──────────────┐
│  Generator   │     │  Evaluator   │
│  (Dev Agent) │     │ (独立 Agent) │
│              │     │              │
│ 读 spec+测试 │     │ 用 Playwright │
│ 实现代码     │────→│ 对比两个产品  │
│ 跑测试       │     │ 截图+评分    │
│              │←────│ 反馈差异报告  │
│ 修复差异     │     │              │
└──────────────┘     └──────────────┘
     ↑  ↓  循环直到收敛
```

### 适用场景
- **Clone/Replicate** — 参照产品复刻（主要场景）
- **UI 重构** — 重构后与重构前对比
- **竞品对标** — 对标竞品的特定功能

### 流程

#### Phase 0: 基线采集 `/baseline`
```
Evaluator Agent + Playwright MCP
  → 遍历参照产品所有页面
  → 截图每个状态
  → 记录交互流程
  → 生成 .harness/baseline/
```

#### Phase 3.5: Wave 间评估检查点
```
Sprint 每个 Wave 完成后:
  → Evaluator Agent（后台）快速检查已完成功能
  → 评分 < 5 的功能标记为 CRITICAL
  → CRITICAL 反馈注入下一 Wave 的 Worker prompt
  → 这是 "Sprint Contract" 机制
```

#### Phase 5: 对抗性评估 `/evaluate`
```
Evaluator Agent + Playwright MCP
  → 在参照产品上执行操作并截图
  → 在开发产品上执行相同操作并截图
  → 4 维度评分（功能/交互/视觉/技术）
  → 生成 eval-report.md + 对比截图
```

#### Phase 6: 对抗修复循环 `/eval-fix`
```
循环:
  1. Generator 读 eval-report，修复差异
  2. Evaluator 重新评估，生成新 eval-report
  3. 收敛检查:
     - 总分 ≥ 7 → 完成
     - 连续 2 轮无提升 → 停滞，建议人工介入
     - 分数下降 → 回滚，停止
```

### 评分维度
| 维度 | 权重 | 评估方法 |
|------|------|---------|
| 功能完整度 | 40% | baseline 功能是否全部存在且可用 |
| 交互一致性 | 25% | 相同操作 → 相同结果 |
| 视觉还原度 | 20% | 截图对比布局、样式 |
| 技术质量 | 15% | 性能、错误处理、边界 |

### 评分校准（Few-Shot）
Evaluator 使用严格校准标准：
- 10: 与参照产品无法区分
- 8-9: 仅有微小外观差异
- 6-7: 功能可用但视觉/行为有偏差
- 4-5: 核心功能可用但有显著缺口
- 2-3: 功能存在但几乎不可用
- 1: 功能缺失或完全损坏

## 九、插件机制（原八）

### 插件结构

```
docs/harness-plugin-{name}.md     # 插件文档
.claude/commands/{name}-*.md      # 插件注入的 Slash Commands
.claude/hooks/{name}-*.sh         # 插件注入的 Hooks
```

### 插件接口（插件需实现的能力）

| 接口 | Phase | 作用 |
|------|-------|------|
| `baseline-capture` | 1 | 采集参照物基线 |
| `spec-extend` | 1 | 在 spec 模板中注入业务字段 |
| `verify-extend` | 4 | 注入业务级验证步骤 |
| `evidence-extend` | 4 | 在证据包中追加业务产物 |

### 当前已安装插件
- `desktop` — 桌面端应用开发（见 `harness-plugin-desktop.md`）

## 十、长时间运行策略（Marathon Laws）

### Law 1: 工作不耗尽
- 任务粒度 ≤ 2h，wave 自动推进
- tasks.md 是唯一真相

### Law 2: 零决策点
- Spec 零决策点清单：预写所有外部依赖
- 测试是明确的完成标准
- 已知问题写在 docs/known-issues.md

### Law 3: Context 不退化
- 原子任务在独立 SubAgent/worktree 中执行
- Team Lead 只需知道测试是否通过
- 进度文件 10 秒恢复全景

## 十一、进度日志格式

```
=== SESSION {ISO-datetime} ===
PHASE: 3-IMPLEMENT
FEATURE: F001 - 用户登录
WAVE: 2/5
---
[HH:MM] TASK T002 started (worker-T002)
[HH:MM] TASK T002 done ✓ commit=abc1234
[HH:MM] TASK T006 done ✓ commit=def5678
[HH:MM] WAVE 2 complete. V1 regression: 24/24 ✓
[HH:MM] Guardian: arch-review PASS, code-review 1 MEDIUM (naming)
[HH:MM] COMPACT: 保留 F001 spec + tasks + wave 状态
[HH:MM] WAVE 3 started
---
STATUS: wave 3 in progress
NEXT: T003 实现中
=== END SESSION ===
```
