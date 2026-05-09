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

    print("== SAVI App Store age rating check ==")

    runbook = read("Docs/Architecture/Runbooks/AppStoreAgeRating.md")
    metadata = read("Docs/Architecture/Runbooks/AppStoreConnectMetadata.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    preflight = read("scripts/savi-preflight.sh")
    safety_scan = read("scripts/savi-safety-scan.sh")
    status = read("Docs/Architecture/Runbooks/StatusReports.md")
    status_script = read("scripts/savi-status-report.py")
    cto = read("Docs/Architecture/CTOHandoffIndex.md")
    architecture = read("Docs/Architecture/README.md")

    for phrase in [
        "SAVI App Store Age Rating Packet",
        "scripts/savi-appstore-age-rating-check.py",
        "not legal advice",
        "Apple: [Set an app age rating]",
        "Apple: [Age ratings reference]",
        "App Review Guidelines",
        "Current Submitted-Build Posture",
        "private-save app",
        "No live public social feed",
        "No public user-generated PDFs",
        "No gambling",
        "No contests",
        "No unrestricted web browser",
        "not medical advice",
        "Medical/Treatment Information",
        "Founder/legal final",
        "Kids category",
        "not intended for the Kids category",
        "Recommended Answer Posture",
        "Suggested App Review Explanation",
        "Future Changes That Trigger Re-rating",
        "Social/UGC",
        "Browser-like features",
        "Final Founder Checklist",
        "scripts/savi-sample-content-check.py",
    ]:
        require_text(runbook, phrase, "AppStoreAgeRating", failures)

    for phrase in [
        "Docs/Architecture/Runbooks/AppStoreAgeRating.md",
        "scripts/savi-appstore-age-rating-check.py",
        "No gambling",
        "No contests",
        "No unrestricted web browser",
        "No live public social feed",
        "neutral health",
    ]:
        require_text(metadata, phrase, "AppStoreConnectMetadata", failures)

    for phrase in [
        "Age Rating",
        "AppStoreAgeRating.md",
        "Blocked",
        "Founder/legal",
    ]:
        require_text(compliance, phrase, "AppStoreComplianceMatrix", failures)

    for phrase in [
        "Age Rating Packet",
        "AppStoreAgeRating.md",
        "Age rating answered in App Store Connect",
    ]:
        require_text(packet, phrase, "AppStoreSubmissionPacket", failures)

    require_text(preflight, "scripts/savi-appstore-age-rating-check.py", "savi-preflight.sh", failures)
    require_text(
        safety_scan,
        "Docs/Architecture/Runbooks/AppStoreAgeRating.md",
        "savi-safety-scan.sh",
        failures,
    )
    require_text(status, "App Store age-rating", "StatusReports", failures)
    require_text(status_script, "scripts/savi-appstore-age-rating-check.py", "savi-status-report.py", failures)
    require_text(cto, "AppStoreAgeRating.md", "CTOHandoffIndex", failures)
    require_text(architecture, "Runbooks/AppStoreAgeRating.md", "Architecture README", failures)

    if failures:
        print("\nSAVI App Store age rating check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI App Store age rating check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI App Store age rating check failed: {exc}")
        raise SystemExit(1)
