// Pure: overview -> the night-shift room. One row per agent (the lead's console, worker booths, helper drones),
// stacked top to bottom, with the cables that join them and the routes packets take along those cables.

import { rowsOf } from "./model.js";

export const METRICS = {
  lead: 68,
  worker: 56,
  helper: 36,
  gap: 6,
  trunkX: 20, // the lead's cable runs down here
  boothX: 36, // worker booths start here
  helperTrunkX: 58, // a worker's cable to its helpers
  helperBoothX: 74,
};

const SCENES = { needsYou: "alert", working: "typing", waiting: "cursor", done: "ok" };

/**
 * @param {import("./model.js").Overview} overview
 * @param {string} [filter]
 * @returns {{kind: "lead"|"worker"|"helper", address: string, bucket?: string, scene: string,
 *   cable: "mid"|"end"|null, trunk: boolean, parent: string|null}[]}
 */
export function deskRows(overview, filter = "") {
  const workers = new Map(overview.workers.map((w) => [w.address, w]));
  const helpers = new Map(overview.workers.flatMap((w) => w.children.map((c) => [c.address, { ...c, parent: w.address }])));
  const ordered = rowsOf(overview, filter);

  const attached = ordered.filter((r) => r.kind === "worker" && workers.get(r.address).orchestrator);
  const lastAttached = attached.at(-1)?.address;
  const attachedAfter = (index) => ordered.slice(index + 1).some((r) => r.kind === "worker" && workers.get(r.address).orchestrator);

  return ordered.map((r, i) => {
    if (r.kind === "orchestrator") return { kind: "lead", address: r.address, scene: "console", cable: null, trunk: false, parent: null };
    if (r.kind === "worker") {
      const w = workers.get(r.address);
      const cable = w.orchestrator ? (r.address === lastAttached ? "end" : "mid") : null;
      return { kind: "worker", address: r.address, bucket: r.bucket, scene: SCENES[r.bucket], cable, trunk: false, parent: w.orchestrator };
    }
    const h = helpers.get(r.address);
    const siblings = workers.get(h.parent).children;
    const cable = siblings.at(-1).address === r.address ? "end" : "mid";
    const parentAttached = Boolean(workers.get(h.parent).orchestrator);
    return {
      kind: "helper", address: r.address, scene: h.status === "working" ? "drone-busy" : "drone-idle",
      cable, trunk: parentAttached && attachedAfter(i), parent: h.parent,
    };
  });
}

/** Rows with their y and height, stacked top to bottom. */
export function placeDesks(rows) {
  let y = 0;
  return rows.map((r) => {
    const placed = { ...r, y, h: METRICS[r.kind] };
    y += placed.h + METRICS.gap;
    return placed;
  });
}

/** The cable route between two connected rows, from `from` to `to`; null when they aren't connected. */
export function cablePoints(placed, from, to) {
  const a = placed.find((r) => r.address === from);
  const b = placed.find((r) => r.address === to);
  if (!a || !b) return null;
  const [upper, lower] = b.parent === a.address ? [a, b] : a.parent === b.address ? [b, a] : [null, null];
  if (!upper) return null;
  const cy = lower.y + lower.h / 2;
  const down = lower.kind === "helper"
    ? [[METRICS.helperTrunkX, upper.y + upper.h], [METRICS.helperTrunkX, cy], [METRICS.helperBoothX, cy]]
    : [[METRICS.trunkX, upper.y + upper.h], [METRICS.trunkX, cy], [METRICS.boothX, cy]];
  return upper === a ? down : [...down].reverse();
}
