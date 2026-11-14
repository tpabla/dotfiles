# Setup

Everything `/orch` depends on, and enough detail to rebuild any piece.

## Requirements

- **Claude Code**, with this folder at `~/.claude/skills/orch`. A symlink is fine.
- **A front end:**
  - the **herdr TUI** (`herdr` CLI), or
  - **herdr-app**, which brings `herdr-app` and `hc` (herdr-core).
- **jq**, used by every script.
- **python3**, needed only by the worker hook in herdr-app.
- **Optional:** `gh` for checking CI and PRs, and a skill that makes pages for questions to the user (for example show-in-browser, visual-explainer or explain).

`scripts/orch doctor` checks all of these.

## Hooks

`scripts/install-hooks` links both hooks into `~/.claude/hooks/` and registers them in `~/.claude/settings.json`. It is safe to re-run: it adds only missing entries and backs up anything it replaces. Pass `--register-only` when something else, such as a dotfiles installer, makes the links.

The entries it adds:

```json
{
  "hooks": {
    "SessionStart": [{"matcher": "^(startup|resume|clear|compact|fork)$",
      "hooks": [{"type": "command", "command": "sh '~/.claude/hooks/herdr-context.sh'", "timeout": 10}]}],
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "sh '~/.claude/hooks/orch-worker-activity.sh' prompt", "timeout": 15, "async": true}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "sh '~/.claude/hooks/orch-worker-activity.sh' stop", "timeout": 15, "async": true}]}]
  }
}
```

The script writes the absolute path where this example shows `~`.

### hooks/herdr-context.sh (every session)

Runs on start, resume, `/clear`, compaction and fork. It skips subagents, which have an `agent_id` in the hook input. It prints one line that Claude reads as context:

- TUI: `herdr (current; ...): herdr TUI. workspace=… tab=… pane=… session=…`
- herdr-app: `herdr (current; ...): herdr-app. terminal=… space=… tab=… orch=… session=…`

In herdr-app it also runs `hc label "$HC_TERMINAL_ID" claude.session=<session_id>`. That label is how a restart finds the session to resume. Outside herdr it prints nothing.

### hooks/orch-worker-activity.sh (worker sessions in herdr-app)

Does nothing unless the terminal has the labels `orch.role=worker` and `orch=<project>`. It also skips subagents.
- `prompt`: someone typed into the worker. It sets `orch.status=working - new input: <first 80 characters>` and flips a `needs-you:` tab back to `work:`.
- `stop`: the turn ended. It waits 3 seconds for the transcript to flush, finds the last `STATUS: <state> - <text>` line in the final assistant messages, and copies it into `orch.status`.

`orch wait` relies on this: a worker has settled when it isn't working and `orch.status` holds a real STATUS rather than `working - new input…`.

## Labels (herdr-app)

| Label | On | Set by | Meaning |
|---|---|---|---|
| `orch` | orchestrator, workers | `orch claim`, `orch spawn` | project slug; ties workers to the orchestrator |
| `orch.role` | orchestrator, workers | same | `orchestrator` or `worker` |
| `orch.item` | workers | `orch spawn` | the ticket or task the worker owns |
| `orch.status` | workers | worker hook and the worker itself | `<state> - <sentence>` from the last STATUS line |
| `claude.session` | every Claude terminal | herdr-context.sh | session id for `--resume` |
| `herdr.space`, `herdr.tab` | app terminals | herdr-app (and `orch spawn`) | where the terminal is shown |

The TUI has no labels, so tab names (`work:`, `review:` and so on) carry the state there.

## Overview panel (optional)

An overview panel can draw the orchestrator, its workers, their sub-agents and their states. In herdr-app this can be a mod that reads `herdr.terminals()`: group by `herdr.space`, find the lead by `orch.role=orchestrator`, take each worker's state from `orch.status` or its tab prefix, and nest sub-agents by `parent`. The skill doesn't need one; tab names and `orch workers` carry the same information.

## Tests

`sh test/orch.test.sh` runs `orch` and `install-hooks` against fake `hc`, `herdr-app` and `herdr` binaries, which it puts first on PATH. It needs `jq` and `git`. Add a test there when you change a script.
