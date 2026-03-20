# Generate Session Retrospective

Capture the current session as a structured Logseq journal entry: `/journal $ARGUMENTS`

The `/journal` command generates a session retrospective — a concise record of what problem was tackled, what plan was established, what issues were encountered, and what was learned.

## Process

### Step 1: Identify Session and Project

Determine the current session ID and project hash from the OpenCode SQLite database at `~/.local/share/opencode/opencode.db`.

Run a single query to find the most recent session whose `directory` matches the current working directory:

```bash
sqlite3 ~/.local/share/opencode/opencode.db \
  "SELECT id, project_id FROM session WHERE directory = '$(pwd)' ORDER BY time_updated DESC LIMIT 1;"
```

The output is `session_id|project_id`. Use these as `<session_id>` and `<project_hash>` in the next step.

If the query returns no results, the working directory may not match exactly (e.g. symlinks or trailing slashes). Try a prefix match:

```bash
sqlite3 ~/.local/share/opencode/opencode.db \
  "SELECT id, project_id, directory FROM session ORDER BY time_updated DESC LIMIT 10;"
```

Then visually match the directory to the current working directory and pick the correct session.

### Step 2: Extract Session Metadata

Run the metadata extraction script:

```bash
python3 ~/.config/opencode/skills/logseq-journal/journal.py <session_id> <project_hash> \
  --project-dir <cwd> \
  --chain
```

Capture the JSON output. This contains:
- Session info (ID, duration, timestamps)
- Cost and token usage
- Project/repository info
- GitHub issues and PRs
- Delegation summary (per-agent calls and captain edits)
- Research URLs (librarian sources)
- Tool usage summary
- User prompts
- Work chain info

### Step 3: Review Conversation and Generate Retro

Using the JSON metadata AND your review of the full conversation, generate the Logseq markdown for two files:

#### 3a: Work Page (`~/Documents/Logseq/pages/Work___<title>.md`)

Generate the full work page in Logseq outliner format (every line starts with `- ` or indented `  - `). Use this exact section order:

```
- **GitHub**
  - Issue: [#N — title](url)
  - PR: [#N — title](url)
- **Summary**
  - [2-3 sentences: problem statement + outcome]
- **Session Retrospective**
  - **Problem**
    - [What was the core issue or goal? Why did this session happen?]
  - **Plan**
    - [What approach was decided? What were the key steps?]
  - **Issues & Gotchas**
    - [What didn't work as expected?]
    - [What was surprising or non-obvious?]
  - **Learnings**
    - [What did we discover about the codebase/system?]
    - [What patterns or anti-patterns emerged?]
- **Research**
  - [Link title](url)
    - [Brief summary of findings from this source]
- **Delegation**
  - | Agent | Calls | Edits |
    |-------|-------|-------|
    | captain | — | +N / -N (M files) |
    | explore | N | — |
    | backend | N | — |
    | critic | N | — |
  - **Delegation Score**: N/10
    - [Reason 1 for the score]
    - [Reason 2 for the score]
    - [Whether critic was called, whether architect should have been called, etc.]
- **Session Info**
  - | Metric | Value |
    |--------|-------|
    | Session ID | `ses_...` |
    | Duration | Xh Ym |
    | Cost | $X.XX |
    | Tokens | Xk in / Xk out / Xk cache |
    | Repository | `name` (`branch`) |
```

**Section rules:**
- **GitHub**: Only include if there are issues or PRs in the metadata. Omit the section entirely if none.
- **Summary**: Concise problem statement + outcome. Past tense, active voice.
- **Retrospective**: The core value — be specific about problems, plans, gotchas, and learnings. Don't be generic.
- **Research**: Only include if there are librarian sources in the metadata. Each link gets a brief summary of what was found. Omit if none.
- **Delegation**: Always include. The delegation score is your assessment (see scoring guide below).
- **Session Info**: Always include at the bottom. Use data directly from the JSON metadata.

#### 3b: Daily Journal Entry (appended to `~/Documents/Logseq/journals/YYYY_MM_DD.md`)

Generate a compact entry:

```
- [[Work/<title>]] #opencode
  - **Problem**: [One sentence]
  - **Outcome**: [One sentence]
  - **Cost**: $X.XX | Xh Ym
```

### Step 4: Write Logseq Files

1. **Work page**: Write to `~/Documents/Logseq/pages/Work___<title>.md`
   - Generate the filename from the session title: replace `/` with `___`, keep spaces, remove characters `<>:"/\|?*`
   - Truncate to 120 characters max

2. **Daily journal**: Append to `~/Documents/Logseq/journals/YYYY_MM_DD.md`
   - Use the session start date for the filename (format: `YYYY_MM_DD`)
   - If the file exists, read it first and append the new entry at the end
   - If it doesn't exist, create it with just the entry

Use the Write tool for the work page and the Edit tool (or Write with existing content prepended) for the daily journal.

### Step 5: Report Results

Output to the user:
- Path to the daily journal entry
- Path to the work page
- Brief confirmation of what was captured

## Delegation Score Guide

Evaluate delegation quality based on the JSON metadata:

**Scoring:**
- **9-10**: Captain delegated all implementation, critic reviewed, architect consulted when needed
- **7-8**: Minor captain edits (config, small fixes), good delegation otherwise
- **5-6**: Captain wrote significant code that should have been delegated
- **3-4**: Captain did most implementation work directly
- **1-2**: No delegation at all, captain did everything

**Always assess:**
- If critic was NOT called after implementation work → flag it
- If captain made substantial edits (>50 lines) → note which agent should have handled it
- If architect was not called but design decisions were made → flag it
- If captain had 0 edits and delegated well → praise it

**Format:** Score on one line, reasons as bullet points underneath:
```
- **Delegation Score**: 7/10
  - Captain made direct edits to 2 config files — acceptable for small changes
  - Critic was called after backend implementation ✓
  - Architect was not consulted for the caching strategy decision
```

## Guidelines

- **Session detection must be accurate** — verify the session matches the current project directory
- **If session detection fails**, ask the user to provide the session ID manually
- **Be specific in the retro** — avoid generic phrases like "worked on" or "made changes"
- **The script handles credential sanitization** in the JSON — but avoid including secrets in your narrative
- **Logseq outliner format** — every line must start with `- ` (top-level) or `  - ` (nested). Tables go under a bullet.
- **Omit empty sections** — if no GitHub links, no research, etc., skip those sections entirely
