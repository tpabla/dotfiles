// Reports pi's agent state to tmux-agent-status.
//
// pi has no first-party hooks file, so this extension plays the role that
// better-hook.sh / codex-hook.sh play for Claude Code and Codex: it translates
// pi lifecycle events into the plugin's status files via agent-status-hook.sh.
//
// Events are those actually emitted by pi 0.69.0 (see
// dist/core/extensions/types.d.ts). Note there is no permission/approval event,
// so "wait" is not derivable here -- only working and done.
// @ts-nocheck

import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const AGENT = "pi";
// Sibling of this file. Node resolves symlinks, so this points into the
// dotfiles repo even though the extension is linked into ~/.pi/agent/extensions.
const HOOK = join(dirname(fileURLToPath(import.meta.url)), "agent-status-hook.sh");

function inTmux(): boolean {
  return !!process.env.TMUX || !!process.env.TMUX_PANE;
}

function report(state: "working" | "done" | "wait", clearOverrides = false): void {
  if (!inTmux()) return;
  try {
    const args = [HOOK, AGENT, state];
    if (clearOverrides) args.push("--clear-overrides");
    // Detached and ignored: status reporting must never block or kill the agent.
    const child = spawn("bash", args, { stdio: "ignore", detached: true });
    child.on("error", () => {});
    child.unref();
  } catch {
    // Never let status reporting surface an error into pi.
  }
}

export default function (pi) {
  pi.on("session_start", (_event, ctx) => {
    // TUI only: print/json/rpc modes are headless and have no pane to report on.
    if (ctx?.mode !== "tui") return;
    report("done");
  });

  // The user submitted input -- an explicit interaction, so cancel wait/park.
  pi.on("input", () => {
    report("working", true);
  });

  pi.on("agent_start", () => {
    report("working");
  });

  pi.on("tool_execution_start", () => {
    report("working");
  });

  // agent_end is the terminal event in pi 0.69.0. (herdr's own pi integration
  // listens for "agent_settled", which this version never emits.)
  pi.on("agent_end", () => {
    report("done");
  });

  pi.on("session_shutdown", () => {
    report("done");
  });
}
