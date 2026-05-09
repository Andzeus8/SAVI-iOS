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

    print("== SAVI notification readiness check ==")

    runbook = read("Docs/Backend/NotificationRunbook.md")
    openapi = read("Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml")
    social_mobile = read("Docs/Architecture/SocialMobileUXAndNotifications.md")
    master = read("Docs/Architecture/MasterRoadmap.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    account_deletion = read("Docs/Backend/AccountDeletionRunbook.md")
    safety_scan = read("scripts/savi-safety-scan.sh")

    runbook_phrases = [
        "must not be enabled in Release/TestFlight",
        "current TestFlight app should not request push notification permission",
        "Allowed Notification Types",
        "Forbidden Notification Content",
        "Do not ask on first launch.",
        "Use APNs through a protected backend.",
        "Device-token records must not contain private item titles",
        "Account deletion and logout must delete or disable device-token records.",
        "Blocked users must not trigger social notifications to each other.",
        "APNs token",
    ]
    for phrase in runbook_phrases:
        require(runbook, phrase, "NotificationRunbook", failures)

    openapi_phrases = [
        "/me/device-tokens:",
        "/me/device-tokens/{id}:",
        "/me/notification-settings:",
        "DeviceTokenRegistration:",
        "NotificationSettings:",
        "Never include private",
        "file names, screenshots, vault content",
        "raw search queries",
    ]
    for phrase in openapi_phrases:
        require(openapi, phrase, "Social OpenAPI notification contract", failures)

    social_phrases = [
        "Ask permission only after the user understands the value.",
        "Provide in-app notification settings.",
        "Use APNs through a protected backend",
        "Private Vault content",
    ]
    for phrase in social_phrases:
        require(social_mobile, phrase, "SocialMobileUXAndNotifications", failures)

    for label, text in [
        ("MasterRoadmap", master),
        ("AppStoreComplianceMatrix", compliance),
    ]:
        for phrase in [
            "Notifications",
            "APNs",
            "privacy-safe",
        ]:
            require(text, phrase, label, failures)

    require(account_deletion, "device-token records", "AccountDeletionRunbook", failures)
    require(safety_scan, "Docs/Backend/NotificationRunbook.md", "savi-safety-scan.sh", failures)

    if failures:
        print("SAVI notification readiness check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("OK: notification/APNs runbook, OpenAPI contract, social UX, account deletion, and safety front doors are aligned")
    print("SAVI notification readiness check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI notification readiness check failed: {exc}")
        sys.exit(1)
