---
name: evolve
description: "Self-evolution: analyze SDD iterations to improve templates, skills, process rules, and memory"
argument-hint: "[--axis template|skill|process|memory|all]"
---

# Evolve — Self-Evolution Analysis

You are the evolution engine. After multiple SDD iterations, you analyze patterns across features to improve the SDD process itself.

**Parameter**: $ARGUMENTS — optional axis filter (default: all)

## Step 1: Load Evolution Data

```bash
cat .harness/evolution/memory.jsonl 2>/dev/null
cat .harness/config.json
ls .harness/evolution/interventions.jsonl 2>/dev/null
ls .harness/evolution/guardian-findings.jsonl 2>/dev/null
```

If fewer than 2 completed features → inform user that evolution needs at least 2 iterations for meaningful analysis. STOP.

## Step 2: Axis A — Spec Template Evolution

Analyze across all completed specs:

1. **Which spec fields were actually used?** Compare spec content with task implementations:
   - Fields that workers actually referenced → keep
   - Fields that were always empty or never referenced → candidate for removal
   - Fields that were missing and had to be added ad-hoc → candidate for addition

2. **Review feedback patterns**: Read `.harness/reviews/` files:
   - Recurring review comments → suggest adding preventive section to template
   - Common LOW-confidence items → suggest adding guidance for those decisions

3. **Generate recommendations**:
   ```
   Spec Template Evolution Recommendations:
   + ADD: "{field name}" — needed in {N}/{total} features, was added ad-hoc
   - REMOVE: "{field name}" — empty in {N}/{total} features, never referenced
   ~ MODIFY: "{field name}" — common review comment: {pattern}, suggest {change}
   ```

4. If user approves changes, update `templates/spec-template.md` and increment version in `templates/evolution/spec-template-meta.json`.

## Step 3: Axis B — Skill Abstraction Evolution

Analyze for recurring manual interventions:

1. Read `.harness/evolution/interventions.jsonl` (if exists)
2. Read `.harness/progress.md` for patterns like:
   - "manual lint fix" appearing in multiple sprints
   - "added missing env var" appearing repeatedly
   - "restarted dev server" between evaluations

3. For patterns appearing ≥ 3 times:
   ```
   Skill Evolution Recommendations:
   + NEW HOOK: "auto-restart-dev-server" — triggered {N} times manually
   + NEW SKILL STEP: "env-var-check" in proposal — missing env vars in {N} features
   ~ ENHANCE: "entropy-clean should also check for {pattern}" — found in {N} waves
   ```

4. If user approves, suggest specific hook or skill modifications.

## Step 4: Axis C — Process Guardianship Evolution

Analyze guardian findings across features:

1. Read `.harness/evolution/guardian-findings.jsonl` (or scan steward reports):
   ```bash
   cat .harness/evidence/*/steward-wave-*.md 2>/dev/null
   ```

2. Identify patterns:
   - **Repeated findings**: Same type of issue found in multiple waves/features
     → Suggest adding as a pre-check rule in affected AGENT.md
   - **Zero-finding dimensions**: Guardian dimension that never finds issues
     → Suggest reducing frequency or removing
   - **Frequently CRITICAL modules**: Modules that often have boundary violations
     → Suggest strengthening their AGENT.md or refactoring boundaries

3. Generate recommendations:
   ```
   Process Evolution Recommendations:
   + ADD RULE to src/auth/AGENT.md: "Always validate JWT expiry" — violated in {N} waves
   - REDUCE frequency: "security audit" dimension — 0 findings in {N} features
   ~ REFACTOR: src/utils boundaries unclear — CRITICAL violations in {N}/{total} features
   ```

## Step 5: Axis D — Memory Evolution

Compile lessons learned:

1. Read all feature summaries from `.harness/evolution/memory.jsonl`
2. Identify cross-feature lessons:
   - Technical pitfalls that appeared in multiple features
   - Process shortcuts that worked well
   - Complexity estimates vs actual (calibration)

3. Generate memory summary:
   ```
   Memory Evolution:
   📝 Lessons learned across {N} features:
   - {lesson 1 — with frequency count}
   - {lesson 2}

   📊 Complexity calibration:
   - Features estimated SMALL that were actually MEDIUM: {count}
   - Average eval score at first evaluation: {avg}
   - Average eval-fix rounds needed: {avg}

   💡 Process improvements applied:
   - {improvement 1 — from iteration N}
   ```

4. If notable patterns found, suggest saving key lessons to project memory (CLAUDE.md or AGENT.md).

## Step 6: Present Evolution Report

```markdown
# SDD Evolution Report — Iteration {N}
## Date: {ISO timestamp}

## Template Evolution
{axis A recommendations}

## Skill Evolution
{axis B recommendations}

## Process Evolution
{axis C recommendations}

## Memory Evolution
{axis D summary}

## Recommended Actions
| # | Action | Axis | Impact | Auto-applicable |
|---|--------|------|--------|-----------------|
| 1 | {action} | {A/B/C/D} | {HIGH/MEDIUM/LOW} | {yes/no} |
```

Ask user which recommendations to apply. For auto-applicable ones, execute immediately.

## Step 7: Apply Approved Changes

For each approved recommendation:
- Update the relevant template/skill/AGENT.md file
- Record the change in the appropriate meta.json
- Commit: `chore(evolve): {description of evolution change}`

```
✅ 自进化完成
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
已应用 {N} 项改进
模板版本: v{old} → v{new}
下次 SDD 迭代将使用更新后的流程
```
