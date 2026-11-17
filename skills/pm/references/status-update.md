# Weekly status update (`/pm update`)

## Find the format first

1. Open the previous update. Its link is in `project.md` under Remote References; otherwise search Notion for the hub's title and pick the most recent.
2. Open this week's page if someone has already created it from the template. Fill that page instead of making a new one.
3. Match the previous update: its sections, headings, level of detail, how it names people, and how it links trackers and dashboards. Readers compare week over week, so keep the shape stable.

A common hub template, used when there's no previous update:

| Section | What goes in it |
|---|---|
| 🚩 Flags & Discussion Topics | 1–3 things for the dev review: blockers, launches, open questions, missed dates |
| 🎉 Highlights | What shipped or got solved, with experiment dashboards and expected read dates |
| ❗️ Challenges & Risks | What isn't going well, and what's being done about it |
| 🎯 Priorities | The top 2–3 for next week, with the delivery date of any larger item they belong to |

## Gather (read-only)

The window runs from the day after the previous update to today. Search the sources in parallel:
- **Linear:** issues completed in the window, the open Urgent and High issues, anything blocked, and milestone target changes.
- **Slack:** the channels listed under Sources in `project.md`. Standup threads, release announcements, rollout percentages and experiment readouts carry most of the week.
- **Meetings (Granola):** decisions and action items from the recurring syncs listed under Sources.
- **GitHub:** release PRs merged or still waiting in the window.
- **Last week's Priorities:** report on each one, whether it was done, slipped or is still in progress. Readers check these first.

## Write

- Lead with the outcome, then the evidence: "PU&P live at 25% (10% on 2026-11-11, 25% on 2026-11-12)".
- Give numbers with their baseline and window: "3.4% on Nov 13–15, vs about 2% the two weeks before". A peak hour is not a daily rate. Check any rate against its source before you quote it.
- Name the owner in parentheses, as the hub does.
- Write about people in the third person, including the user. The page is for the team.
- Keep anything you couldn't confirm out of the page. List it separately in chat for the user to fill in.

## Publish

- Show the full draft in chat and wait for approval.
- **Notion:** edit with targeted replacements (`update_content`) rather than replacing the whole page. That keeps embedded databases and other people's edits safe. Use date mentions for dates, as the hub does. Fetch the page just before you write if others may be editing it.
- **Linear project update:** `save_status_update` with `type: project`, the body, and `health` matching the overall status.
- **After publishing,** record the page link and date under Remote References in `project.md`, and commit.

## Comments

After you publish, people may comment. When the user asks how to answer one:
1. Read the thread with `get_comments`.
2. Check the claim against its source.
3. Draft a reply. Post it only after the user approves.
4. If the page itself is wrong, propose the corrected line too.
