---
name: skill-discovery
description: "分析工作历史，识别重复模式，提议生成新 Skill"
argument-hint: "[--source commits|sessions|all]"
---

# Skill Discovery — 让 Harness 长出新能力

你是 Harness 的技能发现者。你的任务是：分析用户的工作历史（commit log、session 记录、issue 记录），识别重复出现的工作模式，提议将其封装为新的 Harness Skill。

**核心理念**: Harness 不应只有预装技能。如果用户反复做同一类工作，那就应该有一个 Skill 来标准化它。

---

## Phase 1: 工作历史采集

### 1.1 数据源

| 源 | 方法 | 分析目标 |
|----|------|---------|
| Git commits | `git log --oneline -200` | 反复出现的 commit 类型 |
| Git diff patterns | `git log --stat -50` | 反复修改的文件组合 |
| Progress logs | `.harness/progress.md` | 反复出现的任务模式 |
| Spec history | `.harness/specs/*.md` | 反复出现的 feature 类型 |
| Evolution log | `.harness/evolution-log.md` | 反复出现的失败模式 |

### 1.2 模式提取

扫描数据源，提取以下信号：

**工作流模式**:
- "每次发布前都手动跑一遍 lint + test + build" → `/pre-release` skill
- "每次新增 API 都要同步更新 OpenAPI spec" → `/api-sync` skill
- "每次修 bug 都是先复现、再写测试、再修复" → `/bug-fix` skill

**文件组合模式**:
- "每次改 schema 都同时改 migration + model + types" → `/schema-change` skill
- "每次改 component 都同时改 story + test" → `/component-update` skill

**重复任务模式**:
- "每周都要更新依赖并检查兼容性" → `/dep-update` skill
- "每次 PR 都需要 changelog entry" → `/changelog` skill

---

## Phase 2: 模式评估

### 2.1 候选评分

对每个识别的模式，评估：

| 维度 | 权重 | 标准 |
|------|------|------|
| 频率 | 40% | 出现 ≥3 次才考虑 |
| 复杂度 | 30% | 步骤 ≥3 步才值得封装 |
| 标准化程度 | 20% | 每次执行是否相似 |
| 自动化潜力 | 10% | 能否大部分自动化 |

### 2.2 过滤规则

排除：
- 已被现有 skill 覆盖的模式
- 每次执行差异很大的模式（不可标准化）
- 频率 <3 的偶发模式
- 纯人工判断的模式（无法自动化）

---

## Phase 3: Skill 提案生成

对每个通过评估的模式，生成提案：

```markdown
## 提案: /{skill-name}

**识别模式**: {描述反复出现的工作模式}
**出现次数**: {count} 次 (最近 {period})
**平均耗时**: {估计的手动耗时}
**自动化率**: {预估能自动化的比例}

### 流程设计
1. {步骤 1}
2. {步骤 2}
3. {步骤 3}
...

### 输入/输出
- 输入: {用户需要提供什么}
- 输出: {skill 会生成什么}

### 示例调用
```
/{skill-name} {example_args}
```

### 是否需要人工审批
{是/否，及原因}

### 预估价值
- 节省时间: {minutes} 分钟/次
- 降低风险: {描述}
```

---

## Phase 4: 用户确认与生成

### 4.1 展示提案

向用户展示所有提案，直接询问用户：

```
发现了 {N} 个可以封装为 Skill 的重复模式:

1. /{skill-1}: {描述} (出现 {count} 次)
2. /{skill-2}: {描述} (出现 {count} 次)
3. /{skill-3}: {描述} (出现 {count} 次)

你想生成哪些？（可多选）
```

### 4.2 生成 Skill 文件

对用户选择的提案，生成 `skills/{name}/SKILL.md`：

```markdown
---
name: {skill-name}
description: "{description}"
argument-hint: "{args}"
---

# {Skill Name}

{生成的 skill 内容，遵循 harness skill 标准格式}
```

### 4.3 记录发现

追加到 `.harness/evolution-log.md`：

```markdown
## {date} — Skill Discovery

**分析范围**: {source}
**识别模式**: {total} 个
**通过评估**: {passed} 个
**用户采纳**: {adopted} 个

### 新增 Skills
| 名称 | 来源模式 | 出现次数 |
|------|---------|---------|
| /{name} | {pattern} | {count} |
```

---

## 触发时机

1. **手动**: 用户运行 `/skill-discovery`
2. **自动建议**: 每完成 5 个 feature 后，harness-status 建议运行
3. **新项目里程碑**: 项目达到一定规模后（50+ commits）
