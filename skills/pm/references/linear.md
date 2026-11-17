# Linear notes

## Tools

| Need | Tool | Notes |
|---|---|---|
| Project, milestones | `get_project`, `list_milestones` | |
| Issues | `list_issues` | Filter by `project`, `milestone`, `state`, `priority`, `createdAt`/`updatedAt`/`completedAt` (ISO date or duration such as `-P7D`). Ask only for the `fields` you need. Page through results while `hasNextPage` is true. |
| Comments | `list_comments` | `get_issue` does not include the discussion |
| Cycles | `list_cycles` with `type: current` | |
| Teams, labels, statuses | `list_teams`, `list_issue_labels`, `list_issue_statuses` | These differ per team, so check before you filter or set them |
| Create or update an issue | `save_issue` | Omit `id` to create. Pass `team` on create. |
| Project update | `get_status_updates`, `save_status_update` | `health`: onTrack, atRisk or offTrack |

Tools accept readable references (`FRT-108`, team keys, user names, `me`), so look up IDs only when a reference is ambiguous.

## Priority mapping

The skill says "urgent" where older notes say P0.

| Linear | Value | Old label |
|---|---|---|
| Urgent | 1 | P0 |
| High | 2 | P1 |
| Medium | 3 | P2 |
| Low | 4 | P3 |

## "This sprint" when the team has no cycles

Use the current cycle if `list_cycles` returns one. Otherwise use issues created in the last 14 days (`createdAt: -P14D`), and say which window you used.

## Writes

- **Relations are append-only:** `blockedBy`, `blocks`, `relatedTo` and `addLabels` never remove anything. To undo, use `removeBlockedBy`, `removeRelatedTo` or `removeLabels`.
- **`labels` replaces the whole set,** so use `addLabels` and `removeLabels` instead.
- **Long descriptions:** to change part of one, use `patch` instead of resending the whole description.
- **Agent-only detail** (file lists, plans, logs) goes in a collapsible section at the end of the body:

  ```
  +++ Agent notes

  ...

  +++
  ```

- **Duplicates:** check `list_issues` with a `query` before creating.
- **Batching:** apply approved changes as one batch, then report every ID you changed.
