# Commands

The raw commands behind `scripts/orch`, for working by hand or rebuilding the script. Command output is JSON unless noted.

To learn more about either front end, see:
- `herdr --skill`: the herdr TUI's own agent guide
- `herdr-app --skill`: herdr-app's agent guide
- `herdr-app commands`: every app command and its arguments
- `hc --help` and `hc <command> --help`

## Which front end

| | herdr TUI | herdr-app |
|---|---|---|
| Environment | `HERDR_ENV=1`, `HERDR_PANE_ID`, `HERDR_TAB_ID`, `HERDR_WORKSPACE_ID` | `HC_TERMINAL_ID` (an address such as `t1b`), `hc` on PATH |
| A group of tabs | workspace (`w1`) | space (`sp…`) |
| A tab id | `w1:t2` | `tb…` |
| A worker handle | its agent name, or the pane id `w1:p3` | its address `t7`, or its name |

Check the TUI first: the TUI can run inside an app terminal, and then its own ids are the ones that matter.

## Actions

| Action | herdr TUI | herdr-app |
|---|---|---|
| Own space or workspace name | `herdr workspace get "$HERDR_WORKSPACE_ID"` gives `.result.workspace.label` (a new workspace shows `~` or a number) | `hc get "$HC_TERMINAL_ID" --json` gives `.labels["herdr.space"]`; `herdr-app ls` gives `.spaces[] \| select(.id==…) .name` |
| Own tab | `$HERDR_TAB_ID` | `.labels["herdr.tab"]`, or find the terminal in `herdr-app ls` |
| Rename own tab | `herdr tab rename "$HERDR_TAB_ID" "<label>"` | `herdr-app do tab.rename --id <tab> --name "<label>"` |
| Rename the space | `herdr workspace rename "$HERDR_WORKSPACE_ID" "<name>"` | `herdr-app do space.rename --id <space> --name "<name>"` |
| Tag self as orchestrator | none (the TUI has no labels) | `hc label "$HC_TERMINAL_ID" orch=<project> orch.role=orchestrator` |
| Start a worker | `herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd <worktree> --label "<label>" --no-focus` (gives `.result.tab.tab_id` and `.result.root_pane.pane_id`), then `herdr agent start <name> --kind claude --pane <pane>`, then `herdr agent prompt <name> "<brief>"` | `hc run --bg --json --keep --outlive-parent --name <name> --parent "$HC_TERMINAL_ID" --label orch=<project> --label orch.role=worker --label orch.item="<item>" --label herdr.space=<space> --cwd <worktree> -- claude "<brief>"` (gives `.address`), then `herdr-app do terminal.keep --terminal <address>`, then find its new tab in `herdr-app ls` and rename it |
| List workers | `herdr tab list --workspace "$HERDR_WORKSPACE_ID"` (tabs labelled `work:`, `review:` and so on); `herdr agent list` | `hc ls --json` (`.terminals[].address`), then `hc get <t> --json` for each, keeping `orch=<project>` and `orch.role=worker` |
| Wait | `herdr agent wait <name> --timeout <ms>` (settles on idle, done or blocked) | `hc wait <name> --json --timeout <s>` (`.status`, `.exit_code`, `.reason`) |
| Read its pane | `herdr agent read <name> --source recent-unwrapped --lines 120` | `hc read <name> --lines 60` (text) |
| Prompt it | `herdr agent prompt <name> "<text>"` (refuses while a dialog is open) | `hc send <name> "<text>"` |
| Its state | `herdr agent get <name>`: idle, working, blocked, done, unknown | `hc get <name> --json`: `.status.state`, `.turn` |
| Its session id | printed when it runs `/exit` | `.labels["claude.session"]` (set by herdr-context.sh) |
| Restart with context | `/exit`, then `herdr agent start <name> --kind claude --pane <pane> -- --resume <id>` | `hc kill <name>`, then start it again with `-- claude --resume <id>` |
| Close a tab | `herdr tab close <tab>` | `herdr-app do tab.close --id <tab> --confirmed true` |

## Gotchas

- `terminal.keep` takes the address. It rejects a name.
- A terminal started with `hc` appears in the herdr-app window only with a `herdr.space=<id>` label. Without a `herdr.tab` label, the app creates a new tab for it a moment after launch.
- `orch=<project>` is what ties workers to their orchestrator across restarts. `parent` breaks when the orchestrator comes back in a new terminal. `--outlive-parent` keeps workers alive when the orchestrator exits.
- On macOS, `herdr agent start` rejects a command line longer than the terminal's line limit. Send long briefs with `agent prompt` instead.
- Agent names in the TUI match `[a-z][a-z0-9_-]{0,31}` and must be unique among live agents. hc names allow 1 to 32 characters of `a-z 0-9 - _`. `orch spawn` enforces the stricter rule.

## How each subcommand works

| Subcommand | Behavior |
|---|---|
| `env` | `tui` if `HERDR_ENV=1` and `HERDR_PANE_ID` is set; else `herdr-app` if `HC_TERMINAL_ID` is set and `hc` exists; else `none` |
| `project` | The space or workspace name as a slug: lowercase, runs of non-alphanumerics become `-`, ends trimmed, at most 32 characters. If the name is empty, `~` or all digits, it uses the main repo's directory name (`git rev-parse --git-common-dir`, so a worktree resolves to its repo) or the current directory. |
| `claim [p]` | herdr-app: rename the space if `p` differs from its slug; label self `orch=p orch.role=orchestrator`; relabel workers carrying an old `orch` value; rename own tab `p orchestrator`. TUI: rename the workspace if `p` differs or it is unlabelled; rename own tab. Prints the project. |
| `sync` | herdr-app: if the space slug differs from own `orch` label, re-run claim (which relabels the workers); prints `unchanged p` or `renamed old -> p`. TUI: rename own tab from the current workspace name. |
| `workers [p]` | herdr-app: JSON lines `{address, name, item, state, status, session, where}` for terminals with `orch=p` and `orch.role=worker`. TUI: JSON lines `{tab, label, state}` for tabs labelled `work:`, `needs-you:`, `review:` or `done:`. |
| `spawn` | Validates the arguments, then runs the start-a-worker row above. herdr-app polls `herdr-app ls` for up to 20 checks for the new tab. Prints `{address, name, tab}` (herdr-app) or `{name, tab, pane}` (TUI). |
| `send` | herdr-app: note `.turn`, run `hc send`, then poll until the turn number rises or `orch.status` starts with `working - new input` (set by the worker hook), for up to 15 checks. TUI: `herdr agent prompt`. |
| `wait` | Loop until the deadline (default 1800s). herdr-app: `hc wait`; working means loop; blocked or an exit code means report it; otherwise poll `orch.status` (up to 10 checks) until it is set and doesn't start with `working - new input`, then report `settled`. TUI: `herdr agent wait`, read the state with `agent get`, then take the last `STATUS:` line from the last 40 lines of `agent read`. Prints `{name, result, state, status}`, where result is settled, blocked, exited or timeout. |
| `doctor` | Checks jq, the front end's CLI (plus python3 for the herdr-app worker hook), and that `~/.claude/settings.json` registers the three hooks. Exits 1 if anything is missing. |

`ORCH_POLL` sets the poll interval in seconds (default 1). `ORCH_SETTINGS` points `doctor` and `install-hooks` at another settings file.
