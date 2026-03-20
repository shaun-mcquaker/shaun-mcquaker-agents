# OpenCode Agent System

Operating guide for the OpenCode setup in this repo.

This repo is Shaun McQuaker's personal OpenCode, Neovim, Zellij, Ghostty, shell, and helper-script config. The `opencode/` subtree is the source of truth for the OpenCode side of that setup.

## Who You're Working With

Shaun McQuaker.

Optimize for leverage, clarity, and forward motion. Prefer direct recommendations, brief trade-offs, and the next concrete action when useful.

When drafting messages for collaborators, keep them concise, plainspoken, and useful.

## Communication

- Be concise and decisive.
- Lead with the recommendation, then the reason.
- Prefer practical language over flourish.
- For reviews and docs, explain impact and follow-up clearly.
- When multiple valid paths exist, recommend one.

## Repo Context

This repo is not an app codebase. It is a local tooling/config repo.

The most important paths for OpenCode work are:

- `opencode/agents/` - agent definitions
- `opencode/commands/` - command docs and workflows
- `opencode/skills/` - reusable skill instructions
- `opencode/plugins/` - local plugin code
- `opencode/opencode.jsonc` - runtime config, MCP setup, defaults
- `bin/` - helper scripts used by the stack, including MCP helpers
- `qstack` - symlink installer/manager for the whole config repo

## Agents

### Core Team

| Agent | Purpose | Writes Code |
|-------|---------|-------------|
| **captain** | Orchestrator for delegated implementation work | Small config edits only |
| **explore** | Fast codebase mapping and file/pattern search | No |
| **architect** | Strategic debugging, design choice, and audits | No |
| **librarian** | Documentation, research, and implementation examples | No |
| **backend** | Server, API, data, and systems implementation | Yes |
| **frontend** | UI, layout, styling, and interaction work | Yes |
| **critic** | Review gate after implementation | No |
| **scribe** | Documentation and technical writing | Yes |
| **looker** | Visual analysis for images, PDFs, and screenshots | No |

### Research Team

| Agent | Purpose |
|-------|---------|
| **research-lead** | Orchestrates deep research workflows |
| **visionary** | Expansive, idea-generating research |
| **pragmatist** | Constraint-aware, feasibility-focused research |

### PR Review Team

| Agent | Purpose |
|-------|---------|
| **pr-reviewer** | Orchestrates full PR reviews |
| **pr-repo-scout** | Finds repo conventions and local patterns |
| **pr-history-analyst** | Mines prior review patterns |
| **pr-security-auditor** | Reviews auth, secrets, and risk surfaces |
| **pr-performance-analyst** | Reviews performance-sensitive changes |

## Delegation Rules

| Pattern | Delegate To |
|---------|-------------|
| find, search, where, map, structure | `explore` |
| how does X work, docs, best practices | `librarian` |
| stuck, not working, trade-off, debugging | `architect` |
| API, database, migrations, server work | `backend` -> then `critic` |
| React, CSS, component, page, layout, animation | `frontend` -> then `critic` |
| write docs, README, guide, explanation | `scribe` |
| screenshot, PDF, image, diagram | `looker` |
| deep exploration of an idea or project | `research-lead` |
| review a PR | `pr-reviewer` |

Rule of thumb: use specialists for meaningful work. If implementation spans multiple files or significant logic, delegate instead of doing everything in the coordinator.

Critique loop: implementation -> `critic` review -> fix -> re-review. Escalate after three loops if still stuck.

## Skills In This Repo

Current active skills include:

- `beads`
- `deep-research`
- `find-skills`
- `frontend-design`
- `logseq-journal`
- `pr-review`
- `pr-workflow`
- `research-export`
- `using-git-worktrees`

There are also a few repo-specific workflow skills such as `checkin`, `data-mapping`, `slack-integration`, and `vault-post`.

Use `find-skills` when the right skill is unclear.

## Commands In This Repo

Notable command docs live in `opencode/commands/`, including workflows for:

- delegation checks
- journaling and session handoff
- research export and resume flows
- PR and branch review
- dependency updates

## Stack Notes

- OpenCode runtime config lives in `opencode/opencode.jsonc`.
- The current OpenCode default agent is configured there, not in this document.
- `qstack` installs this repo into the live config locations under `~/.config` and `~/.local/bin`.
- Worktrees are expected under `~/src/worktrees/<repo>/<branch>/`.
- Remote authenticated MCPs are proxied through `bin/mcp-remote-header-proxy`.

## Repository Pattern

- `bin/` - helper scripts
- `shell/` - zsh config
- `nvim/` - Neovim config
- `ghostty/` - terminal config
- `zellij/` - multiplexer config, layouts, plugins
- `opencode/` - OpenCode config, agents, commands, skills, plugins
- `qstack` - symlink-based installer and config manager
