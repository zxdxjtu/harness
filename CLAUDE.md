# Harness Plugin

Harness now targets multiple agent hosts.

## Canonical Source Layout

- `skills/` — canonical workflow definitions
- `hooks/` — Claude-specific hook config and scripts
- `scripts/` — shared automation helpers
- `templates/` — spec, design, and evaluation templates
- `docs/` — framework and compatibility documentation

## Packaging Targets

- `.claude-plugin/` — Claude Code plugin manifest and marketplace metadata
- `.codex-plugin/` — Codex plugin manifest
- `.agents/skills/` — agent-compatible skill discovery view for Codex/OpenCode-style loaders

## Development Rules

- Keep workflow logic canonical in `skills/`.
- Treat `.claude-plugin/` and `.codex-plugin/` as packaging layers.
- Keep Claude-specific hooks isolated from Codex/OpenCode packaging.
- Keep skills project-agnostic. All runtime state belongs in `.harness/` inside the user's project.
