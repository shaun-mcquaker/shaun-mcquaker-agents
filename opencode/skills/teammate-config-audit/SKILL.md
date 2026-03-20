---
name: teammate-config-audit
description: Audits teammates' OpenCode configurations (skills, commands, agents, plugins) against your own global config. Pulls latest changes, performs a structured comparison, and surfaces opportunities to adopt, adapt, or improve your setup.
---

# Skill: Teammate Config Audit

## Description

Scans one or more teammate OpenCode configuration repositories, compares them against your global config (`~/.config/opencode/`), and produces a structured report of opportunities — things to adopt wholesale, adapt to your style, or use as inspiration for improvements.

## Triggers

- "Audit teammate configs"
- "What are my teammates doing differently in OpenCode?"
- "Compare my config against [teammate]'s"
- "Scan teammate repos for config ideas"
- `/audit-teammate-configs` command invocation

## Prerequisites

- Teammate repos must be cloned locally under `~/src/github.com/shopify-playground/`
- Your global config lives at `~/.config/opencode/` (skills, commands, agents, AGENTS.md)

## Architecture: Symlink Setup

**Critical context:** `~/.config/opencode` contains **symlinks** pointing into the `shaun-mcquaker` git repo:

```
~/.config/opencode/AGENTS.md → ~/src/github.com/shopify-playground/shaun-mcquaker/opencode/AGENTS.md
~/.config/opencode/opencode.jsonc → ~/src/github.com/shopify-playground/shaun-mcquaker/opencode/opencode.jsonc
```

This means:

- Your global OpenCode config is version-controlled in the `shaun-mcquaker` repo
- Symlinked files (AGENTS.md, opencode.jsonc, package.json, tui.json, .gitignore) are edited via the repo
- Some directories (agents/, commands/, skills/) live directly in `~/.config/opencode/` and are not symlinked
- Changes to symlinked files should be committed and pushed via the repo
- The repo lives alongside teammate repos under `~/src/github.com/shopify-playground/`

This is the same pattern teammates may use — check if their repos are also symlinked into `~/.config/opencode` on their machines.

## Known Teammate Repos

| Teammate   | Repo Name              | Local Path                                                 |
| ---------- | ---------------------- | ---------------------------------------------------------- |
| Mark (MJN) | `mjn-opencode-config`  | `~/src/github.com/shopify-playground/mjn-opencode-config`  |
| Michael    | `michaelburjack-stack` | `~/src/github.com/shopify-playground/michaelburjack-stack` |
| You (Shaun) | `shaun-mcquaker`      | `~/src/github.com/shopify-playground/shaun-mcquaker`       |

> **Adding teammates:** To audit a new teammate, add their repo to this table and clone it locally.

## Workflow

### Phase 1: Pull Latest

For each teammate repo, pull the latest changes to ensure you're comparing against current configs:

```bash
# For each repo in the table above (skip your own)
cd <local_path> && git pull --ff-only
```

If a pull fails (diverged, dirty worktree), note it in the report but continue with what's on disk.

### Phase 2: Discover Config Locations

Teammate configs may live in different places. Scan for all of these:

```
# OpenCode standard locations
<repo>/.opencode/          # OpenCode config root
<repo>/opencode/           # Alternative location (Michael's pattern)
<repo>/.agents/            # Agent definitions
<repo>/agent/              # Alternative agent location (Mark's pattern)
<repo>/skills/             # Top-level skills (Mark's pattern)
<repo>/command/            # Top-level commands (Mark's pattern)

# Key files
AGENTS.md                  # Agent orchestration rules
opencode.jsonc / opencode.json  # MCP servers, model config, settings
```

### Phase 3: Inventory Each Teammate

For each teammate, build a structured inventory:

#### 3a. Skills

- Find all `SKILL.md` files
- For each: read name, description, triggers, and key workflow steps
- Note any bundled resources (scripts, templates, reference files)

#### 3b. Commands

- Find all `.md` files in command directories
- For each: read description, agent assignment, and what it does
- Note the frontmatter pattern (description, agent fields)

#### 3c. Agents

- Find all agent definition files (`.md` in agent directories)
- For each: read the role name, description, and key behavioral rules
- Note any unique agent roles not in your config

#### 3d. Plugins

- Find any `.ts` or `.js` plugin files
- Note what they do (e.g., proxy servers, integrations)

#### 3e. MCP Configuration

- Read `opencode.jsonc` or `opencode.json`
- Note any MCP servers you don't have configured
- Note any interesting model or provider settings

#### 3f. AGENTS.md Patterns

- Read the root AGENTS.md
- Note any orchestration patterns, delegation rules, or principles that differ from yours

### Phase 4: Compare Against Your Config

Load your global config for comparison:

```
~/.config/opencode/
├── AGENTS.md              # Your orchestration rules
├── opencode.jsonc         # Your MCP/model config
├── skills/                # Your global skills
├── commands/              # Your global commands
└── agents/                # Your agent definitions
```

For each item found in teammate configs, classify it:

| Category     | Criteria                                                                          |
| ------------ | --------------------------------------------------------------------------------- |
| **ADOPT**    | Teammate has something you don't, and it's directly useful as-is                  |
| **ADAPT**    | Teammate has a similar concept but their approach is better or complementary      |
| **INSPIRE**  | Interesting idea that could spark a new skill/command for your workflow           |
| **SKIP**     | Too personal, already covered, or not relevant to your workflow                   |
| **CONFLICT** | Teammate does something that contradicts your current approach — needs a decision |

### Phase 4b: Convergent Evolution Check

**This is one of the highest-signal findings.** After classifying individual items, cross-reference across teammates:

- If two or more teammates independently built similar skills, commands, or agents — flag this prominently. Independent invention by multiple experienced engineers is strong evidence the capability is worth having.
- If they built the same thing differently, compare both approaches and recommend the stronger one (or a hybrid).
- Present convergent items in a dedicated section of the report, above the per-teammate breakdown.

### Phase 5: Generate Report

Produce a structured report in this format:

```markdown
## Teammate Config Audit Report

**Date:** <date>
**Teammates Scanned:** <list>
**Your Config Version:** <last commit hash of ~/.config/opencode>

---

### Executive Summary

<2-3 sentences: how many opportunities found, biggest wins>

### Convergent Evolution

<Items that multiple teammates built independently — strongest signal>

For each:

- **What:** <concept>
- **Who built it:** <teammates>
- **Their approaches:** <brief comparison>
- **Recommendation:** <which to adopt/adapt, or hybrid>

### ADOPT (Ready to Use)

For each item:

- **What:** <name and source teammate>
- **Why:** <what gap it fills in your config>
- **Action:** <specific steps to adopt it>

### ADAPT (Merge with Your Approach)

For each item:

- **What:** <name and source teammate>
- **Their approach:** <brief description>
- **Your current approach:** <what you have now>
- **Recommended merge:** <how to combine the best of both>

### INSPIRE (New Ideas)

For each item:

- **What:** <concept from teammate>
- **Idea:** <what you could build inspired by this>
- **Effort:** <low/medium/high>

### SKIP (Not Applicable)

<Brief list with one-line reasons>

### CONFLICTS (Needs Decision)

For each item:

- **What:** <the conflicting approaches>
- **Teammate's way:** <description>
- **Your way:** <description>
- **Trade-offs:** <pros/cons of each>

---

### Detailed Inventory

#### <Teammate Name>

**Skills:**
| Name | Description | Verdict |
|------|-------------|---------|

**Commands:**
| Name | Description | Verdict |
|------|-------------|---------|

**Agents:**
| Name | Description | Verdict |
|------|-------------|---------|

**Plugins/Other:**
| Name | Description | Verdict |
|------|-------------|---------|
```

## Important Guidelines

1. **Read, don't assume** — Always read the actual file contents. Don't guess based on filenames.
2. **Pull first** — Stale local copies lead to stale recommendations.
3. **Conversation before action** — Present the report and discuss with the user before making any changes. Never auto-modify the global config.
4. **Credit the source** — Always note which teammate an idea came from.
5. **Consider maintenance** — A skill that's clever but hard to maintain is worse than a simple one.
6. **Respect personal preferences** — Some things (keybindings, naming conventions like `burjack-*`) are personal. Focus on the underlying patterns, not the surface styling.
7. **Check for convergent evolution** — If two teammates independently built similar things, that's a strong signal the capability is worth having.
