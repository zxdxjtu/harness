---
name: verify
description: "Three-stage verification: V1 unit → V2 integration → V3 E2E + evidence package"
argument-hint: "<feature-id e.g. F001>"
---

# Verify — Three-Stage Verification

**Parameter**: $ARGUMENTS — feature ID (e.g. F001)

## V1: Unit/Component Tests

1. Run all V1 tests for this feature
2. Check coverage ≥ 80%
3. **If any fail → STOP, fix first**
4. Record results to `.harness/evidence/$ARGUMENTS/v1-result.md`

## V2: Integration Tests

1. Run all V2 tests for this feature
2. Verify cross-module data flow correctness
3. Verify API contracts match spec
4. **If any fail → STOP, fix first**
5. Record results to `.harness/evidence/$ARGUMENTS/v2-result.md`

## V3: End-to-End Tests

1. Run all V3 tests
2. Execute complete user paths defined in spec
3. Capture screenshots at key steps (if applicable)
4. Compare with baseline screenshots (if available)
5. Record results to `.harness/evidence/$ARGUMENTS/v3-result.md`

## Evidence Package

Create `.harness/evidence/$ARGUMENTS/verdict.md`:

```markdown
# Verification Verdict — $ARGUMENTS

## Summary
- Feature: [name]
- Date: [timestamp]
- Result: PASS / FAIL

## Acceptance Criteria Status
| AC | Description | V1 | V2 | V3 | Status |
|----|-------------|----|----|-----|--------|
| AC-1 | ... | PASS | PASS | PASS | ✅ |
| AC-2 | ... | PASS | FAIL | - | ❌ |

## Invariant Status
| INV | Description | Status |
|-----|-------------|--------|
| INV-1 | ... | ✅ |

## Coverage
- V1 coverage: XX%
- Lines: X/Y

## Issues Found
- [list any issues discovered during verification]
```

## Stewardship Verification (if module stewardship enabled)

If `.harness/module-graph.json` exists:
1. Run a final stewardship check across ALL modules affected by this feature
2. Verify no unresolved CRITICAL or HIGH issues from steward reports
3. Include stewardship status in the verdict

## Completion

- Update `.harness/tasks.md`: set feature status to `verified`
- Update `.harness/progress.md` with verification results

## Next Step — Auto-Navigate

1. Read the `flow` field from `.harness/specs/{FXXX}-*.md`
2. Display progress:

```
📋 SDD 进度 — {FXXX}: {feature name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ proposal → ✅ tdd-align → ✅ decompose → ✅ sprint → ✅ evaluate → ✅ verify → ⬜ archive
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
验证结果: {PASS/FAIL}
V1: {pass}/{total} | V2: {pass}/{total} | V3: {pass}/{total} | 覆盖率: {XX}%
```

If PASS:
> "验证通过。下一步是 **归档提交**（合并 spec、代码审查、原子 commit、推送）。是否继续？"

If FAIL:
> "验证未通过（{failed_count} 个测试失败）。需要修复后重新验证。"
