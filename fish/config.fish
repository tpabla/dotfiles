# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:$HOME/.docker/bin"
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

bind -M insert \cd delete-char  # For vi insert mode
bind -M default \cd delete-char # For vi normal mode


alias icat="kitten icat"

set -x GOPATH $HOME/go
set -x GOBIN $HOME/go/bin

set -x EDITOR nvim
set -x DOCKERPATH $HOME/.docker/bin

set -x PAGER less -R

set -gx PATH /opt/homebrew/bin $PATH $HOME/.local/bin ~/Library/Android/sdk/platform-tools $PWD/node_modules/.bin ~/.tools

alias unlock-keychain="security unlock-keychain ~/Library/Keychains/login.keychain-db"

# Hermes Agent — ensure ~/.local/bin is on PATH
fish_add_path "$HOME/.local/bin"
