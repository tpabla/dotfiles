// Night shift: the shown space's agents as a control room, docked on the right of main-vim-nav (cmd-shift-o).
// The lead's console on top, a neon cable down to each worker's booth, helper drones under their worker.
// A booth's screen shows its state; inferred prompts and reports run along the cables as packets.
// Every colour comes from the herdr theme. Enter or a click goes to the agent's pane.

import { View, div, PathBuilder, Background } from "gpui-kit";
import { v_flex, h_flex, ScrollHandle, InputState, Input } from "gpui-base";
import { focused, spaces, terminals, panes, run, exec, nextCommand, notify, layout, shared, setShared, theme } from "herdr";
import { buildOverview } from "./model.js";
import { deskRows, placeDesks, cablePoints, METRICS } from "./desks.js";
import { inferSignals } from "./signals.js";
import { INITIAL, handleKey, tokenOf } from "./keymap.js";

const PANEL = "orchestra-panel";
const WATCH_MS = 700;
const SEGMENT_MS = 380;
const HINT = "j k move   enter go to agent   ]n needs you   K peek   s send   / filter   m maximize   ? keys";
const KEYS_HELP = [
  ["j k  gg G  ctrl-d ctrl-u", "move"],
  ["]n  [n", "next or previous agent that needs you"],
  ["enter  o  click", "go to the agent's pane"],
  ["K  p", "peek at the agent"],
  ["s", "send it a prompt"],
  ["/  esc", "filter, clear"],
  ["m", "maximize the panel"],
  ["ctrl-h j k l", "move to the next pane"],
];
const SPINNER = ["◐", "◓", "◑", "◒"];
const CODE = [["▬▬ ▬▬▬", "▬▬▬ ▬", "▬ ▬▬▬▬", "▬▬▬▬ ▬"], ["▬▬▬ ▬", "▬ ▬▬", "▬▬▬▬▬", "▬▬ ▬"], ["▬ ▬▬", "▬▬▬▬", "▬▬ ▬▬", "▬▬▬"]];

export default class Orchestra extends View {
  init(_props, cx) {
    this.keys = INITIAL;
    this.selectedAddress = null;
    this.filter = "";
    this.mode = null;
    this.help = false;
    this.packets = [];
    this.flash = new Map();
    this.previous = null;
    this.nextPacket = 0;
    this.handle = cx.focus_handle();
    this.scroll = ScrollHandle.new();
    this.input = InputState.new({});
    this.input.on("change", (_e, cx) => this.onInputChange(cx));
    this.input.on("submit", (_e, cx) => this.onInputSubmit(cx));

    cx.spawn(async (cx) => {
      for (;;) {
        const command = await nextCommand();
        if (command === "focus") this.handle.focus();
        cx.notify();
      }
    });
    cx.timer.every(WATCH_MS, (cx) => this.watch(cx));
  }

  // ---- data

  space() {
    const id = focused()?.space;
    return spaces().find((s) => s.id === id) ?? null;
  }

  overview() {
    const space = this.space();
    return space ? buildOverview(terminals(), space) : null;
  }

  watch(cx) {
    const space = this.space();
    if (!space) return;
    const current = terminals().map((t) => ({ address: t.address, status: t.status, turn: t.turn, parent: t.parent, labels: t.labels, name: t.name, state: t.state, report: t.report }));
    const overview = buildOverview(current, space);
    const signals = this.previous?.space === space.id ? inferSignals(this.previous.terminals, current, overview) : [];
    this.previous = { space: space.id, terminals: current };
    if (!signals.length || !this.placed) return;
    for (const s of signals) this.launch(s, cx);
    cx.notify();
  }

  launch(signal, cx) {
    const points = cablePoints(this.placed, signal.from, signal.to);
    this.flash.set(signal.to, signal.kind);
    cx.timer.after(2200, (cx) => { this.flash.delete(signal.to); cx.notify(); });
    if (!points) return;
    const packet = { id: this.nextPacket++, points, step: 0, kind: signal.kind };
    this.packets.push(packet);
    const advance = (cx) => {
      packet.step++;
      if (packet.step < points.length) cx.timer.after(SEGMENT_MS, advance);
      else this.packets = this.packets.filter((p) => p !== packet);
      cx.notify();
    };
    cx.timer.after(30, advance);
  }

  // ---- keys and actions

  onKey(event, cx) {
    if (this.mode) {
      if (event.key === "escape") this.closeMode(cx, this.mode.type === "filter");
      return;
    }
    const key = tokenOf(event);
    if (!key) return;
    const rows = this.rows();
    const { state, action } = handleKey({ ...this.keys, selected: this.selectedIndex(rows) }, key, rows);
    this.keys = state;
    this.selectedAddress = rows[state.selected]?.address ?? null;
    if (action) this.perform(action, cx);
    cx.stop_propagation();
    cx.notify();
  }

  rows() {
    const overview = this.overview();
    return overview ? deskRows(overview, this.filter).map((r) => ({ ...r, bucket: r.bucket })) : [];
  }

  selectedIndex(rows) {
    const i = rows.findIndex((r) => r.address === this.selectedAddress);
    return i >= 0 ? i : Math.min(this.keys.selected, Math.max(rows.length - 1, 0));
  }

  perform(action, cx) {
    switch (action.type) {
      case "focus":
        if (panes().some((p) => p.terminal === action.address)) run("pane.focus", { terminal: action.address });
        else run("terminal.peek", { terminal: action.address });
        break;
      case "peek":
        run("terminal.peek", { terminal: action.address });
        break;
      case "send":
        this.openMode({ type: "send", address: action.address }, "");
        break;
      case "filter":
        this.openMode({ type: "filter" }, this.filter);
        break;
      case "clear":
        this.filter = "";
        break;
      case "maximize":
        toggleMaximize();
        break;
      case "legend":
        this.help = !this.help;
        break;
      case "leave":
        run("pane.go", { direction: action.direction });
        break;
    }
  }

  openMode(mode, value) {
    this.mode = mode;
    this.input.set_value(value);
    this.input.focus();
  }

  closeMode(cx, clearFilter) {
    if (clearFilter) this.filter = "";
    this.mode = null;
    this.handle.focus();
    cx.notify();
  }

  onInputChange(cx) {
    if (this.mode?.type === "filter") this.filter = this.input.value();
    cx.notify();
  }

  onInputSubmit(cx) {
    const mode = this.mode;
    const text = this.input.value().trim();
    this.closeMode(cx, false);
    if (mode?.type !== "send" || !text) return;
    cx.spawn(async (cx) => {
      const r = await exec("hc", ["send", mode.address, text]);
      if (r.code !== 0) notify({ title: "Couldn't send the prompt", body: r.stderr.trim() || r.stdout.trim(), level: "error" });
      cx.notify();
    });
  }

  // ---- render

  render() {
    const t = theme();
    const overview = this.overview();
    const root = v_flex().id("orchestra").track_focus(this.handle).on_key_down((e, cx) => this.onKey(e, cx))
      .size_full().overflow_hidden().bg(t.background).text_color(t.foreground).text_size(13)
      .on_size_change((size, cx) => { this.size = size; cx.notify(); });
    if (!overview) return root.child(div().p(20).text_color(t.muted).child("No space is shown."));

    const rows = deskRows(overview, this.filter);
    this.placed = placeDesks(rows);
    const selected = rows[this.selectedIndex(rows)]?.address ?? null;
    const terms = new Map(terminals().map((x) => [x.address, x]));

    return root
      .child(header(overview, t))
      .child(neonRule(t))
      .child(v_flex().id("room-scroll").flex_1().min_h(0).overflow_y_scrollbar().track_scroll(this.scroll)
        .child(this.room(overview, this.placed, selected, terms, t)))
      .when(this.help, (el) => el.child(keysHelp(t)))
      .child(this.footer(t));
  }

  room(overview, placed, selected, terms, t) {
    const width = this.size?.width ?? 460;
    const height = placed.length ? placed.at(-1).y + placed.at(-1).h + 16 : 120;
    const box = div().id("room").relative().w_full().h(height).px(0).pt(12);
    if (!placed.length) {
      return box.child(v_flex().px(18).gap(6)
        .child(div().text_size(14).font_semibold().child(this.filter ? "Nothing matches the filter" : "The room is empty"))
        .child(div().text_color(t.muted).child(this.filter ? "Press esc to clear it." : "Start an orchestrator in this space. Its workers take a booth as they start.")));
    }
    const workers = new Map(overview.workers.map((w) => [w.address, w]));
    const helpers = new Map(overview.workers.flatMap((w) => w.children.map((c) => [c.address, c])));
    const leads = new Map(overview.orchestrators.map((o) => [o.address, o]));
    const names = new Map([...overview.workers.map((w) => [w.address, w.name])]);

    return box
      .child(cables(placed, width, height, t))
      .child(v_flex().gap(METRICS.gap).children(placed.map((r) => {
        const isSelected = r.address === selected;
        const click = (_e, cx) => { this.selectedAddress = r.address; this.handle.focus(); this.perform({ type: "focus", address: r.address }, cx); cx.notify(); };
        const flash = this.flash.get(r.address);
        const line = r.kind === "lead" ? leadRow(r, leads.get(r.address), t)
          : r.kind === "worker" ? workerRow(r, workers.get(r.address), terms.get(r.address), names, t)
          : helperRow(r, helpers.get(r.address), t);
        return line.id(`row-${r.address}`).relative().cursor_pointer().on_click(click)
          .hover((s) => s.bg(t.hover))
          .when(isSelected, (el) => el.bg(t.selected))
          .when(Boolean(flash), (el) => el.child(div().absolute().left(0).top(0).size_full().rounded(6)
            .bg(alpha(t.accent, "26")).loop("opacity", { from: 0, to: 1, period: 500 })))
          .when(isSelected, (el) => el.child(div().absolute().left(0).top(6).bottom(6).w(2).rounded(1).bg(t.accent)));
      })))
      .children(this.packets.map((p) => packetDot(p, t)));
  }

  footer(t) {
    const bar = h_flex().flex_shrink_0().items_center().gap(10).px(16).py(8).border_t_1().border_color(t.border).text_size(11.5);
    if (!this.mode) return bar.child(div().truncate().text_color(t.dim).child(HINT));
    const label = this.mode.type === "send" ? `Send to ${this.mode.address}` : "Filter";
    return bar.child(div().flex_shrink_0().text_color(t.accent).child(label))
      .child(Input.new(this.input).flex_1().h(26).px(8).rounded(4).border_1().border_color(t.accent).bg(t.surface).text_color(t.foreground));
  }
}

// ---- pieces

function bucketColor(bucket, t) {
  return { needsYou: t.blocked, working: t.working, waiting: t.idle, done: t.done }[bucket] ?? t.muted;
}

function alpha(color, hex) {
  return typeof color === "string" && color.length === 7 ? `${color}${hex}` : color;
}

const RECT = () => PathBuilder.fill().move_to("0%", "0%").line_to("100%", "0%").line_to("100%", "100%").line_to("0%", "100%").close().build();

function gradient(from, to, angle) {
  return window.paint_path(RECT(), Background.linear_gradient(angle, from, to)).absolute().top(0).left(0).size_full();
}

function header(overview, t) {
  const c = overview.counts;
  const parts = [
    ["needsYou", c.needsYou, `${c.needsYou} need${c.needsYou === 1 ? "s" : ""} you`],
    ["working", c.working, `${c.working} working`],
    ["waiting", c.waiting, `${c.waiting} waiting`],
    ["done", c.done, `${c.done} done`],
  ].filter(([, n]) => n);
  return v_flex().flex_shrink_0().px(16).pt(14).pb(10).gap(6)
    .child(div().text_size(19).font_semibold().truncate().child(overview.space.name))
    .child(h_flex().gap(12).flex_wrap().text_size(11.5).children(parts.length ? parts.map(([b, , text]) =>
      h_flex().id(`count-${b}`).gap(5).items_center()
        .child(div().size(7).rounded_full().bg(bucketColor(b, t))
          .when(b === "needsYou", (el) => el.loop("opacity", { from: 0.35, to: 1, period: 1300 })))
        .child(div().text_color(bucketColor(b, t)).child(text))) : [div().text_color(t.muted).child("Nobody on shift")]));
}

function neonRule(t) {
  return div().flex_shrink_0().relative().h(6)
    .child(div().absolute().left(0).right(0).top(2).h(2).child(gradient(t.accent, t.working, 90)))
    .child(div().absolute().left(0).right(0).top(0).h(6).opacity(0.25).child(gradient(t.accent, t.working, 90)));
}

// The trunk from the lead down to each worker and from each worker down to its helpers, drawn twice for a glow.
function cables(placed, width, height, t) {
  const top = 12;
  const segments = [];
  const lead = placed.find((r) => r.kind === "lead");
  const attached = placed.filter((r) => r.kind === "worker" && r.cable);
  if (lead && attached.length) {
    const last = attached.at(-1);
    segments.push([[METRICS.trunkX, lead.y + lead.h], [METRICS.trunkX, last.y + last.h / 2]]);
    for (const w of attached) segments.push([[METRICS.trunkX, w.y + w.h / 2], [METRICS.boothX - 2, w.y + w.h / 2]]);
  }
  for (const w of placed.filter((r) => r.kind === "worker")) {
    const kids = placed.filter((r) => r.kind === "helper" && r.parent === w.address);
    if (!kids.length) continue;
    const last = kids.at(-1);
    segments.push([[METRICS.helperTrunkX, w.y + w.h], [METRICS.helperTrunkX, last.y + last.h / 2]]);
    for (const k of kids) segments.push([[METRICS.helperTrunkX, k.y + k.h / 2], [METRICS.helperBoothX - 2, k.y + k.h / 2]]);
  }
  if (!segments.length) return div();
  const path = (width) => {
    let p = PathBuilder.stroke(width);
    for (const [[x1, y1], [x2, y2]] of segments) p = p.move_to(x1, y1 + top).line_to(x2, y2 + top);
    return p.build();
  };
  const layer = (w, color) => window.paint_path(path(w), color).absolute().top(0).left(0).w(width).h(height);
  return div().absolute().top(0).left(0).w(width).h(height)
    .child(layer(5, alpha(t.accent, "22")))
    .child(layer(1.5, alpha(t.accent, "b3")));
}

function packetDot(p, t) {
  const [x, y] = p.points[Math.min(p.step, p.points.length - 1)];
  const color = { prompt: t.working, report: t.accent, spawn: t.done }[p.kind];
  const move = (el) => el.transition("left", { duration: SEGMENT_MS - 30, easing: "linear" }).transition("top", { duration: SEGMENT_MS - 30, easing: "linear" });
  return move(div().id(`packet-${p.id}`).absolute().left(x - 8).top(y + 12 - 8).size(16))
    .child(div().absolute().left(0).top(0).size(16).rounded_full().bg(alpha(color, "40")))
    .child(div().absolute().left(4).top(4).size(8).rounded(2).bg(color));
}

// ---- rows

function leadRow(r, o, t) {
  const working = o?.status === "working";
  const status = working ? (o.activity ?? "Working") : capitalize(o?.status ?? "idle");
  return h_flex().h(r.h).mx(8).px(4).gap(10).items_center().rounded(8).border_1().border_color(alpha(t.accent, "66")).bg(t.surface)
    .child(consoleScene(working, t))
    .child(v_flex().flex_1().min_w(0)
      .child(h_flex().gap(8).items_center()
        .child(div().font_semibold().text_size(14).truncate().child(o?.name ?? r.address))
        .child(div().flex_shrink_0().px(5).rounded(3).bg(alpha(t.accent, "26")).text_size(10.5).text_color(t.accent).child("Lead")))
      .child(div().truncate().text_size(11.5).text_color(working ? t.working : t.muted).child(status)));
}

function workerRow(r, w, term, names, t) {
  const color = bucketColor(r.bucket, t);
  const word = r.bucket === "needsYou" ? (w.state === "blocked" ? "Blocked" : "Needs you") : { working: "Working", waiting: "Waiting", done: "Done" }[r.bucket];
  const waits = w.dependsOn.map((a) => names.get(a)).filter(Boolean);
  const detail = w.status === "working" && w.activity ? w.activity
    : waits.length && r.bucket !== "done" ? `waits on ${waits.join(", ")}`
    : (w.summary && w.summary !== w.name ? w.summary : "");
  const waited = r.bucket === "needsYou" ? since(term?.status_ms) : null;
  return h_flex().h(r.h).ml(METRICS.boothX - 4).mr(8).pl(4).pr(8).gap(10).items_center().rounded(6)
    .child(booth(r.scene, color, t))
    .child(v_flex().flex_1().min_w(0)
      .child(h_flex().gap(8).items_center()
        .child(div().flex_1().min_w(0).font_semibold().truncate().child(w.name))
        .when(Boolean(w.pr), (el) => el.child(div().flex_shrink_0().px(5).rounded(3).bg(alpha(color, "22")).text_size(10.5).text_color(color).child(`#${w.pr}`)))
        .when(Boolean(waited), (el) => el.child(div().flex_shrink_0().text_size(11).text_color(color).child(waited))))
      .child(h_flex().gap(6).min_w(0).text_size(11.5)
        .child(div().flex_shrink_0().text_color(color).child(word))
        .child(div().flex_1().min_w(0).truncate().text_color(w.status === "working" ? t.working : t.muted).child(detail))));
}

function helperRow(r, h, t) {
  const busy = h?.status === "working";
  return h_flex().h(r.h).ml(METRICS.helperBoothX - 4).mr(8).pl(4).pr(8).gap(8).items_center().rounded(6)
    .child(drone(busy, t))
    .child(div().flex_1().min_w(0).truncate().text_size(12).child(h?.name ?? r.address))
    .child(div().flex_shrink_0().text_size(11).text_color(busy ? t.working : t.dim).child(busy ? "helping" : (h?.status ?? "")));
}

// ---- scenes

// A small CRT on a stand; its screen shows what the agent is doing.
function booth(scene, color, t) {
  const screen = div().relative().w(46).h(32).rounded(5).border_1().border_color(color).bg(alpha(color, "14")).overflow_hidden()
    .child(scanlines(46, 32, color));
  let content;
  if (scene === "typing") {
    content = v_flex().absolute().left(6).top(5).gap(1).children(CODE.map((frames, i) =>
      div().text_size(6.5).text_color(color).opacity(0.85 - i * 0.2).frames(frames, 260 + i * 70)));
  } else if (scene === "alert") {
    content = div().absolute().left(0).top(0).size_full().flex().items_center().justify_center()
      .child(div().text_size(18).font_bold().text_color(color).loop("opacity", { from: 0.3, to: 1, period: 900 }).child("!"));
  } else if (scene === "cursor") {
    content = div().absolute().left(7).top(9).text_size(12).text_color(color).frames(["_", " "], 530);
  } else {
    content = div().absolute().left(0).top(0).size_full().flex().items_center().justify_center()
      .child(div().text_size(11).font_bold().text_color(color).child("OK"));
  }
  const unit = v_flex().items_center().flex_shrink_0()
    .child(screen.child(content))
    .child(div().w(12).h(3).mt(1).rounded(1).bg(alpha(color, "80")));
  if (scene !== "alert") return unit;
  return div().relative().flex_shrink_0()
    .child(div().absolute().left(-3).top(-3).w(52).h(38).rounded(7).border_2().border_color(color)
      .loop("opacity", { from: 0.05, to: 0.7, period: 1300 }))
    .child(unit);
}

// Three screens; they flicker while the lead works.
function consoleScene(working, t) {
  const screen = (i) => div().w(16).h(22).rounded(3).border_1().border_color(t.accent).bg(alpha(t.accent, working ? "26" : "10"))
    .flex().items_center().justify_center().text_size(8).text_color(t.accent)
    .when(working, (el) => el.frames(["▪", "▪▪", " ▪", "▪ ▪"].map((_, k, a) => a[(k + i) % a.length]), 220 + i * 60))
    .when(!working, (el) => el.child("▪"));
  return h_flex().flex_shrink_0().gap(3).px(6).child(screen(0)).child(screen(1)).child(screen(2));
}

function drone(busy, t) {
  const color = busy ? t.working : t.dim;
  const body = div().text_size(13).text_color(color).child("◈");
  return v_flex().w(18).items_center().flex_shrink_0()
    .child(busy ? body.loop("top", { from: -2, to: 1, period: 900 }) : body)
    .child(div().w(8).h(1).rounded(1).bg(alpha(color, "66")));
}

function scanlines(width, height, color) {
  let p = PathBuilder.stroke(1);
  for (let y = 2; y < height; y += 3) p = p.move_to(0, y).line_to(width, y);
  return window.paint_path(p.build(), alpha(color, "12")).absolute().top(0).left(0).w(width).h(height);
}

function keysHelp(t) {
  return v_flex().flex_shrink_0().gap(4).px(16).py(10).border_t_1().border_color(t.border).text_size(11.5)
    .children(KEYS_HELP.map(([keys, what]) => h_flex().gap(10)
      .child(div().w(150).flex_shrink_0().text_color(t.accent).child(keys))
      .child(div().text_color(t.muted).child(what))));
}

// ---- helpers

function since(ms) {
  if (!ms) return null;
  const minutes = Math.max(0, Math.round((Date.now() - ms) / 60000));
  return minutes < 60 ? `${minutes}m` : `${Math.round(minutes / 60)}h`;
}

function capitalize(s) {
  return s ? s[0].toUpperCase() + s.slice(1) : s;
}

function toggleMaximize() {
  const node = find(layout(), PANEL);
  if (shared("orchestra.maximized")) {
    run("layout.resize", { id: PANEL, px: shared("orchestra.width") ?? 460 });
    setShared("orchestra.maximized", false);
  } else {
    setShared("orchestra.width", node?.size?.px ?? 460);
    run("layout.resize", { id: PANEL, weight: 4 });
    setShared("orchestra.maximized", true);
  }
}

function find(node, id) {
  if (node?.id === id) return node;
  for (const child of node?.children ?? []) {
    const found = find(child, id);
    if (found) return found;
  }
  return null;
}
