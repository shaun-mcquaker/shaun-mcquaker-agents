---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Location

All worktrees should go in the following location `$HOME/src/worktrees/<project-name>/`.

A worktree SHOULD NEVER be created directly inside the main project directory to avoid confusion and potential git issues.

## Creation Steps

### 1. Create Worktree Directory

```bash
$PROJECT=$(basename "$(git rev-parse --show-toplevel)")
$WORKTREE_PATH="$HOME/src/worktrees/$PROJECT/$BRANCH_NAME"
# Create worktree with new branch
git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME"
cd "$WORKTREE_PATH"
```

### 3. Run Project Setup

```bash
dev up
```

### 4. Report Location

```
Worktree ready at <full-path>
Ready to implement <feature-name>
```

## Common Mistakes

### Creating worktree in project directory

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** NEVER create worktree inside main project dir

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** ALWAYS create worktree in `$HOME/src/worktrees/<project-name>/`

### Ignoring setup command

- **Problem:** Worktree lacks dependencies, doesn't work properly
- **Fix:** ALWAYS run `dev up` after creation

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Check $HOME/src/worktrees/ - exists]
[Create worktree: git worktree add $HOME/src/worktrees/sage-remix/auth -b feature/auth]
[Run dev up]

Worktree ready at /Users/shaunmcquaker/src/worktrees/sage-remix/auth
Ready to implement auth feature
```

