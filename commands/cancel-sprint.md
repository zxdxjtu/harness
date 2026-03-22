---
description: "Cancel an active sprint loop"
allowed-tools: ["Bash(test -f .harness/sprint-loop.md:*)", "Bash(rm .harness/sprint-loop.md)", "Read(.harness/sprint-loop.md)"]
hide-from-slash-command-tool: "true"
---

# Cancel Sprint

1. Check if `.harness/sprint-loop.md` exists: `test -f .harness/sprint-loop.md && echo "EXISTS" || echo "NOT_FOUND"`

2. **If NOT_FOUND**: Say "No active sprint loop found."

3. **If EXISTS**:
   - Read `.harness/sprint-loop.md` to get current iteration and wave
   - Remove the file: `rm .harness/sprint-loop.md`
   - Report: "Cancelled sprint loop (was at iteration N, wave M)"
   - Append cancellation to `.harness/progress.md`
