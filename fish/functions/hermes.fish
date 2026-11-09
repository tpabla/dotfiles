# hermes — herdr-aware launcher (installed to fix Herdr 0.9.5 agent recognition)
#
# Herdr 0.9.5 identifies the "hermes" agent from the process argv, but the stock
# launcher runs `python3 -I -c '<code>'` whose argv only shows `python3`, so a
# pane never appears in `herdr agent list`. Launching through a real file named
# `hermes` (with the managed interpreter) makes the process recognizable
# while behaving the same as the stock launcher.
#
# IMPORTANT (fix 2026-10-29): the interpreter MUST be the managed one recorded in
# ~/.hermes/tools/facts.json. If hermes starts under any other python, its
# venv_sync.relaunch_command() re-execs the process (same PID) into
# `python3 -I -I -c '<runpy ...>'`, which loses the recognizable argv and Herdr
# drops the pane from agent recognition. The old `python-3.14.7*` glob hit this
# trap (3.14.7 predates the managed 3.14.9 generation).
#
# Inside a Herdr pane: use the named launcher. Elsewhere: fall through to the
# real `hermes` command (preserving its update-recovery path).
function hermes
    if set -q HERDR_ENV; or set -q HERDR_PANE_ID
        # Managed interpreter from the pm ledger (facts.json), e.g.
        # ~/.hermes/tools/python-3.14.9+<build>-darwin-arm64/bin/python3
        set -l bp (python3 -c '
import json, pathlib
try:
    facts = pathlib.Path.home() / ".hermes" / "tools" / "facts.json"
    entry = json.loads(facts.read_text())["packages"]["python"]["entry"]
    p = pathlib.Path.home() / ".hermes" / "tools" / entry / "bin" / "python3"
    if p.is_file():
        print(p)
except Exception:
    pass' 2>/dev/null)
        if test -z "$bp"
            # Fallback: newest bundled 3.14.x toolchain
            set bp (ls -d ~/.hermes/tools/python-3.14.*/bin/python3 2>/dev/null | sort -V | tail -n 1)
        end
        if test -n "$bp"
            exec "$bp" -I ~/.hermes/herdr-hermes/hermes $argv
        else
            command hermes $argv
        end
    else
        command hermes $argv
    end
end
