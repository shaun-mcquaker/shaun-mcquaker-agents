#!/usr/bin/env zsh
# dev-session: open (or attach to) a named zellij dev session for a project directory
#
# Usage:
#   work [path]    - open dev session rooted at path (default: current directory)
#   work           - open dev session rooted at $PWD
#
# Session name is derived from the directory basename with non-alphanumeric chars
# replaced by hyphens. Collisions across different absolute paths with the same
# basename are unlikely in practice; if needed, use a more unique derivation.

work() {
  local target_dir="${1:-$PWD}"
  local requested_target="${1-}"

  if [[ -n "$requested_target" && ! -d "$target_dir" ]]; then
    # Not a local path — try resolving via dev cd -n
    local resolved
    resolved="$(dev cd -n "$requested_target" 2>/dev/null)"
    if [[ -n "$resolved" && -d "$resolved" ]]; then
      target_dir="$resolved"
    else
      echo "work: not a directory and could not resolve via dev cd: $requested_target" >&2
      return 1
    fi
  fi

  target_dir="$(realpath "$target_dir")"

  if [[ ! -d "$target_dir" ]]; then
    echo "work: not a directory: $target_dir" >&2
    return 1
  fi

  # Derive session name from basename, sanitized
  # Special-case: home directory gets a friendlier name
  local session_name
  if [[ "$target_dir" == "$HOME" ]]; then
    session_name="Bridge"
  else
    session_name="$(basename "$target_dir" | tr -cs '[:alnum:]' '-' | sed 's/-$//')"
  fi

  # Generate a temporary layout KDL with the correct cwd
  local tmp_layout="/tmp/zellij-layout-${session_name}.kdl"
  rm -f "$tmp_layout"

  cat > "$tmp_layout" <<KDL
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    tab name="$session_name" {
        pane split_direction="vertical" {
            pane cwd="$target_dir" {
                name "nvim"
                command "bash"
                args "-c" "ZELLIJ_TAB_NAME='$session_name' NVIM_SOCKET_PATH='/tmp/nvim-${session_name}.sock' rm -f '/tmp/nvim-${session_name}.sock'; exec nvim --listen '/tmp/nvim-${session_name}.sock'"
                size "50%"
            }
            pane split_direction="horizontal" {
                pane cwd="$target_dir" {
                    name "opencode"
                    command "bash"
                    args "-c" "export ZELLIJ_TAB_NAME='$session_name' NVIM_SOCKET_PATH='/tmp/nvim-${session_name}.sock'; if command -v devx >/dev/null 2>&1; then exec devx opencode; elif command -v opencode >/dev/null 2>&1; then exec opencode; else echo 'opencode not found' >&2; exit 127; fi"
                    size "60%"
                }
                pane cwd="$target_dir" focus=true {
                    name "shell"
                    command "bash"
                    args "-c" "export ZELLIJ_TAB_NAME='$session_name' NVIM_SOCKET_PATH='/tmp/nvim-${session_name}.sock'; if [ -f dev.yml ]; then dev up; fi; exec zsh"
                }
            }
        }
    }
}
KDL

  if [[ -n "${ZELLIJ-}" ]]; then
    # Already inside a session — open as a new tab, then clean up
    zellij action new-tab --layout "$tmp_layout" --name "$session_name"
  else
    # Check if the "work" session already exists (running or exited) — strip ANSI codes before grepping
    if zellij list-sessions 2>/dev/null | sed $'s/\x1b\\[[0-9;]*m//g' | grep -qF "work"; then
      rm -f "$tmp_layout"
      zellij attach "work"
      return
    fi
    zellij -s "work" --new-session-with-layout "$tmp_layout"
  fi

  rm -f "$tmp_layout"
}

# worktree: create (or reuse) a git worktree for a repo+branch, and open a Zellij tab for it
#
# Usage:
#   worktree <repo> <branch>        - create/reuse worktree, open Zellij tab
#   worktree --list                 - list all worktrees across all repos
#   worktree --clean                - prune worktrees whose branches are merged/gone
#
# Worktrees live under ~/src/worktrees/<repo>/<sanitized-branch>/
# Tab names follow the pattern <repo>:<sanitized-branch>
# nvim sockets: /tmp/nvim-<repo>-<sanitized-branch>.sock

# Sanitize a branch name: lowercase, replace non-alphanumeric-hyphen with hyphen,
# collapse consecutive hyphens, strip leading/trailing hyphens.
_worktree_sanitize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '-' | sed 's/^-//;s/-$//;s/--*/-/g'
}

worktree() {
  # --- Subcommands ---
  if [[ $# -gt 0 && "$1" == "--list" ]]; then
    local worktree_root="$HOME/src/worktrees"
    if [[ ! -d "$worktree_root" ]]; then
      echo "No worktrees found."
      return 0
    fi
    echo "Worktrees:"
    echo ""
    for repo_dir in "$worktree_root"/*/; do
      [[ -d "$repo_dir" ]] || continue
      local repo_name="$(basename "$repo_dir")"
      for wt_dir in "$repo_dir"*/; do
        [[ -d "$wt_dir/.git" || -f "$wt_dir/.git" ]] || continue
        local branch_slug="$(basename "$wt_dir")"
        local last_commit="$(git -C "$wt_dir" log -1 --format='%cr — %s' 2>/dev/null || echo 'unknown')"
        echo "  ${repo_name}:${branch_slug}  ($last_commit)"
      done
    done
    return 0
  fi

  if [[ $# -gt 0 && "$1" == "--clean" ]]; then
    local worktree_root="$HOME/src/worktrees"
    if [[ ! -d "$worktree_root" ]]; then
      echo "No worktrees found."
      return 0
    fi
    local count=0
    for repo_dir in "$worktree_root"/*/; do
      [[ -d "$repo_dir" ]] || continue
      local repo_name="$(basename "$repo_dir")"
      for wt_dir in "$repo_dir"*/; do
        [[ -d "$wt_dir/.git" || -f "$wt_dir/.git" ]] || continue
        local branch_slug="$(basename "$wt_dir")"
        local branch="$(git -C "$wt_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
        # Check if branch has been merged into main/master
        local main_repo
        main_repo="$(git -C "$wt_dir" worktree list --porcelain 2>/dev/null | head -1 | awk '{print $2}')"
        if [[ -z "$main_repo" ]]; then
          continue
        fi
        local merged=false
        if git -C "$main_repo" branch --merged main 2>/dev/null | grep -qF "$branch"; then
          merged=true
        elif git -C "$main_repo" branch --merged master 2>/dev/null | grep -qF "$branch"; then
          merged=true
        fi
        if $merged; then
          echo -n "  Remove ${repo_name}:${branch_slug} (merged)? [y/N] "
          read -r answer
          if [[ "$answer" == [yY] ]]; then
            git -C "$main_repo" worktree remove "$wt_dir" 2>/dev/null && echo "    Removed." || echo "    Failed — try manually."
            count=$((count + 1))
          fi
        fi
      done
    done
    if [[ $count -eq 0 ]]; then
      echo "No stale worktrees found."
    else
      echo "Cleaned up $count worktree(s)."
    fi
    return 0
  fi

  # --- Main: create/reuse worktree ---
  if [[ $# -lt 2 ]]; then
    echo "Usage: worktree <repo> <branch> [--prompt \"message\"]" >&2
    echo "       worktree --list" >&2
    echo "       worktree --clean" >&2
    return 1
  fi

  local repo="$1"
  local branch="$2"
  shift 2

  # Parse optional --prompt flag
  local oc_prompt=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt)
        oc_prompt="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  local sanitized_branch
  sanitized_branch="$(_worktree_sanitize "$branch")"

  # Resolve main repo path — try dev cd, then common locations
  local main_repo_dir
  main_repo_dir="$(dev cd -n "$repo" 2>/dev/null)"
  if [[ -z "$main_repo_dir" || ! -d "$main_repo_dir" ]]; then
    local repo_candidates=(
      "$HOME/src/github.com"/*/"$repo"(N)
      "$HOME/src"/*/"$repo"(N)
    )
    if (( ${#repo_candidates[@]} > 0 )); then
      main_repo_dir="$repo_candidates[1]"
    else
      echo "worktree: cannot find repo '$repo'" >&2
      return 1
    fi
  fi

  local worktree_dir="$HOME/src/worktrees/$repo/$sanitized_branch"
  local tab_name="${repo}:${sanitized_branch}"
  local socket_name="${repo}-${sanitized_branch}"

  # Check if worktree already exists
  if [[ -d "$worktree_dir" && ( -d "$worktree_dir/.git" || -f "$worktree_dir/.git" ) ]]; then
    echo "Reusing existing worktree: $worktree_dir"
  else
    # Create the worktree
    mkdir -p "$(dirname "$worktree_dir")"

    # Check if branch exists remotely or locally
    if git -C "$main_repo_dir" show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
      # Local branch exists — check it out
      git -C "$main_repo_dir" worktree add "$worktree_dir" "$branch"
    elif git -C "$main_repo_dir" show-ref --verify --quiet "refs/remotes/origin/$branch" 2>/dev/null; then
      # Remote branch exists — create tracking branch
      git -C "$main_repo_dir" worktree add "$worktree_dir" -b "$branch" "origin/$branch"
    else
      # New branch — create from main/master
      local base_branch="main"
      if ! git -C "$main_repo_dir" show-ref --verify --quiet "refs/heads/main" 2>/dev/null; then
        base_branch="master"
      fi
      git -C "$main_repo_dir" worktree add "$worktree_dir" -b "$branch" "$base_branch"
    fi

    if [[ $? -ne 0 ]]; then
      echo "worktree: failed to create worktree" >&2
      return 1
    fi
    echo "Created worktree: $worktree_dir"
  fi

  # Open Zellij tab (or switch to existing one)
  if [[ -z "${ZELLIJ-}" ]]; then
    echo "Not inside Zellij — worktree is at: $worktree_dir"
    echo "cd $worktree_dir"
    return 0
  fi

  # Write prompt to temp file if provided (avoids quoting issues in KDL heredoc)
  local oc_prompt_file=""
  if [[ -n "$oc_prompt" ]]; then
    oc_prompt_file="${TMPDIR}opencode-prompt-${socket_name}.txt"
    printf '%s' "$oc_prompt" > "$oc_prompt_file"
  fi

  # Check if tab already exists by name — if so, just switch
  # (zellij doesn't have a clean "switch to tab by name" API, so we create if not found)
  local tmp_layout="/tmp/zellij-layout-${socket_name}.kdl"
  rm -f "$tmp_layout"

  cat > "$tmp_layout" <<KDL
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="zellij:tab-bar"
        }
        children
        pane size=2 borderless=true {
            plugin location="zellij:status-bar"
        }
    }
    tab name="$tab_name" {
        pane split_direction="vertical" {
            pane cwd="$worktree_dir" {
                name "nvim"
                command "bash"
                args "-c" "ZELLIJ_TAB_NAME='$tab_name' NVIM_SOCKET_PATH='/tmp/nvim-${socket_name}.sock' rm -f '/tmp/nvim-${socket_name}.sock'; exec nvim --listen '/tmp/nvim-${socket_name}.sock'"
                size "50%"
            }
            pane split_direction="horizontal" {
                pane cwd="$worktree_dir" {
                    name "opencode"
                    command "bash"
                    args "-c" "export ZELLIJ_TAB_NAME='$tab_name' NVIM_SOCKET_PATH='/tmp/nvim-${socket_name}.sock'; if command -v devx >/dev/null 2>&1; then exec devx opencode${oc_prompt_file:+ --prompt \"\$(cat $oc_prompt_file)\"}; elif command -v opencode >/dev/null 2>&1; then exec opencode${oc_prompt_file:+ --prompt \"\$(cat $oc_prompt_file)\"}; else echo 'opencode not found' >&2; exit 127; fi"
                    size "60%"
                }
                pane cwd="$worktree_dir" focus=true {
                    name "shell"
                    command "bash"
                    args "-c" "export ZELLIJ_TAB_NAME='$tab_name' NVIM_SOCKET_PATH='/tmp/nvim-${socket_name}.sock'; if [ -f dev.yml ]; then dev up; fi; exec zsh"
                }
            }
        }
    }
}
KDL

  zellij action new-tab --layout "$tmp_layout" --name "$tab_name"
  rm -f "$tmp_layout"
}

# review: open a PR for review in an isolated worktree with the PR review skill pre-loaded
#
# Usage:
#   review <repo> <pr-number>                              - fetch PR, create worktree, launch review
#   review <repo> <pr-number> --channel <id> --ts <ts>     - include Slack context for :eyes: signaling
#
# Example:
#   review growth-labs-sdp 3377
#   review growth-labs-sdp 3377 --channel C035SJYJ2SK --ts 1773933579.000086

review() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: review <repo> <pr-number> [--channel <id> --ts <ts>]" >&2
    return 1
  fi

  local repo="$1"
  local pr_number="$2"
  shift 2

  # Parse optional Slack context
  local slack_channel="" slack_ts=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --channel) slack_channel="$2"; shift 2 ;;
      --ts)      slack_ts="$2"; shift 2 ;;
      *)         shift ;;
    esac
  done

  # Resolve main repo path (same logic as worktree)
  local main_repo_dir
  main_repo_dir="$(dev cd -n "$repo" 2>/dev/null)"
  if [[ -z "$main_repo_dir" || ! -d "$main_repo_dir" ]]; then
    local repo_candidates=(
      "$HOME/src/github.com"/*/"$repo"(N)
      "$HOME/src"/*/"$repo"(N)
    )
    if (( ${#repo_candidates[@]} > 0 )); then
      main_repo_dir="$repo_candidates[1]"
    else
      echo "review: cannot find repo '$repo'" >&2
      return 1
    fi
  fi

  # Fetch PR metadata
  echo "Fetching PR #${pr_number} metadata..."
  local pr_json
  pr_json="$(gh pr view "$pr_number" --repo "$(git -C "$main_repo_dir" remote get-url origin | sed 's|.*github.com[:/]||;s|\.git$||')" --json headRefName,title,author,url 2>&1)"
  if [[ $? -ne 0 ]]; then
    echo "review: failed to fetch PR #${pr_number}: $pr_json" >&2
    return 1
  fi

  local branch title author pr_url
  branch="$(echo "$pr_json" | jq -r '.headRefName')"
  title="$(echo "$pr_json" | jq -r '.title')"
  author="$(echo "$pr_json" | jq -r '.author.login')"
  pr_url="$(echo "$pr_json" | jq -r '.url')"

  if [[ -z "$branch" || "$branch" == "null" ]]; then
    echo "review: could not determine branch for PR #${pr_number}" >&2
    return 1
  fi

  echo "PR #${pr_number}: \"${title}\" by ${author}"
  echo "Branch: ${branch}"

  # Fetch the branch so the worktree can check it out
  git -C "$main_repo_dir" fetch origin "$branch" 2>/dev/null

  # Build the prompt for the OpenCode instance
  local prompt="/review-pr Review ${pr_url}"
  if [[ -n "$slack_channel" && -n "$slack_ts" ]]; then
    prompt="${prompt} — Slack-initiated from channel ${slack_channel} at timestamp ${slack_ts}."
  fi

  # Delegate to worktree with the prompt
  worktree "$repo" "$branch" --prompt "$prompt"
}
