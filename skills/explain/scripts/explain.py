#!/usr/bin/env python3
"""Manage the explain docs site: create docs, archive them, rebuild index pages."""

import argparse
import html
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

HOME = Path.home() / ".explain-skill"
CONFIG_PATH = HOME / "config.json"
SKILL_DIR = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = SKILL_DIR / "templates"

DEFAULT_CONFIG = {
    "base_url": "http://mac-studio",
    "docs_root": str(HOME / "docs"),
    "doc_types": {
        "technical-documents": "Technical",
        "product-documents": "Product",
        "game-documents": "Game",
        "investigations": "Investigation",
        "question-sets": "Questions",
        "slides": "Slides",
    },
}

META_RE = re.compile(
    r'(<script type="application/json" id="explain-meta">)(.*?)(</script>)', re.S
)


@dataclass(frozen=True)
class Doc:
    path: Path
    project: str
    doc_type: str
    meta: dict

    @property
    def archived(self) -> bool:
        return self.meta.get("status") == "archived"


# Pure helpers


def slugify(text: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug or "doc"


def timestamp(now: datetime) -> str:
    return now.astimezone(timezone.utc).strftime("%Y%m%dT%H%M%SZ")


def iso(now: datetime) -> str:
    return now.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def human_date(iso_string: str) -> str:
    try:
        d = datetime.strptime(iso_string[:10], "%Y-%m-%d")
    except ValueError:
        return ""
    return f"{d:%b} {d.day}, {d.year}"


def doc_filename(now: datetime, slug: str) -> str:
    return f"{timestamp(now)}-{slug}.html"


def parse_meta(text: str) -> dict | None:
    match = META_RE.search(text)
    if not match:
        return None
    try:
        return json.loads(match.group(2))
    except json.JSONDecodeError:
        return None


def replace_meta(text: str, meta: dict) -> str:
    payload = "\n" + json.dumps(meta, indent=2) + "\n"
    return META_RE.sub(lambda m: m.group(1) + payload + m.group(3), text, count=1)


def url_for(base_url: str, docs_root: Path, path: Path) -> str:
    rel = path.relative_to(docs_root).as_posix()
    if rel == ".":
        rel = ""
    elif path.is_dir():
        rel += "/"
    rel = rel.removesuffix("index.html")
    return f"{base_url.rstrip('/')}/docs/{rel}"


def path_for(target: str, base_url: str, docs_root: Path) -> Path:
    prefix = f"{base_url.rstrip('/')}/docs/"
    if target.startswith(prefix):
        return docs_root / target[len(prefix):]
    return Path(target).expanduser().resolve()


def render_template(template: str, values: dict[str, str]) -> str:
    for key, value in values.items():
        template = template.replace("{{" + key + "}}", value)
    return template


def render_listing(title: str, crumbs: list[tuple[str, str]], groups: list[tuple[str, str, list[Doc]]],
                   doc_types: dict[str, str], docs_root: Path, data_type: str = "") -> str:
    def href(path: Path) -> str:
        return "/docs/" + path.relative_to(docs_root).as_posix()

    def row(doc: Doc) -> str:
        m = doc.meta
        tags = "".join(f'<span class="tag">{html.escape(t)}</span>' for t in m.get("tags", []))
        status = ' <span class="badge badge-archived">Archived</span>' if doc.archived else ""
        kind = html.escape(doc_types.get(doc.doc_type, doc.doc_type))
        created = m.get("created", "")
        return (
            f'<li class="doc-row{" archived" if doc.archived else ""}" data-type="{html.escape(doc.doc_type)}">'
            f'<h3><a href="{href(doc.path)}">{html.escape(m.get("title", doc.path.stem))}</a>{status}</h3>'
            f'<div class="row-meta"><span class="kind">{kind}</span>'
            f'<time datetime="{html.escape(created)}">{human_date(created)}</time></div>'
            f'<p>{html.escape(m.get("summary", ""))}</p>'
            f'{f"<div class=tags>{tags}</div>" if tags else ""}</li>'
        )

    sep = '<span class="sep" aria-hidden="true">/</span>'
    crumb_html = sep.join(f'<a href="{html.escape(h)}">{html.escape(t)}</a>' for t, h in crumbs)
    sections = []
    for heading, link, docs in groups:
        docs = sorted(docs, key=lambda d: d.meta.get("created", ""), reverse=True)
        active = sum(not d.archived for d in docs)
        count = f"{active} doc{'' if active == 1 else 's'}"
        if active != len(docs):
            count += f", {len(docs) - active} archived"
        sections.append(
            f'<section class="group"><h2><a href="{html.escape(link)}">{html.escape(heading)}</a>'
            f'<small>{count}</small></h2>'
            f'<ul class="doc-list">{"".join(row(d) for d in docs)}</ul></section>'
        )
    body = "".join(sections) or '<p class="empty">Nothing here yet. Ask Claude to explain something and the doc will appear here.</p>'
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{html.escape(title)}</title>
<link rel="stylesheet" href="/docs/_assets/explain.css">
</head>
<body class="listing"{f' data-type="{html.escape(data_type)}"' if data_type else ""}>
<input type="checkbox" id="show-archived" class="visually-hidden">
<header class="site-bar">
<nav class="crumbs" aria-label="Breadcrumb">{crumb_html}</nav>
<label for="show-archived" class="toggle">Show archived</label>
</header>
<header class="hero">
<div class="hero-inner"><h1>{html.escape(title)}</h1></div>
</header>
<main>
{body}
</main>
</body>
</html>
"""


# Side effects


def load_config() -> dict:
    if not CONFIG_PATH.exists():
        HOME.mkdir(parents=True, exist_ok=True)
        CONFIG_PATH.write_text(json.dumps(DEFAULT_CONFIG, indent=2) + "\n")
    config = {**DEFAULT_CONFIG, **json.loads(CONFIG_PATH.read_text())}
    config["docs_root"] = Path(config["docs_root"]).expanduser()
    return config


def collect_docs(docs_root: Path) -> list[Doc]:
    docs = []
    for path in sorted(docs_root.glob("*/*/*.html")):
        if path.name == "index.html" or path.parts[-3].startswith("_"):
            continue
        meta = parse_meta(path.read_text())
        if meta is None:
            continue
        docs.append(Doc(path, path.parts[-3], path.parts[-2], meta))
    return docs


def build_index(config: dict) -> None:
    root: Path = config["docs_root"]
    types = config["doc_types"]
    docs = collect_docs(root)
    home = ("docs", "/docs/")

    projects = sorted({d.project for d in docs})
    (root / "index.html").write_text(render_listing(
        "Docs", [home],
        [(p, f"/docs/{p}/", [d for d in docs if d.project == p]) for p in projects],
        types, root,
    ))
    for project in projects:
        project_docs = [d for d in docs if d.project == project]
        kinds = sorted({d.doc_type for d in project_docs})
        crumbs = [home, (project, f"/docs/{project}/")]
        (root / project / "index.html").write_text(render_listing(
            project, crumbs,
            [(types.get(k, k), f"/docs/{project}/{k}/", [d for d in project_docs if d.doc_type == k])
             for k in kinds],
            types, root,
        ))
        for kind in kinds:
            (root / project / kind / "index.html").write_text(render_listing(
                f"{project} / {types.get(kind, kind)}",
                crumbs + [(kind, f"/docs/{project}/{kind}/")],
                [(types.get(kind, kind), f"/docs/{project}/{kind}/",
                  [d for d in project_docs if d.doc_type == kind])],
                types, root, data_type=kind,
            ))


def set_meta(path: Path, **changes) -> dict:
    text = path.read_text()
    meta = parse_meta(text)
    if meta is None:
        sys.exit(f"no explain-meta block in {path}")
    meta.update(changes)
    path.write_text(replace_meta(text, meta))
    return meta


# Commands


def cmd_new(args, config):
    types = config["doc_types"]
    if args.type not in types:
        sys.exit(f"unknown doc type '{args.type}'. options: {', '.join(types)}")
    now = datetime.now(timezone.utc)
    project = slugify(args.project)
    slug = slugify(args.slug or args.title)
    path = config["docs_root"] / project / args.type / doc_filename(now, slug)
    path.parent.mkdir(parents=True, exist_ok=True)

    meta = {
        "title": args.title,
        "summary": args.summary or "",
        "project": project,
        "doc_type": args.type,
        "status": "active",
        "tags": [t.strip() for t in (args.tags or "").split(",") if t.strip()],
        "created": iso(now),
        "updated": iso(now),
    }
    template_name = "slides.html" if args.type == "slides" else "doc.html"
    template = (TEMPLATES_DIR / template_name).read_text()
    path.write_text(render_template(template, {
        "META": "\n" + json.dumps(meta, indent=2) + "\n",
        "DOC_TYPE": args.type,
        "TITLE": html.escape(args.title),
        "SUMMARY": html.escape(args.summary or ""),
    }))
    build_index(config)
    print(f"path: {path}")
    print(f"url:  {url_for(config['base_url'], config['docs_root'], path)}")


def cmd_touch(args, config):
    path = path_for(args.target, config["base_url"], config["docs_root"])
    changes = {"updated": iso(datetime.now(timezone.utc))}
    if args.title:
        changes["title"] = args.title
    if args.summary is not None:
        changes["summary"] = args.summary
    set_meta(path, **changes)
    build_index(config)
    print(url_for(config["base_url"], config["docs_root"], path))


def cmd_status(status: str):
    def run(args, config):
        path = path_for(args.target, config["base_url"], config["docs_root"])
        set_meta(path, status=status, updated=iso(datetime.now(timezone.utc)))
        build_index(config)
        print(f"{status}: {url_for(config['base_url'], config['docs_root'], path)}")
    return run


def cmd_list(args, config):
    for doc in sorted(collect_docs(config["docs_root"]), key=lambda d: d.meta.get("created", "")):
        if args.project and doc.project != slugify(args.project):
            continue
        if args.type and doc.doc_type != args.type:
            continue
        if doc.archived and not args.all:
            continue
        flag = " [archived]" if doc.archived else ""
        url = url_for(config["base_url"], config["docs_root"], doc.path)
        print(f"{doc.meta.get('created', '')[:10]}  {doc.meta.get('title', '')}{flag}\n  {url}")


def cmd_index(args, config):
    build_index(config)
    print(url_for(config["base_url"], config["docs_root"], config["docs_root"]))


def main() -> None:
    parser = argparse.ArgumentParser(prog="explain")
    sub = parser.add_subparsers(dest="command", required=True)

    new = sub.add_parser("new", help="create a doc from a template")
    new.add_argument("--project", required=True)
    new.add_argument("--type", required=True)
    new.add_argument("--title", required=True)
    new.add_argument("--summary")
    new.add_argument("--tags", help="comma separated")
    new.add_argument("--slug", help="filename slug, defaults to the title")
    new.set_defaults(func=cmd_new)

    touch = sub.add_parser("touch", help="bump updated time, optionally retitle")
    touch.add_argument("target", help="path or url")
    touch.add_argument("--title")
    touch.add_argument("--summary")
    touch.set_defaults(func=cmd_touch)

    for name, status in (("archive", "archived"), ("unarchive", "active")):
        p = sub.add_parser(name)
        p.add_argument("target", help="path or url")
        p.set_defaults(func=cmd_status(status))

    ls = sub.add_parser("list")
    ls.add_argument("--project")
    ls.add_argument("--type")
    ls.add_argument("--all", action="store_true", help="include archived")
    ls.set_defaults(func=cmd_list)

    sub.add_parser("index", help="rebuild index pages").set_defaults(func=cmd_index)

    args = parser.parse_args()
    args.func(args, load_config())


if __name__ == "__main__":
    main()
