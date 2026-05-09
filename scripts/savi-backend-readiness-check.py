#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        print(f"OK: {message}")
    else:
        print(f"FAIL: {message}")
        failures.append(message)


def validate_json(path: str, failures: list[str]) -> None:
    try:
        json.loads(read(path))
        print(f"OK: valid JSON {path}")
    except Exception as exc:  # pragma: no cover - script output is the test surface
        print(f"FAIL: invalid JSON {path}: {exc}")
        failures.append(f"invalid JSON {path}")


def main() -> int:
    failures: list[str] = []

    print("== SAVI backend/social readiness check ==")

    for path in [
        "Docs/Backend/Schemas/savi-item.schema.json",
        "Docs/Backend/Schemas/public-link.schema.json",
        "Docs/Backend/Schemas/analytics-event.schema.json",
        "Docs/Backend/PostHog/dashboard-specs.json",
        "Docs/Backend/Fixtures/valid/savi-item-link.json",
        "Docs/Backend/Fixtures/valid/public-link-video.json",
        "Docs/Backend/Fixtures/valid/analytics-save-completed.json",
    ]:
        validate_json(path, failures)

    openapi = read("Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml")
    for token in [
        "/me/profile:",
        "/profiles/{username}:",
        "/follows/{username}:",
        "/public-links:",
        "/feed/friends:",
        "/reports:",
        "/blocks/{username}:",
        "bearerAuth:",
    ]:
        require(token in openapi, f"OpenAPI contains {token}", failures)

    schema = read("Docs/Backend/Supabase/social_v1_schema.sql")
    tables = ["profiles", "follows", "public_links", "link_likes", "reports", "blocks"]
    for table in tables:
        require(
            f"create table if not exists public.{table}" in schema,
            f"Supabase schema creates {table}",
            failures,
        )
        require(
            f"alter table public.{table} enable row level security" in schema,
            f"RLS enabled for {table}",
            failures,
        )

    for phrase in [
        "public_link_web_only",
        "public_link_types",
        "users manage their public links",
        "users create their own reports",
        "users manage their blocks",
    ]:
        require(phrase in schema, f"Supabase schema contains {phrase}", failures)

    core = read("SAVI/Core/SaviCore.swift")
    require(
        "#if DEBUG" in core
        and "static let socialFeaturesEnabled = true" in core
        and "#else" in core
        and "static let socialFeaturesEnabled = false" in core,
        "Release social gate is false outside DEBUG",
        failures,
    )

    social_doc = read("Docs/Architecture/SocialV1ImplementationPlan.md")
    for phrase in [
        "Release/TestFlight must keep social hidden",
        "explicit public web-link",
        "report",
        "block",
        "moderation",
        "account deletion",
        "Notifications Later",
    ]:
        require(phrase in social_doc, f"Social plan includes {phrase}", failures)

    notification_doc = read("Docs/Architecture/SocialMobileUXAndNotifications.md")
    for phrase in [
        "New follower",
        "Someone liked your public link",
        "Private Vault content",
        "Use APNs through a protected backend",
    ]:
        require(phrase in notification_doc, f"Notification plan includes {phrase}", failures)

    safety_script = read("scripts/savi-safety-scan.sh")
    require(
        "Founder Hub|SaviFounder|PostHog Query" in safety_script,
        "Safety scan checks founder/admin separation",
        failures,
    )

    if failures:
        print("\nSAVI backend/social readiness check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI backend/social readiness check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
