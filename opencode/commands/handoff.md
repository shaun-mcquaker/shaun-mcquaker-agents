# Create Session Handoff

Create a comprehensive handoff document to preserve context for future sessions: `/handoff $ARGUMENTS`

Accepts optional `--journal` flag to also generate a Logseq session retrospective.

## Process

### Step 1: Gather Context

Run these in parallel:
- `git status` and `git diff --stat` to capture current changes
- `git log --oneline -10` for recent commit context
- `bd list --status=in_progress` for active beads
- `bd list --status=open` for pending work

### Step 2: Analyze Session

Review the conversation to identify:
- **Tasks completed** - What got done this session
- **Tasks in progress** - What's partially complete
- **Key learnings** - Patterns discovered, gotchas encountered
- **Critical files** - The 3-5 most important files touched/examined
- **Decisions made** - Architectural or approach decisions

### Step 3: Write Handoff Document

Create file at `.claude/artifacts/handoff-YYYY-MM-DD-HH-MM.md`:

```markdown
---
created: YYYY-MM-DDTHH:MM:SS
branch: [current branch]
commit: [latest commit hash]
beads_in_progress: [list of bead IDs]
---

# Session Handoff: [Brief Description]

## Completed This Session
- [ ] Task 1 - outcome
- [x] Task 2 - outcome

## In Progress
- **[Bead ID]**: [Title] - Current state, what's left

## Critical Files
- `path/to/file.ext:line` - Why it matters
- `path/to/other.ext` - Context

## Key Learnings
1. **[Pattern/Discovery]**: Explanation
2. **[Gotcha]**: What to avoid and why

## Decisions Made
- **Decision**: Rationale

## Uncommitted Changes
[Summary of git diff if any]

## Next Steps (Priority Order)
1. [ ] Immediate next action
2. [ ] Follow-up task
3. [ ] Lower priority item

## Open Questions
- Question needing clarification?

## Resume Command
To continue this work:
```
/resume .claude/artifacts/handoff-YYYY-MM-DD-HH-MM.md
```
```

### Step 4: Generate Session Retrospective (if --journal)

**Only if the user passed `--journal`**, generate a Logseq session retrospective:

1. Determine the current session ID and project hash from the OpenCode SQLite database:
   ```bash
   sqlite3 ~/.local/share/opencode/opencode.db \
     "SELECT id, project_id FROM session WHERE directory = '$(pwd)' ORDER BY time_updated DESC LIMIT 1;"
   ```
   The output is `session_id|project_id`. If no results, try listing recent sessions to match manually:
   ```bash
   sqlite3 ~/.local/share/opencode/opencode.db \
     "SELECT id, project_id, directory FROM session ORDER BY time_updated DESC LIMIT 10;"
   ```
2. Run the metadata extraction script:
   ```bash
   python3 ~/.config/opencode/skills/logseq-journal/journal.py <session_id> <project_hash> --project-dir <cwd> --chain
   ```
3. Capture the JSON output and follow the `/journal` command workflow (Steps 3-5) to generate and write the Logseq retrospective files
4. Report the journal output paths alongside the handoff confirmation

**If `--journal` is not passed, skip this step entirely.**

### Step 5: Sync State

Run in sequence:
1. `bd sync --from-main` (if in ephemeral branch)
2. Commit the handoff file if appropriate

### Step 6: Confirm

Output:
- Path to handoff file
- Path to Logseq journal entry and work chain page (if `--journal` was used)
- Summary of what was captured
- The resume command to use

## Guidelines

- **Prioritize actionable context** over comprehensive history
- **Use file:line references** instead of pasting code
- **Link beads** to provide task continuity
- **Be specific** about current state vs. desired state
- Keep under 800 words - dense, not verbose
