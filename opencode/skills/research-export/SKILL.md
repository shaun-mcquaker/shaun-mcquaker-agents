---
name: research-export
description: Exports a deep research topic from Logseq into a single shareable Markdown file. Concatenates all round artifacts in order, strips Logseq-specific formatting (outliner bullets, properties), and produces clean standard Markdown. Activates for "export research", "share research", or when /export-research command is used.
license: MIT
metadata:
  category: global
---

# Research Export

Exports a complete deep research topic into a single, clean Markdown file suitable for sharing with colleagues who don't use Logseq.

## Quick Start

```
/export-research EcommercePulse
```

Produces: `~/Documents/Logseq/exports/EcommercePulse_export_2026-03-10.md`

## What It Does

1. **Finds all pages** matching `Research___<TopicName>*.md` in `~/Documents/Logseq/pages/`
2. **Orders them**: Topic index first, then rounds in numerical order
3. **Converts from Logseq outliner format to standard Markdown**:
   - Strips `- ` bullet prefixes from content blocks
   - Converts indentation back to standard Markdown structure
   - Removes Logseq properties (`tags::`, `round::`, `status::`, `topic::`, `type::`, `date::`, `version::`, `parent-rounds::`)
   - Strips `[[` and `]]` from wikilinks, leaving plain text
4. **Adds a document header** with title, export date, and source file count
5. **Inserts horizontal rules** (`---`) between rounds for visual separation
6. **Writes** the combined file to `~/Documents/Logseq/exports/`

## Output Location

```
~/Documents/Logseq/exports/<TopicName>_export_<YYYY-MM-DD>.md
```

The `exports/` directory is created automatically if it doesn't exist.

## Configuration

- **Source directory**: `~/Documents/Logseq/pages/`
- **Output directory**: `~/Documents/Logseq/exports/`
- **File pattern**: `Research___<TopicName>*.md`
