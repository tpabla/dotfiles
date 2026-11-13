import { test } from "node:test";
import assert from "node:assert/strict";
import { buildOverview } from "../mods/orchestra/model.js";
import { inferSignals } from "../mods/orchestra/signals.js";
import { space, term } from "./fixtures.js";

const S = space([["tb1", "o"], ["tb2", "work: a"]]);

function snap({ o = "idle", w = "idle", wTurn = 1, sub = null } = {}) {
  const list = [
    { ...term("t1", { tab: "tb1", status: o, labels: { "orch.role": "orchestrator" } }), turn: 5 },
    { ...term("t2", { tab: "tb2", parent: "t1", status: w }), turn: wTurn },
  ];
  if (sub) list.push({ ...term("t3", { parent: "t2", name: "reviewer", status: sub.status }), turn: sub.turn });
  return list;
}

const infer = (prev, cur) => inferSignals(prev, cur, buildOverview(cur, S));

test("no previous snapshot: no signals", () => {
  assert.deepEqual(infer(null, snap()), []);
});

test("worker turn goes up while the orchestrator works: prompt orchestrator -> worker", () => {
  assert.deepEqual(infer(snap({ o: "working", wTurn: 1 }), snap({ o: "working", w: "working", wTurn: 2 })),
    [{ from: "t1", to: "t2", kind: "prompt" }]);
  assert.deepEqual(infer(snap({ o: "working", wTurn: 1 }), snap({ o: "idle", w: "working", wTurn: 2 })),
    [{ from: "t1", to: "t2", kind: "prompt" }]);
});

test("worker turn goes up while the orchestrator is idle: that was you, no signal", () => {
  assert.deepEqual(infer(snap({ wTurn: 1 }), snap({ w: "working", wTurn: 2 })), []);
});

test("worker stops working: report worker -> orchestrator", () => {
  assert.deepEqual(infer(snap({ w: "working" }), snap({ w: "idle" })), [{ from: "t2", to: "t1", kind: "report" }]);
  assert.deepEqual(infer(snap({ w: "working" }), snap({ w: "blocked" })), [{ from: "t2", to: "t1", kind: "report" }]);
});

test("nothing changed: no signals", () => {
  assert.deepEqual(infer(snap({ w: "working" }), snap({ w: "working" })), []);
});

test("a new worker appears: spawn from its orchestrator", () => {
  const prev = snap().filter((t) => t.address !== "t2");
  assert.deepEqual(infer(prev, snap()), [{ from: "t1", to: "t2", kind: "spawn" }]);
});

test("sub-agents: prompted by and report to their worker", () => {
  assert.deepEqual(
    infer(snap({ w: "working", sub: { status: "idle", turn: 1 } }), snap({ w: "working", sub: { status: "working", turn: 2 } })),
    [{ from: "t2", to: "t3", kind: "prompt" }]);
  assert.deepEqual(
    infer(snap({ w: "working", sub: { status: "working", turn: 2 } }), snap({ w: "working", sub: { status: "idle", turn: 2 } })),
    [{ from: "t3", to: "t2", kind: "report" }]);
});

test("unattached workers produce no signals", () => {
  const solo = (status, turn) => [{ ...term("t9", { tab: "tb2", status }), turn }];
  assert.deepEqual(inferSignals(solo("working", 1), solo("idle", 2), buildOverview(solo("idle", 2), S)), []);
});

test("status given as an object is understood", () => {
  const prev = snap({ w: "working" });
  const cur = snap();
  cur[1].status = { app: "claude-code", state: "idle" };
  assert.deepEqual(infer(prev, cur), [{ from: "t2", to: "t1", kind: "report" }]);
});
