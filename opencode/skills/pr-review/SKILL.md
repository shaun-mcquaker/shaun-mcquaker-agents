---
name: pr-review
description: Portable PR review methodology for the pr-reviewer agent. Provides structured, multi-dimensional assessments across any repository, focusing on correctness, security, performance, and maintainability.
---

# PR Review Skill

This skill contains the portable review methodology that the `pr-reviewer` agent loads. It works across ANY repository by combining universal best practices with repo-specific conventions discovered during the review process.

## 1. Review Dimensions

- **Correctness** — Does the code do what it claims? Are there edge cases or logic errors?
- **Security** — Input validation, secrets management, authentication, and protection against injection attacks.
- **Performance** — Identification of bottlenecks, N+1 queries, unnecessary computation, and memory leaks.
- **Maintainability** — Readability, consistency with the codebase, and appropriate levels of abstraction.
- **Error Handling** — Proper catch/handle blocks, user-friendly error messages, and appropriate logging.
- **Behavioral Preservation** — For changes to existing code: does it preserve input/output contracts, API surfaces, and database schemas?
- **Testing** — Are changes covered by tests? Are the tests meaningful and do they cover edge cases?
- **PR Description Quality** — Is the GitHub PR itself in good shape? Clear title, thorough description, linked issues, screenshots for visual changes, testing instructions, and accurate scope summary. The PR description is the first thing reviewers and future readers see — it should stand on its own as documentation of the change.

## 2. Structured Output Format

The exact markdown template for reviews:

```markdown
## PR Review: #<number> — "<title>"

**Author:** <author> | **Base:** <base branch> | **Files Changed:** <count>
**Repo Conventions Applied:** <list of skills/rules discovered>

### Verdict: [APPROVED | CHANGES_REQUESTED | NEEDS_DISCUSSION]

### Summary

[2-3 sentence overview of the changes and assessment]

### Repo Convention Violations

[Issues specific to repo-discovered rules — only if pr-repo-scout found conventions]

### Blocking Issues (must fix)

1. **[File:Line]** Issue description
   - **Why it matters:** [impact]
   - **Suggested fix:** [concrete suggestion]

### Important Issues (should fix)

1. **[File:Line]** Issue description
   - **Why it matters:** [impact]
   - **Suggested fix:** [concrete suggestion]

### Minor Issues (nice to have)

1. **[File:Line]** Issue description

### Patterns from Recent PRs

[Insights from pr-history-analyst — recurring issues this author or repo has]

### Security Assessment

[Summary from pr-security-auditor if invoked, or brief inline assessment]

### Performance Assessment

[Summary from pr-performance-analyst if invoked, or brief inline assessment]

### PR Description Assessment

[Evaluate the GitHub PR itself — not just the code]

- **Title:** Clear, follows repo conventions (e.g., `[engine]: description`)?
- **Summary:** Explains what changed AND why? Understandable without reading the code?
- **Scope:** Accurately reflects the actual changes? Not misleading?
- **Testing instructions:** Present and actionable? Can a reviewer verify the change?
- **Screenshots:** Included for visual/UI changes?
- **Linked issues:** References related issues or closes them?
- **Checklist:** Repo-required checklist items addressed?
- **Next steps:** Documented if this is part of a larger effort?

### What's Good

- [Positive observation 1]
- [Positive observation 2]

### Recommendations

[High-level suggestions for the author]
```

## 3. Severity Classification Rules

- **Blocking**: Security vulnerabilities, correctness bugs, data loss risk, broken contracts, missing error handling for critical paths.
- **Important**: Performance issues, missing tests for new logic, inconsistency with codebase patterns, poor error messages, missing or misleading PR description, no testing instructions for non-trivial changes.
- **Minor**: Style preferences, naming suggestions, documentation improvements, optional optimizations, PR description polish (wording, formatting).

## 4. Verdict Rules

- **APPROVED**: No blocking issues. Important issues are minor or acceptable trade-offs. Code is correct and secure.
- **CHANGES_REQUESTED**: Any blocking issues exist. Security vulnerabilities found. Correctness problems. Multiple important issues accumulate.
- **NEEDS_DISCUSSION**: Architectural concerns that need team input. Trade-offs that the reviewer can't decide alone. Ambiguous requirements.

## 5. Behavioral Preservation Rules (for changes to existing code)

- Verify input/output contracts are preserved.
- Check that API surfaces haven't changed unintentionally.
- Ensure database schemas are compatible.
- Confirm task IDs, job names, and table names are unchanged (unless intentional).
- Flag any changes to external API contracts.

## 6. Feedback Quality Standards

- **Specific**: Point to exact files and lines.
- **Actionable**: Explain HOW to fix, not just what's wrong.
- **Prioritized**: Clear blocking vs. nice-to-have distinction.
- **Constructive**: Always acknowledge good work.
- **Consistent**: Apply the same standards every time.
- **Evidence-based**: Reference repo conventions, not personal preference.

## 7. Worktree Lifecycle

- **Setup**: `git worktree add $HOME/src/worktrees/<project>/review-pr-<number> <branch>`
- **Read**: Always read files in the worktree, not the main workspace.
- **Cleanup**: `git worktree remove $HOME/src/worktrees/<project>/review-pr-<number>`
- **Failure**: If cleanup fails, report the path for manual cleanup.

## 8. PR Description Quality Criteria

The PR description is the first thing reviewers see and serves as permanent documentation of the change. Evaluate it systematically:

### Must Have (flag as Important if missing)

- **Clear title** — Follows repo naming convention (if any). Describes the change, not the ticket.
- **What changed and why** — A summary that makes sense without reading the diff. Explains motivation, not just mechanics.
- **Testing instructions** — How can a reviewer verify this works? Required for any non-trivial change.
- **Accurate scope** — The description matches what the diff actually does. No undocumented changes, no misleading claims.

### Should Have (flag as Minor if missing)

- **Linked issues** — References related issues, closes tickets where applicable.
- **Screenshots/recordings** — Required for any visual/UI change. Helpful for before/after comparisons.
- **Checklist completion** — If the repo has a PR template with checkboxes, they should be addressed (checked or explicitly noted as N/A).
- **Next steps** — If this is part of a larger effort, document what comes next and what's intentionally deferred.

### Watch For

- **Description-diff mismatch** — PR says it does X but the diff also does Y (undocumented side effects).
- **Stale description** — Description was written for an earlier version of the code and not updated.
- **Missing context for reviewers** — Assumes knowledge that reviewers may not have.
- **No rollback plan** — For risky changes, how to revert should be documented.

## 9. Multi-Repo Awareness

- This skill works across ANY repository.
- Do NOT assume growth-labs-sdp conventions.
- Always rely on `pr-repo-scout`'s findings for repo-specific rules.
- Fall back to universal best practices when no repo conventions exist.
