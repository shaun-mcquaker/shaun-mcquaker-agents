# OpenCode Agent System

Operating guide for the OpenCode setup in this repo.

This repo is Shaun McQuaker's personal OpenCode, Neovim, Zellij, Ghostty, shell, and helper-script config. The `.agents/` subtree is the canonical home for repo-local OpenCode agents, commands, skills, and knowledge.

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

- `.agents/agents/` - repo-local agent definitions
- `.agents/commands/` - repo-local slash command docs and workflows
- `.agents/skills/` - repo-local skill definitions
- `.agents/knowledge/` - repo-local shared knowledge and supporting docs
- `opencode/opencode.jsonc` - runtime config, MCP setup, defaults
- `opencode/plugins/` - local plugin code
- `bin/` - helper scripts used by the stack, including MCP helpers
- `qstack` - symlink installer/manager for the whole config repo

## Canonical Paths

- `.agents/` is the source of truth for repo-local OpenCode skills, commands, agents, and knowledge.
- If you create a new skill, command, agent, or knowledge file, put it under `.agents/` rather than `opencode/`.
- After creating or renaming a repo-local skill, command, or agent, ask Shaun to run `qstack install` so the global files under `~/.config/opencode/` are refreshed.
- Keep runtime configuration and plugins in `opencode/`; keep repo-local prompt content in `.agents/`.

## Current Repo-Local Inventory

- Skills: `find-skills`
- Commands: `/welcome`
- Agents: none currently checked in
- Knowledge: none currently checked in

Use `find-skills` when the right skill is unclear.

## Stack Notes

- OpenCode runtime config lives in `opencode/opencode.jsonc`.
- `qstack` installs this repo into the live config locations under `~/.config` and `~/.local/bin`.
- Repo-local commands, agents, skills, and knowledge are discovered from `.agents/` and symlinked into `~/.config/opencode/`.
- Worktrees are expected under `~/src/worktrees/<repo>/<branch>/`.
- Remote authenticated MCPs are proxied through `bin/mcp-remote-header-proxy`.

## Repository Pattern

- `.agents/` - repo-local agents, commands, skills, and knowledge
- `opencode/` - OpenCode runtime config and plugins
- `bin/` - helper scripts
- `shell/` - zsh config
- `nvim/` - Neovim config
- `ghostty/` - terminal config
- `zellij/` - multiplexer config, layouts, plugins
- `qstack` - symlink-based installer and config manager
