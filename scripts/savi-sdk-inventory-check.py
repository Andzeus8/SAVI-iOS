#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

IGNORED_PARTS = {
    ".git",
    ".DerivedData",
    "DerivedData",
    "build",
    ".build",
}

APPLE_IMPORTS = {
    "AppKit",
    "AuthenticationServices",
    "Charts",
    "CloudKit",
    "Combine",
    "CoreGraphics",
    "CoreImage",
    "Darwin",
    "Foundation",
    "FoundationModels",
    "ImageIO",
    "LinkPresentation",
    "LocalAuthentication",
    "MobileCoreServices",
    "Network",
    "PhotosUI",
    "QuickLook",
    "SafariServices",
    "Security",
    "SwiftUI",
    "UIKit",
    "UniformTypeIdentifiers",
    "Vision",
    "WebKit",
}

KNOWN_THIRD_PARTY_IMPORTS = {
    "Supabase",
    "PostHog",
    "Sentry",
    "Firebase",
    "FirebaseAnalytics",
    "FirebaseCrashlytics",
    "Amplitude",
    "Mixpanel",
    "RevenueCat",
    "Purchases",
    "GoogleSignIn",
    "GoogleMobileAds",
    "FacebookCore",
    "FBSDKCoreKit",
    "Alamofire",
    "Kingfisher",
    "SDWebImage",
}


def is_ignored(path: Path) -> bool:
    return any(part in IGNORED_PARTS for part in path.relative_to(ROOT).parts)


def read(path: str) -> str:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Missing required file: {path}")
    return target.read_text(encoding="utf-8")


def all_repo_files() -> list[Path]:
    return [path for path in ROOT.rglob("*") if path.is_file() and not is_ignored(path)]


def swift_files() -> list[Path]:
    roots = ["SAVI", "SAVIShareExtension", "Shared", "SAVIMac"]
    files: list[Path] = []
    for root in roots:
        base = ROOT / root
        if base.exists():
            files.extend(path for path in base.rglob("*.swift") if path.is_file())
    return sorted(files)


def swift_imports() -> dict[str, list[str]]:
    imports: dict[str, list[str]] = {}
    pattern = re.compile(r"^\s*import\s+([A-Za-z_][A-Za-z0-9_]*)", re.MULTILINE)
    for path in swift_files():
        text = path.read_text(encoding="utf-8", errors="ignore")
        rel = str(path.relative_to(ROOT))
        for module in pattern.findall(text):
            imports.setdefault(module, []).append(rel)
    return imports


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    warnings: list[str] = []

    print("== SAVI third-party SDK inventory check ==")

    repo_files = all_repo_files()
    forbidden_names = {"Package.swift", "Package.resolved", "Podfile", "Podfile.lock", "Cartfile", "Cartfile.resolved"}
    package_files = [path for path in repo_files if path.name in forbidden_names]
    vendor_frameworks = [
        path
        for path in repo_files
        if path.suffix in {".xcframework", ".framework"} or path.name.endswith(".framework")
    ]

    require(not package_files, "no SwiftPM/CocoaPods/Carthage package files checked in", failures)
    if package_files:
        for path in package_files:
            print(f"  package file: {path.relative_to(ROOT)}")

    require(not vendor_frameworks, "no checked-in vendor frameworks/xcframeworks", failures)
    if vendor_frameworks:
        for path in vendor_frameworks:
            print(f"  vendor framework: {path.relative_to(ROOT)}")

    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    for token in ["XCRemoteSwiftPackageReference", "XCSwiftPackageProductDependency", "packageProductDependencies"]:
        require(token not in pbxproj, f"project has no {token}", failures)

    imports = swift_imports()
    third_party_imports = sorted(KNOWN_THIRD_PARTY_IMPORTS.intersection(imports))
    unknown_imports = sorted(module for module in imports if module not in APPLE_IMPORTS)

    require(not third_party_imports, "no known third-party SDK imports in Swift source", failures)
    if third_party_imports:
        for module in third_party_imports:
            print(f"  {module}: {', '.join(imports[module])}")

    require(not unknown_imports, "all Swift imports are in Apple/system allowlist", failures)
    if unknown_imports:
        for module in unknown_imports:
            print(f"  {module}: {', '.join(imports[module])}")

    inventory = read("Docs/Architecture/ThirdPartySDKInventory.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    privacy_inventory = read("Docs/Architecture/PrivacyDataInventory.md")
    safety_scan = read("scripts/savi-safety-scan.sh")

    for phrase in [
        "no Swift Package Manager dependency checkout",
        "no live Supabase iOS SDK",
        "no live PostHog iOS SDK",
        "Current Apple/System Frameworks Seen",
        "Future SDK Review Gate",
        "scripts/savi-sdk-inventory-check.py",
        "Apple third-party SDK requirements",
    ]:
        require(phrase in inventory, f"SDK inventory documents {phrase}", failures)

    for phrase in [
        "Third-Party SDKs",
        "ThirdPartySDKInventory.md",
    ]:
        require(phrase in compliance, f"compliance matrix references {phrase}", failures)

    require("third-party SDK" in privacy_inventory, "privacy inventory references third-party SDK review", failures)
    require("Docs/Architecture/ThirdPartySDKInventory.md" in safety_scan, "safety scan front door includes SDK inventory", failures)

    if warnings:
        print("\nWarnings:")
        for warning in warnings:
            print(f"- {warning}")

    if failures:
        print("\nSAVI third-party SDK inventory check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: Swift imports are Apple/system only: {', '.join(sorted(imports))}")
    print("SAVI third-party SDK inventory check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI third-party SDK inventory check failed: {exc}")
        sys.exit(1)
