---
description: Comprehensive code review of current branch against main
model: openai/gpt-5.2-codex
---

Perform a thorough code review of the current branch compared to `main`.

## Step 1: Gather Context

Run this command to get the branch name and diff:

```bash
git rev-parse --abbrev-ref HEAD
```

Then get the diff:

```bash
git diff main...HEAD --stat
```

And the detailed diff:

```bash
git diff main...HEAD
```

## Step 2: Parallel Review via Subagents
Spawn separate subagents for each review dimension. For each subagent, provide the diff output and specific review focus.

### Subagent 1: Logic & Correctness

Focus areas:
- Off-by-one errors, null/undefined handling
- Race conditions or async issues
- Edge cases not handled
- Logic that doesn't match apparent intent

### Subagent 2: Security Review

Focus areas:
- Injection vulnerabilities (SQL, XSS, command)
- Authentication/authorization gaps
- Secrets or credentials in code
- Unsafe deserialization or input handling

### Subagent 3: Performance

Focus areas:
- N+1 queries or unnecessary DB calls
- Missing indexes implied by new queries
- Unbounded loops or memory growth
- Expensive operations in hot paths

### Subagent 4: Code Quality

Focus areas:
- Consistency with existing patterns in codebase
- Dead code or unused imports
- Functions doing too much (single responsibility)
- Missing or misleading comments
- Test coverage for new logic

## Step 3: Synthesize Results
After all subagents complete, compile findings into this format:

```markdown
# Code Review: [branch-name]

## Summary
<2-3 sentence overview of changes and overall assessment>

## Critical Issues (Must Fix)
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|

## Warnings (Should Fix)
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|

## Suggestions (Consider)
| File | Line | Issue | Recommendation |
|------|------|-------|----------------|

## Positive Observations
<What was done well>

## Testing Recommendations
<Specific test cases that should exist for these changes>
```

## Step 4: Offer Follow-ups

After presenting the review, ask if I want to:
- Dive deeper into any specific issue
- Generate fixes for critical issues
- Create missing tests
- Review specific files in more detail

## Output Format

Structure the review by file, then by severity:

```markdown
## <filename>

### 🔴 Critical
- Line X: <issue>

### 🟡 Warning  
- Line Y: <issue>

### 🔵 Suggestion
- Line Z: <issue>
```

