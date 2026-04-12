# 三项目竞品分析报告

> 调研时间：2026-04-12
> 对比对象：get-shit-done (GSD) | wow-harness (WH) | harness (本项目)

---

## 一、核心定位对比

| 维度 | GSD | wow-harness | harness (本项目) |
|------|-----|-------------|-----------------|
| **定位** | 多运行时 Meta-Prompting 框架 | 项目级治理层（单项目深耕） | Claude Code 通用 SDD 插件 |
| **规模** | 69 commands, 24 agents, 68 workflows | 16 skills, 18 hooks, 15 checks | 11 skills, 1 hook |
| **运行时** | 14+ AI IDE | 仅 Claude Code | 仅 Claude Code |
| **哲学** | Context Rot 解决 → 每 Agent 新鲜上下文 | 机械约束 > 指令遵从 | Spec → Test → Task → Sprint → Verify |
| **成熟度** | v1.35.0 (生产级) | 设计完善但紧耦合到 Towow 项目 | v0.1.0 (MVP) |

## 二、关键能力矩阵

| 能力 | GSD | WH | harness | 业界最佳实践 |
|------|-----|----|---------|-----------:|
| **Spec-Driven 管道** | ✓ 研究→规划→执行→验证 | ✓ 9-Gate 状态机 | ✓ 5-Phase 管道 | ✓ |
| **对抗式评估** | △ AI 系统评估框架 | △ Guardian Issues | ✓ GAN-Inspired | ✓ Anthropic GAN |
| **自进化** | △ 用户分析管线 | ✓ crystal-learn 不变量注入 | ✓ crystal-learn + skill-discovery | ✓ DSPy GEPA |
| **团队规范适配** | ✓ config.json + profiles | ✓ 3 层安装 + 模板槽位 | ✓ harness-init + config.yaml | ✓ harness-init |
| **上下文管理** | ✓ 60%红线+SubAgent隔离 | ✓ 上下文路由+碎片注入 | ✓ 60%红线 | ✓ |
| **追踪/可观测性** | △ 进度文件 | ✓ JSONL 指标 | △ progress 日志 | ✓ JSONL spans |
| **Hook 系统** | ✓ 9 hooks | ✓ 18 hooks, 7 生命周期 | △ 1 Stop hook | ✓ 全生命周期 |
| **并行执行** | ✓ Wave 级并行 | ✓ 多轨并行(write_set) | ✓ Wave 级并行 | ✓ |
| **安全防护** | ✓ Prompt injection 检测 | ✓ Schema 级工具隔离 | ✗ 无 | ✓ 多层 |
| **Doom Loop** | ✓ 3 规则检测 | ✓ 机械化门禁 | ✓ 3 规则检测 | ✓ |
| **用户 Onboarding** | ✓ install.js + 文档 | ✓ 3 tier 安装器 | ✓ harness-init | ✓ |
| **CI/CD 集成** | △ 预留 | △ CI checks | ✗ 无 | ✓ |

### 图例
- ✓ 完全实现  
- △ 部分实现  
- ✗ 未实现  

## 三、GSD 的独特价值

### 3.1 Context Rot 解决方案
每个 Agent 获得 200K 新鲜上下文，而非在单一长对话中累积。这从根本上解决了质量随上下文增长而衰退的问题。

### 3.2 Goal-Backward 验证
不检查任务清单是否完成，而是反向验证目标是否达成。避免了"所有任务完成但产品不工作"的问题。

### 3.3 多运行时抽象
单套代码支持 14+ AI IDE（工具名映射、Hook 事件映射、路径规范化）。

### 3.4 波级执行 + 自适应上下文
自动分析任务依赖分组为 Wave，1M 令牌模型下自适应调整上下文预算。

### 3.5 关键借鉴点
- **config.json 配置系统**: model_profile、model_overrides、branching_strategy
- **用户分析管线**: 扫描会话记录 → 生成 USER-PROFILE.md
- **Nyquist 审计**: 验证覆盖度缺口

## 四、wow-harness 的独特价值

### 4.1 机械约束 > 指令遵从
核心洞察：CLAUDE.md 指令遵从率 ~10-20%，而机械约束（Hook、Schema 级工具隔离）100% 执行。

### 4.2 上下文工程（Context Engineering）
ADR-030 的双机制：
- **主动投射**: 编辑文件 → 自动注入相关上下文碎片
- **被动反馈**: 违规 → 注入必读清单

### 4.3 不变量注入（crystal-learn）
失败模式 → 结构化不变量(INV-0~7) → 代码级注入到技能上下文。
这是**真正的自进化机制**——从失败中学习并转化为执行层约束。

### 4.4 Schema 级工具隔离
Review Agent 的 tools manifest 不包含 Edit/Write → 物理上无法修改文件（100%执行率，而非指令 70%）。

### 4.5 三层安装器（drop-in / adapt / mine）
从"直接用" → "读 README 适配" → "深度学习项目风格"。

### 4.6 关键借鉴点
- **crystal-learn 自进化**: 失败 → 模式 → 不变量 → 注入
- **上下文路由**: 文件路径 → 相关知识碎片自动注入
- **Schema 级隔离**: 工具权限在 frontmatter 中声明
- **MANIFEST.yaml**: 机器可读的组件注册表
- **ADR 系统**: 架构决策记录，可追溯设计演进
- **skill-discovery**: 从工作记录识别重复模式 → 提议新 skill

## 五、harness (本项目) 的优势

### 5.1 Five-Phase 管道简洁有力
Spec → TDD → Decompose → Sprint → Verify，清晰无歧义。

### 5.2 Zero-Decision-Point 清单
预写所有 Agent 可能需要问人的信息，实现 Agent 完全自治。

### 5.3 GAN-Inspired 评估最完整
baseline → evaluate → eval-fix 循环，4 维度加权评分，停滞/回归检测。

### 5.4 Stop Hook 自推进
用最少代码（120 行）实现 sprint 永恒循环，无需外部调度。

### 5.5 作为 Plugin 的清洁边界
与业务逻辑完全解耦，插件槽位预留。

## 六、GAP 分析 — harness 需要补齐的能力

### P0（必须有）

| Gap | 来源 | 实现思路 |
|-----|------|---------|
| **harness-init** | 新 | 用户主导的初始化流程：学习仓库→了解团队规范→生成定制 harness |
| **自进化机制** | WH crystal-learn + DSPy | Sprint 失败模式沉淀 → 不变量注入 → prompt 进化 |
| **配置系统** | GSD config.json | `.harness/config.yaml` 支持项目类型、团队规范、评估维度 |
| **追踪/可观测性** | OpenAI JSONL | JSONL 事件流 + 会话摘要 + 分数趋势 |

### P1（应该有）

| Gap | 来源 | 实现思路 |
|-----|------|---------|
| **更多 Hook** | WH 18 hooks | PreToolUse/PostToolUse/SessionStart hooks |
| **上下文路由** | WH ADR-030 | 文件路径 → 相关知识自动注入 |
| **安全防护** | GSD prompt-guard | Prompt injection 检测 + 敏感数据保护 |
| **对抗式评估 Agent** | Anthropic + WH | 独立 Agent 对代码/设计持续挑战 |
| **Skill Discovery** | WH skill-discovery | 从工作记录识别重复模式 → 生成新 skill |

### P2（可以有）

| Gap | 来源 | 实现思路 |
|-----|------|---------|
| **多运行时** | GSD | 工具名映射层（远期） |
| **CI/CD** | 业界 | GitHub Actions 集成（远期） |
| **Dashboard** | 业界 | HTML 可视化进度（远期） |
