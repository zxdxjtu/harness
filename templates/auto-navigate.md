# Auto-Navigate 标准模式

> 所有 skill 在末尾 `## Next Step` 部分引用此标准模式。
> 此文件定义了 Agent 自动推进 SDD 流程的统一行为。

## Next Step — Auto-Navigate

### 1. 读取流程状态

```bash
# 读取当前 feature 的 spec，获取 flow 字段
cat .harness/specs/FXXX-*.md | head -20
```

从 spec frontmatter 中提取：
- `flow`: 该 feature 需要执行的阶段列表，如 `[tdd-align, decompose, sprint, evaluate, verify, archive]`
- `complexity`: 复杂度级别

### 2. 确定当前阶段和下一阶段

根据当前 skill 名称在 `flow` 列表中的位置，确定：
- **current_phase**: 当前刚完成的阶段
- **next_phase**: flow 列表中的下一个阶段
- **remaining**: 剩余未完成的阶段数

阶段名称到 skill 的映射：
| 阶段名 | Skill | 描述 |
|--------|-------|------|
| `proposal` | `/proposal` | 需求规格设计 |
| `spec-review` | `/spec-review` | 多人评审 |
| `tdd-align` | `/tdd-align` | TDD 测试对齐 |
| `decompose` | `/decompose` | 任务拆解 + 责任田 |
| `sprint` | `/sprint` | 自动执行 |
| `evaluate` | `/evaluate` | 对抗式评估 |
| `eval-fix` | `/eval-fix` | GAN 修复循环 |
| `verify` | `/verify` | 三层验证 |
| `archive` | `/archive` | 归档提交 |

### 3. 显示进度可视化

使用以下格式绘制进度条：

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{phase_1_icon} {phase_1}  →  {phase_2_icon} {phase_2}  →  ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前阶段: {current_phase} ({description})
下一阶段: {next_phase} ({description})
```

图标规则：
- ✅ 已完成的阶段
- 🔵 当前正在进行的阶段
- ⬜ 未开始的阶段
- ⏭️ 被跳过的阶段

### 4. 自然语言询问用户

用一句话总结当前阶段的产出，然后询问：

**格式**:
> "{当前阶段产出总结}。下一步是 **{下一阶段名称}**（{一句话描述}）。是否继续？"

**示例**:
- "规格设计已完成，共 5 个验收标准，置信度全部 HIGH。下一步是 **TDD 测试对齐**（为每个 AC 生成三层测试）。是否继续？"
- "任务拆解完成，共 8 个原子任务分 3 个 Wave。下一步是 **Sprint 自动执行**（按 Wave 并行开发）。是否继续？"
- "所有任务已完成。下一步是 **对抗式评估**（按 fullstack 维度评分）。是否继续？"

### 5. 响应用户指令

| 用户说 | Agent 行为 |
|--------|-----------|
| "继续" / "好的" / "是" / "go" | 自动执行下一阶段的 skill 逻辑 |
| "跳过" / "skip" | 标记当前下一阶段为 skipped，推进到下下个阶段 |
| "回到上一步" / "back" | 重新执行上一个阶段 |
| "停一下" / "暂停" / "wait" | 不推进，等待用户进一步指令 |
| "改流程" / "调整" | 重新展示流程路由选项，让用户修改 flow 列表 |

### 6. 如果是最后一个阶段

当 `next_phase` 为空（flow 列表已到末尾）：

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal  →  ✅ tdd-align  →  ✅ sprint  →  ✅ verify
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Feature {FXXX} 已完成全部 SDD 流程！
```

然后询问："Feature 已验证通过。是否需要开始下一个 Feature？"
