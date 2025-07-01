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

alias icat="kitten icat"

set -x GOPATH /Users/taran/go
set -x GOBIN /Users/taran/go/bin

set -x EDITOR nvim
set -x DOCKERPATH $HOME/.docker/bin

set -gx PATH /opt/homebrew/bin $PATH /Users/taran/.local/bin
