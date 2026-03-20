---
description: Consolidate Dependabot PRs into batch updates with testing and auto-close
---

Automate dependency updates: audit, categorize, update patch/minor, test, PR, and cleanup.

**Goal:** Replace multiple Dependabot PRs with a single consolidated PR that auto-closes them on merge.

## Step 1: Prepare

1. **Detect package manager** (check for `package.json`, `requirements.txt`, `pyproject.toml`):
   - JavaScript: `yarn` or `npm` (check for `yarn.lock` vs `package-lock.json`)
   - Python: `pip`, `poetry`, or `uv` (check for `poetry.lock` vs `uv.lock` vs bare requirements.txt)

2. **Fetch and create branch:**
   ```bash
   git fetch origin main
   git checkout -b <username>/dependency-updates origin/main
   ```
3. **If branch exists remotely**, check for open PR. If found, delete branch and recreate fresh.

## Step 2: Audit

1. **List outdated packages:**
   - JavaScript: `yarn outdated` or `npm outdated`
   - Python: `pip list --outdated` or `poetry show --outdated` or `uv pip list --outdated`

2. **Categorize by semver:**
   - **Patch/Minor** (safe): Current major version = latest major version
   - **Major** (breaking): Latest major > current major — skip for separate PR

3. **Find Dependabot PRs:**

   ```bash
   gh pr list --search "is:open author:app/dependabot"
   ```

4. **Check if transitive:** For each Dependabot PR, grep package name in manifest file to determine if direct or transitive dependency.

## Step 3: Update Patch/Minor Only

**JavaScript:**

```bash
yarn upgrade --latest pkg1 pkg2 pkg3 ...
# or
npm update pkg1 pkg2 pkg3
```

**Python:**

```bash
pip install --upgrade pkg1 pkg2 pkg3
# or
poetry update pkg1 pkg2 pkg3
# or
uv pip install --upgrade pkg1 pkg2 pkg3
```

**Do NOT explicitly update major versions.** Package managers may automatically upgrade them if semver ranges allow (e.g., `^1.8.15` → `^2.0.5`). This is expected and acceptable - if tests pass, the auto-upgrade is valid.

## Step 4: Check Breaking Changes

For packages with minor bumps (especially multi-minor jumps):

1. Check changelogs for deprecations or behavioral changes
2. Note any relevant warnings in PR description

## Step 5: Validate

Run project-specific validation commands. **Stop and fix before proceeding.**

**Shopify projects:**

```bash
/opt/dev/bin/dev check      # lint + typecheck
/opt/dev/bin/dev test       # test suite
/opt/dev/bin/dev build      # production build (if applicable)
```

**Generic projects:**

```bash
npm run lint && npm run typecheck && npm test && npm run build
# or
pytest && mypy . && ruff check
```

**If validation fails:**

- Identify failing package
- Revert: `yarn upgrade pkg@<old-version>` or `pip install pkg==<old-version>`
- Re-run validation
- Document revert in PR

## Step 6: Commit and Push

**Commit message format:**

```
Consolidate <ecosystem> dependency updates (<month> <year>)
```

**Examples:**

- `Consolidate JavaScript dependency updates (Feb 2026)`
- `Consolidate Python dependency updates (Feb 2026)`
- `Bump qs from 6.14.1 to 6.14.2` (if only 1 package)

```bash
git add -A
git commit -m "Consolidate <ecosystem> dependency updates (<month> <year>)"
git push -u origin <username>/dependency-updates
```

## Step 7: Create PR

**CRITICAL:** Place `Closes:` at the TOP to auto-close Dependabot PRs on merge.

```markdown
Closes #NNN, #NNN, #NNN

## Summary

Consolidated update of N packages to latest patch/minor versions.

## Updated Packages

| Package | From  | To    | Type       |
| ------- | ----- | ----- | ---------- |
| pkg1    | x.y.z | x.y.w | patch/fix  |
| pkg2    | x.y.z | x.w.z | minor/feat |

## Skipped (Major Versions - Separate PRs)

| Package | Current | Latest | Notes                |
| ------- | ------- | ------ | -------------------- |
| pkg3    | x.0.0   | y.0.0  | Breaking API changes |

## Validation

- [x] Lint passes
- [x] TypeCheck passes
- [x] Tests pass (N/N)
- [x] Build succeeds

## Deployment Notes

**Cloud Functions:** Re-deployed following functions to production:

- `function-name` (if applicable)

**DAGs:** Monitored in staging:

- `dag_name` (if applicable)
```

Create PR:

```bash
gh pr create --title "Consolidate <ecosystem> dependency updates (<month> <year>)" --body "$(cat pr_body.md)"
```

## Step 8: Major Version Updates (Separate Handling)

### IMPORTANT: Check if already upgraded first!

**Before creating separate PRs**, verify if package manager already upgraded major versions:

1. **Check actual installed versions:**

   ```bash
   # JavaScript
   npm list <package-name>

   # Python
   uv pip list | grep <package-name>
   ```

2. **Compare with Dependabot PR scope:**
   - If Dependabot PR says "1.x → 2.x" but package is already at 2.x, **no separate PR needed**
   - The consolidated update already handled it
   - Build/test success validates the upgrade worked

3. **If major upgrade is already complete:**
   - Verify builds pass
   - Verify tests pass
   - **Manually close Dependabot PRs** with comment explaining they were handled in consolidated PR
   - **Skip creating separate PR** - it's redundant

### When separate PRs ARE needed

Only create separate PRs for major version updates when:

- Package manager did NOT auto-upgrade (no semver range match)
- Breaking changes require code modifications
- Extensive testing is needed beyond standard CI

### Creating separate major version PRs

1. **Create dedicated branch:**

   ```bash
   git checkout -b <username>/upgrade-<package-name> origin/main
   ```

2. **Research breaking changes:**
   - Read package's GitHub releases or CHANGELOG.md
   - Search codebase for usage: `rg "<deprecated-api>"`
   - Identify affected files/modules

3. **Perform upgrade and fix breaks:**

   ```bash
   yarn upgrade --latest <package>
   # or
   pip install --upgrade <package>
   ```

4. **Validate thoroughly** (same as Step 5)

5. **Commit and PR:**

   ```bash
   git commit -m "Upgrade <package> from vX to vY"
   git push -u origin <username>/upgrade-<package-name>
   ```

6. **PR description should include:**
   - Summary of breaking changes (from changelog)
   - Which files were modified and why
   - Link to release notes
   - Whether manual testing is needed (e.g., UI changes)

**Grouping rules:**

- Tightly coupled packages (e.g., `@react-router/*`, `react-router`) go in one PR
- Unrelated packages get separate PRs

## Repository-Specific Overrides

**After running this command**, check for:

- `package.json` `overrides` or `resolutions` fields (don't update pinned packages)
- Python `constraints.txt` or version pins in comments
- Monorepo lockfile coordination (e.g., updating 14 `package-lock.json` + 1 `yarn.lock`)
- Project-specific validation commands in README or dev.yml

## Key Learnings

1. **Auto-upgrades are OK:** If package manager upgrades major versions due to semver ranges (e.g., `^1.8.15` → `^2.0.5`), and tests pass, accept it. No separate PR needed.

2. **Verify before creating PRs:** Always check actual installed versions before creating "major upgrade" PRs. Avoid duplicate work.

3. **Manual closure is fine:** If Dependabot PRs remain open after a consolidated update handles them, manually close with explanation. Don't create empty PRs just to trigger auto-close.

4. **Test coverage is key:** Strong CI/CD pipelines catch breaking changes early, making consolidated updates safer.

## Examples

**growth-labs-sdp (Python + TypeScript monorepo):**

- Branch: `<username>/dependency-updates`
- Validation: `/opt/dev/bin/dev ruff` (Python), `npm run lint` (JS)
- PR #3018: Consolidated 28 Dependabot PRs
- bunyan 1.x → 2.x was auto-upgraded successfully (no separate PR needed)

**sage-remix (TypeScript):**

- Branch: `sage/dependency-updates`
- Validation: `/opt/dev/bin/dev check && dev test && dev build`
- PR updated 28 packages, documented 4 major version skips
