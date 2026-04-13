# 模块责任田系统 (Module Stewardship)

## 概念

受"责任田"启发，每个代码模块有一个守护定义（AGENT.md），定义模块的职责边界、质量标准和接口契约。当代码变更触及某模块时，守护者自动激活检查。

## AGENT.md 结构

放在用户项目的**实际模块目录中**，随代码提交版本控制：

```markdown
# Module: {module-name}
## Path: {relative/path}

## Responsibilities
- {主要职责，如 "处理用户认证和授权"}

## Boundaries
- **Owns**: {拥有的文件/目录}
- **Depends On**: {允许依赖的模块}
- **Depended By**: {依赖本模块的模块}
- **Forbidden Dependencies**: {绝对不能依赖的模块}

## Quality Standards
- Max file size: {行数上限}
- Max function complexity: {圈复杂度上限}
- Required patterns: {必须遵循的模式}
- Forbidden patterns: {禁止的模式}

## Interface Contract
- **Exports**: {公开 API}
- **Data Flow**: {输入/输出数据形状}

## Change History
| Date | Change | Impact | Reviewer |
|------|--------|--------|----------|
```

## 生命周期

### 生成时机
- `/decompose` 阶段：分析代码库，识别模块边界，为每个模块生成 AGENT.md
- 现有项目：基于目录结构和 import 分析自动推断
- 新项目：基于 design doc 的模块划分

### 激活时机
- Sprint 每 Wave 完成后，`/steward` 自动触发
- 读取 `git diff` 确定本 Wave 变更了哪些文件
- 映射变更文件到对应 AGENT.md

### 检查内容

| 检查项 | 描述 | 违反级别 |
|--------|------|---------|
| Ownership | 变更文件是否在模块 Owns 范围内 | CRITICAL |
| Dependency Direction | 新 import 是否在 Depends On 中，是否引入 Forbidden Dependencies | CRITICAL |
| Interface Contract | 公开 API 是否有 breaking change | CRITICAL |
| Quality Standards | 文件大小、函数复杂度、必须/禁止模式 | HIGH/MEDIUM |

### 结果处理

```
CRITICAL → 阻断：停止 Sprint，必须修复后继续
HIGH     → 警告：当前 Wave 完成后必须修复
MEDIUM   → 记录：加入清理列表
```

## 模块依赖图

`.harness/module-graph.json` 追踪全局依赖关系：

```json
{
  "modules": {
    "src/auth": {
      "agent_md": "src/auth/AGENT.md",
      "depends_on": ["src/db", "src/config"],
      "depended_by": ["src/api", "src/middleware"],
      "forbidden": ["src/ui"]
    }
  },
  "last_updated": "2026-03-28T10:00:00Z"
}
```

由 `/decompose` 生成，`/steward` 每次检查后更新。

## 与自进化的关系

`/evolve` 的 Process 轴会分析 steward 的历史发现：
- 如果某模块持续出现同类违反 → 建议强化 AGENT.md 规则
- 如果某检查维度从未发现问题 → 建议降低检查频率
- 如果模块边界频繁 CRITICAL → 建议重构模块划分
