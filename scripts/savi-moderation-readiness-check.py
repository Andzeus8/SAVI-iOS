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

    workflow = read("Docs/Backend/AdminModerationWorkflow.md")
    admin_openapi = read("Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml")
    social_checklist = read("Docs/Backend/SocialSafetyChecklist.md")
    backend_arch = read("Docs/Architecture/BackendArchitecture.md")
    desktop_roadmap = read("Docs/Architecture/DesktopAndFounderHubRoadmap.md")
    safety_scan = read("scripts/savi-safety-scan.sh")

    print("== SAVI moderation readiness check ==")

    workflow_phrases = [
        "protected admin surface only",
        "reported public web links",
        "reported profiles",
        "public-link hide and unhide actions",
        "moderation audit logging",
        "must never be stored in source control or shipped in iOS",
        "Reports use exactly these states",
        "`open`",
        "`reviewing`",
        "`actioned`",
        "`dismissed`",
        "The queue must not display private notes, screenshots, PDFs, vault items",
        "External social stays hidden until all of this is true",
    ]
    for phrase in workflow_phrases:
        require(workflow, phrase, "AdminModerationWorkflow", failures)

    admin_routes = [
        "/admin/moderation/reports:",
        "/admin/moderation/reports/{id}/status:",
        "/admin/moderation/public-links/{id}/hide:",
        "/admin/moderation/public-links/{id}/unhide:",
        "/admin/moderation/audit-log:",
    ]
    for route in admin_routes:
        require(admin_openapi, route, "Admin OpenAPI", failures)

    admin_phrases = [
        "adminBearerAuth",
        "consumer iPhone app or share extension",
        "enum: [open, reviewing, actioned, dismissed]",
        "hide_public_link",
        "unhide_public_link",
        "Public web URL only. Never private file or vault content.",
    ]
    for phrase in admin_phrases:
        require(admin_openapi, phrase, "Admin OpenAPI", failures)

    checklist_phrases = [
        "protected admin moderation queue",
        "moderation audit log",
        "Docs/Backend/AdminModerationWorkflow.md",
        "Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml",
    ]
    for phrase in checklist_phrases:
        require(social_checklist, phrase, "SocialSafetyChecklist", failures)

    architecture_phrases = [
        "public-link hide/unhide actions",
        "moderation audit log",
        "Docs/Backend/AdminModerationWorkflow.md",
        "Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml",
    ]
    for phrase in architecture_phrases:
        require(backend_arch, phrase, "BackendArchitecture", failures)
        require(desktop_roadmap, phrase, "DesktopAndFounderHubRoadmap", failures)

    safety_phrases = [
        "Founder Hub|SaviFounder|PostHog Query",
        "Docs/Backend/AdminModerationWorkflow.md",
        "Docs/Backend/OpenAPI/savi-admin-v1.openapi.yaml",
    ]
    for phrase in safety_phrases:
        require(safety_scan, phrase, "savi-safety-scan.sh", failures)

    if failures:
        print("SAVI moderation readiness check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("OK: protected moderation workflow, admin API draft, docs, and safety front doors are aligned")
    print("SAVI moderation readiness check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI moderation readiness check failed: {exc}")
        sys.exit(1)
