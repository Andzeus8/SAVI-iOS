#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Missing required file: {path}")
    return target.read_text(encoding="utf-8")


def load_manifest(path: str) -> dict:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Missing privacy manifest: {path}")
    with target.open("rb") as handle:
        return plistlib.load(handle)


def accessed_api_map(manifest: dict) -> dict[str, set[str]]:
    entries = manifest.get("NSPrivacyAccessedAPITypes", [])
    result: dict[str, set[str]] = {}
    for entry in entries:
        category = entry.get("NSPrivacyAccessedAPIType")
        reasons = set(entry.get("NSPrivacyAccessedAPITypeReasons", []))
        if category:
            result[category] = reasons
    return result


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def require_reason(
    api_map: dict[str, set[str]],
    category: str,
    reason: str,
    label: str,
    failures: list[str],
) -> None:
    reasons = api_map.get(category, set())
    require(
        reason in reasons,
        f"{label} declares {category} / {reason}",
        failures,
    )


def main() -> int:
    failures: list[str] = []

    print("== SAVI privacy manifest check ==")

    app_manifest = load_manifest("SAVI/PrivacyInfo.xcprivacy")
    share_manifest = load_manifest("SAVIShareExtension/PrivacyInfo.xcprivacy")
    app_api = accessed_api_map(app_manifest)
    share_api = accessed_api_map(share_manifest)

    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    audit = read("Docs/Architecture/PrivacyManifestAudit.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    app_source = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for folder in ["SAVI", "Shared"]
        for path in (ROOT / folder).rglob("*.swift")
    )
    share_source = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for folder in ["SAVIShareExtension", "Shared"]
        for path in (ROOT / folder).rglob("*.swift")
    )

    for label, manifest in [
        ("SAVI", app_manifest),
        ("SAVIShareExtension", share_manifest),
    ]:
        require(manifest.get("NSPrivacyTracking") is False, f"{label} tracking is false", failures)
        require(
            manifest.get("NSPrivacyTrackingDomains") == [],
            f"{label} tracking domains are empty",
            failures,
        )

    require_reason(
        app_api,
        "NSPrivacyAccessedAPICategoryFileTimestamp",
        "C617.1",
        "SAVI",
        failures,
    )
    require_reason(
        share_api,
        "NSPrivacyAccessedAPICategoryFileTimestamp",
        "C617.1",
        "SAVIShareExtension",
        failures,
    )

    if "UserDefaults" in app_source or "@AppStorage" in app_source:
        require_reason(
            app_api,
            "NSPrivacyAccessedAPICategoryUserDefaults",
            "CA92.1",
            "SAVI",
            failures,
        )

    if "UserDefaults" in share_source or "@AppStorage" in share_source:
        require_reason(
            share_api,
            "NSPrivacyAccessedAPICategoryUserDefaults",
            "CA92.1",
            "SAVIShareExtension",
            failures,
        )

    for token in [
        "PrivacyInfo.xcprivacy in Resources",
        "SAVI/PrivacyInfo.xcprivacy",
        "SAVIShareExtension/PrivacyInfo.xcprivacy",
    ]:
        require(token.split("/", 1)[-1] in pbxproj, f"project references {token}", failures)

    for phrase in [
        "NSPrivacyAccessedAPICategoryFileTimestamp",
        "NSPrivacyAccessedAPICategoryUserDefaults",
        "C617.1",
        "CA92.1",
        "NSPrivacyTracking = false",
        "scripts/savi-privacy-manifest-check.py",
    ]:
        require(phrase in audit, f"privacy manifest audit documents {phrase}", failures)

    for label, text in [
        ("AppStoreComplianceMatrix", compliance),
        ("AppStoreSubmissionPacket", packet),
    ]:
        require(
            "PrivacyManifestAudit.md" in text,
            f"{label} references PrivacyManifestAudit.md",
            failures,
        )

    if failures:
        print("\nSAVI privacy manifest check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI privacy manifest check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI privacy manifest check failed: {exc}")
        sys.exit(1)
