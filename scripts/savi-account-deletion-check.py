#!/usr/bin/env python3
from __future__ import annotations

import re
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


def require_regex(text: str, pattern: str, label: str, failures: list[str]) -> None:
    if not re.search(pattern, text, flags=re.IGNORECASE | re.DOTALL):
        failures.append(f"{label}: missing pattern `{pattern}`")


def main() -> int:
    failures: list[str] = []

    print("== SAVI account deletion readiness check ==")

    runbook = read("Docs/Backend/AccountDeletionRunbook.md")
    openapi = read("Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml")
    schema = read("Docs/Backend/Supabase/social_v1_schema.sql")
    rls_plan = read("Docs/Backend/Supabase/rls_test_plan.sql")
    data_deletion = read("Docs/PublicSite/data-deletion.md")
    api_contract = read("Docs/Architecture/APIContract.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    social_plan = read("Docs/Architecture/SocialV1ImplementationPlan.md")
    security = read("Docs/Architecture/SecurityAndPrivacy.md")

    for phrase in [
        "Current Release",
        "Future Account Contract",
        "`DELETE /me/account`",
        "Sign in with Apple credential revocation",
        "Service-role keys stay server-side",
        "Private on-device library content remains controlled by the local app",
        "Data Coverage",
        "Test Checklist",
        "Do not delete accounts directly from the consumer app with service-role keys",
    ]:
        require(runbook, phrase, "AccountDeletionRunbook", failures)

    for phrase in [
        "/me/account:",
        "delete:",
        "Delete current account and social data",
        "Sign in with Apple credentials",
        "delete/cascade user",
        "Private",
        "on-device library data remains controlled by the client/local archive",
    ]:
        require(openapi, phrase, "Social OpenAPI", failures)

    cascade_patterns = [
        r"profiles\s*\([\s\S]*references auth\.users\(id\) on delete cascade",
        r"follows\s*\([\s\S]*follower_id uuid .*references auth\.users\(id\) on delete cascade",
        r"follows\s*\([\s\S]*followee_id uuid .*references auth\.users\(id\) on delete cascade",
        r"public_links\s*\([\s\S]*owner_id uuid .*references auth\.users\(id\) on delete cascade",
        r"link_likes\s*\([\s\S]*user_id uuid .*references auth\.users\(id\) on delete cascade",
        r"reports\s*\([\s\S]*reporter_id uuid .*references auth\.users\(id\) on delete cascade",
        r"blocks\s*\([\s\S]*blocker_id uuid .*references auth\.users\(id\) on delete cascade",
        r"blocks\s*\([\s\S]*blocked_id uuid .*references auth\.users\(id\) on delete cascade",
    ]
    for pattern in cascade_patterns:
        require_regex(schema, pattern, "Supabase schema cascade", failures)

    for phrase in [
        "Account deletion should cascade profile, follows, public links, likes",
        "delete alice auth user",
        "public links, likes, reports, and blocks should be removed by cascade",
    ]:
        require(rls_plan, phrase, "RLS test plan", failures)

    for phrase in [
        "This page is required before account-based features launch.",
        "in-app way to delete your account",
        "profile",
        "public links",
        "account-linked sync records",
    ]:
        require(data_deletion, phrase, "Public data-deletion page", failures)

    for label, text in [
        ("APIContract", api_contract),
        ("AppStoreComplianceMatrix", compliance),
        ("SocialV1ImplementationPlan", social_plan),
        ("SecurityAndPrivacy", security),
    ]:
        for phrase in [
            "account deletion",
            "Sign in with Apple",
        ]:
            require(text, phrase, label, failures)

    if failures:
        print("SAVI account deletion readiness check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("OK: account deletion runbook, OpenAPI route, Supabase cascades, docs, and public copy are aligned")
    print("SAVI account deletion readiness check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI account deletion readiness check failed: {exc}")
        sys.exit(1)
