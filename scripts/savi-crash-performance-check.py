#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


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


def require_text(text: str, needle: str, label: str, failures: list[str]) -> None:
    require(needle in text, f"{label} contains `{needle}`", failures)


def main() -> int:
    failures: list[str] = []

    print("== SAVI crash/performance triage check ==")

    triage = read("Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md")
    production = read("Docs/ProductionReadiness.md")
    testflight = read("Docs/TestFlightReadiness.md")
    ops = read("Docs/Architecture/Runbooks/TestFlightOperations.md")
    status = read("Docs/Architecture/Runbooks/StatusReports.md")
    privacy = read("Docs/Architecture/PrivacyDataInventory.md")
    preflight = read("scripts/savi-preflight.sh")
    safety_scan = read("scripts/savi-safety-scan.sh")

    for phrase in [
        "iPhone 11 / iOS 17.4",
        "Launch crash",
        "Scroll jank",
        "Metadata/thumbnail jank",
        "Share extension failure",
        "TestFlight feedback",
        "Home, Search, Explore, Folders, or Profile",
        "Do not ask testers to email private documents",
        "Private Vault content",
        "scripts/savi-status-report.py",
        "scripts/savi-preflight.sh --release-build",
        "Tools/savi-production-ui-qa.sh",
        "CloudKit stays no-op/hidden in Release",
        "metadata or Apple Intelligence times out",
        "Keep modern iPhones polished",
        "avoid visible thumbnail pop-in",
        "Docs/ChangeLog/2026-05-06.md",
        "Docs/ChangeLog/2026-05-07.md",
    ]:
        require_text(triage, phrase, "CrashAndPerformanceTriage", failures)

    for phrase in [
        "Performance Gate",
        "Home and Search scroll without visible hitching",
        "Feedback Gate",
        "iPhone 11",
        "TestFlight feedback",
    ]:
        require_text(production, phrase, "ProductionReadiness", failures)

    for phrase in [
        "TestFlight screenshot/comment feedback",
        "Share extension",
        "Large library",
        "Home/Search scroll smoothly",
    ]:
        require_text(testflight, phrase, "TestFlightReadiness", failures)

    for phrase in [
        "crash or freeze",
        "TestFlight feedback",
        "old build",
    ]:
        require_text(ops, phrase, "TestFlightOperations", failures)

    for phrase in [
        "crash/performance triage",
        "scripts/savi-crash-performance-check.py",
    ]:
        require_text(status, phrase, "StatusReports", failures)

    for phrase in [
        "Crash/diagnostic data",
        "Do not include private content",
    ]:
        require_text(privacy, phrase, "PrivacyDataInventory", failures)

    require_text(preflight, "scripts/savi-crash-performance-check.py", "savi-preflight.sh", failures)
    require_text(
        safety_scan,
        "Docs/Architecture/Runbooks/CrashAndPerformanceTriage.md",
        "savi-safety-scan.sh",
        failures,
    )

    if failures:
        print("\nSAVI crash/performance triage check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI crash/performance triage check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI crash/performance triage check failed: {exc}")
        raise SystemExit(1)
