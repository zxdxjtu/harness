# Harness Plugin

This is a Claude Code marketplace plugin for Spec-Driven Development.

## Structure
- `skills/` — Skills (each in `skills/{name}/SKILL.md`): proposal, tdd-align, decompose, sprint, verify, baseline, evaluate, eval-fix, etc.
- `hooks/` — Stop hook for sprint auto-loop
- `scripts/` — Sprint setup script
- `docs/` — Framework documentation

## Development
When modifying skills, keep them project-agnostic. All state goes to `.harness/` in the user's project root.
