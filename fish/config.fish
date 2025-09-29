function vim
  nvim $argv
end

function reload_hosts
  sudo killall -HUP mDNSResponder
end

function rust_book
  rustup docs --book
end

if command -v jest >/dev/null 2>&1
  jest --completion fish | source
end

fish_vi_key_bindings

bind -M insert \cd delete-char  # For vi insert mode
bind -M default \cd delete-char # For vi normal mode


alias icat="kitten icat"

set -x GOPATH /Users/taran/go
set -x GOBIN /Users/taran/go/bin

set -x EDITOR nvim
set -x DOCKERPATH $HOME/.docker/bin

set -x PAGER less -R

set -gx PATH /opt/homebrew/bin $PATH /Users/taran/.local/bin ~/Library/Android/sdk/platform-tools $PWD/node_modules/.bin
