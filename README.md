# Shaun McQuaker Agents

This repo is Shaun McQuaker's personal local tooling and AI workflow config.

It manages the dotfiles and helper scripts that power:

- OpenCode configuration, agents, commands, skills, and plugins
- Neovim configuration
- Zellij layouts and plugin source
- Ghostty configuration
- shell and prompt setup
- local helper scripts for editor, worktree, review, and MCP workflows

`qstack` is the installer and symlink manager for this repo.

## What This Repo Actually Does

This is not an application repo.

It is a workstation/config repo that keeps Shaun's local development environment in version control and wires those files into the expected locations under `~/.config`, `~/.local/bin`, and `~/.zprezto/runcoms`.

The most important subtree is `opencode/`, which contains:

- agent definitions in `opencode/agents/`
- slash-style command docs in `opencode/commands/`
- reusable skills in `opencode/skills/`
- OpenCode runtime config in `opencode/opencode.jsonc`
- local plugin code in `opencode/plugins/`

## Repository Layout

| Path | Purpose |
|---|---|
| `qstack` | Installs and manages symlinks for the stack |
| `bin/` | Helper scripts like `nv`, `nv-wait`, `work`, `worktree`, `review`, and `mcp-remote-header-proxy` |
| `shell/` | Zsh and prompt config |
| `nvim/` | Neovim config |
| `ghostty/` | Ghostty config |
| `zellij/` | Zellij config, layouts, and plugin source/assets |
| `opencode/` | OpenCode config, agents, commands, skills, and plugins |

## qstack

`qstack` is the entry point for installing this repo's managed files onto a machine.

Typical commands:

```bash
./qstack install
./qstack uninstall
./qstack adopt <path>
./qstack abandon <path>
./qstack manifest
```

What it manages:

- `~/.config/opencode/`
- `~/.config/nvim/`
- `~/.config/zellij/`
- `~/.config/ghostty/`
- `~/.local/bin/`
- `~/.zprezto/runcoms/`
- `~/.p10k.zsh`

It stores its manifest in `~/.config/qstack/manifest` and will copy the old `~/.config/bstack/manifest` forward if that legacy file exists.

## OpenCode Setup

The OpenCode config in this repo is opinionated around a specialist-agent workflow.

Current highlights:

- repo-local agents live in `opencode/agents/`
- reusable workflow skills live in `opencode/skills/`
- custom commands live in `opencode/commands/`
- the `opencode-beads` plugin is enabled
- local plugin code currently includes `opencode/plugins/zellij-tab-status.ts`
- MCP servers are configured in `opencode/opencode.jsonc`

The current MCP config includes:

- `alphaxiv-mcp`
- `anydb-mcp`
- `dsv-mcp`
- `shaun-mcp`

The remote authenticated MCPs are launched through `bin/mcp-remote-header-proxy`.

## Neovim, Zellij, and Shell

- `nvim/` contains the full Neovim config, including plugin setup and keymaps
- `zellij/` contains the main config, layouts, and the tab-title plugin source/assets
- `shell/` contains zprezto runcoms and Powerlevel10k config
- `bin/nv` and `bin/nv-wait` are designed to work with the local Neovim/Zellij workflow

## Machine Prerequisites

Recommended baseline:

- `git`
- `zsh`
- `zprezto`
- `gh`
- `node` / `npx`
- `bun` or `npm`
- `nvim`
- `zellij`
- `ghostty`

For the bundled Zellij plugin source, rebuilding also needs:

- Rust stable
- `wasm32-wasip1` target
- `wasm-tools`

## First-Time Setup

```bash
git clone <repo-url> <local-path>
cd <local-path>
./qstack install
```

Then install OpenCode plugin dependencies:

```bash
cd opencode
bun install
# or: npm install
```

After that, restart the tools that consume the config:

- OpenCode
- Neovim
- Zellij
- Ghostty
- any shell sessions using the managed zsh config

## Notes

- This repo is intended to be the source of truth for the managed local config it installs.
- `opencode/opencode.jsonc` is the canonical place for OpenCode runtime defaults and MCP configuration.
- `qstack` dynamically discovers many OpenCode commands, agents, and skills instead of hardcoding every file.
