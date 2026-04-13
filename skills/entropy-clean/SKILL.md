---
name: entropy-clean
description: "Post-wave entropy cleanup — remove debug artifacts, enforce style, ensure git hygiene"
argument-hint: "<feature-id e.g. F001> [--wave N]"
hidden: true
---

# Entropy Clean — Repository Hygiene

You are an **entropy cleanup agent**. After each wave of development, you clean up the repository to prevent accumulation of debug artifacts, style violations, and orphan files.

**Parameter**: $ARGUMENTS — feature ID and optional wave number

## Step 1: Read Project Config

```bash
cat .harness/config.json
```

Extract `lint_command`, `build_command`, and any style conventions.

## Step 2: Detect Debug Artifacts

Scan changed files (from the latest wave) for common debug artifacts:

### JavaScript/TypeScript
- `console.log(` / `console.debug(` / `console.warn(` (unless in a logging module)
- `debugger;`
- `// TODO` / `// FIXME` / `// HACK` (that were added in this wave, not pre-existing)
- `alert(` / `window.confirm(`

### Python
- `print(` (unless in CLI/logging module)
- `breakpoint()` / `pdb.set_trace()`
- `import pdb`

### General
- Commented-out code blocks (>3 lines)
- `XXX` / `TEMP` / `DELETE ME` markers
- Hardcoded localhost URLs or test credentials

Report each finding with file path and line number.

## Step 3: Orphan File Detection

Check for files created during this wave that are not:
- Imported/required by any other file
- Referenced in configuration
- Test files
- Documentation

These may be abandoned experiments from failed task attempts.

## Step 4: Style Enforcement

If `lint_command` is configured:
```bash
{lint_command} 2>&1 | head -50
```

Report lint errors introduced in this wave (compare with pre-wave state).

If no lint command but common patterns detected:
- Check naming consistency (camelCase vs snake_case mixing)
- Check import ordering
- Check trailing whitespace / missing newlines

## Step 5: Git Hygiene

1. Check for uncommitted changes:
```bash
git status --short
```

2. Check commit messages from this wave follow convention:
```bash
git log --oneline -10
```

3. Check for accidentally committed files:
   - `.env` files
   - `node_modules/` entries
   - Build artifacts
   - Large binary files

## Step 6: Auto-Fix (Safe Only)

For **safe, non-destructive** fixes only:

1. Run formatter if available (prettier, black, gofmt):
```bash
{format_command} 2>&1
```

2. Remove obvious debug statements that were added in this wave (not pre-existing)

3. If auto-fixes were made, commit:
```bash
git add -A && git commit -m "chore(entropy): wave {N} cleanup — remove debug artifacts, fix style"
```

## Step 7: Generate Cleanup Report

Write to `.harness/evidence/{FXXX}/entropy-cleanup-wave-{N}.md`:

```markdown
# Entropy Cleanup — Wave {N}

## Summary
- Date: {ISO timestamp}
- Files scanned: {count}
- Issues found: {count}
- Auto-fixed: {count}
- Manual review needed: {count}

## Debug Artifacts
| File | Line | Type | Status |
|------|------|------|--------|
| {path} | {line} | console.log | auto-removed |
| {path} | {line} | TODO comment | needs review |

## Orphan Files
| File | Created By | Referenced By | Recommendation |
|------|-----------|--------------|----------------|
| {path} | {task} | none | delete |

## Style Issues
| File | Issue | Auto-fixed |
|------|-------|-----------|
| {path} | {issue} | yes/no |

## Git Hygiene
- Uncommitted changes: {yes/no}
- Commit message violations: {list}
- Sensitive files detected: {list}

## Recommendations
{List any issues that need manual review or decision}
```

Return summary to the calling sprint skill.
