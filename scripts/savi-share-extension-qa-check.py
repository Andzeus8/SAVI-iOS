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

    print("== SAVI share extension real-device QA check ==")

    runbook = read("Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md")
    production = read("Docs/ProductionReadiness.md")
    readiness = read("Docs/TestFlightReadiness.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    governance = read("Docs/Architecture/Runbooks/ReleaseGovernance.md")
    status = read("Docs/Architecture/Runbooks/StatusReports.md")
    preflight = read("scripts/savi-preflight.sh")
    safety_scan = read("scripts/savi-safety-scan.sh")
    cto = read("Docs/Architecture/CTOHandoffIndex.md")
    architecture = read("Docs/Architecture/README.md")

    for phrase in [
        "SAVI Share Extension Real-Device QA",
        "scripts/savi-share-extension-qa-check.py",
        "The Share Sheet is a core SAVI promise",
        "real-device Share Sheet QA",
        "iPhone 11 / iOS 17.4-class hardware",
        "Release `SAVI` / `com.altatecrd.savi`",
        "Safari URL",
        "YouTube",
        "TikTok/Instagram/X",
        "Photos screenshot",
        "Photos image",
        "Files PDF",
        "Files generic file",
        "Plain text",
        "Offline URL",
        "Metadata is a bonus, not a dependency",
        "Save is disabled while metadata loads",
        "completed shares do not import into the main app",
        "Do not attach private saved content",
        "CrashAndPerformanceTriage.md",
        "TestFlightOperations.md",
    ]:
        require_text(runbook, phrase, "ShareExtensionRealDeviceQA", failures)

    for phrase in [
        "Share Extension Gate",
        "URL link",
        "YouTube/TikTok/Instagram/X link",
        "Plain text",
        "Image",
        "PDF",
        "Generic file",
        "Save button remains reachable",
        "Pending share imports into the main app",
        "Share Extension real-device gate",
    ]:
        require_text(production, phrase, "ProductionReadiness", failures)

    for phrase in [
        "Share extension: URL, YouTube, TikTok, Instagram, X/Twitter, text, image, PDF, generic file",
        "Share extension real-device QA",
        "SAVI Share Extension Real-Device QA",
    ]:
        require_text(readiness, phrase, "TestFlightReadiness", failures)

    for phrase in [
        "Share Sheet",
        "Safari/Photos/Files/YouTube",
        "Share Extension real-device QA",
    ]:
        require_text(packet, phrase, "AppStoreSubmissionPacket", failures)

    for phrase in [
        "Share extension real-device QA",
        "scripts/savi-share-extension-qa-check.py",
    ]:
        require_text(governance, phrase, "ReleaseGovernance", failures)
        require_text(status, phrase, "StatusReports", failures)

    require_text(preflight, "scripts/savi-share-extension-qa-check.py", "savi-preflight.sh", failures)
    require_text(
        safety_scan,
        "Docs/Architecture/Runbooks/ShareExtensionRealDeviceQA.md",
        "savi-safety-scan.sh",
        failures,
    )
    require_text(cto, "ShareExtensionRealDeviceQA.md", "CTOHandoffIndex", failures)
    require_text(architecture, "Runbooks/ShareExtensionRealDeviceQA.md", "Architecture README", failures)

    if failures:
        print("\nSAVI share extension real-device QA check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI share extension real-device QA check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI share extension real-device QA check failed: {exc}")
        raise SystemExit(1)
