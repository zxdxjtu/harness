# Harness — Self-Evolving Spec-Driven Development

一个 Claude Code 插件。你只需要一个命令，它帮你走完从想法到交付的全流程，并且越用越好。

## 安装

```bash
/install-plugin zxdxjtu/harness
```

## 用法

```bash
/harness 实现用户登录功能，支持邮箱密码和 GitHub OAuth
```

就这一行。Harness 自动完成：

```
了解你的项目 → 讨论需求 → 生成测试 → 分解任务 → 并行执行 → 验证交付 → 从失败中学习
                  ↑            ↑
                你确认         你确认        其余全自动
```

## 命令

| 命令 | 作用 |
|------|------|
| `/harness 功能描述` | 一站式：从想法到交付 |
| `/harness` | 自动判断当前状态，接着干 |
| `/harness status` | 查看全景 |
| `/cancel-sprint` | 紧急停止 |

四个命令覆盖日常使用。高级子命令见 `/help`。

## 它做了什么

### 1. 初始化（首次自动，无需手动）
读 lockfile、CI 配置、CONTRIBUTING.md 等自动发现项目规范和团队约束。你只需确认分析结果。

### 2. Spec → Test → Implement → Verify
- **Spec**: 交互式需求讨论 + 零决策点清单 + 按功能性质定制评估维度
- **Test**: 三层测试（V1 单元 / V2 集成 / V3 E2E），全部 RED 起步
- **Implement**: 原子任务 DAG + Wave 并行 + worktree 隔离 + 后台 Guardian 审查
- **Verify**: V1 → V2 → V3 顺序验证 + 证据包

### 3. 自进化（全自动，无需手动触发）
- Sprint 结束时自动分析 JSONL 追踪日志
- 同一失败模式 ≥ 3 次 → 自动生成不变量 → 注入下次 Sprint
- 灵感来自 [EvoMap/evolver](https://github.com/EvoMap/evolver) 的 daemon loop 模式

### 4. 对抗式评估（克隆场景）
Generator 和 Evaluator 分离，防止自评偏差。评估维度在 Spec 中按功能性质定制。

## 设计影响

| 来源 | 借鉴 |
|------|------|
| [Anthropic — Harness Design](https://www.anthropic.com/engineering/harness-design-long-running-apps) | Generator 与 Evaluator 对抗分离 |
| [Anthropic — Effective Harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) | Progress file + git 状态恢复 |
| [OpenAI — Harness Engineering](https://openai.com/index/harness-engineering/) | 机械约束 > 指令遵从 |
| [OpenAI — Eval Skills](https://developers.openai.com/blog/eval-skills) | JSONL 追踪 + 多维评估 |
| [EvoMap/evolver](https://github.com/EvoMap/evolver) | 后台自动进化 daemon loop |
| [wow-harness](https://github.com/celesteanders/harness) | 失败模式不变量化 + 文件编辑时上下文路由 |
| [get-shit-done](https://github.com/affaan-m/everything-claude-code) | Wave 级任务并行 + 目标反向验证 |
| [DSPy GEPA](https://dspy.ai/api/optimizers/GEPA/overview/) | 反思式 prompt 进化 |

## 核心原则

1. **一个入口** — `/harness` 编排一切，用户不需要记子命令
2. **Spec → Test → Code** — 测试是人和 AI 之间的对齐合约
3. **自动进化** — Sprint 失败自动沉淀为不变量，下次避免
4. **对抗分离** — 写代码的和评代码的不是同一个 Agent
5. **机械约束 > 指令** — Hook 和 config 比 prompt 指令更可靠

## License

MIT
