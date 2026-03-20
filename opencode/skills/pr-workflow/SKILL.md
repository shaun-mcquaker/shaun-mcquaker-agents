---
name: pr-workflow
description: Standardized procedure for preparing code, managing git branches, and submitting Pull Requests using GitHub CLI.
---

# Skill: Standardized PR Workflow

## Description
 This skill defines the strict procedure for preparing code, managing git branches, and submitting Pull Requests using the GitHub CLI (`gh`). It ensures all contributions follow the team's naming conventions and documentation standards.

## Triggers
- "Prepare a PR"
- "Create a pull request"
- "Ship this"
- "Submit changes"

## Prerequisites
- The environment must have `git` and `gh` (GitHub CLI) installed.
- `gh` must be authenticated (`gh auth status` returns active).

## Workflow Steps

When the user initiates this skill, perform the following steps in order:

### 1. Context Analysis & Safety Check
- Run `git status` to see currently modified files.
- Run `git diff --stat` to understand the scope of changes and their architectural impact for the PR description.
- If the current branch is `main` or `master`, you **must** create a new branch.

### 2. Branch Management
- **Naming Convention:** Default to project specific branch name conventions, if defined; otherwise use `[type]/[short-kebab-case-description]`
  - Types: `feat`, `fix`, `docs`, `refactor`, `chore`, `ci`.
  - Example: `feat/add-dark-mode-toggle`
- Command: `git checkout -b [branch_name]`

### 3. Staging and Committing
- Stage the relevant files.
- **Commit Message Convention:** Follow **Conventional Commits**.
  - Format: `type(scope): subject`
  - Example: `feat(ui): add dark mode toggle to settings`
- Command: `git commit -m "..."`

### 4. Push to Origin
- Command: `git push -u origin [branch_name]`

### 5. Create Pull Request
- Use the GitHub CLI to create the PR.
- **Title:** Use the commit message subject.
- **Body:** Generate a markdown summary consisting of:
  - **Summary:** High-level explanation of what changed.
  - **Architectural Changes:** Which modules/files were affected (from git diff).
  - **Test Plan:** How the user can verify this works.
- **Command:**
  ```bash
  gh pr create --title "[Title]" --body "[Generated Body]"
  ```
- **Constraint**: Do not use interactive mode. Do not open the browser (`--web` flag is optional depending on user preference, default to CLI output).

### Error Handling
- If the branch name already exists, append a version number (e.g., feat/add-dark-mode-toggle-v2).
- If `gh` is not authenticated, stop and alert the user to run `gh auth login`.
