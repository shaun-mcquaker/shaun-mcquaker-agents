# Shaun McQuaker Stack

This repo is the source of truth for Shaun McQuaker's local development environment.

It follows Michael Burjack's stack/layout/install pattern, swaps in mjn's captain-led OpenCode architecture, and layers in selected jrc skills and MCP integrations.

## What Is In Here

| Directory | Purpose |
|---|---|
| `shell/` | Zsh config |
| `nvim/` | Neovim config |
| `ghostty/` | Ghostty config |
| `zellij/` | Zellij config, layouts, plugin assets |
| `bin/` | Local helper scripts like `nv`, `nv-wait`, `work`, `worktree`, and `review` |
| `opencode/` | OpenCode config, agents, commands, skills, plugins |
| `bstack` | Symlink-based installer and config manager |

## OpenCode Shape

The `opencode/` subtree is intentionally synthesized:

- layout/install pattern from `michaelburjack-stack`
- primary philosophy and agent team from `mjn-opencode-config`
- selected review/worktree/data skills and MCP setup from `jrc-opencode-config`

## Quick Start

### 1. Clone the repo

```bash
git clone <repo-url> <local-path>
cd <local-path>
```

### 2. Run the installer

```bash
./bstack install
```

`bstack` walks the managed files, backs up anything already present, and creates symlinks into the expected locations like `~/.config/opencode`, `~/.config/zellij`, `~/.config/nvim`, and `~/.local/bin`.

After install, these workspace launchers should be available on your `PATH`:

```bash
work [path-or-repo]
worktree <repo> <branch>
review <repo> <pr-number>
```

### 3. Install OpenCode plugin dependencies

```bash
cd opencode
bun install      # preferred
# or
npm install
```

### 4. Restart the relevant tools

- restart OpenCode
- restart Zellij or open a fresh shell session
- restart Neovim and Ghostty if you installed those configs

## Local Machine Prerequisites

Recommended baseline:

- Ghostty
- Zellij
- Neovim
- Bun (preferred) or npm
- Node.js / `npx`
- `uv` / `uvx`
- `gh`
- zprezto
- Powerlevel10k

For the bundled Zellij plugin source, rebuilding also needs:

- Rust stable
- `wasm32-wasip1` target
- `wasm-tools`

## OpenCode MCP Setup

Enabled by default in `opencode/opencode.jsonc`:

- `data-portal-mcp`
- `shopify-dev-mcp`
- `slack-mcp`
- `vault-mcp`

Available but disabled by default:

- `sage-mcp`
- `chrome-devtools`

Environment variables you should set in your shell profile:

```bash
export VAULT_MCP_API_TOKEN="your-vault-token"
```

If you enable `sage-mcp`, also make sure your local Sage/proxy auth flow is already working.

## bstack Reference

```bash
bstack install
bstack uninstall
bstack adopt <path>
bstack abandon <path>
bstack manifest
```

## Notes

- OpenCode config is expected at `~/.config/opencode/` via symlink.
- Worktrees are expected under `~/src/worktrees/<repo>/<branch>/`.
- `nv` and `nv-wait` are designed to work with the Zellij/Neovim socket pattern used in this stack.
