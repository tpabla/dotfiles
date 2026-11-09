---
name: explain
description: Write explanations, design docs, investigations, question sets and slide decks as cyberpunk-styled HTML pages served on the local network, then hand the user a link. Use when the user asks to explain something, write up or document a design, investigate a problem, make a doc, or make slides or a deck to walk them through something. Supports Mermaid diagrams (sequence, UML class, ER, flow, state), Chart.js charts, and tables (schemas, truth tables, decision matrices).
user_invocable: true
---

# Explain

Docs are single self-contained HTML files. nginx serves them from `~/.explain-skill/docs` at `<base_url>/docs/`. Each file carries its metadata (title, status, tags) in a JSON block, and the index pages are rebuilt from that metadata.

```
~/.explain-skill/
  config.json                         base_url, docs_root, doc_types
  docs/
    index.html                        generated
    _assets/                          explain.css, explain.js, slides.js (symlinked to this skill), vendor/
    <project>/index.html              generated
    <project>/<doc_type>/index.html   generated
    <project>/<doc_type>/<YYYYMMDDTHHMMSSZ>-<slug>.html
```

`CLI` below means `python3 ~/.claude/skills/explain/scripts/explain.py`.

## Workflow

1. **Choose the project.** Use the current repo's directory name unless the user names one. Pick the doc type from `config.json`:

   | doc_type | Use for |
   | --- | --- |
   | `technical-documents` | architecture, system design, code organization, APIs, data models |
   | `product-documents` | PRDs, feature specs, user flows, roadmaps |
   | `game-documents` | game design docs, mechanics, level design, narrative |
   | `investigations` | debugging write-ups, root-cause analysis, research findings |
   | `question-sets` | questions for the user to answer, interview prep, quizzes |
   | `slides` | any deck or walkthrough the user asks for as slides |

2. **Create the file.** Run `CLI new --project <p> --type <t> --title "<title>" --summary "<one sentence>" --tags a,b`. It prints the `path` and `url`, and rebuilds the indexes.
3. **Write the content.** Replace the `<!-- explain:content -->` marker in the file with the body, using the components below. Don't touch the `<head>`, the meta block or the script tags.
4. **Give the user the url** printed in step 2. Lead the reply with the link, then 1-3 lines on what the doc covers.
5. **When revising an existing doc,** edit it in place and run `CLI touch <path-or-url>`, which bumps `updated` and rebuilds the indexes. Pass `--title` or `--summary` if they changed. To start over instead, create a new doc and archive the old one.

Other commands:
- `CLI list [--project p] [--type t] [--all]` finds docs and their URLs. Use it when the user asks for a link to something already written.
- `CLI archive <path-or-url>` and `CLI unarchive <path-or-url>` set the status. Archived docs are hidden on index pages behind a "show archived" toggle, and their URL keeps working with an archived banner.
- `CLI index` rebuilds all index pages.
- If the site isn't reachable, run `~/.claude/skills/explain/setup.sh`. It's idempotent: it installs nginx, vendors the libraries, links the assets and restarts nginx.

## Writing the doc

- **Lead with the answer.** The `lead` paragraph under the title is the summary. Each `<h2>` section opens with its point.
- **Use the right visual.** A sequence of calls between systems is a sequence diagram, code structure is a class diagram, database tables are an ER diagram, and data is a chart. Don't describe a shape in prose that a picture shows better.
- **Use `<h2>` for the main sections.** With three or more, the page builds a table of contents automatically. Use `<h3>` and `<h4>` below that.
- **Write plain semantic HTML.** Never load external scripts, stylesheets or fonts: everything the page needs is in `/docs/_assets/`.
- **No emojis.**

### Design system

The look is a cyberpunk rainbow-pastel style on deep violet. Follow these rules:

- **Each doc type owns one pastel hue,** set from `data-type` on `<body>`. Headings, links, table headers, diagram lines and the first chart series all use it. Don't hard-code a hue for page chrome: the rainbow should show across the site as a whole, not all on one page.
- **The title is the one loud moment:** holographic foil type over a horizon grid. Keep everything below it quiet. Don't add gradients, glows or extra animation to the content.
- **Labels and headings are sentence case.** No all-caps labels, no eyebrow text above headings, and no monospace except for code and data values.
- **Prose stays at 68ch.** Figures, tables and grids can run the full content width.
- **Use cards only for parallel items** (options, acts, stats). Never wrap a single block of prose in a card.

### Components

```html
<section>
  <h2>Section title</h2>
  <p>...</p>
</section>

<div class="callout info"><strong>Note</strong><p>...</p></div>   <!-- info | ok | warn | danger | idea -->

<div class="grid">
  <div class="card"><h3>Title</h3><p>...</p></div>
  <div class="card"><div class="stat">42ms</div><div class="stat-label">p95 latency</div></div>
</div>

<span class="badge">label</span> <span class="tag">tag</span>
<span class="badge pill-mint">done</span>   <!-- pill-pink | pill-peach | pill-lemon | pill-mint | pill-sky | pill-lavender -->

<pre><code>code here, HTML-escaped</code></pre>
<hr>   <!-- rainbow divider -->
```

### Tables

Write a normal `<table>` with `<thead>`. Tables are wrapped for horizontal scrolling automatically. Add a `<caption>` when the table needs context. Variants:

- **`class="schema"`** for column definitions. Mark keys with `<span class="pk">PK</span>` and `<span class="fk">FK</span>`.
- **`class="truth"`** for truth tables. Cells with `class="t"` / `class="f"` (or `data-v="1"` / `data-v="0"`) are colored.
- **`class="matrix"`** for decision matrices. Score columns are centered, and `<tr class="best">` highlights the winner.

### Mermaid diagrams (v12)

Use `<pre class="mermaid">` with the diagram source. Wrap it in `<figure>` with a `<figcaption>` when it needs a caption. The pastel theme is applied automatically. The source is HTML text, so escape `<` as `&lt;` and `&` as `&amp;`: `<<interface>>` becomes `&lt;&lt;interface&gt;&gt;` and `<|--` becomes `&lt;|--`. Arrows like `-->` are fine as written, and generics use `List~T~`.

| Show | Diagram |
| --- | --- |
| how systems or services interact over time | `sequenceDiagram` (use `autonumber`, `activate`, `alt`/`opt`/`loop`, `Note`) |
| how code is organized, shared and reused | `classDiagram` (interfaces with `<<interface>>`, inheritance `<|--`, composition `*--`, dependency `..>`) |
| database tables and relationships | `erDiagram` (attributes with `PK`/`FK`, crow's-foot cardinality) |
| control flow, pipelines, architecture boxes | `flowchart LR` / `TD` with `subgraph` |
| lifecycles and modes | `stateDiagram-v2` |
| plans over time | `gantt`, `timeline` |
| idea maps | `mindmap` |
| options on two axes | `quadrantChart` |
| branching strategy | `gitGraph` |

Color specific nodes to show meaning, using the palette: pink `#ff9ad5`, peach `#ffb38a`, lemon `#fff38a`, mint `#8affc1`, sky `#8ad8ff`, lavender `#b69cff`. Pair a light fill with dark text:

```
classDef hot fill:#ff9ad5,stroke:#ff9ad5,color:#0d0a1a
classDef new fill:#8affc1,stroke:#8affc1,color:#0d0a1a
class AuthService hot
```

In sequence diagrams, use `box rgba(138,216,255,0.08) Backend ... end` to group participants and `rect rgba(255,154,213,0.12) ... end` to highlight a span.

### Charts (Chart.js 4)

Put a Chart.js config as JSON in a script tag. The page renders it with pastel defaults, so leave colors out unless one carries meaning.

```html
<script type="application/json" class="chart" data-height="320" data-label="Requests per day by region" data-caption="Week of Oct 20">
{"type": "bar", "data": {"labels": ["Mon", "Tue"], "datasets": [{"label": "us-east", "data": [120, 140]}]},
 "options": {"plugins": {"title": {"display": true, "text": "Requests per day"}}}}
</script>
```

Choose the chart from the data's shape: `line` for change over time, `bar` to compare categories, stacked `bar` for parts of a whole across categories, `doughnut` only for parts of one whole (at most 6 slices), `scatter` for correlation, `radar` to compare a few items across several scores. Give the axes titles with units.

## Slides

Use `--type slides`. The file holds markdown inside `<script type="text/markdown" id="deck-source">`. Replace the marker with the slides:

- **Separate slides** with a line containing only `---`. Don't use `---` anywhere else, including Mermaid frontmatter.
- **A ` ```mermaid ` fence** becomes a diagram, and a **` ```chart ` fence** holding Chart.js JSON becomes a chart.
- **Inline HTML works**, including the components above.
- **Never write `</script>`** inside the deck.
- **One idea per slide:** a heading plus at most 5 bullets, or one diagram, chart or table. The first slide (the title and summary) is already there.

Navigation: arrow keys, space, h/l, swipe or the on-screen buttons. `#n` in the URL opens slide n.

## Config

`~/.explain-skill/config.json` sets `base_url`, which defaults to `http://mac-studio` (this Mac's Tailscale name). It also sets `docs_root` and the `doc_types` map. To add a doc type, add it to the map.
