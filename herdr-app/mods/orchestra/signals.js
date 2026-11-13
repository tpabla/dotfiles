// Pure: two terminal snapshots -> the messages that probably passed between agents.
// herdr keeps no message log, so these are inferred:
//   prompt: an agent's turn count rose while the agent above it was working (it sent the prompt)
//   report: an agent stopped working (the one above it hears back)
//   spawn:  an agent appeared under an orchestrator or worker

/**
 * @param {any[]|null} previous  terminals() at the last look
 * @param {any[]} current        terminals() now
 * @param {import("./model.js").Overview} overview  built from `current`
 * @returns {{from: string, to: string, kind: "prompt"|"report"|"spawn"}[]}
 */
export function inferSignals(previous, current, overview) {
  if (!previous) return [];
  const before = new Map(previous.map((t) => [t.address, t]));
  const now = new Map(current.map((t) => [t.address, t]));
  const signals = [];

  const pairs = [];
  for (const w of overview.workers) {
    if (w.orchestrator) pairs.push([w.orchestrator, w.address]);
    for (const c of w.children) pairs.push([w.address, c.address]);
  }

  for (const [upper, lower] of pairs) {
    const was = before.get(lower);
    const is = now.get(lower);
    if (!is) continue;
    if (!was) {
      signals.push({ from: upper, to: lower, kind: "spawn" });
      continue;
    }
    const upperBusy = statusOf(before.get(upper)) === "working" || statusOf(now.get(upper)) === "working";
    if ((is.turn ?? 0) > (was.turn ?? 0) && upperBusy) signals.push({ from: upper, to: lower, kind: "prompt" });
    if (statusOf(was) === "working" && statusOf(is) !== "working") signals.push({ from: lower, to: upper, kind: "report" });
  }
  return signals;
}

function statusOf(t) {
  if (!t) return null;
  return typeof t.status === "string" ? t.status : t.status?.state ?? null;
}
