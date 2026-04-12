---
name: evolve
description: "从 Sprint 历史中提取失败模式，生成不变量，驱动自进化"
argument-hint: "[--source sprint|traces|eval|all]"
---

# Evolve — 自进化引擎

你是 Harness 的自进化引擎。你的任务是：分析 Sprint 执行历史，提取结构性失败模式，将其转化为不变量（Invariant），注入到后续执行中，使 Harness 越用越好。

**核心理念**：反思式进化——从执行历史中提取结构性教训。
- 单次失败 = 偶然 → 记录
- 同一模式 3 次失败 = 结构性 → 提升为不变量
- 不变量 = 违反即失败的硬约束 → 注入技能上下文

---

## Phase 1: 数据采集

### 1.1 分析源选择

根据 `$ARGUMENTS`（默认 all）选择分析源：

| 源 | 文件 | 分析内容 |
|----|------|---------|
| sprint | `.harness/progress.md` + `tasks.md` | 任务失败、重试、doom loop |
| traces | `.harness/traces/events.jsonl` | 结构化事件流：错误事件、同文件高频编辑、测试重复运行 |
| eval | `.harness/evidence/*/eval-report.md` | 评估低分维度、反复修不好的问题 |
| guardian | Guardian SubAgent 输出 | 守护 Agent 发现的模式 |
| git | `git log` + `git diff` | 频繁 revert、同文件反复修改 |

**JSONL Trace 分析**（最有价值的结构化数据源）:
```bash
# 提取所有错误事件
jq 'select(.is_error == true)' .harness/traces/events.jsonl

# 找出高频编辑文件（可能的循环）
jq -r 'select(.event_type == "file_modify") | .input' .harness/traces/events.jsonl | sort | uniq -c | sort -rn

# 测试运行频率和结果
jq 'select(.event_type == "test_run")' .harness/traces/events.jsonl
```

### 1.2 失败模式提取

逐条分析失败记录，提取：

```yaml
pattern:
  id: "FP-{N}"                    # 失败模式 ID
  description: "{描述}"
  occurrences: {count}             # 出现次数
  first_seen: "{datetime}"
  last_seen: "{datetime}"
  features: ["F001", "F002"]       # 涉及的 feature
  tasks: ["T003", "T007"]          # 涉及的 task
  root_cause: "{根因分析}"
  category: "{category}"           # 分类（见下表）
  evidence:
    - file: "{file}"
      line: {line}
      detail: "{具体证据}"
```

### 1.3 失败模式分类

| 类别 | 描述 | 示例 |
|------|------|------|
| stale-context | 基于过时信息做决策 | 用旧的 grep 结果写代码，实际代码已变 |
| cascade-miss | 修改接口未同步更新消费方 | 改了函数签名没改调用方 |
| mock-reality-gap | Mock 与真实行为不一致 | Mock 返回值和实际 API 不同 |
| parallel-collision | 并行任务修改同一文件 | Worktree 合并冲突 |
| multi-source-drift | 同一信息存在多处且不一致 | 类型定义和接口定义不匹配 |
| boundary-violation | 任务超出范围修改无关文件 | 修 bug 时顺便重构了不相关代码 |
| integration-gap | 跨模块集成点无人负责 | 两个 task 都假设对方会处理对接 |
| blind-spot | 评估/测试遗漏关键场景 | 只测了 happy path，忽略了空状态 |

---

## Phase 2: 模式分析

### 2.1 频率统计

```
对每个失败模式:
  if occurrences < 3:
    → 记录为"观察中"（watching）
  if occurrences >= 3:
    → 标记为"候选不变量"（candidate）
  if occurrences >= 5:
    → 标记为"紧急不变量"（urgent）
```

### 2.2 独立性验证

候选不变量必须满足：
1. **跨 feature**: 在 ≥2 个不同 feature 中出现（排除单 feature 的特殊问题）
2. **跨时间**: 在 ≥2 个不同 session 中出现（排除一次性环境问题）
3. **可表述**: 能用一句话描述为明确的约束

### 2.3 根因归因

使用 Agent 工具深度分析每个候选不变量：

```
Agent(
  subagent_type: "debugger",
  prompt: "分析以下失败模式的根本原因:
    模式: {description}
    证据: {evidence_list}
    
    判断:
    1. 这是模型能力限制（需要机械约束）还是上下文不足（需要信息注入）？
    2. 哪个 skill 执行时如果知道这个约束就能避免失败？
    3. 约束应该写成什么形式？（规则 + 检测方法）"
)
```

---

## Phase 3: 不变量生成

### 3.1 不变量格式

对每个确认的候选，生成不变量：

```markdown
### INV-{N}: {名称}

- **规则**: {一句话约束}
- **为什么**: {N} 次独立失败证明这是结构性问题
  - {证据 1}
  - {证据 2}
  - {证据 3}
- **注入目标**: {skill 名称} (如 sprint, decompose)
- **检测方法**: {如何检查是否违反}
- **动作指令**: {Agent 应该做什么来遵守}

**证据链**:
| # | Feature | Task | 失败描述 | 日期 |
|---|---------|------|---------|------|
| 1 | F001 | T003 | {描述} | {date} |
| 2 | F002 | T007 | {描述} | {date} |
| 3 | F003 | T012 | {描述} | {date} |
```

### 3.2 注入策略

不变量需要注入到正确的 skill 上下文中：

| 不变量类别 | 注入目标 skill | 注入方式 |
|-----------|--------------|---------|
| stale-context | sprint | Worker prompt 追加"编辑前先刷新当前状态" |
| cascade-miss | sprint, decompose | 任务描述追加"修改接口后检查所有调用方" |
| mock-reality-gap | tdd-align | Mock 生成指导 |
| parallel-collision | decompose | 依赖分析时检测文件集重叠 |
| multi-source-drift | proposal | Spec 中标注信息唯一来源 |
| boundary-violation | sprint | Worker 禁止清单 |
| integration-gap | decompose | 集成点分配明确负责人 |
| blind-spot | evaluate | 检查点清单补充 |

---

## Phase 4: 持久化与注入

### 4.1 更新不变量注册表

追加到 `.harness/invariants.md`：

```markdown
## 运行时学习的不变量

### INV-{N}: {名称}
- **规则**: {约束}
- **来源**: evolve {date}
- **证据**: {count} 次失败 across {feature_count} features
- **注入**: {target_skill}
- **动作**: {action_directive}
```

### 4.2 更新 Skill 上下文

为目标 skill 生成上下文注入片段，存储在 `.harness/skill-context/`：

```markdown
# .harness/skill-context/sprint-invariants.md

## ⚠️ 已知失败模式（必须遵守）

### INV-{N}: {名称}
动作: {3-5 行具体行动指令}
检测: {如何在执行前/后检查}
```

Sprint skill 在执行时会读取这些文件并注入到 Worker prompt 中。

### 4.3 追踪进化历史

追加到 `.harness/evolution-log.md`：

```markdown
## {date} — Crystal Learn 运行报告

**分析范围**: {source}
**发现模式**: {total_patterns} 个
**新增不变量**: {new_invariants} 个
**观察中模式**: {watching_patterns} 个

### 新增不变量
| ID | 名称 | 来源次数 | 注入目标 |
|----|------|---------|---------|
| INV-{N} | {name} | {count} | {skill} |

### 模式趋势
| 类别 | 上次 | 本次 | 趋势 |
|------|------|------|------|
| cascade-miss | 5 | 3 | ↓ 改善 |
| boundary-violation | 2 | 4 | ↑ 恶化 |
```

---

## Phase 5: 反馈验证

### 5.1 不变量有效性验证

对已注入的不变量，检查后续 Sprint 中该类失败是否减少：

```
if 注入后同类失败 = 0:
  → 标记 "effective"，保留
if 注入后同类失败减少 50%+:
  → 标记 "partially effective"，考虑加强
if 注入后同类失败无变化:
  → 标记 "ineffective"，分析原因:
    - 注入措辞不够明确？→ 改写
    - 注入目标 skill 错误？→ 重定向
    - 模型能力限制？→ 考虑 Hook 机械约束
```

### 5.2 不变量退化检测

如果某个不变量超过 30 天无相关失败：
- 可能已被解决（代码层面）
- 可能不再适用（架构变更）
- 建议：标记为 "archived"，不再注入（节省 token）

---

## 输出

运行结束后，向用户报告：

```
## Crystal Learn 报告

📊 分析了 {N} 个 feature 的执行历史
🔍 发现 {M} 个失败模式
⬆️ 提升 {K} 个为不变量

### 新增不变量:
{list}

### 效果验证:
{已有不变量的有效性统计}

### 建议:
{如果有恶化趋势，给出具体建议}
```

---

## 触发时机

1. **自动**: Sprint 结束时 Stop Hook 自动执行轻量级进化分析
2. **手动**: 用户运行 `/harness evolve` 触发完整深度分析
3. **建议**: `/harness status` 在合适时机建议运行
