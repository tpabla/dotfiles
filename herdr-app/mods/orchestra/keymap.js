// Pure: vim-style keys over the overview's rows. (state, key, rows) -> { state, action }; main.js performs actions.

export const INITIAL = { selected: 0, pending: null };

const HALF_PAGE = 10;
const LEAVE = { "ctrl-h": "left", "ctrl-j": "down", "ctrl-k": "up", "ctrl-l": "right" };
const ROW_ACTIONS = { enter: "focus", o: "focus", K: "peek", p: "peek", s: "send" };
const ACTIONS = { "/": "filter", r: "refresh", m: "maximize", "?": "legend", escape: "clear" };

/** A KeyEvent as one token: "j", "G", "]", "ctrl-d", "enter"; null for cmd/alt chords (left to the app). */
export function tokenOf(event) {
  const m = event.modifiers ?? {};
  if (m.platform || m.alt) return null;
  if (m.control) return `ctrl-${event.key}`;
  // Named keys (enter, escape, up) type control characters; use the name for those.
  if (event.key.length > 1) return event.key;
  return event.key_char && event.key_char.length === 1 ? event.key_char : event.key;
}

/**
 * @param {{selected: number, pending: string|null}} state
 * @param {string|null} key  from tokenOf
 * @param {{kind: string, address: string, bucket?: string}[]} rows
 */
export function handleKey(state, key, rows) {
  const last = Math.max(rows.length - 1, 0);
  const at = (i) => ({ selected: Math.min(Math.max(i, 0), last), pending: null });
  const current = at(state.selected).selected;
  const done = (next, action = null) => ({ state: next, action });

  if (state.pending === "g" && key === "g") return done(at(0));
  if ((state.pending === "]" || state.pending === "[") && key === "n") {
    return done(at(nextNeedingYou(rows, current, state.pending === "]" ? 1 : -1)));
  }
  if (key === "g" || key === "]" || key === "[") return done({ selected: current, pending: key });

  const here = at(current);
  if (key === "j" || key === "down") return done(at(current + 1));
  if (key === "k" || key === "up") return done(at(current - 1));
  if (key === "G") return done(at(last));
  if (key === "ctrl-d") return done(at(current + HALF_PAGE));
  if (key === "ctrl-u") return done(at(current - HALF_PAGE));
  if (key in LEAVE) return done(here, { type: "leave", direction: LEAVE[key] });
  if (key in ACTIONS) return done(here, { type: ACTIONS[key] });
  if (key in ROW_ACTIONS) {
    return done(here, rows.length ? { type: ROW_ACTIONS[key], address: rows[current].address } : null);
  }
  return done(here);
}

function nextNeedingYou(rows, from, step) {
  for (let i = 1; i <= rows.length; i++) {
    const index = (((from + step * i) % rows.length) + rows.length) % rows.length;
    if (rows[index].bucket === "needsYou") return index;
  }
  return from;
}
