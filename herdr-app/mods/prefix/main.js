import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { closeOverlay, exec, focused, nextCommand, openOverlay, props, run, setShared, shared } from "herdr";

// tmux-style prefix: ctrl-b arms it, the next key runs a command.
const PREFIX = "ctrl+b";
const OPEN = "prefix.open";
const TIMEOUT_MS = 3000;

const split = (direction) => ["pane.split", { direction }];
const go = (direction) => ["pane.go", { direction }];

const BINDINGS = {
  c: ["tab.new"],
  n: ["tab.next"],
  p: ["tab.prev"],
  ",": ["tab.rename"],
  T: ["tab.rename"],
  "&": ["tab.close"],
  X: ["tab.close"],
  '"': split("down"),
  "%": split("right"),
  h: go("left"),
  j: go("down"),
  k: go("up"),
  l: go("right"),
  left: go("left"),
  down: go("down"),
  up: go("up"),
  right: go("right"),
  J: ["pane.swap", { direction: "down" }],
  K: ["pane.swap", { direction: "up" }],
  enter: ["pane.swap", { direction: "left" }],
  x: ["pane.close"],
  z: ["pane.zoom"],
  b: ["layout.toggle", { id: "sidebar" }],
  w: ["mod.open", { name: "picker" }],
  s: ["mod.open", { name: "picker" }],
  N: ["space.new"],
  $: ["space.rename"],
  "(": ["space.prev"],
  ")": ["space.next"],
  "?": ["app.help"],
};
for (let i = 1; i <= 9; i++) BINDINGS[String(i)] = ["tab.select", { index: i }];

const NAMED = new Set(["enter", "escape", "left", "right", "up", "down"]);
const MODIFIERS = new Set(["shift", "control", "ctrl", "alt", "cmd", "platform", "function", "fn"]);

function keyOf(e) {
  if (NAMED.has(e.key)) return e.key;
  if (e.modifiers.control || e.modifiers.platform) return e.keystroke;
  return e.key_char ?? e.key;
}

async function sendPrefix(terminal) {
  if (terminal) await exec("hc", ["keys", terminal, PREFIX]);
}

export default class Prefix extends View {
  init(_props, cx) {
    if (props()?.overlay) return this.initOverlay(cx);
    setShared(OPEN, null);
    cx.spawn(async (cx) => {
      for (;;) {
        if ((await nextCommand()) === "arm") await this.arm();
        cx.notify();
      }
    });
  }

  // A second ctrl-b can reach here instead of the overlay when the global binding wins.
  async arm() {
    const open = shared(OPEN);
    if (open) {
      closeOverlay(open.id);
      setShared(OPEN, null);
      return sendPrefix(open.terminal);
    }
    const terminal = focused()?.terminal ?? null;
    const id = openOverlay({
      mod: "prefix",
      kind: "window",
      frame: "none",
      width: 84,
      height: 26,
      at: { x: 12, y: 8 },
      props: { terminal },
    });
    setShared(OPEN, { id, terminal });
  }

  initOverlay(cx) {
    this.handle = cx.focus_handle();
    this.handle.focus();
    const id = props().overlay;
    cx.spawn(async (cx) => {
      await cx.sleep(TIMEOUT_MS);
      if (shared(OPEN)?.id === id) this.close();
    });
  }

  close() {
    setShared(OPEN, null);
    closeOverlay(props().overlay);
  }

  async onKey(e, cx) {
    cx.stop_propagation();
    if (MODIFIERS.has(e.key)) return;
    const key = keyOf(e);
    const { terminal } = props();
    this.close();
    if (terminal) run("pane.focus", { terminal });
    if (key === "ctrl-b") return sendPrefix(terminal);
    const binding = BINDINGS[key];
    if (binding) run(binding[0], binding[1] ?? {});
  }

  render() {
    if (!props()?.overlay) return div();
    return h_flex()
      .id("prefix")
      .track_focus(this.handle)
      .on_key_down((e, cx) => this.onKey(e, cx))
      .size_full()
      .items_center()
      .justify_center()
      .rounded(6)
      .bg("#f26bff")
      .text_color("#11111b")
      .text_size(12)
      .font_semibold()
      .child("PREFIX");
  }
}
