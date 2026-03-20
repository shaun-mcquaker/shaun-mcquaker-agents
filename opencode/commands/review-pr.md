---
description: Review a teammate's Pull Request
agent: pr-reviewer
---

Review the Pull Request $ARGUMENTS.

### PR Context

**Metadata:**
! `gh pr view $ARGUMENTS --json number,title,author,body,baseRefName,headRefName,url,files,reviews,reviewDecision,additions,deletions,changedFiles`

**Diff:**
! `gh pr diff $ARGUMENTS`

**Existing Comments:**
! `gh pr view $ARGUMENTS --json comments --jq '.comments[].body'`

### Instructions

1. **Parse PR Context**: Analyze the metadata, diff, and existing comments provided above to understand the PR's intent and current status.
2. **Setup Worktree**: Set up a temporary git worktree for the PR branch to allow for deep code analysis and local testing.
3. **Parallel Research**: Delegate to `pr-repo-scout` and `pr-history-analyst` in parallel to gather broader codebase impact and historical context.
4. **Load Review Standards**: Load the `pr-review` skill to ensure compliance with team standards and review checklists.
5. **Analyze Changes**: Perform a detailed analysis of all changed files, looking for logic errors, security vulnerabilities, performance issues, and style violations.
6. **Structured Review**: Produce a comprehensive, structured review including:
   - Summary of changes
   - Key findings (Blocking, Important, Minor)
   - Specific code suggestions
   - Positive feedback on good implementations
7. **Cleanup**: Once the review is complete, clean up and remove the temporary worktree.
