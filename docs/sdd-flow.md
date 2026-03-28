# SDD 完整流程文档

## 概述

SDD (Spec-Driven Development) 是一种以规格驱动的开发方法。核心思想：**Spec → Test → Code**。测试是人和 Agent 对齐的唯一可执行契约。

## 流程复杂度自适应

不是所有需求都需要完整流程。Proposal 阶段会自动评估复杂度，推荐合适的流程路径：

```
TRIVIAL (改配置、修 typo)     → proposal → implement → verify(轻量)
SMALL   (1-3 AC, 单模块)     → proposal → tdd-align → implement → verify
MEDIUM  (3-8 AC, 跨模块)     → proposal → tdd-align → decompose → sprint → evaluate → verify → archive
LARGE   (8+ AC, 架构变更)    → proposal → spec-review → tdd-align → decompose → sprint → evaluate → eval-fix → verify → archive
```

## Agent 自动导航

用户无需记住命令名称。每个阶段完成后，Agent 会：
1. 显示进度条（✅ 已完成 / 🔵 当前 / ⬜ 未开始）
2. 用自然语言总结当前阶段产出
3. 询问"是否继续下一步"
4. 用户说"继续"即可，也可以"跳过"或"暂停"

## 阶段详解

### Phase 1: 需求设计

#### /sdd-init — 项目初始化
- 扫描代码库，自动检测项目类型和技术栈
- 生成 `.harness/config.json`（评估维度、命令配置）
- 生成 `.harness/full-spec.md` 和 `.harness/full-design.md`

#### /proposal — 增量规格设计
- 交互式需求澄清（User Story + AC + Invariants）
- 置信度评估（HIGH/MEDIUM/LOW），LOW 项必须和用户澄清
- 对齐子 Agent 检查新 spec 与现有 design 的一致性
- 流程路由判断（自动评估 trivial/small/medium/large）
- 生成 spec-delta 和 design-delta

#### /spec-review — 多人评审 (LARGE 流程)
- 逐行评论机制
- 支持 Agent 多角色评审（完整性/可行性/一致性）
- 评论 resolution 自动回写 spec

#### /baseline — 基线采集 (Clone 场景)
- Playwright MCP 遍历参考产品
- 截图所有页面和交互状态
- 生成 feature 文档和基线报告

### Phase 2: 代码测试生成

#### /tdd-align — TDD 测试对齐
- 为每个 AC 生成三层测试（V1 单元 / V2 集成 / V3 E2E）
- 全部 RED（证明测试有效）
- 人工审批测试

#### /decompose — 任务拆解 + 模块责任田
- 测试 → 原子任务 DAG（≤2h 每任务）
- Wave 分配（同 Wave 可并行）
- 为每个代码模块生成 AGENT.md（边界、依赖、质量标准）
- 生成 module-graph.json

#### /sprint — 自动执行
- Stop Hook 驱动的持续循环
- Wave 内 worktree 隔离并行执行
- 每 Wave 后三检查点：
  1. **Steward** — 检查模块边界违反
  2. **Entropy Clean** — 清理调试残留和风格问题
  3. **Evaluator** — 按维度打分，<5 分注入修复任务
- Doom loop 检测（3+ 次失败自动停止）

### Phase 2.5: 对抗式评估

#### /evaluate — 多维度评估
- 评估维度由 JSON 配置驱动（fullstack / api / library / clone-visual）
- 三种评估方法：automated（运行工具）/ playwright（视觉对比）/ agent-review（代码审查）
- 严格评分标准 1-10，加权总分

#### /eval-fix — GAN 修复循环
- Generator（修复）→ Evaluator（重评）→ 循环
- 按维度类型分派修复策略
- 收敛（≥7分）/ 停滞（2轮无进步）/ 回退（分数下降则回滚）

### Phase 3: 归档提交

#### /verify — 三层验证
- V1 → V2 → V3 逐层验证
- 覆盖率 ≥80%
- 证据包（verdict.md + 测试报告）

#### /archive — 归档提交
- 合并 spec-delta 到 full-spec.md
- 最终代码审查
- 风格统一
- 原子 commit 拆分
- Push + MR

### 自进化

#### /evolve — 四轴进化
- **模板进化**：分析 spec 字段使用率，优化模板
- **Skill 进化**：追踪重复人工干预，建议自动化
- **流程进化**：追踪 guardian 发现模式，强化预检规则
- **记忆进化**：跨迭代经验积累

## 对抗式评估维度

| 项目类型 | 配置文件 | 核心维度 |
|---------|---------|---------|
| 全栈应用 | fullstack.json | Spec 合规 35% + 架构对齐 25% + 覆盖率 15% + 代码质量 15% + 安全 10% |
| API 服务 | api-service.json | 合约合规 35% + 性能 20% + 错误处理 20% + 安全 15% + 代码质量 10% |
| 库/包 | library.json | API 设计 35% + 覆盖率 25% + 兼容性 20% + 代码质量 15% + 文档 5% |
| Clone | clone-visual.json | 功能完整 40% + 交互一致 25% + 视觉还原 20% + 技术质量 15% |

## 模块责任田

每个代码模块的 AGENT.md 定义：
- **Responsibilities**: 模块职责
- **Boundaries**: 拥有的文件、依赖方向、禁止依赖
- **Quality Standards**: 文件大小上限、复杂度上限、必须/禁止模式
- **Interface Contract**: 公开 API、数据流
- **Change History**: 变更记录

Sprint 期间，Steward 在每 Wave 后自动检查变更是否违反这些定义。CRITICAL 违反阻断下一 Wave。
