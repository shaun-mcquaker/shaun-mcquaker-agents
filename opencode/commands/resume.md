# Resume from Handoff

Resume work from a handoff document: `/resume $ARGUMENTS`

If no path provided, find the most recent handoff in `.claude/artifacts/handoff-*.md`.

## Process

### Step 1: Load Handoff

Read the complete handoff document. Extract:
- Branch and commit from frontmatter
- Beads in progress
- Critical files listed
- Next steps and open questions

### Step 2: Verify Current State

Run these in parallel to check for drift:

**Git State:**
- `git branch --show-current` - Confirm correct branch
- `git log --oneline -5` - Check if commits match
- `git status` - Any unexpected changes?

**Beads State:**
- `bd show [each bead ID from handoff]` - Still accurate?
- `bd list --status=in_progress` - Any new work started?

**File State:**
- Read each critical file listed - Still exists? Changed?

### Step 3: Present Verification Report

```markdown
## Resume Verification: [Handoff Title]

### State Check
| Aspect | Expected | Actual | Status |
|--------|----------|--------|--------|
| Branch | X | Y | OK/DRIFT |
| Commit | abc123 | def456 | OK/AHEAD/BEHIND |
| Beads | 3 in progress | 3 in progress | OK/CHANGED |

### Critical Files
- `file.ext` - Unchanged / Modified since handoff
- `other.ext` - Unchanged / Missing

### Drift Analysis
[If any state changed, explain what and implications]

### Recommended Approach
Based on current state, I recommend:
1. [First action]
2. [Second action]

Proceed with these next steps?
```

### Step 4: Get Confirmation

Wait for user approval before taking action.

### Step 5: Initialize Work Session

Once confirmed:
1. Load next steps into todo tracking (use beads, not TodoWrite)
2. Read critical files into context
3. Begin with first priority item

If handoff has open questions, surface them immediately before starting work.

## Handling Scenarios

**Clean continuation** (no drift):
- Proceed directly with next steps
- Reference learnings throughout

**Branch diverged**:
- Show what changed
- Ask if handoff assumptions still valid
- May need to re-assess approach

**Beads changed**:
- Some may be closed by others
- New blockers may exist
- Run `bd ready` to see what's actually available

**Stale handoff** (>7 days old):
- Warn that context may be outdated
- Recommend quick codebase check before proceeding
- Offer to spawn research agent to verify assumptions

## Output Format

After verification and confirmation:

```
Resuming: [Handoff Title]
Branch: [branch] (verified)
Active Beads: [count]

Starting with: [First next step]
```
