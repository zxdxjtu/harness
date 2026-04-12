# 业界 Harness 最佳实践研究报告

> 调研时间：2026-04-12
> 来源：Anthropic、OpenAI、LangChain、DSPy、Braintrust 等

---

## 一、Anthropic Harness 设计理念

### 1.1 Generator-Evaluator 对抗架构（GAN-Inspired）

**来源**: [Harness Design for Long-Running Apps](https://www.anthropic.com/engineering/harness-design-long-running-apps)

**核心问题**: AI Agent 评估自己的工作时会产生"自信偏差"——即使质量明显不佳，也会自信地赞美自己的产出。

**解决方案**: 三 Agent 架构

| Agent | 职责 | 上下文 |
|-------|------|--------|
| Planner | 将简短 prompt 转化为完整产品规范（10-16 功能） | 独立 |
| Generator | 按 Sprint 实现功能 | 独立 |
| Evaluator | 使用 Playwright 测试并评分 | 独立 |

**关键设计原则**:
- "调校一个独立的 Evaluator 使其保持怀疑态度，远比让 Generator 自我批评更容易"
- Sprint 合约机制：Generator 和 Evaluator 在编码前协商期望结果
- 每个 harness 组件都编码了一个假设："模型自己做不到什么"

### 1.2 长运行 Agent Harness

**来源**: [Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

**状态恢复三层**:
1. Feature List (JSON) — 200+ 细粒度功能，标记 passing/failing
2. Progress File (txt) — 会话间传递的进度日志
3. Git History — 每个功能完成后 commit

**关键洞察**:
- JSON 比 Markdown 更适合状态文件——模型不太可能不当修改 JSON
- 初始化 Agent 和编码 Agent 使用不同 prompt
- 让 Agent 自行运行 `init.sh` 而不是每次重新构建环境
- 浏览器自动化工具（Playwright/Puppeteer）显著提高验证准确性

### 1.3 Managed Agents 架构

**来源**: [Scaling Managed Agents](https://www.anthropic.com/engineering/managed-agents)

**大脑-手解耦**: Session（事件日志）、Harness（无状态循环）、Sandbox（执行环境）三者分离。

**关键启示**:
- Session 是 append-only 的事件日志，持久存储在 harness 之外
- Harness 是无状态的，可以崩溃恢复
- "元 Harness"——对接口有约束，对实现不设限

---

## 二、OpenAI Harness Engineering

### 2.1 核心理念

**来源**: [Harness Engineering](https://openai.com/index/harness-engineering/) | [InfoQ 分析](https://www.infoq.com/news/2026/02/openai-harness-engineering-codex/)

**范式转移**: 人类工程师从"写代码"转变为"设计环境和表达意图"。

**层次化依赖**: Types → Config → Repo → Service → Runtime → UI，代码只能"向前"依赖。

**核心原则**:
- 给 Codex "一张地图，而不是一本 1000 页的说明书"
- 用机械化约束（linter + 结构测试）而非人工审查
- 文档即代码：交叉链接的设计规范作为唯一真相源

### 2.2 Agent Tracing 与评估

**来源**: [Testing Agent Skills with Evals](https://developers.openai.com/blog/eval-skills)

**JSONL 追踪**: `codex exec --json` 输出结构化事件流

**四维评估**:
| 维度 | 评估内容 |
|------|---------|
| Outcome goals | 任务是否完成 |
| Process goals | 是否正确调用了技能 |
| Style goals | 是否遵循了代码约定 |
| Efficiency goals | 命令数量、token 使用、回归 |

**两阶段评分**:
1. 确定性阶段：文件/命令存在性检查（快速）
2. Rubric 阶段：LLM 评分（0-100，带 overall_pass）

**最佳实践**:
- 先定义成功标准，再写技能
- 包含显式调用和隐式触发测试
- 包含否定控制（不应触发的场景）
- 让真实失败驱动测试覆盖扩展

---

## 三、LangChain/LangSmith 评估体系

### 3.1 三层评估模式

**来源**: [LangChain Evaluation Concepts](https://docs.langchain.com/langsmith/evaluation-concepts)

| 层 | 类型 | 测试什么 |
|----|------|---------|
| 单步 | Unit-like | 单个 LLM 调用的工具选择 |
| 完整轮次 | Trajectory | 整个执行路径的正确性 |
| 多轮 | Conversation | 跨多轮对话的语义一致性 |

### 3.2 评估方法混合

| 方法 | 适用场景 | 占比 |
|------|---------|------|
| Human review | 高风险、细微判断 | 59.8% |
| LLM-as-judge | 广度覆盖 | 常用 |
| Code evaluators | 确定性规则 | 基础 |
| Pairwise comparison | A/B 对比 | 选用 |

### 3.3 可观测性现状（2025-2026）

- 89% 的组织已实施某种形式的 agent 可观测性
- 62% 有详细追踪（可检查单个 agent 步骤和工具调用）
- 52.4% 运行离线测试集评估

---

## 四、DSPy 自进化机制

### 4.1 核心理念

**来源**: [DSPy Framework](https://dspy.ai/) | [GEPA Optimizer](https://dspy.ai/api/optimizers/GEPA/overview/)

**宣言**: "编程语言模型，而非提示语言模型"

### 4.2 GEPA（Genetic-Pareto）优化器

**关键创新**: 反思式 Prompt 进化
1. LLM 反思执行轨迹——什么做对了，什么做错了，什么可以改进
2. 基于反思提出新 prompt，构建进化树
3. 维护 Pareto 前沿（而非单一最优候选）
4. 按覆盖率概率采样下一个变异候选

**结果**: GPT-4.1 Mini 在 AIME 2025 上提升 10%

### 4.3 Hermes Agent Self-Evolution

**来源**: [hermes-agent-self-evolution](https://github.com/NousResearch/hermes-agent-self-evolution)

使用 DSPy + GEPA 实现 agent 技能、prompt 和代码的进化式自改进。

---

## 五、自进化 Agent 研究前沿

### 5.1 分类体系

**来源**: [Comprehensive Survey of Self-Evolving AI Agents](https://arxiv.org/abs/2508.07407)

| 类型 | 机制 | 时间尺度 |
|------|------|---------|
| Intra-task | 反思 + 错误纠正 | 单次任务内 |
| Inter-task | 知识沉淀 + 技能复用 | 跨任务 |

### 5.2 关键机制

1. **Intrinsic Meta-Learning (IML)**: Agent 内在学习如何学习
2. **Editable Memory Systems**: 可修订和巩固的长期记忆
3. **Self-Critique Pipelines**: 内部评估循环
4. **Memento-Skills**: 作为外部记忆的可进化技能集合

### 5.3 AgentEvolver 三机制

**来源**: [AgentEvolver](https://arxiv.org/abs/2511.10395)

1. **Self-questioning**: 好奇驱动的任务生成
2. **Self-navigating**: 探索效率优化
3. **Self-attributing**: 样本效率提升

---

## 六、安全与对抗测试

### 6.1 AgentDojo 基准

**评估指标**:
- Benign Utility: 未攻击下的任务完成率
- Utility Under Attack: 受攻击时的正确完成率
- Attack Success Rate: 攻击者目标执行率

### 6.2 分层安全

1. **Guardrails**: 防止有害/越界行为（在线）
2. **Permissions**: 定义 agent 权限边界
3. **Auditability**: 追踪、问责、透明度

**发现**: 某些模型在拒绝 jailbreak 后，仍在工具使用时违规——仅拒绝有害文本不够。

---

## 七、综合最佳实践清单

### 架构层
- [ ] 分离 Planner/Generator/Evaluator
- [ ] Generator 不自评，Evaluator 独立严格
- [ ] Session 作为 append-only 事件日志
- [ ] Harness 无状态，可崩溃恢复
- [ ] 层次化依赖约束（机械化执行）

### 状态管理
- [ ] JSON 格式存储功能列表（比 Markdown 更安全）
- [ ] Progress file 作为会话间桥梁
- [ ] Git 作为状态恢复后备
- [ ] 初始化 Agent 和编码 Agent 分离

### 评估
- [ ] 四维评估（Outcome + Process + Style + Efficiency）
- [ ] 确定性检查 + LLM 评分两阶段
- [ ] 包含否定控制测试
- [ ] 分数趋势追踪（收敛/停滞/回归检测）

### 自进化
- [ ] 反思式 prompt 进化（GEPA 模式）
- [ ] 失败模式沉淀为不变量（crystal-learn 模式）
- [ ] 可编辑的技能记忆系统
- [ ] 好奇驱动的新任务生成

### 可观测性
- [ ] JSONL 追踪事件流
- [ ] 分布式 spans（嵌套追踪）
- [ ] 在线/离线评估混合
- [ ] 成本和 token 使用追踪

### 安全
- [ ] Schema 级工具隔离（而非指令级）
- [ ] Prompt injection 检测
- [ ] 敏感数据保护
- [ ] Sandbox 隔离执行
