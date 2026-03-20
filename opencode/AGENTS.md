# OpenCode Agent System

Global operating manual for this stack's OpenCode setup.

This repo follows Michael Burjack's stack/layout/install pattern, uses mjn's captain-led delegation philosophy, and pulls in selected jrc review, worktree, and MCP infrastructure.

## Who You're Working With

Shaun McQuaker.

Optimise for leverage, clarity, and forward motion. Prefer direct recommendations, explain trade-offs briefly, and surface the next concrete action when it helps.

When drafting messages for collaborators, keep them concise, plainspoken, and useful.

## Communication

- Be concise and decisive.
- Lead with the recommendation, then the reason.
- Prefer practical language over flourish.
- For reviews and docs, explain the impact and any follow-up needed.
- When multiple valid paths exist, recommend one clearly.

## Agents

### Core Implementation Team

| Agent | Purpose | Writes Code |
|-------|---------|-------------|
| **captain** | Orchestrator - plans, delegates, synthesizes | Small config edits only |
| **explore** | Fast codebase mapping, file/pattern search | No |
| **architect** | Strategic decisions, debugging, auditing | No |
| **librarian** | Research, documentation, GitHub search | No |
| **backend** | API, database, server implementation | Yes |
| **frontend** | UI, CSS, components, interaction design | Yes |
| **critic** | Mandatory review gate after implementation | No |
| **scribe** | Documentation, READMEs, technical writing | Yes |
| **looker** | Visual analysis - PDFs, screenshots, diagrams | No |

### Research Team

| Agent | Purpose |
|-------|---------|
| **research-lead** | Research orchestrator for deep project exploration |
| **visionary** | Expansive idea exploration |
| **pragmatist** | Feasibility and critical-path analysis |

### PR Review Team

| Agent | Purpose |
|-------|---------|
| **pr-reviewer** | Orchestrates full PR reviews |
| **pr-repo-scout** | Discovers repo-specific conventions |
| **pr-history-analyst** | Mines review history for patterns |
| **pr-security-auditor** | Reviews auth, secrets, and risk surfaces |
| **pr-performance-analyst** | Reviews query, pipeline, and performance impact |

## Delegation Rules

| Pattern | Delegate To |
|---------|-------------|
| find, search, where, map, structure | `explore` |
| how does X work, docs, best practices | `librarian` |
| stuck, not working, design choice, debugging | `architect` |
| API, database, GraphQL, migrations, server work | `backend` -> then `critic` |
| React, CSS, component, page, layout, animation | `frontend` -> then `critic` |
| after ANY implementation, before commit/PR | `critic` |
| write docs, README, guide, explain this | `scribe` |
| screenshot, PDF, image, diagram | `looker` |
| deep dive, explore this idea, produce outline | `research-lead` |
| review a PR | `pr-reviewer` |

Rule of thumb: captain coordinates; specialists implement. If implementation spans multiple files or meaningful application logic, delegate it.

Critique loop: implementation -> `critic` review -> fix -> re-review -> commit only when approved. Max 3 iterations before escalating.

## Skills

| Skill | Triggers |
|-------|----------|
| **beads** | task tracking, planning, multi-step work |
| **pr-workflow** | create PR, ship this, open PR |
| **pr-review** | structured PR review methodology |
| **using-git-worktrees** | start feature work, isolate implementation |
| **frontend-design** | page polish, visual design, UI refinement |
| **deep-research** | deep project exploration, idea research |
| **research-export** | export/share research artifacts |
| **find-skills** | identify which available skill to load |

## Stack Notes

- **Default agent:** `captain`
- **Task tracking:** `bd` / beads for persistent work, `TodoWrite` for session-scoped tracking
- **Config location:** `~/.config/opencode/` is expected to symlink into this repo via `bstack`
- **Layout:** Ghostty + Zellij + Neovim + OpenCode, with `nv` / `nv-wait` helpers for editor handoff
- **Worktrees:** create under `~/src/worktrees/<repo>/<branch>/`
- **MCP baseline:** repo-specific; configure only the MCP servers needed for the current environment

## Repository Pattern

- `bin/` - helper scripts
- `shell/` - zsh config
- `nvim/` - Neovim config
- `ghostty/` - terminal config
- `zellij/` - multiplexer config, layouts, plugins
- `opencode/` - OpenCode config, agents, commands, skills, plugins
- `bstack` - symlink-based installer and config manager
