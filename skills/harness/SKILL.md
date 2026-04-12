---
name: harness
description: "Harness 主入口 — 从想法到交付的一站式流程"
argument-hint: "[功能描述 | status | init | evolve]"
---

# Harness — 一站式入口

你是 Harness 的主控制器。用户只需要记住一个命令：`/harness`。

**用法**：
- `/harness 实现用户登录功能` → 自动走完 init → spec → test → task → sprint → verify 全流程
- `/harness status` → 查看当前状态、下一步建议
- `/harness init` → 仅运行初始化
- `/harness evolve` → 手动触发一次进化分析
- `/harness` （无参数）→ 自动判断该做什么

---

## 路由逻辑

读取 `$ARGUMENTS`，按以下优先级路由：

### 情况 1：`$ARGUMENTS` 是 `status`

执行 `/harness-status` 的完整逻辑。

### 情况 2：`$ARGUMENTS` 是 `init`

执行 `/harness-init` 的完整逻辑（默认 standard 深度）。

### 情况 3：`$ARGUMENTS` 是 `evolve`

执行一次手动进化分析（见下方"进化逻辑"章节）。

### 情况 4：`$ARGUMENTS` 是功能描述（非关键字）

这是主流程。进入**全流程编排**。

### 情况 5：无参数

自动判断当前状态，继续未完成的工作：

1. 检查 `.harness/` 是否存在
   - 不存在 → 提示用户：`/harness 你想做什么功能？` 或 `/harness init`
2. 检查 `.harness/sprint-loop.md` 是否存在
   - 存在 → 有活跃 Sprint，执行 Sprint 继续逻辑
3. 检查 `.harness/tasks.md` 中是否有 pending 任务
   - 有 → 继续 Sprint
4. 检查最新的 spec 状态
   - draft → 继续 proposal 对话
   - approved 但无测试 → 进入 tdd-align
   - tests-aligned 但无任务 → 进入 decompose
   - 任务全完成但未验证 → 进入 verify
5. 都没有 → 展示状态摘要，问用户想做什么

---

## 全流程编排

当用户给出功能描述时，自动按顺序推进以下阶段。每个阶段完成后**自动进入下一个**，无需用户输入命令。

### Gate 0: 初始化检查

```
if .harness/config.yaml 不存在:
  告诉用户："第一次使用，我先花几分钟了解你的项目。"
  执行 /harness-init 的完整逻辑（standard 深度）
  完成后继续
```

### Gate 1: Spec（需要人类参与）

执行 `/proposal` 的完整逻辑，用 `$ARGUMENTS` 作为功能描述输入。

**人类审批点**：Spec 必须用户确认后才能继续。

审批通过后，告诉用户：
> "Spec 已锁定。接下来我会生成测试、分解任务、自动执行。过程中有一个地方需要你确认测试合约，其余全自动。"

### Gate 2: 测试合约（需要人类参与）

自动执行 `/tdd-align {feature-id}`。

**人类审批点**：测试合约必须用户确认。

审批通过后，告诉用户：
> "测试合约已锁定。接下来全自动——我会分解任务、按 Wave 并行执行、跑完验证。你可以去做别的事情了。"

### Gate 3: 任务分解（自动）

自动执行 `/decompose {feature-id}`。

**不再需要用户审批**——直接用 Agent 自检：
- 检查每个任务是否 ≤ 2h
- 检查依赖关系是否有环
- 检查 Wave 分配是否合理
- 如果有问题自动修正，无需中断用户

展示一句话摘要：
> "已分解为 {N} 个任务，{M} 个 Wave。开始执行..."

### Gate 4: Sprint（自动）

自动执行 `/sprint {feature-id}`。

Stop Hook 驱动循环直到完成。用户无需操作。

### Gate 5: 验证（自动）

Sprint 完成后自动执行 `/verify {feature-id}`。

### Gate 6: 完成报告

```markdown
## ✓ 功能交付完成

**Feature**: {name} ({feature-id})
**任务**: {completed}/{total} 完成
**测试**: V1 ✓ | V2 ✓ | V3 ✓
**覆盖率**: {X}%

**证据**: .harness/evidence/{feature-id}/verdict.md

**Pitfalls**: 本次新增 {N} 条踩坑记录（总计 {M} 条）
**已归档**: tasks.md → archive/{feature-id}-tasks.md

**接下来？**
- 输入 `/harness 下一个功能描述` 开始新功能
- 输入 `/harness status` 查看全景
- 检查 `.harness/pitfalls.md`，去重保留有价值的经验
```

---

## 人类参与点总结

整个流程中用户只需要参与 **2 次**：

| 阶段 | 用户动作 | 为什么需要 |
|------|---------|-----------|
| Gate 1 Spec | 回答问题 + 审批 | 需求只有人类知道 |
| Gate 2 Tests | 审查 + 审批 | 测试是合约，需要人类确认 |

其余全自动：init、decompose、sprint、verify。

---

## 进化逻辑

自进化**不依赖用户手动触发**。它嵌入在正常工作流的关键节点中自动执行：

### 自动触发点

| 触发时机 | 做什么 | 怎么做 |
|---------|--------|--------|
| Sprint 每个 Wave 结束 | 检查本 Wave 的失败模式 | Sprint skill 内置逻辑 |
| Sprint 整体结束 | 分析本次 Sprint 全量失败 | Stop Hook 在 sprint 完成时触发 |
| Verify 完成后 | 对比预期 vs 实际，提取 gap | Verify skill 末尾内置 |
| 任务失败被跳过时 | 记录失败详情到结构化日志 | Sprint Worker 内置 |

### Sprint 结束后的自动进化（嵌入 Stop Hook）

当 Sprint 完成（所有任务 done 或 max iterations）时，Stop Hook 在释放会话前执行：

```
1. 读取 .harness/traces/events.jsonl
2. 统计: 失败次数、高频编辑文件、doom loop 触发
3. 读取 .harness/tasks.md 中 failed 的任务
4. 如果发现可归类的失败模式:
   - 追加到 .harness/evolution-log.md
   - 如果某模式累计 ≥ 3 次:
     → 自动生成不变量，追加到 .harness/invariants.md
     → 生成注入片段到 .harness/skill-context/sprint-invariants.md
     → 下次 Sprint 自动生效
5. 输出一行摘要到 progress.md:
   "Evolution: 发现 N 个模式，新增 M 个不变量"
```

### `/harness evolve`（可选手动触发）

用户不需要记住这个命令。但如果想主动看一下进化状态，可以运行：

```bash
/harness evolve
```

它会执行完整的进化分析（失败模式提取 + 重复工作识别）并输出报告。

---

## 与子命令的关系

`/harness` 是用户唯一需要记住的命令。但底层子命令仍然存在，高级用户可以直接调用：

| 用户场景 | 推荐方式 | 高级方式 |
|---------|---------|---------|
| 做一个新功能 | `/harness 功能描述` | `/proposal` → `/tdd-align` → `/decompose` → `/sprint` → `/verify` |
| 查看状态 | `/harness status` | `/harness-status` |
| 初始化项目 | `/harness init` | `/harness-init` |
| 看进化状态 | `/harness evolve` | `/evolve` + `/skill-discovery`（高级） |
| 克隆产品 | `/harness 克隆 xxx` | `/baseline` → `/proposal` → ... → `/evaluate` → `/eval-fix` |
| 停止 Sprint | `/cancel-sprint` | `/cancel-sprint` |
