---
name: logseq-journal
description: Generates structured Logseq session retrospectives from OpenCode sessions. Captures problem, plan, issues/gotchas, learnings, and session metadata. Supports multi-session work chains via handoff tracking. Activates for "journal", "session retro", "document this session", or when /journal command is used.
license: MIT
metadata:
  category: global
---

# Logseq Journal

Generates session retrospectives and work chain pages from OpenCode sessions into your Logseq graph.

## Quick Start

```
/journal    # Generate session retrospective + daily journal entry
```

The `/journal` command creates a structured retrospective of the current session — what problem was tackled, what plan was established, what issues were encountered, and what was learned.

## Architecture

The system uses a two-stage approach:

1. **Script (`journal.py`)** extracts session metadata as JSON: cost, tokens, duration, delegation info, GitHub links, research URLs, user prompts, and tool usage. It reads from OpenCode's session storage and outputs structured JSON to stdout.

2. **LLM (agent)** reads the JSON metadata, reviews the full conversation, and generates complete Logseq markdown files. The LLM handles all narrative content (summary, retro sections, delegation score) and file I/O.

This separation keeps data extraction deterministic and reliable while letting the LLM handle the narrative synthesis it's good at.

## What Gets Generated

### Work Page (`~/Documents/Logseq/pages/Work___<title>.md`)

A detailed session retrospective with these sections (in order):

| Section | Content | Source |
|---------|---------|--------|
| **GitHub** | Issue and PR links | JSON metadata |
| **Summary** | Problem statement + outcome (2-3 sentences) | LLM narrative |
| **Retrospective** | Problem, Plan, Issues & Gotchas, Learnings | LLM narrative |
| **Research** | Librarian sources with findings summaries | JSON metadata + LLM |
| **Delegation** | Agent table + delegation score | JSON metadata + LLM |
| **Session Info** | ID, duration, cost, tokens, repository | JSON metadata |

### Daily Journal Entry (`~/Documents/Logseq/journals/YYYY_MM_DD.md`)

A compact entry linking to the work page:
- Problem (one sentence)
- Outcome (one sentence)
- Cost and duration

## JSON Metadata Schema

The `journal.py` script outputs this structure:

```json
{
  "session": {
    "id": "ses_...",
    "title": "Session title",
    "start_time": "ISO 8601",
    "end_time": "ISO 8601",
    "duration_seconds": 4488,
    "duration_human": "1h 14m"
  },
  "cost": {
    "total_usd": 0.0234,
    "input_tokens": 12500,
    "output_tokens": 3400,
    "cache_read_tokens": 45000,
    "cache_write_tokens": 8000
  },
  "project": {
    "repositories": [
      { "path": "/path/to/repo", "name": "repo", "branch": "feature/x" }
    ]
  },
  "github": {
    "issues": ["https://github.com/..."],
    "pull_requests": ["https://github.com/..."]
  },
  "delegation": {
    "agents": [
      { "agent": "captain", "calls": 0, "lines_added": 45, "lines_removed": 12, "files_edited": ["..."] },
      { "agent": "explore", "calls": 3, "lines_added": null, "lines_removed": null, "files_edited": [] }
    ],
    "critic_called": true,
    "architect_called": false
  },
  "research": {
    "librarian_sources": [
      { "url": "https://...", "context": "Research question" }
    ]
  },
  "tools": {
    "files_read": ["..."],
    "files_edited": ["..."],
    "commands_run": ["..."],
    "tasks_delegated": [{ "description": "...", "agent": "..." }],
    "github_urls": ["..."]
  },
  "prompts": [
    { "text": "User prompt text", "time": "ISO 8601" }
  ],
  "work_chain": {
    "session_count": 1,
    "sessions": ["ses_..."]
  }
}
```

## How Work Chains Work

When `--chain` is used (default via `/journal`), the script:
1. Scans `.claude/artifacts/handoff-*.md` files to find handoff boundaries
2. Links sessions connected by handoff artifacts into a chain
3. Includes all linked session data in the JSON output

Use `/handoff` at end of session → `/resume` in next session → `/journal` to capture both.

## Configuration

- **Session data (SQLite, default)**: `~/.local/share/opencode/opencode.db`
- **Session data (legacy JSON fallback)**: `~/.local/share/opencode/storage/session/<project_hash>/`
- **Output directory**: `~/Documents/Logseq/`
- **Project detection**: SHA1 hash of working directory path

The script auto-detects the storage backend. If the SQLite database exists it is used; otherwise it falls back to reading JSON files from the legacy storage directory.

## Credential Sanitization

The script automatically redacts secrets in JSON output:
- API keys and tokens (Bearer, sk-*, ghp_*, etc.)
- Environment variable values from `.env` patterns
- Connection strings with embedded credentials
- High-entropy strings that look like secrets

## Script Usage

```bash
# Extract session metadata as JSON
python3 ~/.config/opencode/skills/logseq-journal/journal.py <session_id> <project_hash> \
  --project-dir /path/to/project \
  --chain

# Flags
--project-dir    # Project directory for handoff chain tracking
--chain          # Follow handoff chain for related sessions
--db-path        # Override OpenCode SQLite database path
--storage-root   # Override OpenCode storage root directory (legacy JSON)
```

## Integration

- **Handoff**: `/handoff` Step 4 triggers `/journal` automatically
- **Resume**: `/resume` starts a session; `/journal` at the end closes the loop
- **Beads**: Active beads referenced in session appear in journal context

## Output Structure

```
~/Documents/Logseq/
├── journals/
│   └── 2026_02_12.md                              # Daily entry (appended)
└── pages/
    └── Work___Session retro implementation.md      # Work page (created)
```
