#!/usr/bin/env bash
# Installs dotfiles: Homebrew packages, config symlinks, tmux plugin manager,
# and the yabai/skhd services. Safe to rerun; never clobbers without asking.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d%H%M%S)"

DRY_RUN=0
SKIP_BREW=0
SKIP_SERVICES=0
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
  --no-services     Skip starting the yabai/skhd services
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
    --no-services) SKIP_SERVICES=1 ;;
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

# link <source-relative-to-dotfiles> <absolute-target>
link() {
  local src="$DOTFILES/$1" target="$2" current

  if [ ! -e "$src" ]; then
    info "missing in repo, skipping: $1"
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

    local backup="$target.bak.$STAMP"
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
  # yabai and skhd come from a third-party tap, which recent Homebrew refuses to
  # load until it is explicitly trusted.
  for tap in asmvik/formulae; do
    trusted="$(brew tap-info --json "$tap" 2>/dev/null | grep -c '"trusted":true')"
    if [ "$trusted" = "0" ]; then
      info "tap $tap is not trusted; Homebrew will refuse to install from it"
      if [ "$CONFLICT_MODE" = ask ]; then
        read -r -p "    run \`brew trust $tap\`? [y/N] " reply </dev/tty
        case "$reply" in
          y|Y) run brew tap "$tap" && run brew trust "$tap" ;;
          *) info "left untrusted; yabai/skhd will not install" ;;
        esac
      else
        info "run \`brew trust $tap\` yourself, then rerun"
      fi
    fi
  done

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
link yabai "$HOME/.config/yabai"
link skhd  "$HOME/.config/skhd"

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
    link "skills/$name" "$target"
  done
fi

step "yabai config permissions"
if [ -f "$DOTFILES/yabai/yabairc" ] && [ ! -x "$DOTFILES/yabai/yabairc" ]; then
  run chmod +x "$DOTFILES/yabai/yabairc"
  info "made yabairc executable"
else
  info "yabairc already executable"
fi

step "tmux plugin manager"
TPM="$HOME/.tmux/plugins/tpm"
if [ -d "$TPM" ]; then
  info "already installed at $TPM"
else
  run git clone https://github.com/tmux-plugins/tpm "$TPM"
  info "run tmux and press prefix + I to install plugins"
fi

step "Window manager services"
if [ "$SKIP_SERVICES" = 1 ]; then
  info "skipped (--no-services)"
else
  for svc in yabai skhd; do
    if ! command -v "$svc" >/dev/null 2>&1; then
      info "$svc not installed, skipping"
    elif pgrep -x "$svc" >/dev/null 2>&1; then
      info "$svc already running"
    else
      run "$svc" --start-service
      info "started $svc"
    fi
  done
  info "grant Accessibility permission to yabai and skhd in System Settings if prompted"
fi

step "Summary"
info "linked: $LINKED, already correct: $ALREADY, backed up: $BACKED_UP, skipped: $SKIPPED"
if [ "$SKIPPED" -gt 0 ]; then
  info "left untouched:"
  for p in "${SKIPPED_PATHS[@]}"; do info "  $p"; done
fi
[ "$DRY_RUN" = 1 ] && info "dry run, nothing was changed"
exit 0
