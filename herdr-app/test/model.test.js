import { test } from "node:test";
import assert from "node:assert/strict";
import { buildOverview, rowsOf } from "../mods/orchestra/model.js";
import { space, term } from "./fixtures.js";

const worker = (o, address) => o.workers.find((w) => w.address === address);
const bucketOf = (o, address) => worker(o, address)?.bucket;

test("empty space has no orchestrators, workers or counts", () => {
  const o = buildOverview([], space([["tb1", "1"]]));
  assert.deepEqual(o.orchestrators, []);
  assert.deepEqual(o.workers, []);
  assert.deepEqual(o.counts, { needsYou: 0, working: 0, waiting: 0, done: 0 });
});

test("non-agent terminals (no status) are left out", () => {
  const o = buildOverview([term("t1", { status: null, tab: "tb1" })], space([["tb1", "1"]]));
  assert.equal(o.workers.length, 0);
});

test("terminals from other spaces and machines are left out", () => {
  const o = buildOverview(
    [term("t1", { tab: "tb1", spaceId: "other" }), term("vps/t2", { tab: "tb1" })],
    space([["tb1", "1"]]),
  );
  assert.equal(o.workers.length, 0);
});

test("remote space matches its machine's terminals by local ids", () => {
  const s = space([["vps/tb1", "work: a"]], { id: "vps/sp1", machine: "vps" });
  const o = buildOverview([term("vps/t2", { tab: "tb1" }), term("t3", { tab: "tb1" })], s);
  assert.deepEqual(o.workers.map((w) => w.address), ["vps/t2"]);
  assert.equal(worker(o, "vps/t2").tabName, "work: a");
});

test("status precedence: blocked > needs-you labels > working > waiting; done wins", () => {
  const s = space([
    ["tb1", "work: a"], ["tb2", "needs-you: b"], ["tb3", "review: c #12"],
    ["tb4", "work: d"], ["tb5", "done: e"], ["tb6", "work: f"], ["tb7", "blocked: g"],
  ]);
  const o = buildOverview([
    term("t1", { tab: "tb1", status: "blocked" }),
    term("t2", { tab: "tb2", status: "working" }),
    term("t3", { tab: "tb3", status: "idle" }),
    term("t4", { tab: "tb4", status: "working" }),
    term("t5", { tab: "tb5", status: "blocked" }),
    term("t6", { tab: "tb6", status: "done" }),
    term("t7", { tab: "tb7", status: "idle" }),
  ], s);
  assert.equal(bucketOf(o, "t1"), "needsYou");
  assert.equal(bucketOf(o, "t2"), "needsYou");
  assert.equal(bucketOf(o, "t3"), "needsYou");
  assert.equal(bucketOf(o, "t4"), "working");
  assert.equal(bucketOf(o, "t5"), "done");
  assert.equal(bucketOf(o, "t6"), "waiting");
  assert.equal(bucketOf(o, "t7"), "needsYou");
});

test("finished terminals are shown as done, not dropped", () => {
  const o = buildOverview([term("t1", { tab: "tb1", state: "finished", status: "idle" })], space([["tb1", "work: a"]]));
  assert.equal(bucketOf(o, "t1"), "done");
});

test("orch.status label: state sets the bucket, sentence is the summary", () => {
  const s = space([["tb1", "work: a"], ["tb2", "work: b"], ["tb3", "work: c"]]);
  const o = buildOverview([
    term("t1", { tab: "tb1", status: "idle", labels: { "orch.status": "ready-for-review - CI green, Bugbot clean" } }),
    term("t2", { tab: "tb2", status: "idle", labels: { "orch.status": "needs-orchestrator - which branch?" } }),
    term("t3", { tab: "tb3", status: "working", labels: { "orch.status": "working" } }),
  ], s);
  assert.equal(bucketOf(o, "t1"), "needsYou");
  assert.equal(worker(o, "t1").summary, "CI green, Bugbot clean");
  assert.equal(worker(o, "t1").state, "ready-for-review");
  assert.equal(bucketOf(o, "t2"), "waiting");
  assert.equal(worker(o, "t3").summary, null);
});

test("without orch.status the summary falls back to the tab name after its prefix", () => {
  const o = buildOverview([term("t1", { tab: "tb1", status: "idle" })], space([["tb1", "needs-you: Roku #3020 (2 decisions)"]]));
  const w = worker(o, "t1");
  assert.equal(w.summary, "Roku #3020 (2 decisions)");
  assert.equal(w.state, "needs-you");
  assert.equal(w.pr, "3020");
});

test("activity comes from the agent's live report, status may be an object", () => {
  const t = term("t1", { tab: "tb1" });
  t.status = { app: "claude-code", state: "working", msg: "running tests" };
  t.report = null;
  const o = buildOverview([t, term("t2", { tab: "tb1", status: "working", msg: "reading files" })], space([["tb1", "work: a"]]));
  assert.equal(worker(o, "t1").activity, "running tests");
  assert.equal(worker(o, "t1").bucket, "working");
  assert.equal(worker(o, "t2").activity, "reading files");
});

test("orchestrator found by orch.role label", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1", labels: { "orch.role": "orchestrator", orch: "api" } }),
    term("t2", { tab: "tb2", labels: { orch: "api", "orch.role": "worker" } }),
  ], space([["tb1", "1"], ["tb2", "work: a"]]));
  assert.deepEqual(o.orchestrators.map((x) => x.address), ["t1"]);
  assert.equal(worker(o, "t2").orchestrator, "t1");
});

test("orchestrator found by tab name when there are no labels", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1" }), term("t2", { tab: "tb2" }),
  ], space([["tb1", "fortress orchestrator"], ["tb2", "work: FRT-34"]]));
  assert.deepEqual(o.orchestrators.map((x) => x.address), ["t1"]);
  assert.equal(worker(o, "t2").orchestrator, "t1");
});

test("orchestrator found as the parent of agents in the space", () => {
  const o = buildOverview([
    term("t15", { tab: "tb1" }),
    term("t16", { parent: "t15", name: "roku-release", status: "idle" }),
  ], space([["tb1", "Platform Manager"]]));
  assert.deepEqual(o.orchestrators.map((x) => x.address), ["t15"]);
  const w = worker(o, "t16");
  assert.equal(w.orchestrator, "t15");
  assert.equal(w.name, "roku-release");
  assert.equal(w.tabId, null);
});

test("workers stay grouped by orch label after the orchestrator restarted (dead parent)", () => {
  const o = buildOverview([
    term("t9", { tab: "tb1", labels: { "orch.role": "orchestrator", orch: "api" } }),
    term("t2", { tab: "tb2", parent: "t1", labels: { orch: "api" } }),
  ], space([["tb1", "api orchestrator"], ["tb2", "work: a"]]));
  assert.equal(worker(o, "t2").orchestrator, "t9");
});

test("sub-agents nest under their worker, not listed as workers", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1", labels: { "orch.role": "orchestrator" } }),
    term("t2", { tab: "tb2", parent: "t1", status: "working" }),
    term("t3", { parent: "t2", name: "reviewer", status: "working" }),
  ], space([["tb1", "o"], ["tb2", "work: a"]]));
  assert.deepEqual(o.workers.map((w) => w.address), ["t2"]);
  assert.deepEqual(worker(o, "t2").children, [{ address: "t3", name: "reviewer", status: "working" }]);
});

test("worker with no labels and no tab name is still listed by address", () => {
  const o = buildOverview([term("t5", { status: "working" })], space([]));
  const w = worker(o, "t5");
  assert.equal(w.name, "t5");
  assert.equal(w.bucket, "working");
  assert.equal(w.orchestrator, null);
});

test("name prefers orch.item, then terminal name, then tab summary", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1", name: "n1", labels: { "orch.item": "FRT-34" } }),
    term("t2", { tab: "tb2", name: "n2" }),
    term("t3", { tab: "tb3" }),
  ], space([["tb1", "work: x"], ["tb2", "work: y"], ["tb3", "review: pricing #9"]]));
  assert.equal(worker(o, "t1").name, "FRT-34");
  assert.equal(worker(o, "t2").name, "n2");
  assert.equal(worker(o, "t3").name, "pricing #9");
});

test("buckets list addresses in tab order and counts match", () => {
  const o = buildOverview([
    term("t3", { tab: "tb3", status: "working" }),
    term("t1", { tab: "tb1", status: "working" }),
    term("t2", { tab: "tb2", status: "blocked" }),
  ], space([["tb1", "work: a"], ["tb2", "work: b"], ["tb3", "work: c"]]));
  assert.deepEqual(o.buckets.working, ["t1", "t3"]);
  assert.deepEqual(o.buckets.needsYou, ["t2"]);
  assert.deepEqual(o.counts, { needsYou: 1, working: 2, waiting: 0, done: 0 });
});

test("rowsOf: orchestrators, then workers by bucket, each followed by its sub-agents", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1", labels: { "orch.role": "orchestrator" } }),
    term("t2", { tab: "tb2", parent: "t1", status: "working" }),
    term("t3", { tab: "tb3", parent: "t1", status: "blocked" }),
    term("t4", { parent: "t2", name: "reviewer", status: "working" }),
  ], space([["tb1", "o"], ["tb2", "work: a"], ["tb3", "work: b"]]));
  assert.deepEqual(rowsOf(o).map((r) => [r.kind, r.address, r.bucket ?? null]), [
    ["orchestrator", "t1", null],
    ["worker", "t3", "needsYou"],
    ["worker", "t2", "working"],
    ["sub", "t4", null],
  ]);
});

test("rowsOf with a filter keeps matching workers (name, summary, tab) and their sub-agents", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1", labels: { "orch.role": "orchestrator" } }),
    term("t2", { tab: "tb2", status: "working", labels: { "orch.status": "working - fixing Roku cert" } }),
    term("t3", { tab: "tb3", status: "working" }),
    term("t4", { parent: "t2", name: "reviewer" }),
  ], space([["tb1", "o"], ["tb2", "work: a"], ["tb3", "work: pricing"]]));
  assert.deepEqual(rowsOf(o, "roku").map((r) => r.address), ["t2", "t4"]);
  assert.deepEqual(rowsOf(o, "PRICING").map((r) => r.address), ["t3"]);
  assert.deepEqual(rowsOf(o, "").map((r) => r.address), ["t1", "t2", "t4", "t3"]);
});

test("dependsOn: a worker that mentions another worker's PR depends on it", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1", status: "idle" }),
    term("t2", { tab: "tb2", status: "idle" }),
    term("t3", { tab: "tb3", status: "idle", labels: { "orch.status": "blocked - waiting on #3020 and #9999" } }),
  ], space([["tb1", "needs-you: Roku #3020"], ["tb2", "blocked: FRT-47 #3237 (after #3020: main merge)"], ["tb3", "work: x #1"]]));
  assert.deepEqual(worker(o, "t2").dependsOn, ["t1"]);
  assert.deepEqual(worker(o, "t3").dependsOn, ["t1"]);
  assert.deepEqual(worker(o, "t1").dependsOn, []);
});

test("own PR is the first #N outside parentheses; parenthesised ones are only mentions", () => {
  const o = buildOverview([
    term("t1", { tab: "tb1" }), term("t2", { tab: "tb2" }),
  ], space([["tb1", "blocked: FRT-47 (after #3020)"], ["tb2", "work: FRT-34 #1421 (see #77)"]]));
  assert.equal(worker(o, "t1").pr, null);
  assert.equal(worker(o, "t2").pr, "1421");
});
