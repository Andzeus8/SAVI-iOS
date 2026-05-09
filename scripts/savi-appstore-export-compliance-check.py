#!/usr/bin/env python3
from __future__ import annotations

import plistlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


CRYPTO_PATTERNS = [
    r"^\s*import\s+CryptoKit\b",
    r"^\s*import\s+CommonCrypto\b",
    r"^\s*import\s+CryptoSwift\b",
    r"OpenSSL",
    r"BoringSSL",
    r"libsodium",
    r"\bCCCrypt\b",
    r"\bSymmetricKey\b",
    r"\bCryptoKit\b",
    r"\bChaChaPoly\b",
    r"\bAES\.GCM\b",
    r"\bCurve25519\b",
]


def read(path: str) -> str:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Missing required file: {path}")
    return target.read_text(encoding="utf-8")


def load_plist(path: str) -> dict:
    target = ROOT / path
    if not target.exists():
        raise AssertionError(f"Missing required plist: {path}")
    with target.open("rb") as handle:
        return plistlib.load(handle)


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def require_text(text: str, needle: str, label: str, failures: list[str]) -> None:
    require(needle in text, f"{label} contains `{needle}`", failures)


def swift_sources() -> list[Path]:
    roots = ["SAVI", "SAVIShareExtension", "Shared", "SAVIMac"]
    paths: list[Path] = []
    for root in roots:
        folder = ROOT / root
        if folder.exists():
            paths.extend(sorted(folder.rglob("*.swift")))
    return paths


def current_build() -> str:
    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    matches = sorted(set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", pbxproj)))
    if not matches:
        raise AssertionError("Could not detect CURRENT_PROJECT_VERSION")
    return matches[-1]


def main() -> int:
    failures: list[str] = []

    print("== SAVI App Store export compliance check ==")

    app_info = load_plist("SAVI/Info.plist")
    share_info = load_plist("SAVIShareExtension/Info.plist")
    runbook = read("Docs/Architecture/Runbooks/AppStoreExportCompliance.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    metadata = read("Docs/Architecture/Runbooks/AppStoreConnectMetadata.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    production = read("Docs/ProductionReadiness.md")
    readiness = read("Docs/TestFlightReadiness.md")
    preflight = read("scripts/savi-preflight.sh")
    safety_scan = read("scripts/savi-safety-scan.sh")
    status = read("Docs/Architecture/Runbooks/StatusReports.md")
    status_script = read("scripts/savi-status-report.py")
    cto = read("Docs/Architecture/CTOHandoffIndex.md")
    architecture = read("Docs/Architecture/README.md")

    require(
        app_info.get("ITSAppUsesNonExemptEncryption") is False,
        "SAVI/Info.plist has ITSAppUsesNonExemptEncryption = false",
        failures,
    )
    require(
        share_info.get("ITSAppUsesNonExemptEncryption") is False,
        "SAVIShareExtension/Info.plist has ITSAppUsesNonExemptEncryption = false",
        failures,
    )
    require(
        "ITSEncryptionExportComplianceCode" not in app_info,
        "SAVI/Info.plist does not include ITSEncryptionExportComplianceCode while key is false",
        failures,
    )
    require(
        "ITSEncryptionExportComplianceCode" not in share_info,
        "SAVIShareExtension/Info.plist does not include ITSEncryptionExportComplianceCode while key is false",
        failures,
    )

    crypto_hits: list[str] = []
    for path in swift_sources():
        text = path.read_text(encoding="utf-8", errors="ignore")
        for pattern in CRYPTO_PATTERNS:
            if re.search(pattern, text, flags=re.MULTILINE):
                crypto_hits.append(f"{path.relative_to(ROOT)} matches {pattern}")
    require(not crypto_hits, "Swift sources do not contain known custom/non-Apple crypto patterns", failures)
    for hit in crypto_hits[:20]:
        print(f"  HIT: {hit}")

    for phrase in [
        "SAVI App Store Export Compliance Packet",
        "scripts/savi-appstore-export-compliance-check.py",
        "not legal advice",
        "Apple: [Overview of export compliance]",
        "Apple: [Export compliance documentation for encryption]",
        "ITSAppUsesNonExemptEncryption",
        "Current Submitted-Build Facts",
        "com.altatecrd.savi",
        "com.altatecrd.savi.ShareExtension",
        f"1.0 ({current_build()})",
        "Apple/system services",
        "URLSession",
        "HTTPS/TLS",
        "LocalAuthentication",
        "Security",
        "CloudKit",
        "no linked third-party SDKs",
        "no custom/proprietary encryption",
        "Founder/legal final answer required",
        "US Commodity Classification Automated Tracking System (CCATS)",
        "French encryption declaration",
        "Future Changes That Trigger Re-review",
        "CryptoKit",
        "CommonCrypto",
        "OpenSSL",
        "libsodium",
        "Supabase/PostHog",
        "Final Founder Checklist",
    ]:
        require_text(runbook, phrase, "AppStoreExportCompliance", failures)

    for label, text, phrases in [
        (
            "AppStoreSubmissionPacket",
            packet,
            [
                "Export Compliance Packet",
                "AppStoreExportCompliance.md",
                "scripts/savi-appstore-export-compliance-check.py",
                "ITSAppUsesNonExemptEncryption = NO",
            ],
        ),
        (
            "AppStoreConnectMetadata",
            metadata,
            [
                "AppStoreExportCompliance.md",
                "scripts/savi-appstore-export-compliance-check.py",
                "Founder/legal must confirm export compliance",
            ],
        ),
        (
            "AppStoreComplianceMatrix",
            compliance,
            [
                "Export Compliance",
                "AppStoreExportCompliance.md",
                "Founder/legal",
            ],
        ),
        (
            "ProductionReadiness",
            production,
            [
                "App Store Connect export-compliance answer",
                "ITSAppUsesNonExemptEncryption = NO",
            ],
        ),
        (
            "TestFlightReadiness",
            readiness,
            [
                "ITSAppUsesNonExemptEncryption = NO",
                "export compliance",
            ],
        ),
    ]:
        for phrase in phrases:
            require_text(text, phrase, label, failures)

    require_text(preflight, "scripts/savi-appstore-export-compliance-check.py", "savi-preflight.sh", failures)
    require_text(
        safety_scan,
        "Docs/Architecture/Runbooks/AppStoreExportCompliance.md",
        "savi-safety-scan.sh",
        failures,
    )
    require_text(status, "App Store export compliance", "StatusReports", failures)
    require_text(status_script, "scripts/savi-appstore-export-compliance-check.py", "savi-status-report.py", failures)
    require_text(cto, "AppStoreExportCompliance.md", "CTOHandoffIndex", failures)
    require_text(architecture, "Runbooks/AppStoreExportCompliance.md", "Architecture README", failures)

    if failures:
        print("\nSAVI App Store export compliance check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI App Store export compliance check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI App Store export compliance check failed: {exc}")
        raise SystemExit(1)
