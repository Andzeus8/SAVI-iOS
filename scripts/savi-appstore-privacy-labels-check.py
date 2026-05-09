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

    print("== SAVI App Store privacy labels check ==")

    labels = read("Docs/Architecture/Runbooks/AppStorePrivacyLabels.md")
    worksheet = read("Docs/AppStorePrivacyWorksheet.md")
    inventory = read("Docs/Architecture/PrivacyDataInventory.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    preflight = read("scripts/savi-preflight.sh")
    safety_scan = read("scripts/savi-safety-scan.sh")
    cto = read("Docs/Architecture/CTOHandoffIndex.md")
    architecture = read("Docs/Architecture/README.md")

    for phrase in [
        "SAVI App Store Privacy Labels",
        "scripts/savi-appstore-privacy-labels-check.py",
        "not legal advice",
        "Apple: App privacy details",
        "Apple: Manage app privacy",
        "No required SAVI account",
        "No live Supabase production collection",
        "No live PostHog production analytics",
        "No APNs/device-token collection",
        "No live public social publishing",
        "No live metadata proxy owned by SAVI",
        "Does this app collect data from this app?",
        "`No`",
        "Conservative Support Disclosure Path",
        "Contact Info: Email Address",
        "What Not To Mark As Collected",
        "Private Vault content",
        "Remote Metadata Notes",
        "Future Answer Changes",
        "Sign in with Apple / accounts",
        "Supabase social",
        "PostHog analytics",
        "Push notifications",
        "Metadata proxy",
        "Final Human Checklist",
        "Founder/legal owner confirms",
    ]:
        require_text(labels, phrase, "AppStorePrivacyLabels", failures)

    for phrase in [
        "Docs/Architecture/Runbooks/AppStorePrivacyLabels.md",
        "No Data Collected",
        "Conservative support disclosure",
        "No live Supabase",
        "No live PostHog",
        "No APNs",
    ]:
        require_text(worksheet, phrase, "AppStorePrivacyWorksheet", failures)

    for phrase in [
        "Draft privacy-label posture",
        "no live Supabase production collection",
        "no live PostHog production analytics",
        "no push notifications/device-token collection",
        "Current local-only saves are not developer collection",
    ]:
        require_text(inventory, phrase, "PrivacyDataInventory", failures)

    for phrase in [
        "App Privacy Labels",
        "AppStorePrivacyLabels.md",
        "Blocked",
    ]:
        require_text(compliance, phrase, "AppStoreComplianceMatrix", failures)

    for phrase in [
        "Privacy Label Draft",
        "AppStorePrivacyLabels.md",
        "No live Supabase/PostHog",
    ]:
        require_text(packet, phrase, "AppStoreSubmissionPacket", failures)

    require_text(preflight, "scripts/savi-appstore-privacy-labels-check.py", "savi-preflight.sh", failures)
    require_text(
        safety_scan,
        "Docs/Architecture/Runbooks/AppStorePrivacyLabels.md",
        "savi-safety-scan.sh",
        failures,
    )
    require_text(cto, "AppStorePrivacyLabels.md", "CTOHandoffIndex", failures)
    require_text(architecture, "Runbooks/AppStorePrivacyLabels.md", "Architecture README", failures)

    if failures:
        print("\nSAVI App Store privacy labels check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI App Store privacy labels check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI App Store privacy labels check failed: {exc}")
        raise SystemExit(1)
