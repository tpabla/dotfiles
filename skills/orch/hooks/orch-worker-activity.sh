#!/bin/sh
# Keeps herdr-app orchestration labels fresh for worker sessions (labels orch=<project>, orch.role=worker).
#   prompt: someone typed in the worker. Set orch.status to working and flip a "needs-you:" tab to "work:".
#   stop:   the turn ended. Copy the last "STATUS: <state> - <text>" line into orch.status.
# Does nothing outside herdr-app or in non-worker sessions.

action="${1:-}"
[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
command -v hc >/dev/null 2>&1 || exit 0
command -v python3 >/dev/null 2>&1 || exit 0

input_file="$(mktemp "${TMPDIR:-/tmp}/orch-worker-hook.XXXXXX")" || exit 0
trap 'rm -f "$input_file"' EXIT HUP INT TERM
cat >"$input_file" 2>/dev/null || true

ORCH_ACTION="$action" ORCH_INPUT="$input_file" python3 - <<'PY'
import json, os, re, subprocess

def run(*args):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=5).stdout
    except Exception:
        return ""

term = os.environ["HC_TERMINAL_ID"]
try:
    me = json.loads(run("hc", "get", term) or "{}")
except Exception:
    raise SystemExit(0)
labels = me.get("labels") or {}
if labels.get("orch.role") != "worker" or not labels.get("orch"):
    raise SystemExit(0)

try:
    hook = json.load(open(os.environ["ORCH_INPUT"]))
except Exception:
    hook = {}
if hook.get("agent_id"):
    raise SystemExit(0)

def set_status(text):
    run("hc", "label", term, "orch.status=" + text[:200])

def own_tab():
    try:
        data = json.loads(run("herdr-app", "ls") or "{}")
    except Exception:
        return None
    for space in data.get("spaces", []):
        for tab in space.get("tabs", []):
            if any(t.get("terminal") == term for t in tab.get("terminals", [])):
                return tab
    return None

action = os.environ.get("ORCH_ACTION")
if action == "prompt":
    prompt = " ".join(str(hook.get("prompt") or "").split())
    if prompt.startswith("<task-notification>"):
        raise SystemExit(0)
    set_status("working - new input: " + prompt[:80])
    tab = own_tab()
    if tab and tab.get("name", "").startswith("needs-you:"):
        name = "work:" + tab["name"][len("needs-you:"):]
        run("herdr-app", "do", "tab.rename", json.dumps({"id": tab["id"], "name": name}))
elif action == "stop":
    import time
    time.sleep(3)  # the final message may not be flushed to the transcript yet
    path = hook.get("transcript_path")
    if not path or not os.path.exists(path):
        raise SystemExit(0)
    last = None
    with open(path, encoding="utf-8", errors="replace") as fh:
        lines = fh.readlines()[-400:]
    for line in reversed(lines):
        try:
            entry = json.loads(line)
        except Exception:
            continue
        msg = entry.get("message") or {}
        if entry.get("type") != "assistant" or msg.get("role") != "assistant":
            continue
        content = msg.get("content")
        texts = [c.get("text", "") for c in content if isinstance(c, dict) and c.get("type") == "text"] if isinstance(content, list) else [str(content or "")]
        for text in reversed(texts):
            found = re.findall(r"STATUS:\s*([a-z-]+)\s*[-—–]\s*(.+)", text)
            if found:
                last = found[-1]
                break
        if last:
            break
    if last:
        set_status(last[0] + " - " + " ".join(last[1].split()))
PY
exit 0
