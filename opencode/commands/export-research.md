# Export Research Topic

Export a deep research topic to a single shareable Markdown file: `/export-research $ARGUMENTS`

The `/export-research` command concatenates all Logseq pages for a research topic into a single clean Markdown file, converting from Logseq outliner format to standard Markdown suitable for sharing with colleagues.

## Process

### Step 1: Determine the Topic Name

The argument is the PascalCase topic name (e.g., `EcommercePulse`, `ScholarFlash`).

If no argument is provided, scan `~/Documents/Logseq/pages/` for `Research___*.md` files and list available topics for the user to choose from:

```bash
ls ~/Documents/Logseq/pages/Research___*.md 2>/dev/null | sed 's/.*Research___//;s/___.*//;s/\.md//' | sort -u
```

### Step 2: Run the Export Script

```bash
bash ~/.config/opencode/skills/research-export/export.sh <TopicName>
```

This will:
1. Find all `Research___<TopicName>*.md` files in `~/Documents/Logseq/pages/`
2. Order them (index first, then rounds numerically)
3. Convert from Logseq outliner format to clean standard Markdown
4. Strip Logseq properties, convert wikilinks to plain text, convert TODO items to checkboxes
5. Write the combined file to `~/Documents/Logseq/exports/`

### Step 3: Report the Result

Tell the user:
- The output file path
- How many source files were included
- Suggest they can find the file at `~/Documents/Logseq/exports/<TopicName>_export_<date>.md`
