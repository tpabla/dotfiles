---
name: sync
description: Bidirectional Notion sync for wiki documents. Pull, push, diff, and status operations with hash-based change detection and git versioning.
user_invocable: true
---

# Wiki Notion Sync

Bidirectional sync between local wiki/sync/ files and Notion pages.

## Usage

- `/sync status` — Show all sync files, their hashes, and whether they need pull/push
- `/sync pull <doc>` — Pull latest from Notion into local file
- `/sync push <doc>` — Push local changes to Notion
- `/sync diff <doc>` — Show differences between local and Notion
- `/sync pull-all` — Pull all sync files
- `/sync push-all` — Push all sync files with local changes

`<doc>` is a fuzzy match against filenames in `wiki/sync/` (e.g. "unknowns" matches `unified-subscription-unknowns.md`).

## Sync File Format

Each file in `wiki/sync/` has YAML frontmatter:

```yaml
---
sync:
  notion_url: https://www.notion.so/...
  notion_id: <page-id>
  direction: bidirectional | wiki-to-notion | notion-to-wiki
  local_status: draft | ready-to-push | synced
  last_pulled: YYYY-MM-DD
  last_pushed: YYYY-MM-DD | null
  local_hash: <sha256>
  pulled_hash: <sha256>
  pushed_hash: <sha256>
---
```

## Hash Computation

Strip YAML frontmatter, then SHA-256 the remaining content:

```bash
awk 'BEGIN{f=0} /^---$/{f++; if(f<=2) next} f>=2{print}' <file> | shasum -a 256 | cut -d' ' -f1
```

## Operations

### Status

For each file in `wiki/sync/`:
1. Compute current content hash
2. Compare against `local_hash` in frontmatter (uncommitted edits?)
3. Compare `local_hash` vs `pushed_hash` (unpushed changes?)
4. Report table:

| File | Local Status | Needs Push? | Last Pulled | Last Pushed |
|---|---|---|---|---|

To check for remote changes, optionally fetch each Notion page and compare against `pulled_hash`.

### Pull

1. Read the sync file frontmatter to get `notion_id`
2. Fetch Notion page using `notion-fetch` MCP tool
3. Hash the fetched content -> `new_pulled_hash`
4. If `new_pulled_hash == pulled_hash`, Notion hasn't changed — report "up to date"
5. Otherwise, convert Notion content to markdown and update the local file (preserve frontmatter)
6. Compute new `local_hash`, set `pulled_hash = new_pulled_hash`
7. Set `local_status: synced`, update `last_pulled` to today
8. Git commit: `sync-pull(<doc>): Pull latest from Notion`

### Push

1. Compute current `local_hash` — if it matches `pushed_hash`, report "nothing to push"
2. **Always pull-check first:** fetch Notion page, hash it, compare to `pulled_hash`
   - If Notion changed AND local changed (both hashes differ from stored): **conflict**
     - Warn the user, show what changed on each side
     - Ask: remote wins (default), local wins, or manual merge
     - Do not auto-resolve silently
   - If only local changed: safe to push
3. Read local file, strip frontmatter
4. Convert markdown tables to Notion `<table>` format
5. Convert blockquotes used as callouts to Notion `<callout>` format
6. Quote mermaid node labels containing special characters with double quotes
7. **Use `update_content` with targeted replacements when possible** to preserve:
   - Notion comments (inline discussions, page-level comments)
   - Notion-native formatting not representable in markdown
   - Content added by other collaborators outside of synced sections
   Only use `replace_content` if the structure changed too much for targeted updates, and warn the user first.
8. Set `pushed_hash = local_hash`, `local_status: synced`, update `last_pushed` to today
9. Update `wiki/remote.md` with new hash and status
10. Git commit: `sync-push(<doc>): Push local edits to Notion`

### Diff

1. Read the sync file frontmatter to get `notion_id`
2. Fetch Notion page using `notion-fetch` MCP tool
3. Convert Notion content to comparable markdown
4. Show differences between local content and Notion content
5. Report whether local has unpushed changes and/or Notion has unpulled changes

## Markdown <-> Notion Conversion

### Push (markdown -> Notion)

- Markdown tables (`| col | col |`) -> Notion `<table header-row="true">` with `<tr>/<td>` tags
- Blockquote callouts (`> **Note:**`) -> Notion `<callout icon="..." color="...">` tags
- Mermaid code blocks: wrap node labels containing `(`, `)`, `<`, `>` in double quotes
- Wiki links `[[page]]` -> plain text (or Notion mention links if page IDs are known)
- Preserve `<span discussion-urls="...">` tags to maintain comment anchors

### Pull (Notion -> markdown)

- Notion `<table>` -> markdown tables
- Notion `<callout>` -> blockquote with bold prefix
- Strip `<span discussion-urls="...">` tags (not meaningful in local markdown)
- Preserve mermaid code blocks as-is

## Conflict Resolution

Default: **remote wins**, but always ask first.

| Condition | Meaning | Action |
|---|---|---|
| `local_hash == pushed_hash` | No local changes | Nothing to push |
| `local_hash != pushed_hash` | Local edits exist | Push needed |
| `pulled_hash != notion_current_hash` | Notion changed | Pull needed |
| Both differ | Both sides changed | Warn user, ask which wins (default: remote) |

## Git Integration

Every sync operation creates an atomic git commit:

- `sync-pull(<doc>): <description>` — after pulling from Notion
- `sync-push(<doc>): <description>` — after pushing to Notion

All files touched by the operation (sync file, remote.md) go in one commit for clean reverts.
