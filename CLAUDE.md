# Harness Plugin

This is a Claude Code marketplace plugin for Spec-Driven Development.

## Structure
- `commands/` — Slash commands (proposal, tdd-align, decompose, sprint, verify, etc.)
- `hooks/` — Stop hook for sprint auto-loop
- `scripts/` — Sprint setup script
- `docs/` — Framework documentation

## Development
When modifying commands, keep them project-agnostic. All state goes to `.harness/` in the user's project root.
