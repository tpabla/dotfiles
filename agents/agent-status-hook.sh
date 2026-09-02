#!/usr/bin/env bash

# Generic status writer for tmux-agent-status.
#
#   usage: agent-status-hook.sh <agent-name> <working|done|wait> [--clear-overrides]
#
# Mirrors the file contract of the plugin's bundled better-hook.sh so any agent
# without a first-party hook can report state. --clear-overrides marks an
# explicit user interaction, which cancels wait mode and unparks.

set -u

AGENT_NAME="${1:-}"
REQUESTED_STATUS="${2:-}"
CLEAR_OVERRIDES="${3:-}"

case "$REQUESTED_STATUS" in
    working|done|wait) ;;
    *) exit 0 ;;
esac
[ -n "$AGENT_NAME" ] || exit 0

STATUS_DIR="$HOME/.cache/tmux-agent-status"
WAIT_DIR="$STATUS_DIR/wait"
PARKED_DIR="$STATUS_DIR/parked"
PANE_DIR="$STATUS_DIR/panes"
REFRESH_FILE="$STATUS_DIR/.sidebar-refresh"
mkdir -p "$STATUS_DIR" "$WAIT_DIR" "$PARKED_DIR" "$PANE_DIR" || exit 0

in_remote_session() {
    [ -n "${SSH_CONNECTION:-}" ] || [ -n "${SSH_TTY:-}" ]
}

get_tmux_session() {
    local tmux_session=""
    if [ -n "${TMUX:-}" ] || in_remote_session; then
        tmux_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
        if [ -z "$tmux_session" ]; then
            if in_remote_session; then
                tmux_session=$(hostname -s 2>/dev/null)
            elif [ -n "${TMUX:-}" ]; then
                tmux_session=$(basename "${TMUX%%,*}")
            fi
        fi
    fi
    [ -n "$tmux_session" ] || return 1
    printf '%s\n' "$tmux_session"
}

# The session rolls up from its panes: any working pane wins, then any wait,
# otherwise done. Matches the bundled hook so mixed agents agree.
set_status() {
    local tmux_session="$1" requested_status="$2"
    local session_status="$requested_status"
    local status_file="$STATUS_DIR/${tmux_session}.status"

    if [ -n "${TMUX_PANE:-}" ]; then
        printf '%s\n' "$requested_status" > "$PANE_DIR/${tmux_session}_${TMUX_PANE}.status"
        printf '%s\n' "$AGENT_NAME" > "$PANE_DIR/${tmux_session}_${TMUX_PANE}.agent"

        session_status="done"
        local pane_file pane_status
        for pane_file in "$PANE_DIR/${tmux_session}_"*.status; do
            [ -f "$pane_file" ] || continue
            pane_status=$(cat "$pane_file" 2>/dev/null || echo "")
            case "$pane_status" in
                working) session_status="working"; break ;;
                wait) [ "$session_status" = "working" ] || session_status="wait" ;;
            esac
        done
    fi

    printf '%s\n' "$session_status" > "$status_file"
    if in_remote_session; then
        printf '%s\n' "$session_status" > "$STATUS_DIR/${tmux_session}-remote.status" 2>/dev/null
    fi
}

clear_interaction_overrides() {
    local tmux_session="$1"
    if [ -f "$WAIT_DIR/${tmux_session}.wait" ]; then
        rm -f "$WAIT_DIR/${tmux_session}.wait" "$WAIT_DIR/${tmux_session}_"*.wait 2>/dev/null
    elif [ -n "${TMUX_PANE:-}" ]; then
        rm -f "$WAIT_DIR/${tmux_session}_${TMUX_PANE}.wait" 2>/dev/null
    fi

    if [ -f "$PARKED_DIR/${tmux_session}.parked" ]; then
        rm -f "$PARKED_DIR/${tmux_session}.parked" "$PARKED_DIR/${tmux_session}_"*.parked 2>/dev/null
    elif [ -n "${TMUX_PANE:-}" ]; then
        rm -f "$PARKED_DIR/${tmux_session}_${TMUX_PANE}.parked" 2>/dev/null
    fi
}

TMUX_SESSION=$(get_tmux_session) || exit 0

if [ "$CLEAR_OVERRIDES" = "--clear-overrides" ]; then
    clear_interaction_overrides "$TMUX_SESSION"
else
    # Parking is an explicit user decision, so only a real interaction unparks.
    [ -f "$PARKED_DIR/${TMUX_SESSION}.parked" ] && exit 0
    rm -f "$WAIT_DIR/${TMUX_SESSION}.wait" 2>/dev/null
fi

set_status "$TMUX_SESSION" "$REQUESTED_STATUS"
touch "$REFRESH_FILE" 2>/dev/null || true
exit 0
