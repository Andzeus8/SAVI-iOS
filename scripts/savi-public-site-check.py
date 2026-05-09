#!/usr/bin/env python3
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PUBLIC_SITE = ROOT / "Docs" / "PublicSite"
REQUIRED_SOURCE = [
    "privacy.md",
    "terms.md",
    "support.md",
    "data-deletion.md",
    "community-guidelines.md",
    "README.md",
    "StaticSitePublishing.md",
    "domain-dns-plan.md",
]
REQUIRED_OUTPUT = [
    "index.html",
    "privacy.html",
    "terms.html",
    "support.html",
    "data-deletion.html",
    "community-guidelines.html",
]


def read(path: Path) -> str:
    if not path.exists():
        raise AssertionError(f"Missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def main() -> int:
    failures: list[str] = []

    print("== SAVI public-site check ==")

    for name in REQUIRED_SOURCE:
        require((PUBLIC_SITE / name).exists(), f"source exists: Docs/PublicSite/{name}", failures)

    combined = "\n".join(read(PUBLIC_SITE / name) for name in REQUIRED_SOURCE if name.endswith(".md"))
    require("TODO" not in combined, "public-site source has no unfinished placeholders", failures)
    require(
        "1080solutionsA@gmail.com" in combined,
        "public-site source includes current beta support email",
        failures,
    )
    require(
        "service-role" in read(PUBLIC_SITE / "domain-dns-plan.md"),
        "domain/DNS plan warns against service-role key exposure",
        failures,
    )
    require(
        "scripts/savi-public-site-build.py" in read(PUBLIC_SITE / "StaticSitePublishing.md"),
        "static publishing doc names the build script",
        failures,
    )

    with tempfile.TemporaryDirectory(prefix="savi-public-site-") as tmp:
        output = Path(tmp)
        result = subprocess.run(
            [sys.executable, str(ROOT / "scripts" / "savi-public-site-build.py"), "--output", str(output)],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            print(result.stdout)
            print(result.stderr)
            failures.append("public-site builder failed")
        else:
            print(result.stdout.strip())
            for name in REQUIRED_OUTPUT:
                target = output / name
                require(target.exists(), f"generated {name}", failures)
                if target.exists():
                    html_text = read(target)
                    require("<html lang=\"en\">" in html_text, f"{name} is HTML", failures)
                    require("SAVI" in html_text, f"{name} includes SAVI branding", failures)
            require(
                "TODO" not in "\n".join((output / name).read_text(encoding="utf-8") for name in REQUIRED_OUTPUT),
                "generated site has no unfinished placeholders",
                failures,
            )
            shutil.rmtree(output, ignore_errors=True)

    if failures:
        print("\nSAVI public-site check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI public-site check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI public-site check failed: {exc}")
        raise SystemExit(1)
