import { test } from "node:test";
import assert from "node:assert/strict";
import { handleKey, tokenOf, INITIAL } from "../mods/orchestra/keymap.js";

const ROWS = [
  { kind: "orchestrator", address: "t1" },
  { kind: "worker", address: "t2", bucket: "needsYou" },
  { kind: "worker", address: "t3", bucket: "working" },
  { kind: "sub", address: "t4" },
  { kind: "worker", address: "t5", bucket: "needsYou" },
  { kind: "worker", address: "t6", bucket: "done" },
];

const press = (keys, state = INITIAL, rows = ROWS) => {
  let action = null;
  for (const k of keys) ({ state, action } = handleKey(state, k, rows));
  return { state, action };
};

test("tokenOf: typed characters, ctrl chords and named keys", () => {
  assert.equal(tokenOf({ key: "g", keystroke: "shift-g", key_char: "G", modifiers: { shift: true } }), "G");
  assert.equal(tokenOf({ key: "d", keystroke: "ctrl-d", key_char: "d", modifiers: { control: true } }), "ctrl-d");
  assert.equal(tokenOf({ key: "enter", keystroke: "enter", modifiers: {} }), "enter");
  assert.equal(tokenOf({ key: "]", keystroke: "]", key_char: "]", modifiers: {} }), "]");
  assert.equal(tokenOf({ key: "enter", keystroke: "enter", key_char: "\r", modifiers: {} }), "enter");
  assert.equal(tokenOf({ key: "escape", keystroke: "escape", key_char: "\u001b", modifiers: {} }), "escape");
  assert.equal(tokenOf({ key: "/", keystroke: "shift-/", key_char: "?", modifiers: { shift: true } }), "?");
  assert.equal(tokenOf({ key: "k", keystroke: "cmd-k", key_char: "k", modifiers: { platform: true } }), null);
});

test("j/k and arrows move and stop at the ends", () => {
  assert.equal(press(["j", "j"]).state.selected, 2);
  assert.equal(press(["down", "up", "k", "k"]).state.selected, 0);
  assert.equal(press(Array(20).fill("j")).state.selected, 5);
});

test("gg goes to the top, G to the bottom, a lone g waits", () => {
  assert.equal(press(["G"]).state.selected, 5);
  assert.equal(press(["G", "g"]).state.selected, 5);
  assert.equal(press(["G", "g"]).state.pending, "g");
  assert.equal(press(["G", "g", "g"]).state.selected, 0);
  assert.equal(press(["G", "g", "x"]).state.pending, null);
});

test("ctrl-d / ctrl-u move half a page", () => {
  assert.equal(press(["ctrl-d"], INITIAL, Array(30).fill(ROWS[1])).state.selected, 10);
  assert.equal(press(["G", "ctrl-u"], INITIAL, Array(30).fill(ROWS[1])).state.selected, 19);
});

test("]n / [n jump between rows that need you, wrapping", () => {
  assert.equal(press(["]", "n"]).state.selected, 1);
  assert.equal(press(["]", "n", "]", "n"]).state.selected, 4);
  assert.equal(press(["]", "n", "]", "n", "]", "n"]).state.selected, 1);
  assert.equal(press(["[", "n"]).state.selected, 4);
});

test("]n with nothing needing you stays put", () => {
  const rows = ROWS.filter((r) => r.bucket !== "needsYou");
  assert.equal(press(["j", "]", "n"], INITIAL, rows).state.selected, 1);
});

test("actions carry the selected row's address", () => {
  assert.deepEqual(press(["j", "enter"]).action, { type: "focus", address: "t2" });
  assert.deepEqual(press(["j", "o"]).action, { type: "focus", address: "t2" });
  assert.deepEqual(press(["j", "j", "K"]).action, { type: "peek", address: "t3" });
  assert.deepEqual(press(["j", "j", "j", "p"]).action, { type: "peek", address: "t4" });
  assert.deepEqual(press(["j", "s"]).action, { type: "send", address: "t2" });
  assert.deepEqual(press(["/"]).action, { type: "filter" });
  assert.deepEqual(press(["m"]).action, { type: "maximize" });
  assert.equal(press(["q"]).action, null);
  assert.deepEqual(press(["?"]).action, { type: "legend" });
});

test("ctrl-h/j/k/l leave the pane in that direction", () => {
  assert.deepEqual(press(["ctrl-h"]).action, { type: "leave", direction: "left" });
  assert.deepEqual(press(["ctrl-l"]).action, { type: "leave", direction: "right" });
  assert.deepEqual(press(["ctrl-j"]).action, { type: "leave", direction: "down" });
});

test("escape clears a pending key and asks to clear the filter", () => {
  const { state, action } = press(["g", "escape"]);
  assert.equal(state.pending, null);
  assert.deepEqual(action, { type: "clear" });
});

test("no rows: movement is harmless and row actions do nothing", () => {
  const { state, action } = press(["j", "G", "enter"], INITIAL, []);
  assert.equal(state.selected, 0);
  assert.equal(action, null);
});

test("selection is clamped when the list shrinks", () => {
  const { state } = press(["k"], { selected: 9, pending: null }, ROWS);
  assert.equal(state.selected, 4);
});
