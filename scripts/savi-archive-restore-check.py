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

    print("== SAVI archive export/restore QA check ==")

    runbook = read("Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md")
    production = read("Docs/ProductionReadiness.md")
    readiness = read("Docs/TestFlightReadiness.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    governance = read("Docs/Architecture/Runbooks/ReleaseGovernance.md")
    status = read("Docs/Architecture/Runbooks/StatusReports.md")
    preflight = read("scripts/savi-preflight.sh")
    safety_scan = read("scripts/savi-safety-scan.sh")
    cto = read("Docs/Architecture/CTOHandoffIndex.md")
    architecture = read("Docs/Architecture/README.md")
    archive_core = read("SAVI/Core/SaviArchive.swift")
    savi_core = read("SAVI/Core/SaviCore.swift")
    profile = read("SAVI/Views/Profile/ProfileAndFriends.swift")
    root = read("SAVI/Views/Root/NativeSaviRootView.swift")

    for phrase in [
        "SAVI Archive Export And Restore QA",
        "scripts/savi-archive-restore-check.py",
        "Archive export/restore is SAVI's safety rope",
        "Do not ask testers to send real SAVI archives",
        "Full local archive export is the supported backup path",
        "iCloud backup is paused/no-op in Release",
        "Release `SAVI` / `com.altatecrd.savi`",
        "Export Test Matrix",
        "Restore Test Matrix",
        "Profile > Backup > Export full archive",
        "preparing/loading state appears",
        "iOS share/file sheet opens",
        "Compact JSON backup export",
        "fresh install",
        "Restore invalid file",
        "Restore is never one tap",
        "Preview explains item/folder counts",
        "Private Vault",
        "restore does not publish public links",
        "Supabase",
        "PostHog",
        "CloudKit",
        "Failure Triage",
        "export appears to do nothing",
        "Block wider TestFlight",
        "SAVI/Core/SaviArchive.swift",
    ]:
        require_text(runbook, phrase, "ArchiveExportRestoreQA", failures)

    for phrase in [
        "Full archive export warns that private/locked content may be included",
        "Restore/import does not publish social or public data without explicit user action",
        "Backup/export/restore",
        "Archive export and restore gate",
        "fresh-install restore",
    ]:
        require_text(production, phrase, "ProductionReadiness", failures)

    for phrase in [
        "archive export/import",
        "Archive export/restore QA",
        "SAVI Archive Export And Restore QA",
    ]:
        require_text(readiness, phrase, "TestFlightReadiness", failures)

    for phrase in [
        "Export a full local archive",
        "full archive export/import",
        "Archive export/restore QA",
    ]:
        require_text(packet, phrase, "AppStoreSubmissionPacket", failures)

    for phrase in [
        "Archive export/restore QA",
        "scripts/savi-archive-restore-check.py",
    ]:
        require_text(governance, phrase, "ReleaseGovernance", failures)
        require_text(status, phrase, "StatusReports", failures)

    for label, text, phrases in [
        (
            "SaviArchive.swift",
            archive_core,
            [
                "SaviArchiveExporter",
                "savi-full-archive",
                "SaviArchiveImporter",
                ".saviarchive",
                "manifest.json",
                "library.json",
            ],
        ),
        (
            "SaviCore.swift",
            savi_core,
            [
                "archiveExportStatus",
                "archiveShareFileURL",
                "prepareFullArchiveForSharing",
                "restorePendingBackupImport",
                "backupDocument",
            ],
        ),
        (
            "ProfileAndFriends.swift",
            profile,
            [
                "Export full archive",
                "Restore archive",
                "Export compact JSON backup",
                "fileExporter",
            ],
        ),
        (
            "NativeSaviRootView.swift",
            root,
            [
                "fileImporter",
                "pendingBackupPreview",
                "restorePendingBackupImport",
                "ArchiveExportLoadingScreen",
            ],
        ),
    ]:
        for phrase in phrases:
            require_text(text, phrase, label, failures)

    require_text(preflight, "scripts/savi-archive-restore-check.py", "savi-preflight.sh", failures)
    require_text(
        safety_scan,
        "Docs/Architecture/Runbooks/ArchiveExportRestoreQA.md",
        "savi-safety-scan.sh",
        failures,
    )
    require_text(cto, "ArchiveExportRestoreQA.md", "CTOHandoffIndex", failures)
    require_text(architecture, "Runbooks/ArchiveExportRestoreQA.md", "Architecture README", failures)

    if failures:
        print("\nSAVI archive export/restore QA check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI archive export/restore QA check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI archive export/restore QA check failed: {exc}")
        raise SystemExit(1)
