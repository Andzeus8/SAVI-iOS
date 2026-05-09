#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote


ROOT = Path(__file__).resolve().parents[1]
DOC_GLOBS = [
    "AGENTS.md",
    "Docs/**/*.md",
]
PATH_PREFIXES = (
    ".github/",
    "Docs/",
    "SAVI/",
    "SAVIMac/",
    "SAVIShareExtension/",
    "Shared/",
    "scripts/",
)
SKIP_MARKERS = (
    "YYYY",
    "TODO",
    "$",
    "<",
    ">",
)


def iter_docs() -> list[Path]:
    paths: set[Path] = set()
    for pattern in DOC_GLOBS:
        paths.update(ROOT.glob(pattern))
    return sorted(
        path
        for path in paths
        if path.is_file()
        and not any(part.endswith("Archive") for part in path.relative_to(ROOT).parts)
    )


def is_external(target: str) -> bool:
    lower = target.lower()
    return lower.startswith(("http://", "https://", "mailto:", "tel:", "app://", "plugin://"))


def normalize_link_target(raw: str) -> str | None:
    target = raw.strip()
    if not target or target.startswith("#") or is_external(target):
        return None
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    if " " in target and not target.startswith("/"):
        target = target.split(" ", 1)[0]
    target = unquote(target.split("#", 1)[0].strip())
    if not target or target.startswith("#") or is_external(target):
        return None
    return target


def resolve_target(source: Path, target: str) -> Path:
    path = Path(target)
    if path.is_absolute():
        return path
    return (source.parent / path).resolve()


def should_check_code_path(value: str) -> bool:
    if any(marker in value for marker in SKIP_MARKERS):
        return False
    if "*" in value or "..." in value:
        return False
    if value.startswith(PATH_PREFIXES):
        return True
    if value in {"AGENTS.md", "README.md"}:
        return True
    return False


def normalize_code_path(value: str) -> str:
    if value.startswith("scripts/"):
        return value.split()[0]
    return value


def check_markdown_links(source: Path, text: str, failures: list[str]) -> int:
    checked = 0
    for match in re.finditer(r"!?\[[^\]]*\]\(([^)\n]+)\)", text):
        target = normalize_link_target(match.group(1))
        if not target:
            continue
        checked += 1
        resolved = resolve_target(source, target)
        if not resolved.exists():
            failures.append(
                f"{source.relative_to(ROOT)}: missing markdown link target `{match.group(1).strip()}`"
            )
    return checked


def check_backticked_paths(source: Path, text: str, failures: list[str]) -> int:
    checked = 0
    for match in re.finditer(r"`([^`\n]+)`", text):
        value = match.group(1).strip()
        if not should_check_code_path(value):
            continue
        value = normalize_code_path(value)
        checked += 1
        target = (ROOT / value).resolve()
        if not target.exists():
            failures.append(f"{source.relative_to(ROOT)}: missing repo path `{value}`")
    return checked


def main() -> int:
    failures: list[str] = []
    doc_count = 0
    link_count = 0

    print("== SAVI docs link check ==")

    for path in iter_docs():
        doc_count += 1
        text = path.read_text(encoding="utf-8")
        link_count += check_markdown_links(path, text, failures)
        link_count += check_backticked_paths(path, text, failures)

    if failures:
        print(f"Checked {doc_count} docs and {link_count} internal links/paths.")
        print("SAVI docs link check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: checked {doc_count} docs and {link_count} internal links/paths")
    print("SAVI docs link check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
