# Check Delegation Patterns

Analyze a conversation or task to verify Captain is delegating appropriately.

Usage: `/check-delegation [optional: paste conversation or describe task]`

## Process

### Step 1: Identify Delegation Opportunities

Review the conversation/task and identify signals that should trigger delegation:

**Exploration Signals** (→ explore):
- "find", "search", "where is", "locate", "map", "structure"
- Looking for files or patterns
- Understanding unfamiliar code areas

**Research Signals** (→ librarian):
- "how does X work", "best practices", "documentation"
- Understanding libraries, frameworks, APIs
- Finding implementation examples

**Strategic Signals** (→ architect):
- "stuck", "not working", "why is this", "debug"
- Architecture decisions with trade-offs
- Multiple failed attempts at something

**Backend Signals** (→ backend):
- API, database, GraphQL, REST, server
- Node.js, Rails, migrations, background jobs
- 4+ files of server-side logic

**Frontend Signals** (→ frontend):
- React, CSS, UI, component, layout
- Styling, animations, responsive design
- 4+ files of UI code

**Documentation Signals** (→ scribe):
- "write docs", "README", "document", "explain"
- Creating guides or API documentation

**Visual Signals** (→ looker):
- Image, screenshot, PDF, diagram attached
- "what does this show", "extract from"

### Step 2: Analyze What Actually Happened

Compare detected signals against actual behavior:

```markdown
## Delegation Audit

### Signals Detected
| Signal | Type | Should Delegate To |
|--------|------|-------------------|
| [quote from conversation] | exploration | explore |
| [quote from conversation] | backend work | backend |

### Actual Behavior
| Signal | Expected | Actual | Verdict |
|--------|----------|--------|---------|
| "find all auth files" | explore | Captain did it | ❌ MISSED |
| "add API endpoint" | backend | Delegated to backend | ✅ CORRECT |
| Simple config edit | Captain | Captain did it | ✅ CORRECT |

### Task Size Check
- Files involved: [count]
- Lines changed: [estimate]
- Threshold: 4+ files OR 50+ lines → should delegate
- Verdict: [✅ Appropriate / ❌ Should have delegated]
```

### Step 3: Generate Recommendations

Based on the audit:

```markdown
## Recommendations

### Missed Delegations
1. **[Signal]** should have gone to `[agent]`
   - Why: [explanation]
   - Correct invocation:
     ```
     Task(
       subagent_type="[agent]",
       prompt="[suggested prompt]"
     )
     ```

### Unnecessary Self-Work
1. **[Task]** was done by Captain but should have been delegated
   - Size: [files/lines]
   - Better approach: Delegate to `[agent]`

### Correct Delegations
- ✅ [List what was done correctly]

### Overall Assessment
- Delegation Score: [X/Y signals correctly handled]
- Verdict: [GOOD / NEEDS IMPROVEMENT / POOR]
```

### Step 4: Suggest Prompt Improvements

If delegation was missed, suggest how Captain's prompt could be improved:

```markdown
## Suggested Captain Prompt Additions

If these patterns are being missed, consider adding to `agent/captain.md`:

### Additional Mandatory Triggers
```
[X]. **[New pattern]** (signals):
   - "[keyword1]", "[keyword2]"
   - [description of when this applies]
   - **→ Delegate to `[agent]`**
```
```

## Quick Check Mode

If no conversation is provided, run a self-diagnostic:

1. Read `agent/captain.md` and verify:
   - [ ] Mandatory delegation rules exist
   - [ ] Task tool syntax is correct (`subagent_type`, not `@mention`)
   - [ ] Size thresholds are defined
   - [ ] All agents are listed with triggers

2. Read `AGENTS.md` and verify:
   - [ ] Delegation rules table exists
   - [ ] All agents documented
   - [ ] Workflow patterns defined

3. Report configuration health:

```markdown
## Configuration Health Check

### Captain Prompt
- Mandatory triggers: [✅ Present / ❌ Missing]
- Task tool syntax: [✅ Correct / ❌ Wrong]
- Size thresholds: [✅ Defined / ❌ Missing]
- Agent list: [✅ Complete / ❌ Incomplete]

### AGENTS.md
- Exists: [✅ Yes / ❌ No]
- Delegation rules: [✅ Present / ❌ Missing]
- Up to date with agents: [✅ Yes / ❌ No]

### Potential Issues
- [List any configuration problems found]

### Recommendations
- [Specific fixes if needed]
```

## Output Format

Always structure output as:

```markdown
# Delegation Audit Report

## Summary
[1-2 sentence overview]

## Findings
[Detailed analysis]

## Recommendations
[Actionable improvements]

## Score
[X/Y] delegation opportunities handled correctly
```
