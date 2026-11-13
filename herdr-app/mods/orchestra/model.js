// Pure: live terminals + one space -> what the overview shows. No herdr imports, so node can test it.

export const BUCKETS = ["needsYou", "working", "waiting", "done"];

const NEEDS_YOU = new Set(["needs-you", "review", "blocked", "ready-for-review"]);
const PREFIX = /^\s*([a-z][a-z-]*)\s*:\s*(.*)$/i;

/**
 * @param {any[]} terminals  terminals() from herdr (hc ls --json shape, with labels)
 * @param {{id: string, name: string, machine?: string|null, tabs: {id: string, name: string, index?: number}[]}} space
 * @returns {Overview}
 */
export function buildOverview(terminals, space) {
  const tabs = new Map(space.tabs.map((t, i) => [localId(t.id), { name: t.name, index: t.index ?? i + 1 }]));
  const members = terminals.filter((t) => inSpace(t, space) && statusOf(t) !== null);
  const byAddress = new Map(members.map((t) => [t.address, t]));

  const orchestratorSet = findOrchestrators(members, tabs);
  const orchestrators = members.filter((t) => orchestratorSet.has(t.address)).map((t) => toOrchestrator(t, tabs));

  const isSubAgent = (t) => t.parent && byAddress.has(t.parent) && !orchestratorSet.has(t.parent);
  const workers = members
    .filter((t) => !orchestratorSet.has(t.address) && !isSubAgent(t))
    .map((t) => toWorker(t, tabs, members, orchestrators))
    .sort((a, b) => order(a, tabs) - order(b, tabs) || a.address.localeCompare(b.address, undefined, { numeric: true }));
  linkDependencies(workers);

  const buckets = Object.fromEntries(BUCKETS.map((b) => [b, workers.filter((w) => w.bucket === b).map((w) => w.address)]));
  const counts = Object.fromEntries(BUCKETS.map((b) => [b, buckets[b].length]));
  return { space: { id: space.id, name: space.name }, orchestrators, workers, buckets, counts };
}

/**
 * The selectable rows, in display order: orchestrators, then workers by bucket, each followed by its sub-agents.
 * A filter keeps workers whose name, summary or tab name contains it (case-insensitive), with their sub-agents.
 * @param {Overview} overview
 * @param {string} [filter]
 * @returns {{kind: "orchestrator"|"worker"|"sub", address: string, bucket?: string}[]}
 */
export function rowsOf(overview, filter = "") {
  const needle = filter.trim().toLowerCase();
  const matches = (w) => !needle || [w.name, w.summary, w.tabName].some((s) => s?.toLowerCase().includes(needle));
  const rows = needle ? [] : overview.orchestrators.map((o) => ({ kind: "orchestrator", address: o.address }));
  const workers = new Map(overview.workers.map((w) => [w.address, w]));
  for (const bucket of BUCKETS) {
    for (const address of overview.buckets[bucket]) {
      const w = workers.get(address);
      if (!matches(w)) continue;
      rows.push({ kind: "worker", address, bucket });
      for (const c of w.children) rows.push({ kind: "sub", address: c.address });
    }
  }
  return rows;
}

function localId(id) {
  return id.includes("/") ? id.slice(id.indexOf("/") + 1) : id;
}

function machineOf(address) {
  return address.includes("/") ? address.slice(0, address.indexOf("/")) : null;
}

function inSpace(t, space) {
  return t.labels?.["herdr.space"] === localId(space.id) && machineOf(t.address) === (space.machine ?? null);
}

function statusOf(t) {
  if (typeof t.status === "string") return t.status;
  return t.status?.state ?? null;
}

function activityOf(t) {
  return t.report?.msg ?? (typeof t.status === "object" ? t.status?.msg : null) ?? null;
}

function tabOf(t, tabs) {
  const id = t.labels?.["herdr.tab"];
  return id && tabs.has(id) ? { id, ...tabs.get(id) } : null;
}

function findOrchestrators(members, tabs) {
  const labelled = members.filter((t) => t.labels?.["orch.role"] === "orchestrator");
  if (labelled.length) return new Set(labelled.map((t) => t.address));
  const named = members.filter((t) => /orchestrator/i.test(tabOf(t, tabs)?.name ?? ""));
  if (named.length) return new Set(named.map((t) => t.address));
  const addresses = new Set(members.map((t) => t.address));
  const parents = members.map((t) => t.parent).filter((p) => p && addresses.has(p));
  const roots = parents.filter((p) => !members.find((t) => t.address === p)?.parent);
  return new Set(roots);
}

function toOrchestrator(t, tabs) {
  const tab = tabOf(t, tabs);
  return {
    address: t.address,
    name: t.name ?? tab?.name ?? t.address,
    status: statusOf(t),
    activity: activityOf(t),
    tabId: tab?.id ?? null,
    tabName: tab?.name ?? null,
  };
}

function parseOrchStatus(value) {
  if (!value) return null;
  const [state, ...rest] = value.split(" - ");
  return { state: state.trim(), sentence: rest.join(" - ").trim() || null };
}

function whereTail(t) {
  const where = t.labels?.where;
  return where?.includes(" / ") ? where.slice(where.indexOf(" / ") + 3) : null;
}

function toWorker(t, tabs, members, orchestrators) {
  const tab = tabOf(t, tabs);
  const title = tab?.name ?? whereTail(t);
  const prefixed = title?.match(PREFIX);
  const tabState = prefixed ? prefixed[1].toLowerCase() : null;
  const tabSummary = prefixed ? prefixed[2].trim() : null;
  const orch = parseOrchStatus(t.labels?.["orch.status"]);
  const status = statusOf(t);
  const state = orch?.state ?? tabState;
  const summary = orch ? orch.sentence : tabSummary;

  return {
    address: t.address,
    name: t.labels?.["orch.item"] ?? t.name ?? tabSummary ?? title ?? t.address,
    item: t.labels?.["orch.item"] ?? null,
    bucket: bucketFor(t, status, orch?.state, tabState),
    status,
    state,
    summary,
    activity: activityOf(t),
    tabId: tab?.id ?? null,
    tabName: tab?.name ?? null,
    pr: title?.replace(/\([^)]*\)/g, "").match(/#(\d+)/)?.[1] ?? null,
    mentions: [...`${title ?? ""} ${orch?.sentence ?? ""}`.matchAll(/#(\d+)/g)].map((m) => m[1]),
    dependsOn: [],
    orchestrator: orchestratorFor(t, orchestrators, members),
    children: members
      .filter((c) => c.parent === t.address)
      .map((c) => ({ address: c.address, name: c.name ?? c.address, status: statusOf(c) })),
  };
}

// A worker that mentions another worker's PR (other than its own) depends on that worker.
function linkDependencies(workers) {
  const byPr = new Map(workers.filter((w) => w.pr).map((w) => [w.pr, w.address]));
  for (const w of workers) {
    const deps = w.mentions.filter((pr) => pr !== w.pr && byPr.has(pr)).map((pr) => byPr.get(pr));
    w.dependsOn = [...new Set(deps)].filter((a) => a !== w.address);
    delete w.mentions;
  }
}

function bucketFor(t, status, orchState, tabState) {
  if (t.state && t.state !== "live") return "done";
  if (tabState === "done" || orchState === "done") return "done";
  if (status === "blocked" || NEEDS_YOU.has(orchState) || NEEDS_YOU.has(tabState)) return "needsYou";
  if (status === "working") return "working";
  return "waiting";
}

function orchestratorFor(t, orchestrators, members) {
  const label = t.labels?.orch;
  if (label) {
    const match = orchestrators.find((o) => members.find((m) => m.address === o.address)?.labels?.orch === label);
    if (match) return match.address;
  }
  if (orchestrators.some((o) => o.address === t.parent)) return t.parent;
  return orchestrators.length === 1 ? orchestrators[0].address : null;
}

function order(w, tabs) {
  return w.tabId ? tabs.get(w.tabId).index : Number.MAX_SAFE_INTEGER;
}

/**
 * @typedef {{address: string, name: string, status: string|null, activity: string|null, tabId: string|null, tabName: string|null}} Orchestrator
 * @typedef {{address: string, name: string, status: string|null}} SubAgent
 * @typedef {{address: string, name: string, item: string|null, bucket: string, status: string|null,
 *   state: string|null, summary: string|null, activity: string|null, tabId: string|null, tabName: string|null,
 *   pr: string|null, dependsOn: string[], orchestrator: string|null, children: SubAgent[]}} Worker
 * @typedef {{space: {id: string, name: string}, orchestrators: Orchestrator[], workers: Worker[],
 *   buckets: Record<string, string[]>, counts: Record<string, number>}} Overview
 */
