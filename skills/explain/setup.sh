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
printf '{\n  "mermaid": "%s",\n  "chart.js": "%s",\n  "marked": "%s"\n}\n' \
  "$MERMAID_VERSION" "$CHARTJS_VERSION" "$MARKED_VERSION" > "$VENDOR/VERSIONS.json"

# Symlink so style changes in the skill show up in every existing doc.
for f in explain.css explain.js slides.js; do
  ln -sfn "$SKILL_DIR/assets/$f" "$ASSETS/$f"
done

NGINX_SERVERS="$(brew --prefix)/etc/nginx/servers"
mkdir -p "$NGINX_SERVERS"
sed "s|__EXPLAIN_HOME__|$EXPLAIN_HOME|" "$SKILL_DIR/nginx/explain.conf.template" > "$NGINX_SERVERS/explain.conf"
nginx -t
brew services restart nginx >/dev/null

python3 "$SKILL_DIR/scripts/explain.py" index
