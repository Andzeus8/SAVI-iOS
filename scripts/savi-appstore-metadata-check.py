#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
APP_NAME = "SAVI: Save Now, Find Later."
SUBTITLE = "Save anything. Find it later."
KEYWORDS = "save,organize,links,notes,files,pdf,screenshots,bookmarks,share sheet,search"
STALE_PHRASES = [
    "1.0 (27)",
    "build `27`",
    "build 27",
    "Build 4",
    "build 4",
]


def read(path: str) -> str:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Missing required file: {path}")
    return target.read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def current_build() -> str:
    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    matches = sorted(set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", pbxproj)))
    if not matches:
        raise AssertionError("Could not detect CURRENT_PROJECT_VERSION")
    return matches[-1]


def main() -> int:
    failures: list[str] = []

    print("== SAVI App Store metadata check ==")

    build = current_build()
    metadata = read("Docs/Architecture/Runbooks/AppStoreConnectMetadata.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    readiness = read("Docs/TestFlightReadiness.md")
    preflight = read("scripts/savi-preflight.sh")

    for path in [
        "Docs/Architecture/Runbooks/AppStoreConnectMetadata.md",
        "Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md",
        "Docs/TestFlightReadiness.md",
    ]:
        require((ROOT / path).exists(), f"metadata source exists: {path}", failures)

    for phrase in [
        "Current Build Context",
        "New App Record",
        "Product Page Draft",
        "Product Description Draft",
        "TestFlight Beta Description",
        "What To Test",
        "App Review Notes",
        "Screenshot Storyboard",
        "Age Rating Notes",
        "Docs/Architecture/Runbooks/AppStoreAgeRating.md",
        "scripts/savi-appstore-age-rating-check.py",
        "Privacy And Legal Reminders",
        "Docs/Architecture/Runbooks/AppStoreExportCompliance.md",
        "scripts/savi-appstore-export-compliance-check.py",
        "Final Human Replacements",
        "com.altatecrd.savi",
        "com.altatecrd.savi.ShareExtension",
        "1080solutionsA@gmail.com",
        "Social sharing is still in progress and is not active",
        "Health-related sample links are saved",
        "not medical advice or treatment claims",
    ]:
        require(phrase in metadata, f"metadata packet contains `{phrase}`", failures)

    require(APP_NAME in metadata, f"app name present: {APP_NAME}", failures)
    require(len(APP_NAME) <= 30, f"app name is <= 30 characters ({len(APP_NAME)})", failures)
    require(SUBTITLE in metadata, f"subtitle present: {SUBTITLE}", failures)
    require(len(SUBTITLE) <= 30, f"subtitle is <= 30 characters ({len(SUBTITLE)})", failures)
    require(KEYWORDS in metadata, "keywords string present", failures)
    require(len(KEYWORDS) <= 100, f"keywords are <= 100 characters ({len(KEYWORDS)})", failures)

    for text_name, text in [
        ("AppStoreConnectMetadata", metadata),
        ("AppStoreSubmissionPacket", packet),
        ("TestFlightReadiness", readiness),
    ]:
        require(
            f"1.0 ({build})" in text or f"build `{build}`" in text,
            f"{text_name} mentions current build {build}",
            failures,
        )
        for stale in STALE_PHRASES:
            require(stale not in text, f"{text_name} does not contain stale `{stale}`", failures)

    for phrase in [
        "Docs/Architecture/Runbooks/AppStoreConnectMetadata.md",
        "scripts/savi-appstore-metadata-check.py",
    ]:
        require(phrase in packet or phrase in preflight, f"metadata checker is linked via `{phrase}`", failures)

    if failures:
        print("\nSAVI App Store metadata check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI App Store metadata check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI App Store metadata check failed: {exc}")
        raise SystemExit(1)
