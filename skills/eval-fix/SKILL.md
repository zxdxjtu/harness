---
name: eval-fix
description: "GAN-style fix loop: read eval report → fix gaps by dimension → re-evaluate → repeat until convergence"
argument-hint: "<feature-id e.g. F001> [--ref-url <url> --dev-url <url>]"
---

# Eval-Fix — Generalized Adversarial Fix-Evaluate Loop

This implements the GAN-inspired adversarial loop: Generator (fix) → Evaluator (assess) → repeat until convergence or stagnation. Works with ANY evaluation dimension profile.

**Parameter**: $ARGUMENTS — feature ID and optional product URLs

## Step 1: Load Evaluation Report

```bash
FEATURE_ID=$(echo "$ARGUMENTS" | grep -oP 'F\d+')
cat ".harness/evidence/${FEATURE_ID}/eval-report.md" 2>/dev/null
```

If no eval-report exists → inform user and suggest running `/evaluate` first. STOP.

Also load the evaluation profile to know convergence threshold and stagnation rules:
```bash
cat .harness/config.json
```

## Step 2: Extract Fix Tasks by Dimension

Parse the eval-report's "Fix Tasks" section. For each dimension scoring below the convergence threshold:

### For `automated` dimensions (spec-compliance, test-coverage, api-contract):
1. Read which specific ACs/tests failed
2. Read the relevant source code
3. Create fix tasks targeting the specific failures

### For `playwright` dimensions (visual/interaction):
1. Read the gap description + screenshot references
2. Read the relevant source code for UI components
3. Create fix tasks matching reference exactly

### For `agent-review` dimensions (architecture, code-quality, security):
1. Read the reviewer's specific findings (file, line, issue)
2. Create fix tasks for each finding
3. Prioritize: CRITICAL findings as P0, others as P1/P2

Each fix task has:
- **Dimension**: which evaluation dimension this fixes
- **What's wrong**: factual description from Evaluator
- **Evidence**: file paths, line numbers, test results, screenshots
- **Expected outcome**: what "fixed" looks like
- **Priority**: P0 (CRITICAL) / P1 (HIGH) / P2 (MEDIUM)

## Step 3: Execute Fixes (Generator Role)

For each fix task, ordered by priority (P0 first):

### Dimension-specific fix strategies:

**spec-compliance**: Read failing test, read spec AC, implement missing logic to make test pass.

**architecture-alignment**: Refactor to respect module boundaries — move code to correct module, fix import directions, update AGENT.md if needed.

**test-coverage**: Write additional tests for uncovered paths. If implementation has untested branches, add tests.

**code-quality**: Fix lint errors, reduce complexity (extract functions), add error handling, fix naming.

**security**: Remove hardcoded secrets, add input validation, fix injection vulnerabilities, add auth checks.

**functional-completeness / interaction-consistency / visual-fidelity** (clone): Read reference screenshots, modify UI code to match reference exactly.

### Execution:

**Single fix**: Execute directly in main branch.

**Multiple independent fixes**: Use `Agent(isolation: "worktree")` for parallel execution:

```
Agent(subagent_type: "general-purpose", isolation: "worktree",
  prompt: "You are a fix worker for {dimension_name}.

  GAP: {gap description from eval-report}
  EVIDENCE: {file paths, line numbers, screenshots}
  FIX SUGGESTION: {evaluator's suggestion}

  Steps:
  1. Read the evidence to understand the gap
  2. Find and modify the relevant code
  3. Run tests to verify no regression
  4. Commit with: fix(eval-{dimension_id}): {description}

  RULES:
  - Fix ONLY what the Evaluator reported
  - Do NOT add unrelated improvements
  - Do NOT modify test files
  - Verify fix addresses the specific finding")
```

## Step 4: Re-Evaluate

After all fixes are applied:

1. Merge any worktrees back to main branch
2. Ensure dev product reflects latest code (restart if needed)
3. Run the full evaluation protocol (same as `/evaluate`):
   - Execute all dimensions from the profile
   - Generate new eval-report with updated scores
   - Track score trend across iterations

## Step 5: Convergence Check

Read the new eval-report and compare with previous iteration. Load convergence rules from the dimension profile:
- `convergence_threshold`: score needed to pass (default 7)
- `stagnation_rounds`: consecutive rounds without improvement before stopping (default 2)

### Convergence achieved (overall score ≥ threshold):
```
Report:
"Eval-fix 循环在第 {N} 轮收敛。
 分数趋势: {iter1} → {iter2} → ... → {current}
 改善维度: {list}
 剩余微小差距: {list if any}"
```
STOP the loop.

### Progress detected (score improved):
Continue to next iteration — go back to Step 2 with the new eval-report.

### Stagnation detected (no improvement for {stagnation_rounds} consecutive iterations):
```
Report:
"分数停滞，连续 {N} 轮无改善。
 分数趋势: {list}

 抗修复差距:
 {list of dimensions still below threshold with descriptions}

 建议:
 1. 人工审查这些差距 — 可能需要架构变更
 2. 调整 spec（如果部分差异是有意为之）
 3. 人工修复后重新运行 /evaluate"
```
STOP and wait for user decision.

### Regression detected (score decreased):
```
Report:
"WARNING: 分数回退！
 上轮: {prev_score} → 本轮: {current_score}

 回退维度: {list}

 正在回滚本轮修复..."
```
Revert the last batch of commits and STOP.

## Step 6: Update Progress & Loop State

Track in `.harness/evidence/{FXXX}/eval-loop-state.md`:

```markdown
---
feature: {FXXX}
iteration: {N}
status: running|converged|stagnated|regressed
profile: {eval dimension profile name}
---

## Score History
| Iteration | Overall | {dim1} | {dim2} | ... | Fixes Applied |
|-----------|---------|--------|--------|-----|---------------|
| 1 | X.X | X | X | ... | initial evaluation |
| 2 | X.X | X | X | ... | {fix descriptions} |
```

Update `.harness/progress.md`:
```
[HH:MM] EVAL-FIX iteration {N}: score {prev} → {current}
[HH:MM] Fixed dimensions: {list improved}
[HH:MM] Remaining below threshold: {list}
```

## Next Step — Auto-Navigate

When converged:

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal → ✅ tdd-align → ✅ decompose → ✅ sprint → ✅ evaluate → ✅ eval-fix → ⬜ verify
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
评估收敛: {final_score}/10 (经过 {N} 轮修复)
```

> "评估修复循环收敛（{score}/10，{N} 轮）。下一步是 **验证**（三层测试 + 证据包）。是否继续？"

## Critical Rules

1. **Generator and Evaluator are SEPARATE roles.** Do not self-evaluate during the fix phase.
2. **Fix what the Evaluator reports, not what you think is wrong.** Scope discipline is critical.
3. **Dimension-aware fixes.** Architecture gaps need refactoring, not patches. Security gaps need proper fixes, not workarounds.
4. **No infinite loops.** Stagnation detection ensures the loop terminates.
5. **Preserve rollback capability.** Each fix batch is a separate commit.
