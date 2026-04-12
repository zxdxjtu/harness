---
name: proposal
description: "Start a new feature proposal — guided spec + design generation"
argument-hint: "[feature description]"
---

# Proposal — Spec-Driven Development Entry Point

You are guiding the user through a structured proposal process. The goal is to produce a complete, unambiguous spec that an AI agent can execute without asking questions.

## Step 1: Initialize

Check if Harness has been configured for this project:
```bash
test -f .harness/config.yaml && echo "CONFIG_OK" || echo "NO_CONFIG"
```

If NO_CONFIG: Tell the user "建议先运行 `/harness-init` 来适配项目规范，这样后续的 Sprint 和验证会更准确。按回车跳过，使用默认配置。" Wait for user response before continuing.

Create `.harness/` directory if it doesn't exist:
```bash
mkdir -p .harness/specs .harness/designs .harness/evidence
```

Check for existing pitfalls:
```bash
cat .harness/pitfalls.md 2>/dev/null || echo "No pitfalls recorded yet."
```

If `.harness/pitfalls.md` exists, keep its contents in mind — these are known pitfalls that agents have repeatedly hit in this project. They MUST be incorporated into the Zero-Decision-Point Checklist of the spec.

Determine the next feature ID by checking existing specs:
```bash
ls .harness/specs/ 2>/dev/null | grep -oP 'F\d+' | sort -t'F' -k2 -n | tail -1
```
If none exist, start with F001.

## Step 2: Understand the Scenario

Ask the user which scenario applies:

1. **New Project** — Building from scratch
2. **Clone/Replicate** — Replicating an existing product
3. **Incremental** — Adding features to an existing codebase

This determines what additional context is needed.

## Step 2.5: Baseline Capture (Clone scenario only)

If the user selected **Clone/Replicate**:

1. Ask for the reference product URL (local or remote)
2. Suggest running `/baseline <url>` to capture a comprehensive baseline first
3. If baseline already exists (`.harness/baseline/baseline-report.md`), read it and use it to inform the spec
4. If user wants to skip baseline → warn that clone fidelity may suffer without Evaluator-generated baseline

After baseline is captured, the spec should reference:
- `.harness/baseline/baseline-report.md` for product overview
- `.harness/baseline/features/*.md` for individual feature details
- `.harness/baseline/screenshots/` for visual reference

## Step 3: Gather Requirements

Based on the user's input and `$ARGUMENTS`, conduct an interactive dialogue to clarify:

1. **User Story**: As [role], I need [capability], so that [value]
2. **Acceptance Criteria**: Concrete, testable conditions (use "When X, then Y" format)
3. **Invariants**: Rules that must always hold true
4. **Technical Constraints**: Dependencies, platform requirements, performance targets
5. **For Clone scenario**: Reference baseline report, required fidelity level
6. **For Incremental scenario**: Which existing modules are affected

Keep asking until ALL acceptance criteria are precise enough to write automated tests for. No vague words like "should", "probably", "try to".

## Step 4: Zero-Decision-Point Checklist

Pre-answer every question the implementing agent might ask:
- Test data: how to generate or where to find
- Mock strategy: which external calls to mock
- Environment variables needed
- **Known pitfalls**: Read `.harness/pitfalls.md` and filter entries relevant to this feature's domain (same modules, same tech, same patterns). Include them verbatim in the spec. Add any new pitfalls the user mentions.
- File naming conventions to follow
- Which existing code patterns to match
## Step 4.5: Define Evaluation Criteria

Based on the nature of this feature, determine how its quality should be **quantitatively measured**. This is NOT a fixed template — different features need different dimensions.

Ask the user:
> "这个功能完成后，你最关心哪些方面来判断它做得好不好？"

Then propose a set of evaluation dimensions with weights tailored to this feature. Examples:

**For a UI feature** (e.g. dashboard page):
| 维度 | 权重 | 含义 |
|------|------|------|
| 功能完整度 | 40% | 所有交互都能用 |
| 视觉还原度 | 30% | 与设计稿一致 |
| 技术质量 | 20% | 性能、错误处理 |
| 无障碍性 | 10% | 键盘导航、屏幕阅读器 |

**For a backend API** (e.g. payment service):
| 维度 | 权重 | 含义 |
|------|------|------|
| 功能正确性 | 50% | 所有边界情况正确处理 |
| 安全性 | 30% | 无注入、认证完备 |
| 性能 | 20% | 响应时间 < 200ms |

**For a CLI tool**:
| 维度 | 权重 | 含义 |
|------|------|------|
| 功能完整度 | 50% | 所有子命令和参数工作 |
| 错误信息质量 | 25% | 错误提示清晰可操作 |
| 文档一致性 | 25% | --help 与实际行为一致 |

Let the user confirm or adjust the dimensions and weights. Write the confirmed evaluation criteria into the Spec's `## Evaluation Criteria` section.

## Step 5: Generate Spec

Write the spec to `.harness/specs/FXXX-[name].md`:

```markdown
# Feature: [Name]
## ID: FXXX | Status: draft | Priority: [P0/P1/P2]

## User Story
As [role], I need [capability], so that [value]

## Acceptance Criteria
- AC-1: When [condition], then [result]
- AC-2: When [condition], then [result]

## Invariants
- INV-1: [rule that must always hold]

## Technical Constraints
- Platform: [requirements]
- Dependencies: [list with versions]
- Performance: [targets]

## Evaluation Criteria
How to quantitatively judge this feature's quality (confirmed with user):

| 维度 | 权重 | 通过标准 |
|------|------|---------|
| [dimension 1] | XX% | [concrete threshold] |
| [dimension 2] | XX% | [concrete threshold] |

Pass threshold: [X/10]

## Zero-Decision-Point Checklist
- Test data: [path or generation method]
- Mock strategy: [what to mock]
- Environment: [KEY=VALUE]
- Known pitfalls: [auto-populated from .harness/pitfalls.md + new items for this feature]
- Code patterns: [which existing patterns to follow]

## Design Notes
[Architecture decisions, data flow, component structure]
```

## Step 6: Generate Design (optional)

If the feature is non-trivial, also generate `.harness/designs/FXXX-[name].md` with:
- Component/module breakdown
- Data flow diagram (ASCII)
- API contracts
- State management approach

## Step 7: Request Approval

Present the spec to the user. Explicitly ask:
> "This spec defines N acceptance criteria and M invariants. Can an agent implement this without asking you any questions? If not, what's missing?"

**Do NOT proceed until the user approves.** Update spec status to `approved` after approval.

## Next Step

After approval:
- **Clone scenario**: Tell the user the recommended flow is:
  `/tdd-align FXXX` → `/decompose` → `/sprint` → `/evaluate FXXX` → `/eval-fix FXXX` (if needed)
- **Other scenarios**: Tell the user to run: `/tdd-align FXXX`
