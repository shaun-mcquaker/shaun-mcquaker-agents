---
name: deep-research
description: Deep multi-perspective research system for exploring project ideas. Coordinates two AI researchers (visionary + pragmatist) through structured debate rounds, producing Logseq artifacts at each stage. Supports resuming and extending existing research topics. Activates for "research this", "deep dive", "explore this idea", or when @research-lead is invoked.
license: MIT
metadata:
  category: global
---

# Deep Research

Multi-perspective research system that coordinates two AI researchers through structured debate to produce comprehensive, implementation-ready project outlines.

## Quick Start

```
@research-lead Build a Chrome extension that summarizes academic papers into flashcards
```

To resume an existing topic:
```
@research-lead resume ScholarFlash: explore the spaced repetition algorithm in more depth
```

To list existing topics:
```
@research-lead resume
```

## Architecture

The system uses a three-agent structure:

1. **research-lead** (`openai/gpt-5.4`) — Orchestrator. Frames questions, synthesizes perspectives, writes artifacts, manages the research flow.
2. **visionary** (`openai/gpt-5.4`) — Expansive thinker. Explores possibilities, challenges conventions, pushes for ambitious approaches.
3. **pragmatist** (`openai/gpt-5.4`) — Feasibility analyst. Evaluates constraints, identifies risks, grounds ideas in reality.

The three agents share `openai/gpt-5.4`, with role prompts and temperatures providing the perspective split.

## Workflow

### New Topic

```
User: @research-lead <idea description>
                    ↓
    ┌───────────────────────────────────┐
    │ Round 1: Problem Space & Vision   │
    │  → visionary: ideal experience?   │
    │  → pragmatist: hard problems?     │
    │  → Synthesize → Write artifact    │
    └───────────────────────────────────┘
                    ↓
    ┌───────────────────────────────────┐
    │ Round 2: Solution Approaches      │
    │  → visionary: innovative ideas?   │
    │  → pragmatist: proven patterns?   │
    │  → Synthesize → Write artifact    │
    └───────────────────────────────────┘
                    ↓
    ┌───────────────────────────────────┐
    │ Round 3: Architecture & Design    │
    │  → visionary: 10x version?        │
    │  → pragmatist: concrete arch?     │
    │  → Synthesize → Write artifact    │
    └───────────────────────────────────┘
                    ↓
    ┌───────────────────────────────────┐
    │ Round 4: Roadmap & Final Outline  │
    │  → visionary: MVP vs future?      │
    │  → pragmatist: critical path?     │
    │  → Synthesize → Write artifact    │
    └───────────────────────────────────┘
                    ↓
    Topic index + daily journal updated
    User reviews asynchronously
```

### Resume Topic

```
User: @research-lead resume TopicName: <follow-up question>
                    ↓
    ┌───────────────────────────────────┐
    │ Load Context (tiered):            │
    │  1. Topic index (always)          │
    │  2. Latest outline (always)       │
    │  3. Relevant rounds (if needed)   │
    └───────────────────────────────────┘
                    ↓
    ┌───────────────────────────────────┐
    │ Follow-up Round(s)                │
    │  → visionary + pragmatist         │
    │  → Synthesize → Write artifact    │
    │  → Continue round numbering (5+)  │
    └───────────────────────────────────┘
                    ↓
    Topic index updated with new rounds
```

## Logseq Output

> **CRITICAL — Logseq Outliner Format**: All Logseq page content MUST use outliner format. Every content block starts with `- `. Headings become `- ## Heading`. Child content is indented 2 spaces: `  - child`. Properties at the top of the file (like `tags::`) do NOT get `- ` prefix. No blank lines between blocks. See the templates in `research-lead.md` for the exact format.

> **CRITICAL — Logseq Links vs Filenames**: Filenames use `___` as namespace separator (e.g., `Research___Topic___Round 1.md`), but **wikilinks in page content** use `/` (e.g., `[[Research/Topic/Round 1]]`). Never use `___` inside `[[ ]]` links.

> **CRITICAL — Logseq Tags**: Tags use `#` prefix (e.g., `tags:: #research, #topic`). Use flat tag names — NOT nested like `research/topic`.

### File Structure

```
~/Documents/Logseq/pages/
├── Research___<Topic>.md                              # Topic index (hub)
├── Research___<Topic>___Round 1 Problem Space.md      # Round artifacts
├── Research___<Topic>___Round 2 Solution Exploration.md
├── Research___<Topic>___Round 3 Architecture.md
├── Research___<Topic>___Round 4 Final Outline.md
├── Research___<Topic>___Round 5 <Follow-up Title>.md  # Follow-ups
└── Research___<Topic>___Round 7 Revised Outline.md    # New outline version
```

**Naming**: TopicName uses PascalCase, no spaces (e.g., `ScholarFlash`, `AICodeEditor`).

### Topic Index Page

The hub page (`Research___<Topic>.md`) contains:
- **Overview**: Topic description and original prompt
- **Metadata**: Status, models, dates, current outline version, total rounds
- **Research Rounds**: Linked list of all rounds with one-line summaries
- **Follow-up Questions Explored**: Record of what was asked in follow-ups

Uses Logseq properties: `tags:: #research, #<topic>`, `status:: active`

### Round Artifacts

Each round page contains:
- **Logseq properties**: `round::`, `topic::`, `type::` (initial/follow-up), `parent-rounds::`, `date::`
- **Question Posed**: What research-lead asked
- **Visionary Perspective**: Attributed response from visionary
- **Pragmatist Perspective**: Attributed response from pragmatist
- **Tensions Identified**: Where perspectives conflicted
- **Synthesis & Resolution**: How tensions were resolved
- **Carrying Forward**: Key insights for next round

### Final Outline

The outline round (Round 4, or revised versions) contains:
- Vision & Goals
- Target Users
- Architecture (components, data flow, tech stack)
- Implementation Phases (MVP → Enhancement → Scale) with task checklists
- Key Decisions & Trade-offs table
- Risks & Mitigations table
- Open Questions
- Handoff instructions to captain

### Daily Journal

Appends a compact entry to `~/Documents/Logseq/journals/<YYYY_MM_DD>.md` linking to the research topic.

## Resume & Follow-up

### Context Loading Strategy

When resuming, research-lead uses tiered context loading:

| Tier | What | When |
|------|------|------|
| **Always** | Topic index + latest outline | Every resume |
| **Conditional** | Specific round | User references it |
| **Conditional** | Grep results across rounds | User mentions specific concept |
| **Never** | All rounds in full | Already synthesized into outline |

### Outline Versioning

- Initial outline is Round 4 (v1)
- After material follow-ups, a new outline round is created (e.g., Round 7 = v2)
- Old outlines are never overwritten — they remain as historical artifacts
- Topic index always points to the current version

### Round Numbering

Follow-up rounds continue sequential numbering: 5, 6, 7...
No nested numbering (3.1) or separate schemes (Follow-up 1).

## Handoff to Captain

When research is complete and the user wants to implement:

```
@captain implement Phase 1 of [[Research/ScholarFlash/Round 4 Final Outline]]
```

Captain reads the outline and creates beads/tasks for implementation.

## Integration

- **Logseq**: All artifacts written to `~/Documents/Logseq/pages/`
- **Captain**: Final outlines designed for direct handoff
- **Beads**: Captain can create beads from outline task checklists
- **Journal**: Research sessions appear in daily Logseq journal

## Configuration

- **Logseq graph**: `~/Documents/Logseq/`
- **Pages directory**: `~/Documents/Logseq/pages/`
- **Journals directory**: `~/Documents/Logseq/journals/`
- **Namespace prefix**: `Research___`
- **File format**: Markdown (`.md`)
