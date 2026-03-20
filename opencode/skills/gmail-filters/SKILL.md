---
name: gmail-filters
description: Manage Gmail filter rules declaratively via gmailctl. Review current filters, add/edit/remove rules, diff, test, and apply changes. Also handles one-time inbox cleanup for newly created filters.
---

## Purpose

Manage Shaun's Gmail filters using [`gmailctl`](https://github.com/mbrt/gmailctl) — a declarative, Jsonnet-based tool that syncs filter rules to Gmail via the API. This skill handles the full lifecycle: reviewing existing rules, proposing new ones, diffing, applying, and doing one-time inbox cleanup after a new filter goes live.

The `checkin` skill may invoke this skill when it detects patterns in inbox noise that could be automated.

---

## Tool & Config

- **CLI:** `gmailctl` (installed via Homebrew)
- **Config file:** `~/.gmailctl/config.jsonnet`
- **Config source (version-controlled):** `~/src/github.com/shopify-playground/shaun-mcquaker/gmailctl/config.jsonnet`
- **Config format:** Jsonnet, version `v1alpha3`
- **Standard library:** `~/.gmailctl/gmailctl.libsonnet` (available but not currently imported)
- **Auth:** `~/.gmailctl/credentials.json` + `~/.gmailctl/token.json` (do not read or modify these)

> **Note:** The live config at `~/.gmailctl/config.jsonnet` is symlinked from the repo copy. Edits should target the repo path so changes are version-controlled and show up in `git diff`.

### Key commands

| Command                                       | Purpose                                             |
| --------------------------------------------- | --------------------------------------------------- |
| `gmailctl diff`                               | Show pending changes vs. remote Gmail state         |
| `gmailctl apply --yes`                        | Apply config to Gmail (always diff first)           |
| `gmailctl test`                               | Run unit tests defined in config                    |
| `gmailctl download > $TMPDIR/current.jsonnet` | Snapshot current remote filters                     |
| `gmailctl edit`                               | Open config in editor (not useful in agent context) |

---

## Workflow

### Adding a new filter

1. **Investigate the pattern.** Read sample messages from inbox using `read_mail` to understand sender, subject, body patterns. Identify the most reliable matching criteria.
2. **Edit the config.** Add the rule to `~/.gmailctl/config.jsonnet`. If the rule needs a new label, add it to the `labels` array too.
3. **Diff.** Run `gmailctl diff` and present the output to Shaun for review.
4. **Apply.** Run `gmailctl apply --yes` only after Shaun confirms.
5. **One-time cleanup.** Use `read_mail` to find existing inbox messages matching the new filter, then `manage_mail` to archive + mark read. Always confirm the count with Shaun before bulk-actioning.

### Modifying an existing filter

Same workflow — edit, diff, confirm, apply. Pay attention to `isEscaped: true` markers from the original download; port these to native gmailctl expressions when touching them.

### Reviewing current state

Run `gmailctl diff` — if the output is empty, local config matches remote. If not, something drifted (manual filter edit in Gmail UI, or unapplied local changes).

---

## Config Conventions

### Filter structure

Each rule is an object with `filter` and `actions`:

```jsonnet
{
  filter: {
    // matching criteria
  },
  actions: {
    // what to do with matched messages
  },
}
```

### Matching criteria

| Field       | Type   | Notes                                                        |
| ----------- | ------ | ------------------------------------------------------------ |
| `from`      | string | Sender address or name                                       |
| `to`        | string | Recipient address                                            |
| `subject`   | string | Subject line match                                           |
| `has`       | string | Body/header keyword match                                    |
| `query`     | string | Raw Gmail search query (for `list:` and other advanced ops)  |
| `not`       | object | Negation wrapper — takes any single criterion                |
| `and`       | array  | Combine multiple criteria (all must match)                   |
| `or`        | array  | Combine multiple criteria (any must match)                   |
| `isEscaped` | bool   | Marks criteria imported verbatim from Gmail; port to native when editing |

### Actions

| Field        | Type          | Notes                                                  |
| ------------ | ------------- | ------------------------------------------------------ |
| `archive`    | bool          | Remove from inbox                                      |
| `markRead`   | bool          | Mark as read                                           |
| `markSpam`   | bool          | `false` to force never-spam                            |
| `labels`     | array[string] | Apply these labels (must exist in `labels` array)      |
| `category`   | string        | Gmail category tab (`updates`, `promotions`, etc.)     |
| `star`       | bool          | Star the message                                       |
| `forward`    | string        | Forward to this address                                |
| `markImportant` | bool       | Mark as important (`false` to suppress)                |

### Labels

Labels are declared in the top-level `labels` array. Nested labels use `/` separators (e.g., `"1 – Daily Emails/SEO Radar"`). Labels can optionally include `color` with `background` and `text` hex values.

Shaun's current label hierarchy:

- **`1 – Daily Emails/`** — automated daily reports (SEO, metrics, monitoring)
- **`2 – Weekly Emails/`** — automated weekly rollups
- **`GitHub`** — GitHub notification overflow
- **`GCP Notices`** — Google Cloud platform noise
- **`Notes`** — personal notes
- **`Recruiting`** — recruiting-related
- **`Leadership`** — leadership comms
- **`Growth Ideas`** — growth initiative ideas
- **`Funnies`** — the good stuff

### Filter design principles

- **Match on the most stable signal.** Prefer `from` address over subject keywords. Use `query: "list:(...)"` for mailing-list traffic — it's the most reliable identifier.
- **Combine criteria with `and` for precision.** A `from` + `list:` combo is more robust than either alone.
- **Default action for automated reports:** `archive: true, markRead: true` + a label. This keeps inbox clean while preserving searchability.
- **Use `markSpam: false`** on any filter matching legitimate automated mail — Gmail's spam classifier can be aggressive with high-volume senders.
- **Add comments** above rules explaining what they catch and why. Future-you will thank present-you.
- **Keep rules ordered by category.** Group infrastructure noise, then daily reports, then weekly reports, then ad-hoc.

---

## Safety

- **Always `gmailctl diff` before `gmailctl apply`.** No exceptions. Present the diff to Shaun and get explicit confirmation.
- **Never modify auth files.** `credentials.json` and `token.json` are off-limits.
- **Confirm bulk cleanup counts.** Before archiving/marking-read existing messages for a new filter, tell Shaun how many messages will be affected and get a go-ahead.
- **Don't delete filters without discussion.** Removing a rule means future messages matching it will land in inbox again. Always flag this trade-off.
- **Test with `gmailctl test`** if the config includes test cases. Don't skip this step.
- **Version control changes.** Since the config is tracked in the repo at `~/src/github.com/shopify-playground/shaun-mcquaker/gmailctl/`, changes will show in `git status`. Remind Shaun to commit after applying.
