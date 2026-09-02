# dotfiles

![alt text](./neovim_and_tmux.png)

## Install

```sh
git clone https://github.com/<you>/dotfiles ~/Personal/dotfiles
cd ~/Personal/dotfiles
./install.sh
```

`install.sh` installs the `Brewfile` packages, symlinks each config into `~/.config`, clones TPM, and starts the yabai and skhd services. It is safe to rerun: symlinks that already point at this repo are left alone, and nothing is ever deleted.

When a real file or directory already sits at a target path, the script stops and asks. Choosing **b** moves the existing path to `<name>.bak.<timestamp>` next to it and then links; choosing **s** leaves it untouched and reports it in the summary. Skills in `skills/` are confirmed one at a time, since they install at the user level in `~/.claude/skills` and apply to every project.

| Flag | Effect |
| --- | --- |
| `--dry-run` | Print what would happen, change nothing |
| `--backup-all` | Back up every conflict instead of prompting |
| `--skip-conflicts` | Leave every conflict untouched instead of prompting |
| `--all-skills` | Install every skill without asking |
| `--no-brew` | Skip `brew bundle` |
| `--no-services` | Skip starting yabai and skhd |

Without a terminal on stdin (piped or CI), conflicts and skills are skipped rather than guessed at.

What gets linked:

| Repo path | Target |
| --- | --- |
| `fish/` | `~/.config/fish` |
| `kitty/` | `~/.config/kitty` |
| `nvim/` | `~/.config/nvim` |
| `tmux/` | `~/.config/tmux` |
| `herdr/config.toml` | `~/.config/herdr/config.toml` |
| `agents/codex-hooks.json` | `~/.codex/hooks.json` |
| `agents/pi-agent-status.ts` | `~/.pi/agent/extensions/pi-agent-status.ts` |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `pi/settings.json` | `~/.pi/agent/settings.json` |
| `yabai/` | `~/.config/yabai` |
| `skhd/` | `~/.config/skhd` |
| `skills/<name>/` | `~/.claude/skills/<name>` |

The sections below describe each config and its manual setup, if you would rather not run the script.

## nvim

A Neovim configuration using [lazy.nvim](https://github.com/folke/lazy.nvim) as the plugin manager with the **Catppuccin Macchiato** color scheme and transparent background.

### Highlights

- **LSP** — LSP support via lsp-zero, mason, and nvim-lsp-config with auto-formatting
- **Completion** — nvim-cmp with LuaSnip snippets
- **Navigation** — Telescope, nvim-tree, oil.nvim, and vim-tmux-navigator
- **Git** — vim-fugitive and diffview.nvim
- **AI** — CodeCompanion and Ollama integration
- **UI** — lualine, noice, dashboard, indent-blankline, tint.nvim (dims inactive windows), and which-key
- **Editing** — treesitter, vim-surround, vim-commentary, undotree, trouble, nvim-ufo (folding), and zen mode
- **Org/Markdown** — orgmode, render-markdown, markdown-preview, and table-mode
- **Debugging** — nvim-dap

### Setup

Copy or symlink the `nvim` directory into `~/.config/nvim`:

```sh
ln -s /path/to/dotfiles/nvim ~/.config/nvim
```

Plugins will install automatically on first launch via lazy.nvim.

## tmux

### Setup

Install [TPM](https://github.com/tmux-plugins/tpm):

```sh
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Copy or symlink the `tmux` directory into `~/.config/tmux`:

```sh
ln -s /path/to/dotfiles/tmux ~/.config/tmux
```

Open tmux and press `prefix + I` to install plugins.

## Agent status in tmux

[tmux-agent-status](https://github.com/samleeney/tmux-agent-status) gives every tmux session a sidebar and a status-line summary showing which coding agents are working, waiting, or done, plus an `fzf` switcher across sessions, windows, and panes.

State comes from each agent's own lifecycle hooks, not from screen scraping, so it reflects what the agent actually reports.

| Key | Action |
| --- | --- |
| `prefix + S` | fzf switcher popup (`ctrl-f` toggles tree/agents view) |
| `prefix + o` | Focus or create the sidebar |
| `prefix + N` | Jump to the next inbox item |
| `prefix + W` | Wait mode for the current session or pane |
| `prefix + P` | Park the current session or pane |

`park` is remapped from the plugin's default `p` so tmux keeps `previous-window`. The other keys are unbound in stock tmux.

Status glyphs: Claude `✳`, Codex `⬢`, other `●` — yellow pulsing while working, cyan waiting, magenta asking, green done.

### Hooks

`install.sh` links `agents/codex-hooks.json` to `~/.codex/hooks.json` and offers to merge `agents/claude-hooks.json` into `~/.claude/settings.json` (backing it up first). The Claude one is merged rather than linked because `settings.json` holds unrelated settings.

Codex additionally needs hooks enabled and trusted:

```sh
# ~/.codex/config.toml
[features]
hooks = true
```

Then run `/hooks` inside Codex and trust the commands — Codex will not run non-managed command hooks until they are trusted.

### pi

The plugin ships hook handlers for Claude Code, Codex, and Devin, but nothing for pi, so `agents/pi-agent-status.ts` is a pi extension that fills that role. It translates pi lifecycle events into the same status files via `agents/agent-status-hook.sh`.

Events are the ones pi 0.69.0 actually emits (`dist/core/extensions/types.d.ts`):

| pi event | reported state |
| --- | --- |
| `session_start` (TUI only) | `done` (seeds the pane) |
| `input` | `working`, and clears wait/park |
| `agent_start` | `working` |
| `tool_execution_start` | `working` |
| `agent_end` | `done` |
| `session_shutdown` | `done` |

Two caveats:

- pi exposes no permission/approval event, so `wait` is not derivable — pi reports `working` and `done` only.
- pi is not in the plugin's glyph table, so it renders as the generic `●` rather than a dedicated symbol.

`agent-status-hook.sh` is a generic writer (`<agent> <working|done|wait>`), so any other agent can be wired up the same way without new code.

> herdr's own pi integration listens for an `agent_settled` event that pi 0.69.0 does not emit, so under herdr pi tends to stay stuck on `working` after a turn ends. This extension uses `agent_end`, which does exist.

## Agent configuration

Global instructions and settings for each agent, so a fresh machine gets the same behaviour:

| File | Purpose |
| --- | --- |
| `claude/CLAUDE.md` | Global Claude Code instructions |
| `codex/AGENTS.md` | Global Codex instructions (same rules, worded for Codex) |
| `pi/settings.json` | pi default provider, model, and theme |
| `skills/` | Claude skills, installed per-skill into `~/.claude/skills` |

**`~/.codex/config.toml` is deliberately not in this repo** — it holds the WorkWeave OTEL ingest token, plus machine-local state like per-project `trust_level` entries. To version it, move the token to an environment variable and commit the redacted file.

`~/.claude/settings.json` is also not versioned: it mixes machine-local state with the agent-status hooks, so `install.sh` merges just the hook block into it instead of replacing the file.

Note that `pi/settings.json` is rewritten by pi itself (theme, `lastChangelogVersion`), so expect it to show up as modified from time to time.

## tmux theme

Catppuccin **macchiato** with neon accents, plus CPU/RAM, battery, and a prefix indicator.

Three latent bugs in the previous config were fixed while adding this — the settings looked right but were silently inert:

- The option is `@catppuccin_flavor`, not `@catppuccin_flavour`, so macchiato never applied and the bar had been rendering **mocha**.
- `@catppuccin_status_modules_left` / `_right` are the **v1** API, removed in the pinned v2. The status line is now composed explicitly with `#{E:@catppuccin_status_*}`.
- The `*_separator` and `*_fill` options were v1-only and did nothing.

Load order in `tmux.conf` matters and is not arbitrary: `catppuccin.tmux` runs first so its module variables exist, the status line is then baked with `set -agF`, and tpm runs afterwards so `tmux-cpu` and `tmux-battery` can substitute their placeholders into that baked string. Reordering these breaks the CPU and battery segments.

`tmux-net-speed` is deliberately not used — it supports Linux only, so RAM is shown via `tmux-cpu` instead.

## herdr

[herdr](https://herdr.dev) is a tmux-like, agent-aware terminal multiplexer. It is kept alongside tmux rather than replacing it, so either can be used.

Only `herdr/config.toml` is linked, not the whole directory — herdr keeps its sockets, logs, and session state in `~/.config/herdr` and would write them into this repo if the directory were symlinked.

### Install

herdr is not in the `Brewfile` on purpose. The official installer puts it in `~/.local/bin` and self-updates with `herdr update`; a `brew install herdr` would land in `/opt/homebrew/bin`, which comes first on `$PATH` and would shadow it with a separately-versioned copy.

```sh
curl -fsSL https://herdr.dev/install.sh | sh
```

### Setup

```sh
ln -s /path/to/dotfiles/herdr/config.toml ~/.config/herdr/config.toml
herdr config check          # validate
herdr server reload-config  # apply to a running server
```

### Config

Prefix is `ctrl+a`, matching `tmux.conf` on a personal machine. Unlike tmux there is no `$WORK` conditional — herdr's `prefix` takes a single chord, not a list — so the work machine's `ctrl+b` is not available. `ctrl+b` is herdr's own default if that ever needs to be flipped.

Carried over from `tmux/tmux.conf`:

| tmux | herdr |
| --- | --- |
| `bind h/j/k/l` pane focus | `prefix+h/j/k/l` |
| `bind J/K` swap-pane | `prefix+shift+h/j/k/l` (built in) |
| splits in `#{pane_current_path}` | `terminal.new_cwd = "follow"` |
| `copy-mode-vi` | `prefix+[`, vim keys, `v` select, `y` copy (built in) |
| `set -g mouse on` | `ui.mouse_capture` |
| `set -g set-clipboard on` | `ui.copy_on_select` |
| `status-position bottom` | `ui.tab_bar_position = "bottom"` |
| catppuccin macchiato | `theme.name` + `[theme.custom]` overrides |
| catppuccin status modules | `ui.tab_bar_right` + `ui.window_title` |
| tmux-resurrect / tmux-continuum | `session.resume_agents_on_restore` (built in) |
| `@resurrect-capture-pane-contents` | `experimental.pane_history` |
| kitty `allow-passthrough` | `experimental.kitty_graphics` |
| `allow-rename off` | manual names by default (`prefix+shift+t` / `prefix+shift+p`) |

Note that herdr's split names are inverted relative to tmux's: `split_vertical` (`prefix+v`) opens a pane to the **right**, `split_horizontal` (`prefix+-`) opens one **below**.

### What does not carry over

- **`vim-tmux-navigator`.** herdr has no equivalent of the `is_vim` shell check, so a bare `ctrl+h` binding would be swallowed unconditionally and never reach nvim. Pane focus is therefore prefix-only. No nvim change is needed: outside tmux `$TMUX` is unset and vim-tmux-navigator falls back to plain `wincmd`, so `ctrl+h/j/k/l` still move between nvim splits.
- **`main-vertical` layout, `main-pane-width 65%`, and `prefix Enter` promote-to-main.** herdr has no named layouts and no main-slot concept. The closest workflow is manual splits plus directional swaps (`prefix+shift+h/j/k/l`) and resize mode (`prefix+r`).

`prefix+?` lists every active binding live.

## claude

Claude Code configuration and skills, split by context:

- **`claude/`** — personal skills
- **`claude-work/`** — work skills and settings

Each directory contains a `.claude/` folder with skills (and optionally `settings.json`). Use `--add-dir` to import them into a project:

```sh
claude --add-dir /path/to/dotfiles/claude-work
```

### Symlink settings

```sh
ln -sf /path/to/dotfiles/claude-work/.claude/settings.json ~/.claude/settings.json
```

## yabai + skhd

Tiling window manager ([yabai](https://github.com/koekeishiya/yabai)) with a hotkey daemon ([skhd](https://github.com/koekeishiya/skhd)) driving it.

### Install

Both come from the `asmvik/formulae` tap (a maintained fork of koekeishiya's, whose upstream skhd repo is archived). Recent Homebrew will not load formulae from a third-party tap until it is trusted:

```sh
brew tap asmvik/formulae
brew trust asmvik/formulae
brew install asmvik/formulae/yabai
brew install asmvik/formulae/skhd
```

### Setup

Symlink both config directories into `~/.config`:

```sh
ln -s /path/to/dotfiles/yabai ~/.config/yabai
ln -s /path/to/dotfiles/skhd ~/.config/skhd
```

`yabairc` must be executable:

```sh
chmod +x ~/.config/yabai/yabairc
```

Start the services:

```sh
yabai --start-service
skhd --start-service
```

On first run macOS will prompt for Accessibility permission — grant it to both `yabai` and `skhd` under **System Settings → Privacy & Security → Accessibility**, then restart the services:

```sh
yabai --restart-service
skhd --restart-service
```

These configs use only the base yabai API, so **disabling SIP is not required**. Partial SIP disablement plus the scripting addition is only needed for extras like window borders, focus-follows-mouse, and creating/destroying spaces.

### Config

`yabai/yabairc` — bsp layout, zero padding and gaps, new windows spawn as the first child (left on a vertical split, top on a horizontal one). Music and mpv are unmanaged; Music is also sticky.

`skhd/skhdrc` — vim-style bindings:

| Keys | Action |
| --- | --- |
| `alt - h/j/k/l` | Focus window west/south/north/east |
| `shift + alt - h/j/k/l` | Warp (move) window west/south/north/east |
| `alt - f` | Toggle float on the focused window |

### Troubleshooting

```sh
yabai --restart-service      # reload after editing yabairc
skhd --restart-service       # reload after editing skhdrc
tail -f /tmp/yabai_$USER.err.log
tail -f /tmp/skhd_$USER.err.log
```

If hotkeys stop working after a macOS update, re-grant Accessibility permission (remove and re-add the entries) and restart the services.
