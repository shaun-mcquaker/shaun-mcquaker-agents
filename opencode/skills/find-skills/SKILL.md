---
name: find-skills
description: Use when the user asks which skill to use or how to approach a workflow. Helps map tasks to the skills available in this stack.
---

# Find Skills

When asked how to do something, first check the available skills in `~/.config/opencode/skills/` and recommend the closest fit.

## Mapping

- planning, multi-step work, persistent tasks -> `beads`
- starting isolated feature work -> `using-git-worktrees`
- creating or shipping a PR -> `pr-workflow`
- reviewing a PR or review methodology -> `pr-review`
- BigQuery, warehouse schemas, typed data access -> `data-mapping`
- UI polish, page design, visual direction -> `frontend-design`
- deep exploration of a project idea -> `deep-research`
- exporting or sharing research artifacts -> `research-export`
- Slack workflows and summaries -> `slack-integration`
- comparing teammate configs -> `teammate-config-audit`
- drafting Vault posts, team updates, announcements -> `vault-post`
- Gmail filter management, inbox noise automation -> `gmail-filters`

## Response Pattern

Return:

1. the recommended skill,
2. why it fits,
3. any companion skill that should be loaded with it.

If no skill fits well, say so directly and proceed without inventing one.
