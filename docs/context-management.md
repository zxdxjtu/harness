# 上下文生命周期管理

> 上下文是最重要的资源。超过 60% 就开始退化。
> 核心策略: 用文件系统做无损压缩，上下文只留"正在做的事"。

---

## 一、红线规则

| 阈值 | 动作 |
|------|------|
| < 40% | 正常工作 |
| 40-60% | 注意，完成当前任务后主动压缩 |
| > 60% | 立即压缩，不等任务完成 |
| > 80% | 系统自动压缩（可能丢失细节） |

**目标: 永远不触发系统自动压缩，主动管理。**

## 二、无损压缩策略

### 2.1 文件系统作为外部记忆

| 信息类型 | 存储位置 | 上下文中保留 |
|---------|---------|-------------|
| 决策记录 | harness/decisions/{date}.md | 只保留最新决策 |
| 方案尝试 | harness/attempts/{task-id}/ | 只保留当前方案 |
| 探索结果 | harness/research/{topic}.md | 只保留结论 |
| 完成任务详情 | harness/harness-progress.txt | 只保留摘要 |
| 测试结果 | harness/evidence/ | 只保留 pass/fail |

### 2.2 Compact 策略

每次 `/compact` 使用定向压缩 prompt：

```
/compact 保留: 当前 feature {ID} 的 spec 要点、当前 wave 的任务状态、
未完成任务的 blockedBy 关系。丢弃: 已完成任务的实现细节、
历史探索路径、已关闭的讨论。
```

### 2.3 任务完成即压缩

```
原子任务完成后:
  1. 结果写入 harness-tasks.json（testsPassed, commit）
  2. 关键决策写入 harness/decisions/
  3. /compact — 释放该任务的实现上下文
  4. 只保留: 任务ID、状态、commit hash
```

### 2.4 Wave 切换时深度压缩

```
Wave N → Wave N+1 切换时:
  1. 更新 harness-progress.txt
  2. 旁路守护 Agent 报告写入文件
  3. /compact — 只保留:
     - 当前 feature spec 概要
     - 任务 DAG 全景（ID + 状态）
     - 下一 wave 的任务详情
     - 未解决的问题清单
```

## 三、SubAgent 隔离策略

### 3.1 何时用 SubAgent（保护主上下文）

| 任务 | 用 SubAgent | 原因 |
|------|------------|------|
| 技术调研/方案探索 | ✓ | 探索产生大量无用上下文 |
| 代码审查 | ✓ | 审查结果只需摘要 |
| 安全审计 | ✓ | 审计细节不需要留在主上下文 |
| 文档查询 (Context7) | ✓ | API 文档很长 |
| 原子任务实现 | ✓ (Worker) | 每个任务独立 context |
| Bug 调试 | ✓ | 调试过程冗长 |

### 3.2 何时在主上下文做

| 任务 | 在主上下文 | 原因 |
|------|-----------|------|
| 任务分解 /decompose | ✓ | 需要全景视图 |
| TDD 对齐 /tdd-align | ✓ | 需要和人类交互 |
| 进度监控 /sprint | ✓ | Team Lead 职责 |
| 关键决策 | ✓ | 需要人类参与 |

### 3.3 SubAgent 结果处理

```
SubAgent 返回后:
  1. 提取关键结论（1-3 句话）
  2. 详细结果写入文件
  3. 只在主上下文保留摘要

示例:
  SubAgent(探索 Tauri vs Electron) → 返回 5000 token 分析
  主上下文只保留: "结论: 选 Electron，原因: 生态+AI训练数据覆盖"
  完整分析存入: harness/research/tech-stack-comparison.md
```

## 四、文件读写优化

### 4.1 读文件策略

```
首次读: Read 完整文件 → 提取需要的部分 → 记录位置
再次读: Read(offset, limit) → 只读需要的行
大文件: 用 Grep 定位 → Read 定位区域
```

### 4.2 已读文件索引

在长 session 中，维护已读文件的心理索引：

```
不需要重复读的信息 → 写入 harness/session-notes.md
需要反复引用的 → 摘要保留在上下文
完整内容 → 在文件系统中，需要时重新读取对应行
```

## 五、方案回退机制

### 5.1 方案记录

每次尝试新方案前，记录：

```markdown
# harness/attempts/T001-approach-1.md
## 方案: 使用 React Hook Form
## 状态: failed
## 原因: 与 Electron IPC 序列化冲突
## 耗时: 3 次迭代
## 教训: Electron 环境下避免依赖 Proxy 对象

# harness/attempts/T001-approach-2.md
## 方案: 使用 Formik
## 状态: succeeded
## commit: abc1234
```

### 5.2 回退流程

```
方案失败 3 次:
  1. 记录失败原因到 harness/attempts/
  2. git stash 当前改动
  3. 从上一个稳定 commit 重新开始
  4. 选择新方案（排除已失败的）
  5. 如果连续 2 个方案失败 → 上报人类决策
```

## 六、监控指标

在 harness-progress.txt 中记录：

```
CONTEXT: ~45% (compact 后)
WAVE: 2/5
TASKS: 8/20 done, 2 in_progress, 10 pending
REGRESSIONS: 0
GUARDIAN: arch ✓, code 1M, security ✓
```
