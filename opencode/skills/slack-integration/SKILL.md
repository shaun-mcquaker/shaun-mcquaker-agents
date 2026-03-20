---
name: slack-integration
description: Slack workspace integration for reading messages, sending updates, managing channels, and synthesizing team communication using the Slack MCP.
---

# Skill: Slack Integration

## Description
This skill provides comprehensive Slack workspace integration via the `@shopify-internal/slack-mcp`. Use it to read channel history, send messages, manage notifications, track saved items, and generate TL;DR summaries of team discussions.

## Triggers
- "What's happening in #channel-name"
- "Catch me up on #channel-name"
- "Send a message to @person"
- "What are my unread messages"
- "Summarize recent activity in #channel"
- `/slack-tldr` command invocation

## Prerequisites
- Slack MCP must be enabled in `opencode.jsonc`
- Valid credentials stored in `~/.config/slack-mcp/credentials.json` (managed by `slack-mcp_update_auth`)
- User must be a member of the Shopify Slack workspace

## Core Capabilities

### 1. Channel Discovery & Information
**Get channel sections and list:**
```
slack-mcp_get_channel_sections(output_format="json")
```
Returns channels organized by sidebar sections. **Important:** This only returns channels pinned to your sidebar, not all channels you belong to.

**Resolve a channel name to ID (when not in sidebar):**
```
slack-mcp_get_messages(action="search", query="in:#channel-name", count=1)
```
Extract the channel ID from the permalink URL in the search results (format: `https://shopify.slack.com/archives/<CHANNEL_ID>/...`).

**Get channel details:**
```
slack-mcp_get_channel_info(channel_id="C...", output_format="markdown")
```
Returns channel name, topic, purpose, member count, and metadata.

### 2. Reading Messages

**Get channel messages:**
```
slack-mcp_get_messages(action="channel", channel="C...", output_format="markdown")
```
Returns recent messages from a channel. Channel ID required (not name).

**Get DM messages:**
```
slack-mcp_get_messages(action="my_messages", count=50, output_format="markdown")
```
Returns your recent direct messages and mentions.

**Search messages:**
```
slack-mcp_get_messages(action="search", query="your search terms", count=100, output_format="markdown")
```
Searches across all accessible channels.

**Get thread replies:**
```
slack-mcp_get_messages(action="thread", channel="C...", ts="1234567890.123456", output_format="markdown")
```
Returns all replies in a specific thread.

### 3. Sending Messages

**Send to channel or DM:**
```
slack-mcp_send_message(target="#channel-name", text="Your message")
```
OR
```
slack-mcp_send_message(target="D0135ENDMV0", text="DM content")
```

**Reply to thread:**
```
slack-mcp_send_message(target="C...", text="Reply", thread_ts="1234567890.123456")
```

**Send with markdown:**
```
slack-mcp_send_message(target="#channel", markdown_text="**Bold** and _italic_")
```

### 4. Reactions & Saved Items

**Add reaction:**
```
slack-mcp_add_reactions(reactions=[{
  "channel": "C...",
  "timestamp": "1234567890.123456",
  "name": "thumbsup"
}])
```

**Get saved items:**
```
slack-mcp_get_saved_items(filter="saved", limit=15, output_format="markdown")
```

**Save a message for later:**
```
slack-mcp_add_saved_item(channel="C...", timestamp="1234567890.123456")
```

### 5. Status & Notifications

**Get current status:**
```
slack-mcp_get_status(output_format="markdown")
```

**Set status with DND:**
```
slack-mcp_set_status(
  text="In a meeting",
  emoji="calendar",
  duration=60,
  dnd_minutes=60
)
```

**Check unreads:**
```
slack-mcp_get_unreads(output_format="markdown")
```

**Mark as read:**
```
slack-mcp_mark_as_read(channel="C...", ts="1234567890.123456")
```

## Workflow: Generate Channel TL;DR

When asked to summarize channel activity (or via `/slack-tldr` command):

### Step 1: Resolve Channel Identifier
If user provides channel ID directly, use it as-is.

If user provides `#channel-name`, use a two-step resolution:

**1a. Check sidebar sections (fast path):**
1. Call `slack-mcp_get_channel_sections(output_format="json")`
2. Search all sections for matching channel name (strip `#` prefix)
3. If found, extract channel ID (format: `C...`)

**1b. Fall back to search (if not in sidebar):**
`get_channel_sections` only returns sidebar-pinned channels, NOT all channels you belong to. If the channel is not found in sections:
1. Call `slack-mcp_get_messages(action="search", query="in:#channel-name", count=1)`
2. Extract the channel ID from the message permalink URL (format: `https://shopify.slack.com/archives/<CHANNEL_ID>/...`)
3. If search returns no results, the channel may not exist or the user may not have access — ask to verify the name

### Step 2: Fetch Messages
```
slack-mcp_get_messages(action="channel", channel=<channel_id>, output_format="markdown")
```

### Step 3: Parse and Filter by Timeframe
- Parse message timestamps from the markdown output
- Filter to requested timeframe ("last 10 days", "since Monday", etc.)
- Group messages by topic/thread when possible

### Step 3b: Expand Key Threads
The initial channel fetch only returns top-level messages and some thread snippets. Proactively expand high-signal threads to capture decisions, answers, and important context that lives in replies.

```
slack-mcp_get_messages(action="thread", channel=<channel_id>, ts=<thread_ts>, output_format="markdown")
```

**Which threads to expand (pick up to ~5):**
1. Threads with decisions or questions — posts asking for input, alignment, or proposals
2. Announcements with discussion — "Start of Thread" markers with visible replies
3. Blockers or incidents — outages, deploy failures, blocking issues
4. Leadership posts — updates from leads/managers with likely follow-up
5. High-engagement posts — many reactions or replies signal important discussion

**How to identify thread timestamps:**
- Messages marked `(💬 Start of Thread)` have a `thread_ts`
- Extract from permalink: `https://shopify.slack.com/archives/<ID>/p<ts>?thread_ts=<thread_ts>`
- Or use the root message timestamp directly

**Parallel fetching:** Expand multiple threads simultaneously to save time.

**Context budget:** Limit to ~5 threads per summary. Prioritize threads most relevant to the timeframe and likely to contain decisions or answers.

### Step 4: Synthesize Summary
Generate structured TL;DR with sections:
- **Major Wins** — key accomplishments, shipped features, resolved blockers
- **Key Blockers & Issues** — active problems, deployment failures, critical bugs
- **Progress & Alignment** — decisions made, specs finalized, PRs merged
- **Questions Pending** — unanswered asks, pending reviews, awaiting input
- **Sentiment** — brief assessment of team velocity and mood

**Synthesis principles:**
- Include names, dates, and links (PRs, vault posts, docs)
- Quote directly when decisions or blockers are stated
- Group related messages (same topic across multiple people)
- Highlight patterns (recurring issues, common themes)
- Use emojis for scannability (🚀 ✅ ⚠️ 🐛 📊 🔧 ❓)

### Step 5: Offer Follow-up
After presenting the summary, offer:
- Deep-dive on specific threads
- Comparison to previous week
- Export to file or send to channel

## Target Resolution

Slack MCP supports multiple target formats for sending messages:

| Format | Example | Use Case |
|--------|---------|----------|
| `#channel-name` | `#growth-labs` | Public channel by name |
| `@username` | `@jclarkin` | User by handle (requires lookup) |
| Channel ID | `C035SJYJ2SK` | Direct channel reference |
| User ID | `U01F1EJT3EY` | Direct user reference |
| DM ID | `D0135ENDMV0` | Existing DM conversation |

**Note:** For reliability, prefer IDs over names. Channel names require lookup — first via `get_channel_sections` (sidebar only), then falling back to search with `in:#channel-name` for channels not pinned to the sidebar.

## Authentication

**Check auth status:**
```
slack-mcp_get_auth_help(output_format="markdown")
```

**Update credentials (browser extraction):**
```
slack-mcp_update_auth(useBrowser=true, saveCredentials=true)
```

Credentials are stored in `~/.config/slack-mcp/credentials.json` with permissions `0600`.

## Guidelines

- **Always filter by time** when generating summaries — don't include everything
- **Respect privacy** — don't share DM content without consent
- **Use IDs when possible** — channel/user IDs are more reliable than names
- **Batch operations** when adding multiple reactions or processing many messages
- **Provide context** in summaries — assume the reader missed the discussions
- **Link to sources** — include message timestamps/permalinks when referencing specific discussions
- **Handle rate limits gracefully** — if API calls fail, inform the user and suggest retry

## Common Patterns

### Pattern 1: Daily Standup Summary
Fetch last 24 hours of messages from team channel, group by person, summarize updates.

### Pattern 2: Project Status Update
Fetch last week from project channel, categorize by progress/blockers/decisions, generate executive summary.

### Pattern 3: On-Call Handoff
Fetch incident channels and on-call DMs, summarize active incidents and resolutions.

### Pattern 4: Weekly Team Digest
Fetch Monday-Friday from multiple channels, generate cross-team summary with key highlights.

## Error Handling

**Channel not found in sidebar:**
- Fall back to search: `slack-mcp_get_messages(action="search", query="in:#channel-name", count=1)`
- Extract channel ID from the permalink URL in search results
- If search also returns nothing, the channel may not exist or the user lacks access — ask to verify

**Authentication failed:**
- Run `slack-mcp_get_auth_help` to show setup instructions
- Suggest running `slack-mcp_update_auth(useBrowser=true)`

**Message sending failed:**
- Verify target format (channel ID, user ID, or `#channel-name`)
- Check that user has permission to post in the target

## References

- [Slack MCP Documentation](https://github.com/Shopify/slack-mcp) (internal)
- Credentials file: `~/.config/slack-mcp/credentials.json`
- MCP config: `~/.config/opencode/opencode.jsonc`
