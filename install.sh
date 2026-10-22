#!/usr/bin/env bash
# Installs dotfiles: Homebrew packages, config symlinks, tmux plugin manager,
# and herdr plugins. Safe to rerun; never clobbers without asking.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

DRY_RUN=0
SKIP_BREW=0
CONFLICT_MODE=ask   # ask | backup | skip
SKILLS_MODE=ask     # ask | all | none

usage() {
  cat <<'USAGE'
usage: ./install.sh [options]

  --dry-run         Show what would happen, change nothing
  --backup-all      Back up every conflict instead of prompting
  --all-skills      Install every skill in skills/ without asking
  --skip-conflicts  Leave every conflict untouched instead of prompting
  --no-brew         Skip `brew bundle`
  -h, --help        Show this message

Each skill in skills/ is confirmed individually before it is installed at the
user level in ~/.claude/skills.

Existing paths are never deleted. A backup moves the current path to
<name>.bak.<timestamp> alongside it, then creates the symlink.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --backup-all) CONFLICT_MODE=backup ;;
    --all-skills) SKILLS_MODE=all ;;
    --skip-conflicts) CONFLICT_MODE=skip ;;
    --no-brew) SKIP_BREW=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

# Non-interactive runs cannot answer prompts, so fall back to leaving things alone.
if [ ! -t 0 ]; then
  if [ "$CONFLICT_MODE" = ask ]; then
    CONFLICT_MODE=skip
    echo "note: stdin is not a terminal, conflicts will be skipped"
  fi
  if [ "$SKILLS_MODE" = ask ]; then
    SKILLS_MODE=none
    echo "note: stdin is not a terminal, skills will be skipped"
  fi
fi

LINKED=0 ALREADY=0 BACKED_UP=0 SKIPPED=0
SKIPPED_PATHS=()

info() { printf '  %s\n' "$1"; }
step() { printf '\n== %s\n' "$1"; }
run()  { if [ "$DRY_RUN" = 1 ]; then info "would: $*"; else "$@"; fi; }

# link <source-relative-to-dotfiles> <absolute-target> [backup-path]
# A backup-path is needed when the target sits in a directory that is scanned
# for content: a <name>.bak.<stamp> left inside ~/.claude/skills would be
# loaded as a second, duplicate skill.
link() {
  local src="$DOTFILES/$1" target="$2" backup_override="${3:-}" current

  if [ ! -e "$src" ]; then
    info "missing in repo, skipping: $1"
    return
  fi

  # A parent directory symlinked into the repo makes the target the source
  # itself; backing it up and linking would leave a self-referencing symlink.
  local parent
  parent="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)"
  if [ -n "$parent" ] && [ "$parent/$(basename "$target")" = "$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")" ]; then
    SKIPPED=$((SKIPPED + 1))
    SKIPPED_PATHS+=("$target")
    info "skipped $target: $(dirname "$target") is a symlink into this repo; replace it with a real directory"
    return
  fi

  if [ -L "$target" ]; then
    # Tolerate a trailing slash on an existing link target.
    current="$(readlink "$target")"
    if [ "${current%/}" = "$src" ]; then
      ALREADY=$((ALREADY + 1))
      return
    fi
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local action="$CONFLICT_MODE" reply
    if [ "$action" = ask ]; then
      local kind="file"
      [ -L "$target" ] && kind="symlink -> $(readlink "$target")"
      [ -d "$target" ] && [ ! -L "$target" ] && kind="directory"
      printf '  %s exists (%s)\n' "$target" "$kind"
      # Read from the terminal so this still works under `curl | bash`.
      read -r -p "    [b]ack up and link, [s]kip? " reply </dev/tty
      case "$reply" in
        b|B) action=backup ;;
        *)   action=skip ;;
      esac
    fi

    if [ "$action" = skip ]; then
      SKIPPED=$((SKIPPED + 1))
      SKIPPED_PATHS+=("$target")
      info "skipped $target"
      return
    fi

    local backup="${backup_override:-$target}.bak.$STAMP"
    run mkdir -p "$(dirname "$backup")"
    run mv "$target" "$backup" || { info "could not back up $target"; return; }
    BACKED_UP=$((BACKED_UP + 1))
    info "backed up -> $backup"
  fi

  run mkdir -p "$(dirname "$target")"
  run ln -s "$src" "$target"
  LINKED=$((LINKED + 1))
  info "linked $target -> $src"
}

step "Homebrew packages"
if [ "$SKIP_BREW" = 1 ]; then
  info "skipped (--no-brew)"
elif ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found, skipping. Install it from https://brew.sh then rerun."
else
  if [ "$DRY_RUN" = 1 ]; then
    brew bundle check --file "$DOTFILES/Brewfile" || true
  else
    brew bundle --file "$DOTFILES/Brewfile"
  fi
fi

step "Config symlinks"
link fish  "$HOME/.config/fish"
link kitty "$HOME/.config/kitty"
link nvim  "$HOME/.config/nvim"
link tmux  "$HOME/.config/tmux"
link herdr/config.toml "$HOME/.config/herdr/config.toml"

# Global agent instructions. Kept per-agent because the wording differs
# (each file names its own agent).
link claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"
link codex/AGENTS.md  "$HOME/.codex/AGENTS.md"
# pi rewrites this file itself (theme, lastChangelogVersion), so expect churn.
link pi/settings.json "$HOME/.pi/agent/settings.json"

# Skills land in ~/.claude/skills, where they apply to every project, so each one
# is opt-in per run rather than linked wholesale.
step "Claude skills"
if [ "$SKILLS_MODE" = none ]; then
  info "skipped (no approval possible non-interactively; use --all-skills)"
else
  for skill in "$DOTFILES"/skills/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    target="$HOME/.claude/skills/$name"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "${DOTFILES}/skills/$name" ]; then
      ALREADY=$((ALREADY + 1))
      continue
    fi
    if [ "$SKILLS_MODE" = ask ]; then
      printf '  skill "%s" -> %s\n' "$name" "$target"
      read -r -p "    install at the user level? [y/N] " reply </dev/tty
      case "$reply" in
        y|Y) ;;
        *) SKIPPED=$((SKIPPED + 1)); SKIPPED_PATHS+=("$target"); info "declined $name"; continue ;;
      esac
    fi
    link "skills/$name" "$target" "$HOME/.claude/skill-backups/$name"
  done
fi

step "Agent hook permissions"
if [ -f "$DOTFILES/agents/agent-status-hook.sh" ] && [ ! -x "$DOTFILES/agents/agent-status-hook.sh" ]; then
  run chmod +x "$DOTFILES/agents/agent-status-hook.sh"
  info "made agent-status-hook.sh executable"
else
  info "agent-status-hook.sh already executable"
fi

step "Agent status hooks"
# tmux-agent-status reads Claude Code and Codex lifecycle hooks. Codex loads a
# whole hooks.json, so it can simply be linked. Claude Code keeps hooks inside
# settings.json alongside unrelated settings, so that one is merged, not linked.
link agents/codex-hooks.json "$HOME/.codex/hooks.json"
# pi ships no hooks file, so the reporter is a pi extension instead. It resolves
# agent-status-hook.sh as a sibling through this symlink.
link agents/pi-agent-status.ts "$HOME/.pi/agent/extensions/pi-agent-status.ts"
info "enable Codex hooks: add [features] hooks = true to ~/.codex/config.toml,"
info "then run /hooks inside Codex and trust the commands"

CLAUDE_SETTINGS="$HOME/.claude/settings.json"
if ! command -v jq >/dev/null 2>&1; then
  info "jq not found; skipping Claude Code hook merge"
elif [ ! -f "$CLAUDE_SETTINGS" ]; then
  info "no $CLAUDE_SETTINGS; skipping Claude Code hook merge"
elif [ "$(jq -r '.hooks.Stop[0].hooks[0].command // ""' "$CLAUDE_SETTINGS")" = \
       "$(jq -r '.hooks.Stop[0].hooks[0].command // ""' "$DOTFILES/agents/claude-hooks.json")" ]; then
  info "Claude Code hooks already installed"
else
  reply=y
  if [ "$CONFLICT_MODE" = ask ]; then
    printf '  merge agent-status hooks into %s?\n' "$CLAUDE_SETTINGS"
    read -r -p "    this overwrites any existing .hooks entries [y/N] " reply </dev/tty
  fi
  case "$reply" in
    y|Y)
      if [ "$DRY_RUN" = 1 ]; then
        info "would merge hooks into $CLAUDE_SETTINGS"
      else
        cp "$CLAUDE_SETTINGS" "$CLAUDE_SETTINGS.bak.$STAMP"
        if jq -s '.[0] * .[1]' "$CLAUDE_SETTINGS" "$DOTFILES/agents/claude-hooks.json" \
             > "$CLAUDE_SETTINGS.tmp" && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"; then
          info "merged hooks (backup at $CLAUDE_SETTINGS.bak.$STAMP)"
        else
          rm -f "$CLAUDE_SETTINGS.tmp"
          info "merge failed; $CLAUDE_SETTINGS left unchanged"
        fi
      fi
      ;;
    *) info "skipped Claude Code hook merge" ;;
  esac
fi

step "tmux plugin manager"
TPM="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM" ]; then
  info "already installed at $TPM"
else
  run git clone https://github.com/tmux-plugins/tpm "$TPM"
  info "run tmux and press prefix + I to install plugins"
fi

step "herdr plugins"
# herdr has no way to declare plugins in config.toml, so herdr/plugins.txt
# lists them and anything missing is installed here.
PLUGIN_LIST="$DOTFILES/herdr/plugins.txt"
if ! command -v herdr >/dev/null 2>&1; then
  info "herdr not installed, skipping"
elif [ ! -f "$PLUGIN_LIST" ]; then
  info "no herdr/plugins.txt, skipping"
else
  # herdr prints an install preview; keep it only when the command fails.
  herdr_plugin() {
    local done_msg="$1" out; shift
    if [ "$DRY_RUN" = 1 ]; then info "would: herdr plugin $*"; return; fi
    if out="$(herdr plugin "$@" 2>&1)"; then info "$done_msg"
    else info "failed: herdr plugin $*"; printf '%s\n' "$out" | sed 's/^/    /'; fi
  }
  installed="$(herdr plugin list 2>/dev/null)"
  # Prints the `herdr plugin list` block (entry line plus its indented lines) matching $1.
  plugin_block() {
    printf '%s\n' "$installed" | awk -v m="$1" '/^- / { show = index($0, m) > 0 } show'
  }
  # A registered plugin whose files are gone still lists, but with this warning.
  plugin_broken() { printf '%s\n' "$1" | grep -q 'manifest unavailable'; }
  plugin_id() { printf '%s\n' "$1" | sed -n 's/^- \([^ ]*\) .*/\1/p'; }
  wanted=()
  while read -r line; do
    line="${line%%#*}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    case "$line" in
      ./*)
        path="$DOTFILES/herdr/${line#./}"
        wanted+=("[local:$path]")
        block="$(plugin_block "[local:$path]")"
        if [ -z "$block" ]; then
          herdr_plugin "linked $line" link "$path"
        elif plugin_broken "$block"; then
          herdr_plugin "unlinked broken $(plugin_id "$block")" unlink "$(plugin_id "$block")"
          herdr_plugin "relinked $line" link "$path"
        else
          info "$line already linked"
        fi
        ;;
      *)
        spec="${line%@*}" ref=""
        [ "$spec" != "$line" ] && ref="${line##*@}"
        wanted+=("[github:$spec@")
        block="$(plugin_block "[github:$spec@")"
        if [ -z "$block" ]; then
          herdr_plugin "installed $spec" install --yes ${ref:+--ref "$ref"} "$spec"
        elif plugin_broken "$block"; then
          herdr_plugin "removed broken $(plugin_id "$block")" uninstall "$(plugin_id "$block")"
          herdr_plugin "reinstalled $spec" install --yes ${ref:+--ref "$ref"} "$spec"
        else
          info "$spec already installed"
        fi
        ;;
    esac
  done < "$PLUGIN_LIST"

  # Report, never remove, plugins that were installed by hand.
  while read -r entry; do
    known=0
    for w in "${wanted[@]}"; do
      case "$entry" in *"$w"*) known=1 ;; esac
    done
    [ "$known" = 1 ] || info "not in plugins.txt: ${entry#- }"
  done < <(printf '%s\n' "$installed" | grep '^- ')
fi

step "Summary"
info "linked: $LINKED, already correct: $ALREADY, backed up: $BACKED_UP, skipped: $SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  info "left untouched:"
  for p in "${SKIPPED_PATHS[@]}"; do info "  $p"; done
fi
[ "$DRY_RUN" = 1 ] && info "dry run, nothing was changed"
exit 0
