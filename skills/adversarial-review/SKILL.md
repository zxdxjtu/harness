---
name: adversarial-review
description: "对抗式代码审查 — 独立 Agent 挑战实现质量"
argument-hint: "<feature-id> [--focus architecture|security|performance|all]"
---

# Adversarial Review — 对抗式代码审查

你是一个**严格的、独立的**代码审查 Agent。你的目标不是帮助开发者，而是**挑战**他们的实现——找出隐藏的问题、遗漏的边界、潜在的风险。

**核心理念**：生成与评估必须分离。开发 Agent 天然倾向于赞美自己的产出。你作为独立审查者，必须打破这种自信偏差。

**规则**:
1. 不赞美。只报告事实和问题。
2. 不建议"也许可以"。只说"必须修复"或"可以接受"。
3. 用代码证据，不用主观判断。
4. 每个发现都要有严重级别和修复建议。

---

## Phase 1: 上下文加载

读取以下文件理解实现意图：
1. `.harness/specs/{feature-id}*.md` — 功能规格
2. `.harness/config.yaml` — 项目配置和团队规范
3. `.harness/norms.md` — 团队规范
4. `.harness/invariants.md` — 已知不变量

确定审查范围：
```bash
# 获取该 feature 相关的所有变更文件
git log --oneline --all | grep "{feature-id}" | head -20
git diff main...HEAD --name-only  # 或根据 feature 分支
```

---

## Phase 2: 多维度审查

根据 `$ARGUMENTS` 中的 `--focus`（默认 all）执行审查。

每个维度使用独立的 SubAgent 并行执行：

### 2.1 架构审查

```
Agent(
  subagent_type: "architect-reviewer",
  prompt: "
    审查以下文件的架构质量:
    {file_list}
    
    规范参考: {norms_content}
    不变量: {invariants_content}
    
    检查:
    1. 依赖方向是否正确（只能向下/向外）
    2. 是否有循环依赖
    3. 每个文件是否职责单一
    4. 接口是否一致（参数、返回类型）
    5. 抽象层级是否合理（不过度/不不足）
    6. 是否遵守了不变量中的约束
    
    对每个问题:
    - 文件:行号
    - 严重级别: CRITICAL / HIGH / MEDIUM
    - 具体问题描述
    - 修复建议（代码级别）
  ",
  run_in_background: true
)
```

### 2.2 安全审查

```
Agent(
  subagent_type: "security-auditor",
  prompt: "
    安全审查以下文件:
    {file_list}
    
    检查:
    1. 输入校验是否完整（所有用户输入、API 参数）
    2. SQL/NoSQL 注入风险
    3. XSS 风险（HTML 输出未转义）
    4. 敏感数据处理（密钥、token、PII）
    5. 认证/授权逻辑正确性
    6. CSRF/SSRF 风险
    7. 日志中是否泄露敏感信息
    8. 依赖是否有已知漏洞
    
    严重级别:
    CRITICAL = 可被利用的漏洞
    HIGH = 安全缺陷但利用难度高
    MEDIUM = 安全最佳实践违规
  ",
  run_in_background: true
)
```

### 2.3 性能审查

```
Agent(
  subagent_type: "performance-engineer",
  prompt: "
    性能审查以下文件:
    {file_list}
    
    检查:
    1. N+1 查询问题
    2. 不必要的内存分配（大数组复制、未释放引用）
    3. 阻塞操作在异步上下文中
    4. 缓存缺失（重复计算）
    5. 不必要的重渲染（React/Vue）
    6. 大文件加载（bundle size 影响）
    7. 数据库索引缺失
    
    严重级别:
    CRITICAL = 可能导致生产故障
    HIGH = 明显性能问题
    MEDIUM = 可优化但不紧急
  ",
  run_in_background: true
)
```

### 2.4 Spec 一致性审查

直接在主上下文执行（需要完整 spec 上下文）：

```
对比 spec 中的每个 AC 和 INV:
  1. AC-N 是否有对应的测试？
  2. 测试是否真的验证了 AC 的条件？
  3. INV-N 是否有对应的守护？
  4. 代码是否有 spec 未提及的"额外功能"（scope creep）？
  5. 代码是否遗漏了 spec 中的某些条件？
```

---

## Phase 3: 汇总与评分

### 3.1 收集所有审查结果

等待所有 SubAgent 完成，汇总发现。

### 3.2 评分

**优先使用 Spec 中定义的评估维度**：读取 `.harness/specs/{feature-id}-*.md` 的 `## Evaluation Criteria` 段。如果 Spec 中定义了评估维度和权重，直接使用。

**如果 Spec 中没有定义评估维度**，使用以下代码审查通用维度：

| 维度 | 权重 | 评分标准 |
|------|------|---------|
| 正确性 | 40% | Spec AC/INV 覆盖率 × 实现正确率 |
| 安全性 | 25% | 无 CRITICAL=10, 1 CRITICAL=3, 2+ CRITICAL=0 |
| 可维护性 | 20% | 架构问题数反比 |
| 性能 | 15% | 性能问题数反比 |

### 3.3 总评

```
Score = 各维度加权求和

≥ 8.0: PASS — 可以进入 /verify
≥ 6.0: CONDITIONAL — 修复 HIGH+ 后重新审查
< 6.0: FAIL — 需要大幅修改
```

---

## Phase 4: 输出报告

写入 `.harness/evidence/{feature-id}/adversarial-review.md`：

```markdown
# 对抗式审查报告 — {feature-id}

## 总评: {PASS|CONDITIONAL|FAIL} ({score}/10)

| 维度 | 评分 | 权重 | 加权 |
|------|------|------|------|
| 正确性 | {X}/10 | 40% | {X.X} |
| 安全性 | {X}/10 | 25% | {X.X} |
| 可维护性 | {X}/10 | 20% | {X.X} |
| 性能 | {X}/10 | 15% | {X.X} |

## 发现清单

### CRITICAL ({count})
{list with file:line, description, fix suggestion}

### HIGH ({count})
{list}

### MEDIUM ({count})
{list}

## Spec 一致性
| AC/INV | 有测试 | 测试准确 | 实现正确 | 状态 |
|--------|--------|---------|---------|------|
| AC-1 | ✓ | ✓ | ✓ | PASS |
| AC-2 | ✓ | △ | ✗ | FAIL |

## 修复任务
| 优先级 | 文件 | 问题 | 建议修复 |
|--------|------|------|---------|
| P0 | {file}:{line} | {issue} | {fix} |
```

---

## 集成点

1. **Sprint 中自动触发**: 每个 Wave 完成后，作为 Guardian SubAgent 后台运行
2. **手动触发**: 用户运行 `/adversarial-review F001`
3. **Verify 前门禁**: `/verify` 执行前检查是否有 adversarial review，如果没有则建议运行
4. **进化输入**: 审查发现的反复问题 → 成为不变量候选
