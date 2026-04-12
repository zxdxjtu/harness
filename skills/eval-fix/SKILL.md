---
name: eval-fix
description: "Adversarial fix loop: read eval report → fix gaps → re-evaluate → repeat until convergence"
argument-hint: "<feature-id e.g. F001> --ref-url <url> --dev-url <url>"
---

# Eval-Fix — Adversarial Fix-Evaluate Loop

This command implements an adversarial fix-evaluate loop: Generator (fix) → Evaluator (assess) → repeat until convergence or user intervention. The Generator and Evaluator are separate agents to prevent self-assessment bias.

**Parameter**: $ARGUMENTS — feature ID and product URLs

## Step 1: Load Evaluation Report

```bash
FEATURE_ID=$(echo "$ARGUMENTS" | grep -oP 'F\d+')
cat ".harness/evidence/${FEATURE_ID}/eval-report.md" 2>/dev/null
```

If no eval-report exists → tell user to run `/evaluate {FXXX}` first and STOP.

## Step 2: Extract Fix Tasks

Parse the eval-report's "Fix Tasks" section. For each feature scoring < 7:

1. Read the detailed findings (gap description + screenshot references)
2. Read the fix suggestions
3. Read the relevant screenshots to understand the visual gap
4. Create a fix task with:
   - **What's wrong**: factual description from Evaluator
   - **Reference screenshots**: paths to reference screenshots
   - **Dev screenshots**: paths to current dev screenshots
   - **Expected outcome**: what "fixed" looks like (described precisely)

## Step 3: Execute Fixes (Generator Role)

For each fix task, ordered by priority (P0 first):

### Single fix approach (no worktree):
1. Read the gap description and screenshots from the Evaluator
2. Read the relevant source code files
3. Implement the fix — focus on matching the reference product exactly
4. Run existing tests to verify no regression
5. Commit: `fix(eval): {brief description of what was fixed}`

### Multiple independent fixes:
Use `Agent(isolation: "worktree")` for parallel execution when fixes are independent.

**Generator Agent Prompt**:
```
You are a fix worker. The Evaluator found this gap:

GAP: {gap description from eval-report}
REFERENCE: {screenshot path} — shows how it SHOULD look/behave
CURRENT: {screenshot path} — shows how it CURRENTLY looks/behaves
FIX SUGGESTION: {evaluator's suggestion}

Steps:
1. Read the reference screenshot to understand the target
2. Read the current screenshot to understand the gap
3. Find and modify the relevant code
4. Test that the fix works
5. Commit with: fix(eval): {description}

RULES:
- Match the reference product EXACTLY
- Do NOT add features the reference doesn't have
- Do NOT "improve" beyond what the reference shows
- If unsure, match the reference screenshot pixel-for-pixel
```

## Step 4: Re-Evaluate

After all fixes are applied, trigger a fresh evaluation:

1. Merge any worktrees back to main branch
2. Ensure the dev product is running with latest code
3. Run the evaluation protocol (same as `/evaluate`):
   - Playwright MCP tests each feature against reference
   - Generate new eval-report with updated scores
   - Track score trend across iterations

## Step 5: Convergence Check

Read the new eval-report and compare with previous iteration:

### Convergence achieved (overall score ≥ 7):
```
Report to user:
"Eval-fix loop converged after N iterations.
 Score progression: {iter1} → {iter2} → ... → {current}
 Remaining minor gaps: {list if any}
 Next step: /verify {FXXX}"
```
STOP the loop.

### Progress detected (score improved):
Continue to next iteration — go back to Step 2 with the new eval-report.

### Stagnation detected (score did NOT improve for 2 consecutive iterations):
```
Report to user:
"Score stagnation detected after N iterations.
 Score progression: {iter1} → ... → {current} (no improvement in last 2 rounds)

 Remaining gaps that resist automated fixing:
 {list of features still < 7 with descriptions}

 Recommended actions:
 1. Review the gaps manually — some may require architectural changes
 2. Adjust the spec if the reference behavior is intentionally different
 3. Run /evaluate again after manual fixes

 Continue the loop? (The fix approach may need human guidance)"
```
STOP and wait for user decision.

### Regression detected (score decreased):
```
Report to user:
"WARNING: Score regression detected!
 Previous: {prev_score} → Current: {current_score}

 Regressed features:
 {list of features that got worse}

 Rolling back last batch of fixes..."
```
Revert the last batch of commits and STOP.

## Step 6: Update Progress

After each iteration, update `.harness/progress.md`:
```
[HH:MM] EVAL-FIX iteration {N}: score {prev} → {current}
[HH:MM] Fixed: {list of features improved}
[HH:MM] Remaining: {list of features still < 7}
```

## Loop State

Track loop state in `.harness/evidence/{FXXX}/eval-loop-state.md`:

```markdown
---
feature: {FXXX}
iteration: {N}
status: running|converged|stagnated|regressed
ref_url: {url}
dev_url: {url}
---

## Score History
| Iteration | Overall | Functional | Interaction | Visual | Technical | Fixes Applied |
|-----------|---------|-----------|-------------|--------|-----------|---------------|
| 1 | X.X | X | X | X | X | initial evaluation |
| 2 | X.X | X | X | X | X | {fix descriptions} |
```

## Critical Rules

1. **Generator and Evaluator are SEPARATE roles.** Do not self-evaluate during the fix phase. Always run the full Evaluator protocol for re-assessment.
2. **Trust the Evaluator's screenshots over your assumptions.** If the Evaluator says it's different, it IS different.
3. **Fix what the Evaluator reports, not what you think is wrong.** Scope discipline is critical.
4. **No infinite loops.** Stagnation detection ensures the loop terminates when automated fixes stop helping.
5. **Preserve rollback capability.** Each fix batch is a separate commit, enabling clean revert on regression.
