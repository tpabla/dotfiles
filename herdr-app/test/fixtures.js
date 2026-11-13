// Builders shaped like herdr's terminals() and spaces() entries.

export const SPACE = "sp1";

export function space(tabs, extra = {}) {
  return {
    id: SPACE,
    name: "platform-api",
    machine: null,
    tabs: tabs.map(([id, name], i) => ({ id, name, index: i + 1 })),
    ...extra,
  };
}

export function term(address, { status = "idle", state = "live", tab, parent = null, name = null, labels = {}, msg, spaceId = SPACE } = {}) {
  return {
    address,
    name,
    state,
    parent,
    status,
    report: msg ? { msg } : null,
    labels: { "herdr.space": spaceId, ...(tab ? { "herdr.tab": tab } : {}), ...labels },
  };
}
