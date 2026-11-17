#!/usr/bin/env bash
# Idempotent setup: nginx, vendored libraries, asset links, config, index pages.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPLAIN_HOME="$HOME/.explain-skill"
ASSETS="$EXPLAIN_HOME/docs/_assets"
VENDOR="$ASSETS/vendor"

MERMAID_VERSION="12.2.0"
CHARTJS_VERSION="4.6.1"
MARKED_VERSION="18.1.2"
FONTSOURCE_VERSION="5.1.1"

command -v nginx >/dev/null || brew install nginx

mkdir -p "$VENDOR/fonts"

fetch() {
  local url="$1" dest="$2"
  [[ -s "$dest" && "${FORCE:-0}" != 1 ]] || curl -fsSL "$url" -o "$dest"
}
fetch "https://cdn.jsdelivr.net/npm/mermaid@$MERMAID_VERSION/dist/mermaid.min.js" "$VENDOR/mermaid.min.js"
fetch "https://cdn.jsdelivr.net/npm/chart.js@$CHARTJS_VERSION/dist/chart.umd.min.js" "$VENDOR/chart.umd.js"
fetch "https://cdn.jsdelivr.net/npm/marked@$MARKED_VERSION/lib/marked.umd.js" "$VENDOR/marked.min.js"
fs="https://cdn.jsdelivr.net/npm/@fontsource"
fetch "$fs/orbitron@$FONTSOURCE_VERSION/files/orbitron-latin-700-normal.woff2" "$VENDOR/fonts/orbitron-700.woff2"
fetch "$fs/chakra-petch@$FONTSOURCE_VERSION/files/chakra-petch-latin-400-normal.woff2" "$VENDOR/fonts/chakra-petch-400.woff2"
fetch "$fs/chakra-petch@$FONTSOURCE_VERSION/files/chakra-petch-latin-600-normal.woff2" "$VENDOR/fonts/chakra-petch-600.woff2"
fetch "$fs/jetbrains-mono@$FONTSOURCE_VERSION/files/jetbrains-mono-latin-400-normal.woff2" "$VENDOR/fonts/jetbrains-mono-400.woff2"
# Fonts explain.css loads (keep in step with its @font-face rules).
for w in 500 700 900; do
  fetch "$fs/tektur@$FONTSOURCE_VERSION/files/tektur-latin-$w-normal.woff2" "$VENDOR/fonts/tektur-$w.woff2"
done
fetch "$fs/atkinson-hyperlegible@$FONTSOURCE_VERSION/files/atkinson-hyperlegible-latin-400-normal.woff2" "$VENDOR/fonts/atkinson-400.woff2"
fetch "$fs/atkinson-hyperlegible@$FONTSOURCE_VERSION/files/atkinson-hyperlegible-latin-400-italic.woff2" "$VENDOR/fonts/atkinson-400-italic.woff2"
fetch "$fs/atkinson-hyperlegible@$FONTSOURCE_VERSION/files/atkinson-hyperlegible-latin-700-normal.woff2" "$VENDOR/fonts/atkinson-700.woff2"
printf '{\n  "mermaid": "%s",\n  "chart.js": "%s",\n  "marked": "%s"\n}\n' \
  "$MERMAID_VERSION" "$CHARTJS_VERSION" "$MARKED_VERSION" > "$VENDOR/VERSIONS.json"

# Symlink so style changes in the skill show up in every existing doc.
for f in explain.css explain.js slides.js; do
  ln -sfn "$SKILL_DIR/assets/$f" "$ASSETS/$f"
done

# nginx: EXPLAIN_NGINX=server (own server block, needs EXPLAIN_LISTEN, e.g. 100.x.y.z:80),
# include (writes explain-location.conf for an existing server to include), or skip.
# See SKILL.md "Hosting" before choosing; the agent asks the user first.
NGINX_PREFIX="$(brew --prefix)/etc/nginx"
case "${EXPLAIN_NGINX:-skip}" in
  server)
    : "${EXPLAIN_LISTEN:?set EXPLAIN_LISTEN, e.g. <tailscale-ip>:80}"
    mkdir -p "$NGINX_PREFIX/servers"
    sed -e "s|__EXPLAIN_HOME__|$EXPLAIN_HOME|" -e "s|__LISTEN__|$EXPLAIN_LISTEN|" \
      "$SKILL_DIR/nginx/explain.conf.template" > "$NGINX_PREFIX/servers/explain.conf"
    ;;
  include)
    sed "s|__EXPLAIN_HOME__|$EXPLAIN_HOME|g" "$SKILL_DIR/nginx/explain-location.conf.template" \
      > "$NGINX_PREFIX/explain-location.conf"
    echo "Add 'include explain-location.conf;' to the server that should serve /docs/."
    ;;
  skip) ;;
esac
if [[ "${EXPLAIN_NGINX:-skip}" != skip ]]; then
  nginx -t 2>&1 | grep -q "syntax is ok"
  if [[ "$(ps -o user= -p "$(pgrep -o nginx 2>/dev/null || echo 1)" 2>/dev/null | tr -d ' ')" == root ]]; then
    echo "nginx runs as root: run 'sudo nginx -s reload' to apply."
  else
    brew services restart nginx >/dev/null
  fi
fi

python3 "$SKILL_DIR/scripts/explain.py" index
