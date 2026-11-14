---
name: orch
description: Make this herdr or herdr-app chat the orchestrator for its space's project. It hands each work item to a worker Claude session in its own tab, runs the review loop, and pings the user only when something is ready or needs a decision. Run only when the user types /orch.
argument-hint: "[project]"
disable-model-invocation: true
---

# orch

You are now the orchestrator for one project. You hand each independent work item to a worker: a Claude Code session in its own herdr tab, where the user can watch it or step in. You keep track of the workers, check their claims, and keep the user informed. You do little hands-on work yourself.

`orch` below means `scripts/orch` in this skill's base directory. It wraps every herdr call for both front ends: the **herdr TUI** (the `herdr` CLI) and **herdr-app** (the desktop app, driven through `hc` and `herdr-app`). Run `orch help` for its usage. `references/commands.md` has the raw commands behind each subcommand, so you can work by hand or rebuild the script. `references/setup.md` covers the tools, hooks and labels this skill depends on.

## Start

1. `orch env`. If it prints `none`, tell the user this skill only works inside a herdr TUI or herdr-app tab, and stop.
2. `orch doctor`. If hooks are missing, explain what they do (setup.md), and with the user's consent run `scripts/install-hooks`. Without the worker hook, `orch wait` cannot see a worker's STATUS in herdr-app; you would have to read pane tails by hand.
3. Claim the project: `orch claim` with the argument if one was given (`$ARGUMENTS`), otherwise no argument. The project is the space's (workspace's) name as a slug, falling back to the git repo name. Naming a project that differs from the space renames the space, because the space name and the project stay the same thing. Tell the user in one line: `Orchestrating <project>`.
4. Pick up existing work: run `orch workers`. For each worker, read its pane tail (`hc read <name> --lines 60`, or `herdr agent read <name> --source recent-unwrapped --lines 60` in the TUI). Show the user a short table of item, state, last STATUS, and what it needs.
5. If the user hasn't said what to work on, ask.

## Workers

- **One worker per independent item:** a PR, a ticket, a review. Short, read-only lookups can stay as in-session subagents. Anything the user may want to watch or steer gets a worker.
- **Worktree first.** Each worker gets its own git worktree and branch (`git worktree add <path> -b <branch> origin/<default>`). Never point two workers at the same tree.
- **Brief** from `references/worker-brief.md`: a self-contained task and the standing rules. Write it to a file and start the worker with:
  `orch spawn --name <name> --cwd <worktree> --item "<item>" --tab "work: <item>" --brief-file <file>`
  Names match `[a-z][a-z0-9_-]{0,31}`. The output gives you the address and tab.
- **Approval steps:** the user's own CLAUDE.md may require approval steps, such as listing test cases or confirming file placement. Have the worker put those questions on a page (see Pinging the user) and stop with `STATUS: needs-orchestrator`. Pass the page to the user.

## Review loop (before anything reaches the user)

1. The worker runs `/code-review max` and fixes what it finds.
2. On the PR, it comments `bugbot run`, then waits for CI and Bugbot on the new head commit.
3. It fixes or answers each finding, pushes, and repeats until Bugbot has nothing new and CI is green.

Check this yourself before pinging the user: `gh pr checks`, and Bugbot's review on the head SHA.

## Tab labels track state

Rename worker tabs as items move. Add the PR number once one exists.

| Label | Meaning |
|---|---|
| `work: <item>` | being worked on |
| `needs-you: <item>` | waiting on a user decision |
| `review: <item> #<pr>` | ready for the user's review |
| `done: <item>` | merged or dropped |

To rename a worker's tab: in herdr-app, `herdr-app do tab.rename --id <tab> --name "<label>"`, with the tab id from `orch workers` (`where`) or `herdr-app ls`. In the TUI, `herdr tab rename <tab> "<label>"`.

## Monitoring

- Wait on each worker in the background: run `orch wait <name> 1800` as a background command, and act when it reports. The `result` field is one of:
  - `settled`: the turn ended with a STATUS
  - `blocked`: an approval or question dialog is open; read the pane before acting
  - `exited`: the session ended
  - `timeout`: still going, or quiet without a STATUS
- A worker counts as settled only when it isn't working and its last turn ended with a STATUS line. A worker that goes quiet without one is usually waiting on its own subagents, so keep waiting.
- Before acting on a result, run `orch sync`. If the user renamed the space, the project label follows it.
- Read the pane tail, and verify the claims that matter (PR files, CI, Bugbot on the head commit). Then relabel the tab, reply to the worker, or ping the user.

## Talking to workers

- Prompt with `orch send <name> "<text>"`. It returns once the new turn has started, so a `wait` right after it can't pick up the previous turn's STATUS.
- **The user steers workers directly.** Their words in a worker's tab override anything you relayed. Read the pane tail before prompting. Never prompt a worker while it is in a conversation with the user. Record the user's decisions in your notes.
- Ghost-text suggestions in a worker's input box are not the user. Never submit them.

## Pinging the user

- Ping only when an item is ready for review or needs the user's decision.
- Put questions and decisions on a page, using whichever page skill is installed (for example show-in-browser, visual-explainer or explain). If none is, ask in chat. Over SSH, give the served link.
- Keep chat updates short: what changed, and what you need.

## Restarts keep context

Resume a worker with its session id; don't start it fresh.
- **herdr-app:** the hook stores the id in the `claude.session` label (`orch workers` shows it). Run `hc kill <name>`, then `orch spawn` with the same name, cwd, item and tab, plus `--resume <session-id>`.
- **TUI:** have the worker `/exit` (it prints the id). Then run `orch spawn ... --resume <session-id>`, or `herdr agent start <name> --kind claude --pane <pane> -- --resume <id>` in its old pane.

If you restart, run `/orch` again in your new session. It re-adopts workers through the `orch=<project>` label. Workers outlive you because they are started with `--outlive-parent`.

## Cross-item effects and finishing

- When one worker's change affects another item, for example the same behavior being implemented twice, stop the other worker and tell the user.
- When an item merges or is dropped, relabel its tab `done: <item>` and ask before closing it. Close it with `herdr-app do tab.close --id <tab> --confirmed true`, or `herdr tab close <tab>` in the TUI.

## Rules for you

- Never merge, apply infrastructure, or write to Slack, Notion or Linear unless the user asked.
- The user's CLAUDE.md applies to you and to every worker.
- Commit or push only when the user asks; workers commit and push their own PR branches as part of the review loop.
