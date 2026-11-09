(() => {
  const source = document.getElementById("deck-source");
  const deck = document.getElementById("deck");
  if (!source || !deck || !window.marked) return;

  const chunks = source.textContent
    .replace(/<!-- explain:content -->/g, "")
    .split(/^\s*---\s*$/m)
    .map((s) => s.trim())
    .filter(Boolean);

  // Turn ```mermaid and ```chart fences into the elements explain.js renders.
  const convertFences = (slide) => {
    slide.querySelectorAll("pre > code.language-mermaid").forEach((code) => {
      const pre = document.createElement("pre");
      pre.className = "mermaid";
      pre.textContent = code.textContent;
      code.parentElement.replaceWith(pre);
    });
    slide.querySelectorAll("pre > code.language-chart").forEach((code) => {
      const script = document.createElement("script");
      script.type = "application/json";
      script.className = "chart";
      script.dataset.height = "420";
      script.textContent = code.textContent;
      code.parentElement.replaceWith(script);
    });
  };

  const slides = chunks.map((md, i) => {
    const slide = document.createElement("section");
    slide.className = i === 0 ? "slide slide-title" : "slide";
    slide.setAttribute("aria-roledescription", "slide");
    slide.setAttribute("aria-label", `${i + 1} of ${chunks.length}`);
    slide.innerHTML = marked.parse(md);
    convertFences(slide);
    deck.append(slide);
    return slide;
  });

  const progress = document.createElement("div");
  progress.className = "deck-progress";
  const counter = document.createElement("span");
  counter.setAttribute("aria-live", "polite");
  const button = (label, text, onClick) => {
    const b = document.createElement("button");
    b.type = "button";
    b.setAttribute("aria-label", label);
    b.textContent = text;
    b.addEventListener("click", onClick);
    return b;
  };
  const controls = document.createElement("div");
  controls.className = "deck-controls";
  controls.append(button("Previous slide", "Back", () => go(current - 1)), counter, button("Next slide", "Next", () => go(current + 1)));
  document.body.append(progress, controls);

  let current = 0;
  function go(index) {
    current = Math.max(0, Math.min(slides.length - 1, index));
    slides.forEach((s, i) => {
      s.classList.toggle("active", i === current);
      s.classList.toggle("past", i < current);
      s.setAttribute("aria-hidden", String(i !== current));
    });
    counter.textContent = `${current + 1} / ${slides.length}`;
    progress.style.width = `${((current + 1) / slides.length) * 100}%`;
    history.replaceState(null, "", `#${current + 1}`);
  }

  document.addEventListener("keydown", (e) => {
    if (e.metaKey || e.ctrlKey || e.altKey) return;
    const next = ["ArrowRight", "ArrowDown", "PageDown", " ", "l", "j"];
    const prev = ["ArrowLeft", "ArrowUp", "PageUp", "h", "k"];
    if (next.includes(e.key)) { e.preventDefault(); go(current + 1); }
    else if (prev.includes(e.key)) { e.preventDefault(); go(current - 1); }
    else if (e.key === "Home") go(0);
    else if (e.key === "End") go(slides.length - 1);
  });

  let touchX = null;
  deck.addEventListener("touchstart", (e) => { touchX = e.touches[0].clientX; }, { passive: true });
  deck.addEventListener("touchend", (e) => {
    if (touchX === null) return;
    const dx = e.changedTouches[0].clientX - touchX;
    if (Math.abs(dx) > 50) go(current + (dx < 0 ? 1 : -1));
    touchX = null;
  });

  go((parseInt(location.hash.slice(1), 10) || 1) - 1);
})();
