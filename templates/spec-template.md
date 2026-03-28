---
id: FXXX
name: ""
status: draft
priority: P1
complexity: ""       # trivial | small | medium | large (由 proposal 流程路由判断填写)
flow: []             # 该 feature 实际需要执行的阶段列表 (由流程路由判断填写)
scenario: ""         # new | clone | incremental
created: ""
approved: ""
---

# Feature: {Name}

## User Story

As {role}, I need {capability}, so that {value}.

## Acceptance Criteria

> 必须可执行，不允许"应该""大概""尽量"等模糊词。每条用 When/Then 格式。

- AC-1: When {condition}, then {result}
- AC-2: When {condition}, then {result}

## Invariants

> 永远为真的规则，无论功能如何变化。

- INV-1: {rule that must always hold}

## Technical Constraints

- Platform: {requirements}
- Dependencies: {list with versions}
- Performance: {targets, e.g. p95 < 200ms}

## Confidence Assessment

> proposal 阶段由 Agent 填写，LOW 项必须和用户澄清后才能继续。

| Decision | Confidence | Rationale | Action |
|----------|-----------|-----------|--------|
| {decision} | HIGH/MEDIUM/LOW | {reason} | Proceed/Clarify |

## Zero-Decision-Point Checklist

> Agent 实现时可能需要问人的信息，全部预写在这里。

- Test data: {path or generation method}
- Mock strategy: {what to mock}
- Environment: {KEY=VALUE}
- Known pitfalls: {issue → mitigation}
- Code patterns: {which existing patterns to follow}
- File naming: {conventions}

## Design Notes

{Architecture decisions, data flow, component structure — 或链接到 .harness/designs/FXXX-*.md}

## Clone/Baseline Reference (Clone 场景)

- Reference URL: {url}
- Development URL: {url}
- Baseline path: `.harness/baseline/`
- Fidelity threshold: {score, default 7}
- Key comparison dimensions: {which dimensions matter most}
