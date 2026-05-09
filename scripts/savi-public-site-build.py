#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "Docs" / "PublicSite"
OUTPUT_DIR = ROOT / "build" / "public-site"

PAGES = [
    ("privacy.md", "privacy.html", "Privacy"),
    ("terms.md", "terms.html", "Terms"),
    ("support.md", "support.html", "Support"),
    ("data-deletion.md", "data-deletion.html", "Data Deletion"),
    ("community-guidelines.md", "community-guidelines.html", "Community Guidelines"),
]


STYLE = """
:root {
  color-scheme: light dark;
  --bg: #f7f3fb;
  --ink: #21152f;
  --muted: #6d6178;
  --card: #ffffff;
  --line: #ded3e8;
  --accent: #7c3aed;
  --accent-soft: #ede9fe;
}
@media (prefers-color-scheme: dark) {
  :root {
    --bg: #130f19;
    --ink: #f8f3ff;
    --muted: #b9aec6;
    --card: #211a2b;
    --line: #34283f;
    --accent: #c4b5fd;
    --accent-soft: #2f2440;
  }
}
* { box-sizing: border-box; }
body {
  margin: 0;
  background: var(--bg);
  color: var(--ink);
  font: 17px/1.62 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", sans-serif;
}
a { color: var(--accent); }
.site {
  width: min(980px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 56px;
}
header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  padding: 10px 0 28px;
}
.brand {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 800;
  letter-spacing: 0;
}
.mark {
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  border-radius: 12px;
  color: #fff;
  background: linear-gradient(135deg, #7c3aed, #06b6d4);
  font-weight: 900;
}
nav {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px 14px;
  font-size: 14px;
}
main {
  background: var(--card);
  border: 1px solid var(--line);
  border-radius: 18px;
  padding: clamp(24px, 4vw, 48px);
  box-shadow: 0 18px 50px rgba(35, 19, 49, 0.09);
}
h1 {
  margin: 0 0 20px;
  font-size: clamp(34px, 7vw, 56px);
  line-height: 0.98;
  letter-spacing: 0;
}
h2 {
  margin: 34px 0 10px;
  font-size: 24px;
  line-height: 1.16;
  letter-spacing: 0;
}
p, ul { margin: 12px 0; }
li { margin: 7px 0; }
code {
  background: var(--accent-soft);
  padding: 2px 5px;
  border-radius: 6px;
  font-size: 0.92em;
}
.home-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 14px;
  margin-top: 28px;
}
.home-card {
  display: block;
  min-height: 118px;
  padding: 18px;
  border: 1px solid var(--line);
  border-radius: 14px;
  text-decoration: none;
  background: color-mix(in srgb, var(--card), var(--accent-soft) 24%);
}
.home-card strong {
  display: block;
  color: var(--ink);
  font-size: 18px;
  margin-bottom: 8px;
}
.home-card span { color: var(--muted); }
footer {
  color: var(--muted);
  font-size: 13px;
  padding-top: 24px;
}
@media (max-width: 640px) {
  header { align-items: flex-start; flex-direction: column; }
  nav { justify-content: flex-start; }
  main { border-radius: 14px; }
}
"""


def render_inline(text: str) -> str:
    escaped = html.escape(text)
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    escaped = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', escaped)
    return escaped


def markdown_to_html(markdown: str) -> str:
    lines = markdown.splitlines()
    body: list[str] = []
    in_list = False
    paragraph: list[str] = []

    def flush_paragraph() -> None:
        if paragraph:
            body.append(f"<p>{render_inline(' '.join(paragraph))}</p>")
            paragraph.clear()

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            body.append("</ul>")
            in_list = False

    for raw in lines:
        line = raw.rstrip()
        if not line:
            flush_paragraph()
            close_list()
            continue
        if line.startswith("# "):
            flush_paragraph()
            close_list()
            body.append(f"<h1>{render_inline(line[2:].strip())}</h1>")
        elif line.startswith("## "):
            flush_paragraph()
            close_list()
            body.append(f"<h2>{render_inline(line[3:].strip())}</h2>")
        elif line.startswith("- "):
            flush_paragraph()
            if not in_list:
                body.append("<ul>")
                in_list = True
            body.append(f"<li>{render_inline(line[2:].strip())}</li>")
        else:
            paragraph.append(line)

    flush_paragraph()
    close_list()
    return "\n".join(body)


def page_shell(title: str, body: str, depth: str = "") -> str:
    nav = "\n".join(
        f'<a href="{depth}{filename}">{label}</a>'
        for _, filename, label in PAGES
    )
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)} - SAVI</title>
  <style>{STYLE}</style>
</head>
<body>
  <div class="site">
    <header>
      <a class="brand" href="{depth}index.html" aria-label="SAVI home">
        <span class="mark">S</span>
        <span>SAVI</span>
      </a>
      <nav>{nav}</nav>
    </header>
    <main>
{body}
    </main>
    <footer>SAVI public beta support: <a href="mailto:1080solutionsA@gmail.com">1080solutionsA@gmail.com</a></footer>
  </div>
</body>
</html>
"""


def build_home() -> str:
    cards = "\n".join(
        f'<a class="home-card" href="{filename}"><strong>{label}</strong><span>{description}</span></a>'
        for _, filename, label, description in [
            ("privacy.md", "privacy.html", "Privacy", "How SAVI handles saved content, metadata, analytics, and future accounts."),
            ("terms.md", "terms.html", "Terms", "Basic use terms for the current beta and future public sharing."),
            ("support.md", "support.html", "Support", "How to get help and send useful TestFlight feedback."),
            ("data-deletion.md", "data-deletion.html", "Data Deletion", "Current local-data deletion and future account deletion rules."),
            ("community-guidelines.md", "community-guidelines.html", "Community Guidelines", "Public-link and social safety rules for future social features."),
        ]
    )
    body = f"""
<h1>Save it now. Find it later.</h1>
<p>SAVI is a private-save app for links, screenshots, PDFs, videos, notes, files, and all the little things you swear you will find again.</p>
<div class="home-grid">
{cards}
</div>
"""
    return page_shell("Public Beta", body)


def build(output_dir: Path) -> list[Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []

    home = output_dir / "index.html"
    home.write_text(build_home(), encoding="utf-8")
    written.append(home)

    for source_name, output_name, label in PAGES:
        markdown = (SOURCE_DIR / source_name).read_text(encoding="utf-8")
        body = markdown_to_html(markdown)
        target = output_dir / output_name
        target.write_text(page_shell(label, body), encoding="utf-8")
        written.append(target)

    return written


def main() -> int:
    parser = argparse.ArgumentParser(description="Build SAVI public-site static HTML.")
    parser.add_argument(
        "--output",
        default=str(OUTPUT_DIR),
        help="Output directory. Defaults to build/public-site.",
    )
    args = parser.parse_args()

    written = build(Path(args.output))
    print("Built SAVI public site:")
    for path in written:
        try:
            display = path.relative_to(ROOT)
        except ValueError:
            display = path
        print(f"- {display}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
