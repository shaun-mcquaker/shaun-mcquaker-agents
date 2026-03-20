---
name: checkin
description: Conversational comms triage — email, Slack, Vault posts, and calendar review. Works through each phase interactively with Shaun to get communications under control and prep for what's ahead.
---

## Purpose

This is a conversational, phased comms check-in. Work through each phase in order, getting confirmation before moving to the next. Never dump everything at once — this is a back-and-forth process.

**Phases (in order):**

1. Email triage
2. Slack catch-up
3. Vault posts
4. Calendar review

At the start, briefly state which phases are available, then immediately launch the parallel pre-fetch (Phase 0) before presenting Phase 1 results.

## CRITICAL — Invocation Rules

**This skill MUST be executed directly by the main orchestrator in the primary conversation context.** Do NOT delegate the skill itself to a sub-agent via the Task tool.

Why: This skill is inherently interactive — it uses the `question` tool for disposition prompts and requires back-and-forth with Shaun across multiple decision points. The Task tool runs sub-agents autonomously and returns a single result string, which means the `question` tool inside a sub-agent never reaches Shaun.

**The correct pattern:**

1. Load this skill via the `skill` tool in the main conversation
2. **Delegate data-gathering to specialist sub-agents** (email, slack, vault, calendar) via the Task tool — they fetch and format data, then return structured results
3. **Present results and handle all interaction directly** — use the `question` tool in the main conversation for disposition prompts, phase transitions, and follow-up decisions
4. Never delegate disposition decisions or interactive flows to a sub-agent

## CRITICAL — Pacing Rules

These rules apply across all phases. Violating them is the most common failure mode.

- **Parallel pre-fetch, sequential presentation.** All four phases launch their data-gathering sub-agents in parallel at the start (see Phase 0). But **presentation and disposition remain strictly sequential** — Phase 1 is fully resolved before Phase 2 results are shown, and so on.
- **One item at a time within a phase.** For priority mail and DMs, present one item, wait for Shaun's explicit disposition, then move to the next. Do not present multiple items at once unless the skill explicitly says to batch them.
- **Never proceed without a gate.** Every phase ends with an explicit question asking Shaun if he's ready to move on. Do not transition until he confirms.
- **Context before questions — always.** Every disposition prompt (whether via the `question` tool or plain text) MUST be preceded by the contextual summary that informs the decision. Never present a bare question. If you're asking about an email, the sender/subject/summary comes first. If you're asking about channels to mark read, the batch summary listing channel names and topic summaries comes first. If you're asking about a phase transition, the phase wrap-up tally comes first. The reader should never see a question without enough context to answer it confidently.

---

## Phase 0 — Parallel Pre-fetch

Before entering Phase 1, **launch all four data-gathering sub-agents in parallel** using a single message with four Task tool calls. This ensures all phase data is fetched concurrently — Shaun only waits once, and results are ready instantly for each phase transition.

### Prerequisites

1. **Read the state file** from `~/.local/state/checkin/last-run.json`. Extract:
   - `slack_last_checkin` — timestamp boundary for Slack mentions search (fall back to 24 hours ago if absent)
   - `vault_last_checkin` — date boundary for Vault feed (fall back to 24 hours ago if absent)
   - `vault_last_seen_post_id` — integer for Vault feed deduplication (fall back to 0 if absent)

2. **Launch all four agents in parallel** (single message, four Task tool calls):

#### Email agent (`subagent_type: email`)

> Fetch all unread inbox messages (`in:inbox is:unread`, include bodies, paginate if needed). Categorize each message using your priority rules. Return the categorized breakdown. Skip empty categories.

#### Slack agent (`subagent_type: slack`)

> Fetch my current unreads. Categorise them into: (1) DMs / group DMs, (2) team channels (`#growth-labs-clubhouse` C035SJYJ2SK, `#growth-labs` C02AZLBCR3N, `#growth-labs-ops` C038G4JRXMW), (3) other channels, and (4) threads with new replies. Resolve all channel names. Report unread counts or backlog estimates for each.

#### Vault agent (`subagent_type: vault`)

> Fetch Shaun's Vault feed since `<vault_last_checkin date in YYYY-MM-DD>` through tomorrow. Discard any posts with ID ≤ `<vault_last_seen_post_id>`. Also fetch Growth Labs team posts (team ID 3003) and search for mentions of "Shaun McQuaker" in posts. Deduplicate across all three sources. Bucket the results into: (1) Growth Labs, (2) Mentions, (3) Feed. Return a structured batch summary: one line per post with author, title, and 1-sentence summary. Skip empty buckets. Also report the highest post ID across all results.

#### Calendar agent (`subagent_type: calendar`)

> Fetch two things: (1) today's remaining events (from now through end of day), and (2) tomorrow's full schedule. Filter calendar furniture, annotate each event with its colour category, resolve attendee names, and flag any scheduling concerns. Return structured summaries for both days.

3. **Store all four `task_id` values** for session reuse during each phase. When a phase needs follow-up actions (e.g., mark a channel read, fetch a full post, archive an email), reuse the original agent session so it retains context from the pre-fetch.

4. **Begin Phase 1** as soon as the email agent's results are available — don't wait for all four to complete. Present email results while the other agents may still be running.

---

## Phase 1 — Email Triage

### Context

Most inbox noise is handled by Gmail filters. What reaches the inbox should be genuinely worth triaging. The email agent knows what the filters should catch and will flag leakage.

### Tools

**All email operations are delegated to the email agent** (`subagent_type: email`). The email agent handles message fetching, categorization (5-tier priority system), and action execution (archive, star, mark read, etc.).

**Reuse the email agent session** from Phase 0's pre-fetch — the agent already has the categorized results and retains message IDs for follow-up actions.

**Interactive disposition stays in the main conversation.** The email agent fetches and categorizes; you present results to Shaun and handle his responses directly (via the `question` tool).

### Step 1: Present categorized results

The email agent's pre-fetch response contains messages sorted into five priority categories. Present them in priority order, following these rules:

**Only present categories that have messages.** Skip empty categories entirely.

#### Priority mail (category 1)

Present **one message at a time**:
- Sender, subject, date
- Brief summary of the content (2–3 sentences max)
- Whether it seems to need a reply

**Stop and wait for Shaun's explicit disposition before presenting the next message.** Disposition options:
- Reply (draft together interactively)
- Star it for later
- Mark as read and move on
- Archive

For actions, **delegate to the email agent** (reuse session): e.g., "archive that message" or "star it".

Do **not** proactively draft replies — only when asked.

#### GitHub actionable (category 2)

Present each message with:
- Repo, PR/issue title, who mentioned Shaun
- Brief summary of what's being asked

Wait for disposition on each. Delegate actions to the email agent.

#### Vendor status / incidents (category 3)

Present as a summarized batch. Ask if Shaun wants detail on any, otherwise move on. These stay in inbox as-is.

#### Mailing list / group threads (category 4)

Present as a summarized batch. Ask which (if any) Shaun wants to look at in detail. Archive the rest via the email agent after confirmation.

#### Filter leakage (category 5)

If the email agent identified leakage:
- Present the leaked messages with sender, subject, and the agent's diagnosed cause
- Suggest reviewing Gmail filter configuration to fix — don't fix inline during triage

Archive leaked messages via the email agent after confirmation.

### Step 2: Wrap-up

Once email is fully triaged:

1. **Tally:** "Archived X, starred Y, replied to Z, N unread remaining."
2. **Filter health:** Note any leakage or new patterns observed.
3. **Transition:** "Email's under control. Ready to move on to Slack?"

Transition to Phase 2.

---

## Phase 2 — Slack Catch-up

### Context

Shaun's Slack handle is `Shaun McQuaker` (User ID: `W018HUTN6BV`). Key channels:

| Channel | ID | Purpose |
|---------|----|---------|
| `#growth-labs-clubhouse` | `C035SJYJ2SK` | Team private channel — highest priority |
| `#growth-labs` | `C02AZLBCR3N` | Team public channel |
| `#growth-labs-ops` | `C038G4JRXMW` | Ops channel |

### State tracking

State file is read once in Phase 0. At the end of Phase 2, write the current timestamp into `slack_last_checkin` in `~/.local/state/checkin/last-run.json`.

### Tools

**All Slack operations are delegated to the slack agent** (`subagent_type: slack`). The slack agent handles API quirks (timestamp extraction, unfurl suppression, channel name resolution, etc.) and retains message IDs in its context for follow-up actions like "mark that channel read" or "reply in that thread".

**Reuse the slack agent session** from Phase 0's pre-fetch — the agent already has the unreads summary and retains channel IDs, timestamps, and message context for follow-up actions.

**Interactive disposition stays in the main conversation.** The slack agent fetches and formats data; you present it to Shaun and handle his responses directly (via the `question` tool). Never delegate disposition decisions to the slack agent.

### Step 1: Present unreads summary

The slack agent's pre-fetch response contains unreads categorized into DMs, team channels, other channels, and threads. Parse it into buckets. If everything is at zero, say so and skip to Step 6 (mentions search).

### Step 2: DMs and group DMs

For each DM/group DM with unreads, in order of most recent activity:

1. **Delegate to the slack agent** (reuse session): fetch the last 20 messages from the DM for context, highlighting which are unread.
2. Present:
   - Who the conversation is with
   - The recent exchange for context
   - The unread messages clearly indicated
3. Wait for disposition. Options:
   - **Reply** — draft together interactively, then delegate sending to the slack agent
   - **Star** — delegate to the slack agent to save the message
   - **Mark read** — delegate to the slack agent
   - **Leave for now** — no action, do not mark read

After Shaun has disposed of all DMs: "Mark all reviewed DMs as read?" — confirm, then delegate mark-as-read to the slack agent.

### Step 3: Team channels

For each of the three team channels that have unreads (`#growth-labs-clubhouse` first, then `#growth-labs`, then `#growth-labs-ops`):

1. **Delegate to the slack agent** (reuse session):

   > Fetch unread messages from `<channel>` since `<oldest unread timestamp>`. For any message containing a GitHub PR or issue link, check reactions and annotate with PR workflow status (`:eyes:`, `:commented1:`, `:approve:`, `:pr-merged:`). Deprioritise messages that have `:approve:` or `:pr-merged:` — mark them as already handled. Summarise by topic, 1–3 sentences each. Flag anything that looks like it needs Shaun's attention.

2. Present the agent's summary to Shaun.
3. Highlight anything flagged as needing his input.
4. Wait for disposition. Shaun may want to:
   - Reply to something (draft together, then delegate sending to the slack agent)
   - Dig into a specific thread (delegate fetching to the slack agent)
   - Mark read and move on

After each channel is handled, confirm and delegate mark-as-read to the slack agent.

### Step 4: Other channels

**Delegate to the slack agent** (reuse session):

> For each of these channels with unreads [list channel names/IDs], fetch recent messages, check PR reactions where applicable, and give a one-line summary per channel: channel name, backlog estimate, brief topic.

Present the agent's batch summary to Shaun. Ask which (if any) he wants to look at in detail.

**Stop and wait for Shaun's response before taking any action.**

For channels he wants to dig into, delegate deeper fetching to the slack agent and present as in Step 3. For the rest, confirm and delegate bulk mark-as-read to the slack agent — but only after Shaun explicitly confirms which ones to mark read.

### Step 5: Thread catch-up

Skip any threads already surfaced in Steps 2–4. For remaining threads with new replies:

**Delegate to the slack agent** (reuse session):

> Fetch these threads [list channel + root timestamp for each]. For each, return: which channel, thread topic/root message, and the new replies.

Present each thread to Shaun. Wait for disposition per thread (reply, mark read, leave).

If no threads remain after deduplication, skip this section silently.

### Step 6: Mentions search

**Delegate to the slack agent** (reuse session):

> Search for messages mentioning Shaun since `<slack_last_checkin from Phase 0 state>`. Deduplicate against anything already surfaced in this session. Return only net-new mentions with: channel, who mentioned Shaun, and brief context.

The slack agent knows to search both `@Shaun McQuaker` and `<@W018HUTN6BV>` formats and deduplicate.

Present net-new mentions to Shaun. Wait for disposition per mention.

If nothing net-new, say so briefly.

### Step 7: Saved items

**Delegate to the slack agent** (reuse session):

> Fetch my pending saved items (up to 20). For each, return: what it is (message preview or reminder text), when saved, and due date if applicable.

Present each item to Shaun. Disposition options per item:

- **Done** — delegate to slack agent to mark completed
- **Snooze** — Shaun provides a new date/time; delegate to slack agent to update due date
- **Leave as-is** — no action

If there are no saved items, skip this section silently.

### Step 8: Wrap-up

1. **Tally:** "Reviewed X DMs, Y channels, Z threads. Replied to A, starred B, marked C read."
2. **Write last check-in timestamp** to `~/.local/state/checkin/last-run.json` with the current time.
3. **Transition:** "Slack is clear. Ready to move on to Vault posts?"

Transition to Phase 3.

---

## Phase 3 — Vault Posts

### Context

Shaun's Vault profile ID is `10809`. Growth Labs team ID is `3003`.

Vault has no mark-as-read concept. The goal here is awareness — surface what's worth reading, let Shaun dig into anything interesting, and note anything that warrants a comment or award (which he'll action in-browser, since the Vault MCP has no write tools for posts).

### State tracking

State file is read once in Phase 0. At the end of Phase 3, write both `vault_last_checkin` (current timestamp) and `vault_last_seen_post_id` (highest post ID from the agent's results) to `~/.local/state/checkin/last-run.json`.

### Tools

**All Vault operations are delegated to the Vault agent** (`subagent_type: vault`). The Vault agent handles feed pagination, date-only API limitations, post ID–based deduplication, GL team post bucketing, and mentions search.

**Reuse the Vault agent session** from Phase 0's pre-fetch — the agent already has the bucketed post summaries and retains post IDs for follow-up requests like "get the full post".

**Interactive disposition stays in the main conversation.** The Vault agent fetches and formats data; you present it to Shaun and handle his responses directly (via the `question` tool). Never delegate disposition decisions to the Vault agent.

### Step 1: Present the batch

Present the Vault agent's bucketed output directly. Growth Labs posts first, then Mentions, then Feed.

After presenting, ask: "Anything you want to read in full?"

**Stop and wait for Shaun's response before fetching any post content.**

### Step 2: Dig into posts on request

For each post Shaun wants to read, **delegate to the Vault agent** (reuse session):

> Fetch the full post for `<post title or author reference>`.

Present the full content and any notable comments. After reading, offer disposition via the `question` tool with these default options:

- **Open in browser** — run `open <vault_post_url>` to open the post in Shaun's default browser. This is the most common action (comment, award, share) and should always be the first option.
- **Read another post** — go back to the batch and pick another.
- **Move on** — done with Vault posts, proceed to wrap-up.

### Step 3: Wrap-up

1. **Tally:** "X posts in feed, Y from Growth Labs, Z mentions. Read N in full."
2. **Write state** to `~/.local/state/checkin/last-run.json`:
   - `vault_last_checkin` — current timestamp
   - `vault_last_seen_post_id` — highest numeric post ID across all posts presented (from feed, GL, and mentions combined)
3. **Transition:** "Vault's clear. Ready to review the calendar?"

Transition to Phase 4.

---

## Phase 4 — Calendar Review

### Context

This phase is forward-looking. The goal is to review what's remaining today and what's on the docket for tomorrow, surface anything that needs prep, and flag scheduling concerns (back-to-back blocks, missing agendas, etc.).

### Tools

**All calendar operations are delegated to the calendar agent** (`subagent_type: calendar`). The calendar agent handles colour category annotation, calendar furniture filtering, scheduling constraint awareness, attendee name resolution, and flag detection (back-to-back, missing agendas, uncategorized events, etc.).

**Reuse the calendar agent session** from Phase 0's pre-fetch — the agent already has today's remaining events and tomorrow's full schedule, pre-filtered and annotated. It retains event IDs for follow-up actions like "decline that meeting" or "add a description".

**Interactive disposition stays in the main conversation.** The calendar agent fetches and formats data; you present it to Shaun and handle his responses directly (via the `question` tool). Never delegate disposition decisions to the calendar agent.

### Step 1: Present today's remaining events

Present the calendar agent's pre-fetch output for today directly. The agent will have already:
- Filtered calendar furniture
- Annotated events with colour categories
- Resolved attendee names (GL teammates by first name, others by full name)
- Flagged scheduling concerns (back-to-back, imminent meetings, missing agendas, uncategorized events)
- Calculated summary stats (total meeting hours, longest gap)

After presenting, ask if Shaun wants to:
- Prep for any specific meeting (pull context from Vault projects, Slack threads, etc.)
- Decline or cancel anything (delegate the action to the calendar agent)
- Check someone's availability for rescheduling (delegate to the calendar agent)

### Step 2: Present tomorrow's events

Present the calendar agent's output for tomorrow. The agent will have additionally flagged:
- Early starts (before 9:00 AM ET)
- Long meetings (over 90 minutes)
- Overlapping events

Ask if Shaun wants to prep for anything tomorrow, or make changes.

### Step 3: Wrap-up

1. **Summary:** "X events remaining today, Y tomorrow. Z flagged for prep."
2. **Close out:** "All done — inbox, Slack, Vault, and calendar are under control."

---

## General Behaviour

- **Conversational, not robotic.** This is a casual check-in, not a status report. Keep it brisk but human.
- **Terse summaries.** Shaun reads fast — don't over-explain message contents. One to three sentences per email max.
- **Batch the noise, individualize the signal.** Noise gets bulk-actioned. Important items get individual attention.
- **Always confirm before bulk actions.** Never archive/mark-read in bulk without asking first.
- **Track what you've done.** At the end, give a brief tally.

### Use the `question` tool for all disposition prompts

Whenever you need Shaun's input — item disposition, bulk-action confirmation, phase transitions, or "want to dig into X?" — use the `question` tool instead of plain text questions. This lets Shaun respond with a click instead of typing.

**Guidelines:**

- **Keep `custom` enabled** (the default) so Shaun can always type a freeform answer if none of the options fit.
- **Set `multiple: true`** when asking which items from a batch to act on (e.g., "which channels to mark read?", "which posts to read in full?").
- **One question per decision point.** Don't bundle unrelated decisions into a single question call.
- **Option labels should be terse** — 1–5 words. Put the detail in the `description` field.
- **Put the recommended/default action first** and append "(Recommended)" to its label when there's an obvious default.
- **Phase transitions** get a simple yes/no-style question: e.g., "Move to Slack?" with options like "Yes" / "Not yet".

**Examples:**

Single email disposition:
```
question(header: "Email from Jane Doe", question: "Re: Q1 budget review — needs your sign-off by Friday.", options: [
  { label: "Archive", description: "No action needed" },
  { label: "Star for later", description: "Come back to it" },
  { label: "Reply", description: "Draft a reply together" },
  { label: "Mark read", description: "Acknowledged, move on" }
])
```

Bulk channel mark-read:
```
question(header: "Mark channels read?", question: "These channels had no actionable items.", options: [
  { label: "Mark all read (Recommended)", description: "#help-shopify-websites, #enable-pillar-lt, #mission-merchant-seo" },
  { label: "Keep all unread", description: "Leave everything as-is" }
], multiple: false)
```

Vault post dig-in:
```
question(header: "Vault posts", question: "3 new posts in feed. Want to read any in full?", options: [
  { label: "Post title A", description: "Author — brief summary" },
  { label: "Post title B", description: "Author — brief summary" },
  { label: "None, move on", description: "Skip to wrap-up" }
], multiple: true)
```
