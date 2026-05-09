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


def require(text: str, needle: str, label: str, failures: list[str]) -> None:
    if needle not in text:
        failures.append(f"{label}: missing `{needle}`")


def main() -> int:
    failures: list[str] = []

    print("== SAVI privacy inventory check ==")

    inventory = read("Docs/Architecture/PrivacyDataInventory.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    analytics = read("Docs/Backend/AnalyticsEventCatalog.md")
    account_deletion = read("Docs/Backend/AccountDeletionRunbook.md")
    notifications = read("Docs/Backend/NotificationRunbook.md")
    security = read("Docs/Architecture/SecurityAndPrivacy.md")
    safety_scan = read("scripts/savi-safety-scan.sh")

    inventory_phrases = [
        "Current Private-Save Release",
        "Future Feature Inventory",
        "Data We Must Not Collect",
        "App Store Privacy Label Drafting Rules",
        "Update Triggers",
        "Submission Checklist",
        "no live Supabase production collection",
        "no live PostHog production analytics",
        "no push notifications/device-token collection",
        "Private Vault content",
        "raw search queries",
        "APNs tokens in analytics",
        "No autocapture",
        "session replay",
        "https://developer.apple.com/app-store/app-privacy-details/",
        "https://developer.apple.com/help/app-store-connect/reference/app-privacy/",
    ]
    for phrase in inventory_phrases:
        require(inventory, phrase, "PrivacyDataInventory", failures)

    for phrase in [
        "App Privacy Labels",
        "Match exact final data collection",
        "Docs/Architecture/PrivacyDataInventory.md",
    ]:
        require(compliance, phrase, "AppStoreComplianceMatrix", failures)

    for phrase in [
        "Privacy Label Draft",
        "Docs/Architecture/PrivacyDataInventory.md",
        "Re-audit the exact build",
    ]:
        require(packet, phrase, "AppStoreSubmissionPacket", failures)

    for label, text in [
        ("AnalyticsEventCatalog", analytics),
        ("AccountDeletionRunbook", account_deletion),
        ("NotificationRunbook", notifications),
        ("SecurityAndPrivacy", security),
    ]:
        for phrase in [
            "Private Vault",
            "raw clipboard",
        ]:
            require(text, phrase, label, failures)

    require(safety_scan, "Docs/Architecture/PrivacyDataInventory.md", "savi-safety-scan.sh", failures)

    if failures:
        print("SAVI privacy inventory check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("OK: privacy inventory, compliance matrix, submission packet, analytics, account deletion, notification, and safety docs are aligned")
    print("SAVI privacy inventory check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI privacy inventory check failed: {exc}")
        sys.exit(1)
