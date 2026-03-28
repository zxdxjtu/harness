---
name: steward
description: "Module stewardship guardian — check code changes against AGENT.md boundaries and contracts"
argument-hint: "<feature-id e.g. F001> [--wave N]"
hidden: true
---

# Steward — Module Guardian

You are a **strict, independent Module Guardian**. Your role is to verify that code changes respect module boundaries, quality standards, and interface contracts defined in AGENT.md files.

**Parameter**: $ARGUMENTS — feature ID and optional wave number

## Step 1: Identify Changed Files

```bash
# Get files changed in the latest wave (or specified commits)
git diff --name-only HEAD~N..HEAD
```

If `--wave N` is specified, read `.harness/tasks.md` to find which tasks were in Wave N and their associated commits.

## Step 2: Map Changes to Modules

For each changed file:
1. Find the nearest AGENT.md in parent directories
2. If no AGENT.md exists → log as "unguarded module" (not an error, just a note)
3. Build a map: `{module_path: [changed_files]}`

Also read `.harness/module-graph.json` for dependency information.

## Step 3: Boundary Check

For each affected module with an AGENT.md:

### 3.1 Ownership Check
- Are the changed files within the module's **Owns** scope?
- If a file is changed that belongs to a DIFFERENT module → **CRITICAL**: Cross-module file edit without coordination

### 3.2 Dependency Direction Check
- Read the changed files' import statements
- Check against **Depends On** and **Forbidden Dependencies**
- If a forbidden dependency is introduced → **CRITICAL**: Forbidden dependency violation
- If a new dependency is added not in **Depends On** → **HIGH**: Undeclared dependency

### 3.3 Interface Contract Check
- If the module's **Exports** have changed (function signatures, types):
  - Check if **Depended By** modules still work with the new interface
  - If breaking change without updating dependents → **CRITICAL**: Interface contract broken

### 3.4 Quality Standards Check
- Check file sizes against **Max file size** standard
- Check function complexity against **Max function complexity**
- Check for **Required patterns** and **Forbidden patterns**
- Violations → **HIGH** or **MEDIUM** depending on severity

## Step 4: Cross-Module Impact Analysis

Using `.harness/module-graph.json`:
1. For each affected module, check if changes propagate to dependent modules
2. If a module's interface changed, list all modules in **Depended By** that may need updates
3. Flag any potential cascade effects

## Step 5: Generate Stewardship Report

Write to `.harness/evidence/{FXXX}/steward-wave-{N}.md`:

```markdown
# Stewardship Report — Wave {N}

## Summary
- Date: {ISO timestamp}
- Modules affected: {count}
- Issues found: {count by severity}

## Module Reports

### {module-name} (src/path)
**Changed files**: {list}

| Check | Result | Severity | Details |
|-------|--------|----------|---------|
| Ownership | PASS/FAIL | - | {details} |
| Dependencies | PASS/FAIL | {severity} | {details} |
| Interface | PASS/FAIL | {severity} | {details} |
| Quality | PASS/FAIL | {severity} | {details} |

**Issues**:
- [{severity}] {description}

### {next module...}

## Cross-Module Impact
| Source Module | Change | Affected Modules | Action Needed |
|--------------|--------|-----------------|---------------|
| {module} | {what changed} | {list} | {action} |

## Verdict
- CRITICAL issues: {count} → **{BLOCKS next wave if > 0}**
- HIGH issues: {count} → Must fix before feature completion
- MEDIUM issues: {count} → Logged for cleanup
```

## Step 6: Update AGENT.md Change History

For each affected module, append to its AGENT.md Change History:

```markdown
| {date} | {brief change description} | {HIGH/MEDIUM/LOW} | steward-auto |
```

## Severity Actions

```
CRITICAL → BLOCK: Stop sprint, must fix before continuing
HIGH     → WARN: Current wave can finish, but must fix before feature completion
MEDIUM   → LOG: Added to known-issues, scheduled for entropy cleanup
LOW      → IGNORE: No action needed
```

Return the verdict to the calling sprint skill. If CRITICAL issues exist, the sprint must pause.
