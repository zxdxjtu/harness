---
name: archive
description: "Phase 3: merge spec/design deltas, code review, atomic commits, push, and trigger self-evolution"
argument-hint: "<feature-id e.g. F001>"
---

# Archive — Merge, Review, Commit & Evolve

You are finalizing a completed feature: merging incremental specs back into the full documents, running a final code review, making clean commits, and triggering self-evolution.

**Parameter**: $ARGUMENTS — feature ID (e.g. F001)

## Step 1: Verify Prerequisites

```bash
cat .harness/evidence/${FEATURE_ID}/verdict.md 2>/dev/null
```

The feature must be verified (verdict = PASS) before archiving. If not verified → suggest running `/verify` first.

## Step 2: Merge Spec & Design Deltas

### 2.1 Merge Spec Delta into Full Spec

Read `.harness/specs/{FXXX}-*.md` (the incremental spec).
Read `.harness/full-spec.md` (the full project spec, if exists).

Merge the feature spec into the full spec:
- Add the feature to the "Existing Features" section
- Update "Module Inventory" if new modules were created
- Update "Architecture Summary" if architecture changed
- Preserve all existing content, only ADD the new feature

If conflicts detected (e.g., feature contradicts existing spec), present to user for resolution.

### 2.2 Merge Design Delta into Full Design

Read `.harness/designs/{FXXX}-*.md` (if exists).
Read `.harness/full-design.md` (if exists).

Merge similarly: add new components, update dependency graph, add new data models.

## Step 3: Final Code Review

Launch a comprehensive code review sub-agent:

```
Agent(subagent_type: "code-reviewer", run_in_background: true,
  prompt: "Final code review for feature {FXXX}.

  Review ALL files changed for this feature:
  git diff {base_commit}..HEAD -- {files from tasks.md}

  Check:
  1. Code quality: naming, readability, complexity
  2. Error handling: no swallowed errors, proper messages
  3. Security: no hardcoded secrets, input validation
  4. Immutability: no mutation of shared state
  5. Style consistency: matches project conventions

  Report: CRITICAL / HIGH / MEDIUM issues only.
  Ignore cosmetic issues.")
```

Read the review. If CRITICAL issues → fix before proceeding. HIGH issues → fix or acknowledge.

## Step 4: Style Unification

If a lint/format command is configured:
```bash
{lint_command} --fix 2>&1
{format_command} 2>&1
```

Commit style fixes separately: `chore(style): unify code style for {FXXX}`

## Step 5: Atomic Commit Splitting

Review the git history for this feature. If commits are messy or mixed:

1. Identify logical units of change
2. Suggest splitting into clean, atomic commits:
   - One commit per logical unit (e.g., "add auth middleware", "add login endpoint", "add login tests")
   - Each commit should build and pass tests independently

Present the commit plan to user:
> "当前有 {N} 个 commits。建议整理为 {M} 个原子 commits: {list}。是否同意？"

If user agrees, execute interactive rebase (only if user explicitly approves).

## Step 6: Push & MR

```bash
git push origin {current_branch}
```

Ask user:
> "代码已推送。是否需要创建 MR/PR？"

If yes:
```bash
gh pr create --title "feat({FXXX}): {feature name}" --body "$(cat <<'EOF'
## Summary
{feature description}

## Changes
{list of key changes}

## Test Evidence
- V1 (Unit): ✅ {pass count}/{total}
- V2 (Integration): ✅ {pass count}/{total}
- V3 (E2E): ✅ {pass count}/{total}
- Evaluation Score: {score}/10

## Evidence
See `.harness/evidence/{FXXX}/` for full reports.
EOF
)"
```

## Step 7: Update Evolution Data

Record this iteration for self-evolution analysis:

Append to `.harness/evolution/memory.jsonl`:
```json
{"iteration": N, "feature": "FXXX", "name": "{feature name}", "date": "{ISO}", "complexity": "{complexity}", "waves": M, "tasks": K, "eval_score": X.X, "lessons": [], "process_improvements": []}
```

Update config iteration count:
```json
"evolution": { "iteration_count": N+1 }
```

## Step 8: Trigger Self-Evolution (if iteration_count ≥ 2)

If this is the 2nd or later feature completed, ask:
> "已完成 {N} 个 feature 迭代。是否要运行自进化分析（检查模板和流程是否需要优化）？"

If user agrees → execute `/evolve` logic.

## Next Step — Auto-Navigate

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal → ✅ tdd-align → ✅ decompose → ✅ sprint → ✅ evaluate → ✅ verify → ✅ archive
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Feature {FXXX}: {feature name} 已完成全部 SDD 流程！
评估得分: {score}/10 | 任务: {completed}/{total} | Waves: {M}
```

> "Feature 已归档完成。是否要开始下一个 Feature？"
