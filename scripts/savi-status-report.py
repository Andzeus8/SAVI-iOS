#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
import subprocess
from collections import Counter
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load_plist(path: str) -> dict:
    with (ROOT / path).open("rb") as handle:
        return plistlib.load(handle)


def run_git_status() -> list[str]:
    result = subprocess.run(
        ["git", "status", "--short"],
        cwd=ROOT,
        check=False,
        text=True,
        capture_output=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def unique_project_values(key: str, pbxproj: str) -> list[str]:
    values = re.findall(rf"\b{re.escape(key)} = ([^;]+);", pbxproj)
    return sorted({value.strip().strip('"') for value in values})


def parse_build_settings(body: str) -> dict[str, str]:
    settings: dict[str, str] = {}
    for match in re.finditer(r"^\s*([A-Z0-9_]+) = ([^;]+);", body, flags=re.MULTILINE):
        settings[match.group(1)] = match.group(2).strip().strip('"')
    return settings


def build_configurations(pbxproj: str) -> dict[str, dict[str, str]]:
    configs: dict[str, dict[str, str]] = {}
    pattern = re.compile(
        r"\n\t\t([A-F0-9]+) /\* (Debug|Release) \*/ = \{\n"
        r"\t\t\tisa = XCBuildConfiguration;\n"
        r"\t\t\tbuildSettings = \{\n"
        r"(?P<body>.*?)"
        r"\n\t\t\t\};\n"
        r"\t\t\tname = (Debug|Release);\n"
        r"\t\t\};",
        flags=re.DOTALL,
    )
    for match in pattern.finditer(pbxproj):
        config_id = match.group(1)
        config_name = match.group(2)
        settings = parse_build_settings(match.group("body"))
        settings["CONFIGURATION"] = config_name
        configs[config_id] = settings
    return configs


def target_configuration_ids(pbxproj: str) -> list[tuple[str, str, list[str]]]:
    targets: list[tuple[str, str, list[str]]] = []
    pattern = re.compile(
        r"\n\t\t([A-F0-9]+) /\* Build configuration list for PBXNativeTarget \"([^\"]+)\" \*/ = \{\n"
        r"\t\t\tisa = XCConfigurationList;\n"
        r"\t\t\tbuildConfigurations = \(\n"
        r"(?P<body>.*?)"
        r"\n\t\t\t\);",
        flags=re.DOTALL,
    )
    for match in pattern.finditer(pbxproj):
        config_ids = re.findall(r"\t\t\t\t([A-F0-9]+) /\* (?:Debug|Release) \*/,", match.group("body"))
        targets.append((match.group(1), match.group(2), config_ids))
    return targets


def target_build_rows(pbxproj: str) -> list[dict[str, str]]:
    configs = build_configurations(pbxproj)
    rows: list[dict[str, str]] = []
    for _, target_name, config_ids in target_configuration_ids(pbxproj):
        for config_id in config_ids:
            settings = configs.get(config_id)
            if not settings:
                continue
            rows.append(
                {
                    "target": target_name,
                    "configuration": settings.get("CONFIGURATION", "unknown"),
                    "bundle": settings.get("PRODUCT_BUNDLE_IDENTIFIER", "(project config)"),
                    "build": settings.get("CURRENT_PROJECT_VERSION", "(inherited)"),
                    "version": settings.get("MARKETING_VERSION", "(inherited)"),
                    "platforms": settings.get("SUPPORTED_PLATFORMS", settings.get("SDKROOT", "(inherited)")),
                }
            )
    return rows


def work_log_entries(limit: int = 8) -> list[tuple[str, str]]:
    entries: list[tuple[str, str]] = []
    current_title: str | None = None
    current_status = "unknown"

    for line in read("Docs/Handoffs/SAVI_ACTIVE_WORK_LOG.md").splitlines():
        if line.startswith("### "):
            if current_title:
                entries.append((current_title, current_status))
            current_title = line.removeprefix("### ").strip()
            current_status = "unknown"
        elif current_title and line.startswith("- Status:"):
            current_status = line.split(":", 1)[1].strip()

    if current_title:
        entries.append((current_title, current_status))
    return entries[:limit]


def public_site_todos() -> list[str]:
    todos: list[str] = []
    for path in sorted((ROOT / "Docs/PublicSite").glob("*.md")):
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
            if "TODO" in line:
                todos.append(f"{path.relative_to(ROOT)}:{number}: {line.strip()}")
    return todos


def social_release_gate_ok(core: str) -> bool:
    return (
        "#if DEBUG" in core
        and "static let socialFeaturesEnabled = true" in core
        and "static let socialFeaturesEnabled = false" in core
    )


def print_section(title: str) -> None:
    print(f"\n## {title}")


def main() -> int:
    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    app_info = load_plist("SAVI/Info.plist")
    share_info = load_plist("SAVIShareExtension/Info.plist")
    readiness = read("Docs/TestFlightReadiness.md")
    core = read("SAVI/Core/SaviCore.swift")
    status_lines = run_git_status()
    build_rows = target_build_rows(pbxproj)

    print("# SAVI Status Report")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Repo: {ROOT}")

    print_section("Build And Bundles")
    for row in build_rows:
        print(
            f"- {row['target']} {row['configuration']}: "
            f"version {row['version']} build {row['build']} | "
            f"{row['bundle']} | {row['platforms']}"
        )
    if not build_rows:
        for value in unique_project_values("CURRENT_PROJECT_VERSION", pbxproj):
            print(f"- Project build: {value}")
        for value in unique_project_values("MARKETING_VERSION", pbxproj):
            print(f"- Marketing version: {value}")
        for value in unique_project_values("PRODUCT_BUNDLE_IDENTIFIER", pbxproj):
            print(f"- Bundle ID: {value}")
    print(f"- App display name token: {app_info.get('CFBundleDisplayName', 'unknown')}")
    print(f"- Share extension display name token: {share_info.get('CFBundleDisplayName', 'unknown')}")

    print_section("TestFlight Readiness Doc")
    for pattern in [
        r"Current local project build number: `([^`]+)`",
        r"Latest uploaded TestFlight build: `([^`]+)`",
        r"Latest uploaded archive:\n\s+([^\n]+)",
    ]:
        match = re.search(pattern, readiness)
        if match:
            print(f"- {match.group(0).strip()}")
    if "Social Beta disabled" in readiness or "social hidden" in readiness.lower():
        print("- Release/TestFlight social posture documented as hidden/disabled")

    print_section("Release Safety Gates")
    print(f"- Release social gate outside DEBUG: {'OK' if social_release_gate_ok(core) else 'CHECK'}")
    print(
        "- App export-compliance plist key: "
        f"{'OK' if app_info.get('ITSAppUsesNonExemptEncryption') is False else 'CHECK'}"
    )
    print(
        "- Share extension export-compliance plist key: "
        f"{'OK' if share_info.get('ITSAppUsesNonExemptEncryption') is False else 'CHECK'}"
    )

    print_section("Active Work Log")
    for title, status in work_log_entries():
        print(f"- {title}: {status}")

    print_section("Dirty Worktree Summary")
    if not status_lines:
        print("- Clean worktree")
    else:
        counts = Counter(line[:2].strip() or "changed" for line in status_lines)
        print(f"- Changed paths: {len(status_lines)}")
        for status, count in sorted(counts.items()):
            print(f"- {status}: {count}")
        print("- First changed paths:")
        for line in status_lines[:12]:
            print(f"  - {line}")
        if len(status_lines) > 12:
            print(f"  - ... {len(status_lines) - 12} more")

    print_section("Known Human/Account Blockers")
    todos = public_site_todos()
    if todos:
        print("- Public site still has TODO placeholders:")
        for todo in todos[:8]:
            print(f"  - {todo}")
        if len(todos) > 8:
            print(f"  - ... {len(todos) - 8} more")
    else:
        print("- Public-site templates have no TODO placeholders")
    print("- Founder/legal must still confirm App Store export compliance and final privacy labels")
    print("- Founder/legal must still answer the App Store age-rating questionnaire")
    print("- Supabase/PostHog/domain setup still requires founder-owned accounts and keys")

    print_section("Recommended Commands")
    print("- Quick gate: `scripts/savi-preflight.sh`")
    print("- App Store gate: `scripts/savi-appstore-readiness-check.py`")
    print("- Privacy labels: `scripts/savi-appstore-privacy-labels-check.py`")
    print("- Age rating: `scripts/savi-appstore-age-rating-check.py`")
    print("- Export compliance: `scripts/savi-appstore-export-compliance-check.py`")
    print("- TestFlight ops: `scripts/savi-testflight-ops-check.py`")
    print("- Crash/performance triage: `scripts/savi-crash-performance-check.py`")
    print("- Share extension QA: `scripts/savi-share-extension-qa-check.py`")
    print("- Archive export/restore QA: `scripts/savi-archive-restore-check.py`")
    print("- Backend contracts: `scripts/savi-contract-fixtures-check.py`")
    print("- Release build gate: `scripts/savi-preflight.sh --release-build`")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
