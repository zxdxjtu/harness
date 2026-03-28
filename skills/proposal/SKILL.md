---
name: proposal
description: "Start a new feature proposal — guided spec + design generation with confidence assessment and flow routing"
argument-hint: "[feature description]"
---

# Proposal — Spec-Driven Development Entry Point

You are guiding the user through a structured proposal process. The goal is to produce a complete, unambiguous spec that an AI agent can execute without asking questions.

**Parameter**: $ARGUMENTS — feature description (optional)

## Step 1: Initialize

Check if harness is initialized:
```bash
ls .harness/config.json 2>/dev/null
```

If not initialized, suggest running `/sdd-init` first. If user wants to skip init, create minimal structure:
```bash
mkdir -p .harness/specs .harness/designs .harness/evidence .harness/reviews .harness/evolution
```

Determine the next feature ID by checking existing specs:
```bash
ls .harness/specs/ 2>/dev/null | grep -oP 'F\d+' | sort -t'F' -k2 -n | tail -1
```
If none exist, start with F001.

## Step 2: Understand the Scenario

Ask the user (via AskUserQuestion) which scenario applies:

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
5. **For Clone scenario**: Reference baseline report, UI fidelity requirements, Evaluator comparison criteria
6. **For Incremental scenario**: Which existing modules are affected

Keep asking until ALL acceptance criteria are precise enough to write automated tests for. No vague words like "should", "probably", "try to".

## Step 4: Zero-Decision-Point Checklist

Pre-answer every question the implementing agent might ask:
- Test data: how to generate or where to find
- Mock strategy: which external calls to mock
- Environment variables needed
- Known pitfalls and their mitigations
- File naming conventions to follow
- Which existing code patterns to match
- **For Clone scenario**:
  - Reference product URL: [url]
  - Development product URL: [url, e.g. http://localhost:3000]
  - Baseline path: `.harness/baseline/`
  - Evaluator comparison criteria: [which dimensions matter most]
  - Acceptable fidelity threshold: [score out of 10, default 7]

## Step 5: Confidence Assessment

For each AC and key design decision, assess confidence:

| Decision | Confidence | Rationale | Action |
|----------|-----------|-----------|--------|
| {AC or decision} | HIGH/MEDIUM/LOW | {reason} | Proceed/Clarify |

Rules:
- **HIGH**: Clear requirements, standard pattern, no ambiguity → proceed
- **MEDIUM**: Reasonable assumption but not explicitly confirmed → note assumption, proceed with caveat
- **LOW**: Missing info, multiple interpretations possible → MUST clarify with user before proceeding

If any item is LOW, use AskUserQuestion to resolve it NOW. Do not generate a spec with LOW-confidence items unresolved.

## Step 6: Spec-Design Alignment Check

If `.harness/full-design.md` exists (project was initialized with `/sdd-init`):

Launch an alignment sub-agent (background) to cross-check:
1. Does the new spec conflict with existing architecture in full-design.md?
2. Does the spec introduce dependencies that violate existing module boundaries?
3. Are there existing components that can be reused instead of building new?

Report findings as:
- **Conflicts**: {list of conflicts with existing design}
- **Reuse Opportunities**: {existing code/modules that can be leveraged}
- **New Modules Needed**: {modules that don't exist yet}

Present alignment findings to user before generating the spec.

## Step 7: Generate Spec

Write the spec to `.harness/specs/FXXX-[name].md` using the template from `templates/spec-template.md`.

Key additions to the spec frontmatter:
```yaml
---
id: FXXX
name: "{feature name}"
status: draft
priority: P1
complexity: ""    # Will be filled in Step 9
flow: []          # Will be filled in Step 9
scenario: "{new|clone|incremental}"
created: "{ISO timestamp}"
---
```

Include the Confidence Assessment table in the spec body.

## Step 8: Generate Design (if non-trivial)

If the feature has 3+ ACs or touches multiple modules, generate `.harness/designs/FXXX-[name].md` using the template from `templates/design-template.md`.

## Step 9: Request Approval

Present the spec to the user. Explicitly ask:
> "This spec defines N acceptance criteria and M invariants. Can an agent implement this without asking you any questions? If not, what's missing?"

**Do NOT proceed until the user approves.** Update spec status to `approved` after approval.

## Step 10: Flow Routing — Determine SDD Complexity

After approval, assess the feature complexity and determine which SDD phases are needed:

### Complexity Assessment

Evaluate based on:
- **Number of ACs**: 1-2 → likely trivial/small, 3-8 → medium, 8+ → large
- **Modules affected**: 1 module → smaller, multiple → larger
- **Risk level**: Config change → trivial, new API → medium, architecture change → large
- **Confidence**: All HIGH → can be simpler, any MEDIUM → needs more process

### Flow Routing

```
📌 TRIVIAL (改配置、修 typo、单文件小改动)
   complexity: trivial
   flow: [implement, verify]

📌 SMALL (1-3 个 AC，单模块，高确定性)
   complexity: small
   flow: [tdd-align, implement, verify]

📌 MEDIUM (3-8 个 AC，跨模块)
   complexity: medium
   flow: [tdd-align, decompose, sprint, evaluate, verify, archive]

📌 LARGE (8+ AC，架构变更，高风险)
   complexity: large
   flow: [spec-review, tdd-align, decompose, sprint, evaluate, eval-fix, verify, archive]
```

For **Clone scenario**, always include `evaluate` in the flow.

Present the routing decision to user:
> "根据需求分析，判断复杂度为 **{complexity}**，建议流程: {flow list with descriptions}。是否同意？可以调整。"

User can:
- Confirm → write complexity and flow to spec frontmatter
- Upgrade → use more complete flow
- Downgrade → use simpler flow
- Customize → pick specific phases

Update the spec frontmatter with final `complexity` and `flow` values.

## Next Step — Auto-Navigate

1. Read the `flow` field from the spec just approved
2. Display progress visualization:

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal  →  ⬜ {next_phase}  →  ⬜ ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
当前阶段: proposal (需求规格设计) ✅ 已完成
下一阶段: {next_phase} ({description})
```

3. Ask naturally: "{spec summary}。下一步是 **{next phase name}**（{description}）。是否继续？"
4. If user says yes/继续/好的 → execute the next phase's skill logic directly
5. If user says skip → mark phase as skipped, advance to the one after
6. If user says wait → stop and let user take control
