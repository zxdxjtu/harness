---
name: spec-review
description: "Multi-person spec review with line-by-line comments and resolution tracking"
argument-hint: "<feature-id e.g. F001>"
---

# Spec Review — Collaborative Specification Review

You are facilitating a structured review of a feature spec. Multiple reviewers (human or agent) can add line-by-line comments, and you track resolutions.

**Parameter**: $ARGUMENTS — feature ID (e.g. F001)

## Step 1: Load Spec

```bash
ls .harness/specs/ 2>/dev/null | grep "$FEATURE_ID"
```

Read the spec file `.harness/specs/FXXX-*.md`. If not found or status is not `approved`, inform user.

## Step 2: Initialize Review

Create or read `.harness/reviews/FXXX-review.md`:

```bash
ls .harness/reviews/ 2>/dev/null | grep "$FEATURE_ID"
```

If review file doesn't exist, generate it:

```markdown
---
feature: FXXX
status: in-review
reviewers: []
created: {ISO timestamp}
open_comments: 0
resolved_comments: 0
---

# Spec Review — FXXX: {feature name}

## Review Status
- Total comments: 0
- Open: 0
- Resolved: 0

## Sections Under Review

{For each major section of the spec (User Story, each AC, each INV, Technical Constraints, Zero-Decision-Point), create a review anchor:}

### User Story
> {quoted content from spec}

---

### AC-1: {content}
> {quoted content from spec}

---

### AC-2: {content}
> {quoted content from spec}

---

{... for all ACs, INVs, and other sections}
```

## Step 3: Collect Reviews

Ask user how they want to review:

1. **Self-review** — User reviews the spec themselves, adding comments interactively
2. **Agent review** — Launch reviewer sub-agents with different perspectives:
   - **Completeness reviewer**: Are all edge cases covered? Missing ACs?
   - **Feasibility reviewer**: Is this technically achievable within constraints?
   - **Consistency reviewer**: Does this conflict with existing features or full-spec?
3. **Collaborative** — Both user and agent reviewers

### For Agent Reviews

Launch up to 3 reviewer sub-agents in parallel:

```
Agent(subagent_type: "general-purpose", run_in_background: true,
  prompt: "You are a COMPLETENESS REVIEWER for spec FXXX.
  Read .harness/specs/FXXX-*.md
  Read .harness/full-spec.md (if exists) for existing feature context.

  For each AC and INV, ask:
  1. Are boundary conditions covered?
  2. Are error/failure scenarios defined?
  3. Are there implicit assumptions not stated?
  4. Could an implementer interpret this ambiguously?

  Output your review as:
  SECTION: {section name}
  COMMENT: {your finding}
  SEVERITY: critical|major|minor|suggestion")
```

### For User Reviews

Present the spec section by section, asking for each:
> "对于 AC-1，你有什么意见或补充吗？（输入评论，或说'通过'跳过）"

## Step 4: Record Comments

Add comments to `.harness/reviews/FXXX-review.md` under the relevant section:

```markdown
### AC-1: {content}
> {quoted content from spec}

**COMMENT** [{reviewer}] [{timestamp}] [severity: {critical|major|minor|suggestion}]
{comment content}
**STATUS**: open

**COMMENT** [{reviewer}] [{timestamp}] [severity: {minor}]
{another comment}
**STATUS**: open
```

Update the review frontmatter counters.

## Step 5: Resolution

For each open comment, present to user and ask for resolution:

> "评审意见 [{severity}]: {comment content}
>
> 如何处理？
> 1. 接受 — 修改 spec
> 2. 拒绝 — 说明理由
> 3. 讨论 — 需要更多信息"

Based on user's choice:

### Accept
- Update the spec file with the change
- Update the comment status:
```markdown
**STATUS**: resolved | **RESOLUTION**: Spec updated — {what changed}
```

### Reject
- Record the rejection reason:
```markdown
**STATUS**: rejected | **REASON**: {user's reason}
```

### Discuss
- Add discussion thread, ask follow-up questions
```markdown
**STATUS**: discussing
**REPLY** [{user}] [{timestamp}]: {discussion content}
```

## Step 6: Review Summary

After all comments are addressed, present summary:

```
📋 Spec Review Summary — FXXX: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total comments: N
  ✅ Resolved: N (spec updated)
  ❌ Rejected: N (with reasons)
  💬 Discussing: N (need follow-up)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If any **critical** or **major** comments are still open → do NOT proceed.

If all critical/major resolved:
- Update review status to `completed`
- Update spec status to `reviewed` (if it was just `approved`, upgrade to `reviewed`)

## Next Step — Auto-Navigate

1. Read the `flow` field from the spec
2. Display progress visualization with spec-review marked as ✅
3. Ask naturally: "Spec 评审完成，{N} 条意见已处理。下一步是 **{next phase}**（{description}）。是否继续？"
4. If user confirms → execute next phase's skill logic directly
