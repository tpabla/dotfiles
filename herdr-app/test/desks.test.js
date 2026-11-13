import { test } from "node:test";
import assert from "node:assert/strict";
import { buildOverview } from "../mods/orchestra/model.js";
import { deskRows, placeDesks, cablePoints, METRICS } from "../mods/orchestra/desks.js";
import { space, term } from "./fixtures.js";

function office() {
  return buildOverview([
    term("t1", { tab: "tb1", labels: { "orch.role": "orchestrator" } }),
    term("t2", { tab: "tb2", parent: "t1", status: "working" }),
    term("t3", { tab: "tb3", parent: "t1", status: "blocked" }),
    term("t4", { parent: "t2", name: "reviewer", status: "working" }),
    term("t5", { parent: "t2", name: "tester", status: "idle" }),
    term("t6", { tab: "tb4", parent: "t1", status: "idle" }),
    term("t7", { tab: "tb5", status: "idle" }),
  ], space([["tb1", "o"], ["tb2", "work: a"], ["tb3", "work: b"], ["tb4", "done: c"], ["tb5", "work: d"]]));
}

const row = (rows, address) => rows.find((r) => r.address === address);

test("empty overview has no desks", () => {
  assert.deepEqual(deskRows(buildOverview([], space([]))), []);
});

test("lead first, then workers by urgency, each followed by its helpers", () => {
  assert.deepEqual(deskRows(office()).map((r) => [r.kind, r.address]), [
    ["lead", "t1"],
    ["worker", "t3"],
    ["worker", "t2"],
    ["helper", "t4"],
    ["helper", "t5"],
    ["worker", "t7"],
    ["worker", "t6"],
  ]);
});

test("scenes follow status: alert, typing, cursor, ok; console for the lead, drones for helpers", () => {
  const rows = deskRows(office());
  assert.equal(row(rows, "t1").scene, "console");
  assert.equal(row(rows, "t3").scene, "alert");
  assert.equal(row(rows, "t2").scene, "typing");
  assert.equal(row(rows, "t7").scene, "cursor");
  assert.equal(row(rows, "t6").scene, "ok");
  assert.equal(row(rows, "t4").scene, "drone-busy");
  assert.equal(row(rows, "t5").scene, "drone-idle");
});

test("cables: workers branch off the lead's trunk and the last one ends it (a lone lead adopts every worker)", () => {
  const rows = deskRows(office());
  assert.equal(row(rows, "t3").cable, "mid");
  assert.equal(row(rows, "t2").cable, "mid");
  assert.equal(row(rows, "t7").cable, "mid");
  assert.equal(row(rows, "t6").cable, "end");
});

test("without a lead, workers have no cable", () => {
  const rows = deskRows(buildOverview([term("t2", { tab: "tb2", status: "working" })], space([["tb2", "work: a"]])));
  assert.equal(rows[0].cable, null);
});

test("helpers branch off their worker; the lead's trunk keeps running past them when more workers follow", () => {
  const rows = deskRows(office());
  assert.equal(row(rows, "t4").cable, "mid");
  assert.equal(row(rows, "t5").cable, "end");
  assert.equal(row(rows, "t4").trunk, true);
  assert.equal(row(rows, "t5").trunk, true);
});

test("a filter keeps matching workers and their helpers, without the lead", () => {
  assert.deepEqual(deskRows(office(), "work: a").map((r) => r.address), ["t2", "t4", "t5"]);
});

test("placeDesks stacks rows with heights by kind", () => {
  const placed = placeDesks(deskRows(office()));
  let y = 0;
  for (const r of placed) {
    assert.equal(r.y, y, r.address);
    assert.equal(r.h, METRICS[r.kind]);
    y += r.h + METRICS.gap;
  }
});

test("cablePoints: lead to worker runs down the trunk and into the booth", () => {
  const placed = placeDesks(deskRows(office()));
  const lead = row(placed, "t1");
  const w = row(placed, "t2");
  const points = cablePoints(placed, "t1", "t2");
  const cy = w.y + w.h / 2;
  assert.deepEqual(points, [[METRICS.trunkX, lead.y + lead.h], [METRICS.trunkX, cy], [METRICS.boothX, cy]]);
});

test("cablePoints: worker to helper uses the helper lane; reversed for reports", () => {
  const placed = placeDesks(deskRows(office()));
  const w = row(placed, "t2");
  const h = row(placed, "t5");
  const cy = h.y + h.h / 2;
  const down = cablePoints(placed, "t2", "t5");
  assert.deepEqual(down, [[METRICS.helperTrunkX, w.y + w.h], [METRICS.helperTrunkX, cy], [METRICS.helperBoothX, cy]]);
  assert.deepEqual(cablePoints(placed, "t5", "t2"), [...down].reverse());
});

test("cablePoints: unconnected or unknown pairs have no route", () => {
  const placed = placeDesks(deskRows(office()));
  assert.equal(cablePoints(placed, "t3", "t2"), null);
  assert.equal(cablePoints(placed, "t1", "nope"), null);
});
