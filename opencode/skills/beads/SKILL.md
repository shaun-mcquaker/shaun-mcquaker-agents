---
name: beads
description: Dependency-aware task tracking that persists across sessions. Use when planning multi-step work, breaking down complex tasks, tracking discovered work, or needing persistence beyond the current session. Works with or without git. Activates for "plan this", "break down", "TODO", "track", "multi-step tasks", "dependencies", or in directories with .beads/.
license: MIT
metadata:
  category: global
---

# Beads Issue Tracking

Beads (`bd`) is a dependency-aware issue tracker for AI agent workflows. It persists across sessions and optionally syncs with Git.

## Quick Start

```bash
# Check what's ready to work on
bd ready

# Create a new issue
bd create "Description" -t task -p 2

# Close when done
bd close <id> --reason "Completed"
```

## Issue Types

| Type | Use For |
|------|---------|
| `bug` | Something broken |
| `feature` | New capability |
| `task` | General work item |
| `epic` | Large multi-issue effort |
| `chore` | Maintenance, cleanup |

## Priority Levels

| Priority | Meaning |
|----------|---------|
| 0 | Critical - drop everything |
| 1 | High - do soon |
| 2 | Medium - normal work (default) |
| 3 | Low - when time permits |
| 4 | Backlog - someday |

## Workflow Rules

1. **Use `bd` for ALL task tracking** - not markdown TODOs or comments
2. **Check ready work first**: `bd ready --json`
3. **Track discovered work**: When you find something that needs fixing while working on another issue:
   ```bash
   bd create "Found issue" -t task -p 2 --deps discovered-from:<current-id>
   ```
4. **Close with reason**: Always explain what was done
5. **Use dependencies**: `--deps blocks:<id>`, `--deps parent:<id>`, `--deps related:<id>`

## Key Commands

```bash
bd ready              # Show unblocked issues ready for work
bd ready --json       # JSON output for programmatic use
bd list               # Show all issues
bd list --status in_progress  # Filter by status
bd show <id>          # Details on specific issue
bd create "desc" -t type -p priority  # Create issue
bd close <id> --reason "why"  # Complete issue
bd prime              # Inject context (1-2k tokens) for agent sessions
bd prime --stealth    # Silent context injection
```

## Storage

Beads stores issues in `.beads/issues.jsonl` (can be git-tracked or local-only with `--stealth`). The SQLite database is for fast queries only - JSONL is the source of truth.

## Integration with Other Systems

- **TodoWrite**: Use for in-session task tracking (ephemeral)
- **Beads**: Use for cross-session persistence (file-backed, optionally git-tracked)
- **Droids**: When droids find issues, create beads for action items
- **Council**: After council sessions, capture next moves as beads

## Best Practice

Store AI-generated planning/design docs in a `history/` directory in the repo, not in beads. Beads tracks *what* needs doing; `history/` tracks *how* decisions were made.
