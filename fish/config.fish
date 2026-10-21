# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/taran/.docker/bin"
# End of Docker Desktop section.

function vim
  nvim $argv
end

function reload_hosts
  sudo killall -HUP mDNSResponder
end

function rust_book
  rustup docs --book
end

fish_vi_key_bindings
fish_config theme choose "Catppuccin Macchiato"

bind -M insert \cd delete-char  # For vi insert mode
bind -M default \cd delete-char # For vi normal mode


alias icat="kitten icat"

set -x GOPATH $HOME/go
set -x GOBIN $HOME/go/bin

set -x EDITOR nvim
set -x DOCKERPATH $HOME/.docker/bin

set -x PAGER less -R


# Keep the tmux socket out of /tmp, which macOS cleans out from under long-running servers
set -gx TMUX_TMPDIR $HOME/.local/state/tmux
mkdir -p $TMUX_TMPDIR

set -x ROKU_DEV_TARGET 192.168.50.38
set -x ROKU_USERNAME rokudev
set -x ROKU_PASSWORD roku123


set -gx PATH /opt/homebrew/bin $PATH $HOME/.local/bin ~/Library/Android/sdk/platform-tools $PWD/node_modules/.bin ~/.tools

alias unlock-keychain="security unlock-keychain ~/Library/Keychains/login.keychain-db"
alias sync 'git fetch origin main:main; and echo "sync complete: main at "(git rev-parse --short main)'

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"


# Added by Antigravity CLI installer
set -gx PATH "/Users/taran/.local/bin" $PATH
