(() => {
  const meta = (() => {
    const node = document.getElementById("explain-meta");
    try { return node ? JSON.parse(node.textContent) : null; } catch { return null; }
  })();
  if (meta && !document.body.dataset.type) document.body.dataset.type = meta.doc_type;

  const style = getComputedStyle(document.body);
  const v = (name) => style.getPropertyValue(name).trim();
  const hue = v("--hue");
  const ink = { night: v("--night"), panel: v("--night-2"), rule: v("--rule"), text: v("--text"), muted: v("--muted") };
  const pastels = ["--pink", "--sky", "--mint", "--lemon", "--lavender", "--peach"].map(v);
  // The doc's own hue leads; the rest of the rainbow follows for extra series.
  const palette = [hue, ...pastels.filter((c) => c.toLowerCase() !== hue.toLowerCase())];
  const fontBody = '"Atkinson Hyperlegible Next", system-ui, sans-serif';

  const el = (tag, attrs = {}, ...children) => {
    const node = document.createElement(tag);
    for (const [k, val] of Object.entries(attrs)) node.setAttribute(k, val);
    node.append(...children);
    return node;
  };
  const slugify = (text) => text.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
  const formatDate = (iso) =>
    iso ? new Date(iso).toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" }) : "";

  function renderSiteBar() {
    if (!meta || !document.body.classList.contains("doc")) return;
    const sep = () => el("span", { class: "sep", "aria-hidden": "true" }, "/");
    const crumbs = el("nav", { class: "crumbs", "aria-label": "Breadcrumb" },
      el("a", { href: "/docs/" }, "docs"), sep(),
      el("a", { href: `/docs/${meta.project}/` }, meta.project), sep(),
      el("a", { href: `/docs/${meta.project}/${meta.doc_type}/` }, meta.doc_type));
    const info = el("div", { class: "bar-meta" },
      el("time", { datetime: meta.updated || meta.created }, `Updated ${formatDate(meta.updated || meta.created)}`));
    if (meta.status === "archived") info.append(el("span", { class: "badge badge-archived" }, "Archived"));
    document.body.prepend(el("header", { class: "site-bar" }, crumbs, info));

    const hero = document.querySelector(".hero-inner");
    if (!hero) return;
    if (meta.tags?.length) hero.append(el("div", { class: "tags" }, ...meta.tags.map((t) => el("span", { class: "tag" }, t))));
    if (meta.status === "archived") {
      hero.append(el("p", { class: "archived-banner", role: "note" }, "This doc is archived. It's kept for reference and may be out of date."));
    }
  }

  function renderDeckHome() {
    if (!meta || !document.body.classList.contains("deck")) return;
    document.body.append(el("a", { class: "deck-home", href: `/docs/${meta.project}/` }, `docs / ${meta.project}`));
  }

  function renderToc() {
    const main = document.querySelector("body.doc main");
    if (!main) return;
    const headings = [...main.querySelectorAll("h2")];
    headings.forEach((h) => { if (!h.id) h.id = slugify(h.textContent); });
    if (headings.length < 3) return;

    const links = headings.map((h) => el("a", { href: `#${h.id}` }, h.textContent));
    const toc = el("nav", { class: "toc", "aria-label": "Contents" }, el("ol", {}, ...links.map((a) => el("li", {}, a))));
    const layout = el("div", { class: "doc-layout" });
    main.before(layout);
    layout.append(toc, main);

    const observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        links.forEach((a) => a.classList.toggle("active", a.hash === `#${entry.target.id}`));
      }
    }, { rootMargin: "0px 0px -75% 0px" });
    headings.forEach((h) => observer.observe(h));
  }

  function wrapTables(root) {
    root.querySelectorAll("table").forEach((table) => {
      if (table.parentElement.classList.contains("table-wrap")) return;
      const wrap = el("div", { class: "table-wrap" });
      table.before(wrap);
      wrap.append(table);
    });
  }

  function initMermaid() {
    if (!window.mermaid) return;
    const [pink, sky, mint, lemon, lavender, peach] = pastels;
    mermaid.initialize({
      startOnLoad: false,
      securityLevel: "strict",
      theme: "base",
      fontFamily: fontBody,
      themeVariables: {
        darkMode: true,
        fontFamily: fontBody,
        fontSize: "16px",
        background: ink.panel,
        primaryColor: "#2a2156",
        primaryTextColor: ink.text,
        primaryBorderColor: hue,
        secondaryColor: "#1f2a4a",
        secondaryTextColor: ink.text,
        secondaryBorderColor: sky,
        tertiaryColor: "#1c3534",
        tertiaryTextColor: ink.text,
        tertiaryBorderColor: mint,
        lineColor: hue,
        textColor: ink.text,
        mainBkg: "#2a2156",
        nodeBorder: hue,
        clusterBkg: "rgba(182, 156, 255, 0.05)",
        clusterBorder: ink.rule,
        titleColor: ink.text,
        edgeLabelBackground: ink.panel,
        noteBkgColor: "#3a3420",
        noteTextColor: lemon,
        noteBorderColor: lemon,
        actorBkg: "#2a2156",
        actorBorder: hue,
        actorTextColor: ink.text,
        actorLineColor: ink.rule,
        signalColor: hue,
        signalTextColor: ink.text,
        labelBoxBkgColor: "#2a2156",
        labelBoxBorderColor: hue,
        labelTextColor: ink.text,
        loopTextColor: ink.muted,
        activationBkgColor: "#3a2a5e",
        activationBorderColor: hue,
        sequenceNumberColor: ink.night,
        attributeBackgroundColorOdd: "#1f1a3a",
        attributeBackgroundColorEven: "#262046",
        classText: ink.text,
        git0: pink, git1: sky, git2: mint, git3: lemon, git4: lavender, git5: peach, git6: pink, git7: sky,
        ...Object.fromEntries(palette.flatMap((c, i) => [[`pie${i + 1}`, c], [`pie${i + 7}`, c]])),
        pieStrokeColor: ink.night,
        pieOuterStrokeColor: ink.rule,
        pieTitleTextColor: ink.text,
        pieSectionTextColor: ink.night,
        pieLegendTextColor: ink.text,
        ...Object.fromEntries(Array.from({ length: 12 }, (_, i) => [`cScale${i}`, palette[i % palette.length]])),
        ...Object.fromEntries(Array.from({ length: 12 }, (_, i) => [`cScaleLabel${i}`, ink.night])),
        quadrant1Fill: "rgba(138, 255, 193, 0.12)",
        quadrant2Fill: "rgba(138, 216, 255, 0.12)",
        quadrant3Fill: "rgba(182, 156, 255, 0.12)",
        quadrant4Fill: "rgba(255, 154, 213, 0.12)",
        quadrantPointFill: lemon,
        quadrantTitleFill: ink.text,
      },
    });
  }

  async function renderDiagrams(root = document) {
    if (!window.mermaid) return;
    const nodes = [...root.querySelectorAll("pre.mermaid:not([data-processed])")];
    if (!nodes.length) return;
    await document.fonts.ready;
    await mermaid.run({ nodes, suppressErrors: true });
    nodes.forEach(keepReadable);
  }

  // Wide diagrams scaled to the column become unreadable; past this shrink, scroll instead.
  const MIN_SCALE = 0.65;
  function keepReadable(pre) {
    const svg = pre.querySelector("svg");
    const box = svg?.viewBox?.baseVal;
    if (!box?.width) return;
    const available = pre.clientWidth - 48;
    if (box.width * MIN_SCALE <= available) return;
    svg.style.maxWidth = "none";
    svg.style.width = `${box.width * MIN_SCALE}px`;
    svg.style.height = `${box.height * MIN_SCALE}px`;
    pre.style.textAlign = "left";
  }

  function applyPalette(config) {
    const perPoint = ["pie", "doughnut", "polarArea"].includes(config.type);
    (config.data?.datasets || []).forEach((ds, i) => {
      const color = palette[i % palette.length];
      if (perPoint) {
        ds.backgroundColor ??= (config.data.labels || []).map((_, j) => palette[j % palette.length]);
        ds.borderColor ??= ink.night;
        return;
      }
      const type = ds.type || config.type;
      ds.borderColor ??= color;
      ds.backgroundColor ??= ["line", "radar"].includes(type) ? `${color}33` : `${color}cc`;
      ds.pointBackgroundColor ??= color;
      if (type === "bar") ds.borderRadius ??= 6;
      if (type === "line") ds.cubicInterpolationMode ??= "monotone";
    });
  }

  function renderCharts(root = document) {
    if (!window.Chart) return;
    Chart.defaults.color = ink.muted;
    Chart.defaults.borderColor = "rgba(179, 171, 214, 0.14)";
    Chart.defaults.font.family = fontBody;
    Chart.defaults.font.size = 14;
    Chart.defaults.plugins.title.color = ink.text;
    Chart.defaults.plugins.tooltip.backgroundColor = ink.panel;
    Chart.defaults.plugins.tooltip.borderColor = ink.rule;
    Chart.defaults.plugins.tooltip.borderWidth = 1;

    root.querySelectorAll('script[type="application/json"].chart:not([data-done])').forEach((script) => {
      script.dataset.done = "1";
      let config;
      try { config = JSON.parse(script.textContent); } catch (err) {
        script.after(el("p", { class: "callout danger" }, `This chart's config isn't valid JSON: ${err.message}`));
        return;
      }
      applyPalette(config);
      config.options = { responsive: true, maintainAspectRatio: false, ...config.options };

      const label = script.dataset.label || config.options?.plugins?.title?.text || "Chart";
      const canvas = el("canvas", { role: "img", "aria-label": label });
      const box = el("div", { class: "chart-box", style: `height: ${script.dataset.height || 320}px` }, canvas);
      script.after(box);
      if (script.dataset.caption) box.after(el("p", { class: "chart-caption" }, script.dataset.caption));
      new Chart(canvas, config);
    });
  }

  initMermaid();
  window.Explain = { meta, renderDiagrams, renderCharts, wrapTables };

  const start = () => {
    renderSiteBar();
    renderDeckHome();
    renderToc();
    wrapTables(document);
    renderCharts(document);
    renderDiagrams(document);
  };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", start);
  else start();
})();
