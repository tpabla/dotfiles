#!/bin/sh
# SessionStart: tell Claude which herdr front end it is in (runs on startup, resume, clear, compact).
# In herdr-app it also labels this terminal with the Claude session id so it can be resumed later.

input=$(cat)
field() { printf '%s' "$input" | jq -r ".$1 // empty" 2>/dev/null; }

# Claude subagents share the terminal; only the main session reports.
[ -n "$(field agent_id)" ] && exit 0

session_id=$(field session_id)
note="herdr (current; overrides any earlier herdr note in this conversation):"

if [ "${HERDR_ENV:-}" = "1" ] && [ -n "${HERDR_PANE_ID:-}" ]; then
  echo "$note herdr TUI. workspace=${HERDR_WORKSPACE_ID:-?} tab=${HERDR_TAB_ID:-?} pane=$HERDR_PANE_ID session=${session_id:-?}. Use the 'herdr TUI' commands in CLAUDE.md."
elif [ -n "${HC_TERMINAL_ID:-}" ] && command -v hc >/dev/null 2>&1; then
  [ -n "$session_id" ] && hc label "$HC_TERMINAL_ID" "claude.session=$session_id" >/dev/null 2>&1
  labels=$(hc get "$HC_TERMINAL_ID" --json 2>/dev/null | jq -r '.labels // {} | "space=\(.["herdr.space"] // "?") tab=\(.["herdr.tab"] // "?") orch=\(.orch // "-")"' 2>/dev/null)
  echo "$note herdr-app. terminal=$HC_TERMINAL_ID ${labels:-space=? tab=?} session=${session_id:-?}. Use the 'herdr-app' commands in CLAUDE.md."
fi
exit 0
