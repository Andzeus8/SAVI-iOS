#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load_plist(path: str) -> dict:
    with (ROOT / path).open("rb") as handle:
        return plistlib.load(handle)


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def add_warning(message: str, warnings: list[str]) -> None:
    print(f"WARN: {message}")
    warnings.append(message)


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    print("== SAVI App Store readiness check ==")

    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    app_info = load_plist("SAVI/Info.plist")
    share_info = load_plist("SAVIShareExtension/Info.plist")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    readiness = read("Docs/TestFlightReadiness.md")
    core = read("SAVI/Core/SaviCore.swift")

    for path in [
        "Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md",
        "Docs/Architecture/Runbooks/AppStoreAgeRating.md",
        "Docs/Architecture/Runbooks/AppStoreExportCompliance.md",
        "Docs/Architecture/AppStoreComplianceMatrix.md",
        "Docs/TestFlightReadiness.md",
        "Docs/PublicSite/privacy.md",
        "Docs/PublicSite/support.md",
        "Docs/PublicSite/terms.md",
        "Docs/PublicSite/data-deletion.md",
        "Docs/PublicSite/community-guidelines.md",
    ]:
        require((ROOT / path).exists(), f"required submission doc exists: {path}", failures)

    require(
        "PRODUCT_BUNDLE_IDENTIFIER = com.altatecrd.savi;" in pbxproj,
        "Release app bundle ID is com.altatecrd.savi",
        failures,
    )
    require(
        "PRODUCT_BUNDLE_IDENTIFIER = com.altatecrd.savi.ShareExtension;" in pbxproj,
        "Release share extension bundle ID is com.altatecrd.savi.ShareExtension",
        failures,
    )
    require(
        "PRODUCT_BUNDLE_IDENTIFIER = com.altatecrd.savi.personaldebug;" in pbxproj,
        "Debug app bundle ID remains personaldebug",
        failures,
    )
    require(
        "SUPPORTED_PLATFORMS = \"iphoneos iphonesimulator\";" in pbxproj
        and "TARGETED_DEVICE_FAMILY = 1;" in pbxproj,
        "iOS targets remain iPhone/simulator focused",
        failures,
    )

    build_match = re.search(r"CURRENT_PROJECT_VERSION = ([0-9]+);", pbxproj)
    if build_match:
        current_build = build_match.group(1)
        print(f"OK: project build number detected: {current_build}")
        if (
            f"Build number: `{current_build}`" in readiness
            or f"Current local project build number: `{current_build}`" in readiness
            or f"build `{current_build}`" in readiness
        ):
            print("OK: TestFlight readiness doc mentions current build number")
        else:
            add_warning(
                f"TestFlight readiness prose may be stale; current project build is {current_build}",
                warnings,
            )
    else:
        require(False, "could not detect CURRENT_PROJECT_VERSION", failures)

    require(
        app_info.get("ITSAppUsesNonExemptEncryption") is False,
        "app Info.plist has ITSAppUsesNonExemptEncryption = false",
        failures,
    )
    require(
        share_info.get("ITSAppUsesNonExemptEncryption") is False,
        "share extension Info.plist has ITSAppUsesNonExemptEncryption = false",
        failures,
    )
    require("NSFaceIDUsageDescription" in app_info, "Face ID usage description is present", failures)
    require(
        share_info.get("NSExtension", {}).get("NSExtensionPointIdentifier")
        == "com.apple.share-services",
        "share extension point is com.apple.share-services",
        failures,
    )

    app_entitlements = read("SAVI/SAVI.entitlements")
    share_entitlements = read("SAVIShareExtension/SAVIShareExtension.entitlements")
    require(
        "group.com.altatecrd.savi.shared" in app_entitlements
        and "group.com.altatecrd.savi.shared" in share_entitlements,
        "Release app and share extension share the production App Group",
        failures,
    )

    require(
        "#if DEBUG" in core
        and "static let socialFeaturesEnabled = true" in core
        and "static let socialFeaturesEnabled = false" in core,
        "Release social gate remains disabled outside DEBUG",
        failures,
    )

    for phrase in [
        "App Store Connect Fields",
        "TestFlight Beta Description",
        "What To Test",
        "App Review Notes",
        "Age Rating Packet",
        "Privacy Label Draft",
        "AppStoreExportCompliance.md",
        "Export Compliance Draft",
        "Social/UGC Release Gate",
        "Final Human Checklist",
    ]:
        require(phrase in packet, f"submission packet includes {phrase}", failures)

    for phrase in [
        "Privacy Policy",
        "App Privacy Labels",
        "Age Rating",
        "Export Compliance",
        "Social / UGC",
        "Account Deletion",
        "App Review Notes",
    ]:
        require(phrase in compliance, f"compliance matrix tracks {phrase}", failures)

    public_todos = sorted(
        str(path.relative_to(ROOT))
        for path in (ROOT / "Docs/PublicSite").glob("*.md")
        if "TODO" in path.read_text(encoding="utf-8")
    )
    if public_todos:
        add_warning(
            "public-site templates still have TODO placeholders: " + ", ".join(public_todos),
            warnings,
        )
    else:
        print("OK: public-site templates have no TODO placeholders")

    if "1080solutionsA@gmail.com" in readiness or "1080solutionsA@gmail.com" in packet:
        print("OK: beta feedback/support email is documented")
    else:
        add_warning("no beta feedback/support email found in readiness packet", warnings)

    if warnings:
        print("\nWarnings:")
        for item in warnings:
            print(f"- {item}")

    if failures:
        print("\nSAVI App Store readiness check failed:")
        for item in failures:
            print(f"- {item}")
        return 1

    print("SAVI App Store readiness check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
