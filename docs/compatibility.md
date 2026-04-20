# Compatibility Guide

Harness is designed as a shared workflow package with **tool-specific packaging**.

The canonical workflow content lives in:

- `skills/`
- `hooks/`
- `scripts/`
- `templates/`

The repository then exposes those assets in the formats different agents expect.

## Support Matrix

| Tool | Packaging entrypoint | Notes |
|------|----------------------|-------|
| Claude Code | `.claude-plugin/plugin.json` | Full native plugin support |
| Codex | `.codex-plugin/plugin.json` | Native plugin bundle support |
| OpenCode | `.agents/skills/*/SKILL.md` | Skill discovery, not Claude/Codex-style plugin manifests |

## Claude Code

Claude Code remains the most feature-complete target for Harness.

Native capabilities used here:

- marketplace plugin manifest
- slash commands backed by skills
- hook execution
- `${CLAUDE_PLUGIN_ROOT}` path resolution

Files:

- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `hooks/hooks.json`

## Codex

Codex compatibility is provided through a native `.codex-plugin/plugin.json` manifest.

Important differences from Claude Code:

- Codex plugins package skills, apps, and MCP config, but its workflow surface is not a one-to-one clone of Claude slash commands.
- Codex currently centers reusable workflows around skills and plugins rather than Claude-style command registries.
- The Claude-specific hook config is not declared in the Codex manifest because the hook contract and path variables are different.

Current recommendation:

1. Clone this repository into a local Codex plugin directory.
2. Activate it using the Codex plugin install flow available in your version.
3. Use the Harness skills from Codex's native skill/plugin UX.

Files:

- `.codex-plugin/plugin.json`

## OpenCode

OpenCode does not use Claude/Codex plugin manifests for this kind of workflow package.

Instead, OpenCode discovers skills from:

- `.opencode/skills/`
- `.claude/skills/`
- `.agents/skills/`
- their global equivalents

To make Harness directly discoverable without rewriting the workflow as an OpenCode JavaScript plugin, this repository exposes the skill set via `.agents/skills/`.

This keeps one canonical implementation in `skills/` while allowing OpenCode's existing agent-compatible skill discovery to pick it up.

## Design Principles

- Keep workflow source canonical in one place.
- Add native manifests where the host supports installable plugins.
- Avoid pretending the host surfaces are identical when they are not.
- Prefer skill-level portability over command-surface emulation.
- Keep Claude-specific hooks isolated instead of leaking them into other runtimes.
