#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OPENAPI_PATH = "Docs/Backend/OpenAPI/savi-social-v1.openapi.yaml"
SCHEMA_PATH = "Docs/Backend/Supabase/social_v1_schema.sql"
SOCIAL_PLAN_PATH = "Docs/Architecture/SocialV1ImplementationPlan.md"
API_CONTRACT_PATH = "Docs/Architecture/APIContract.md"

REQUIRED_ROUTES = [
    "/me/account:",
    "/me/profile:",
    "/profiles/{username}:",
    "/follows/{username}:",
    "/public-links:",
    "/public-links/{id}:",
    "/feed/friends:",
    "/public-links/{id}/like:",
    "/public-links/{id}/save:",
    "/reports:",
    "/blocks/{username}:",
]
REQUIRED_SCHEMAS = [
    "Error:",
    "Profile:",
    "ProfileUpdate:",
    "PublicLink:",
    "PublishPublicLinkRequest:",
    "ReportRequest:",
]
EXCLUDED_PUBLIC_CONTENT = [
    "Files",
    "PDFs",
    "screenshots",
    "images",
    "Private Vault",
    "private notes",
]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def fail_if(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        failures.append(message)


def enum_values_for(name: str, text: str) -> set[str]:
    pattern = re.compile(rf"{re.escape(name)}:\s*\n(?P<body>.*?)(?:\n\s{{4}}[A-Za-z][A-Za-z0-9]+:|\Z)", re.DOTALL)
    match = pattern.search(text)
    if not match:
        return set()
    enum_match = re.search(r"enum:\s*\[([^\]]+)\]", match.group("body"))
    if not enum_match:
        return set()
    return {value.strip() for value in enum_match.group(1).split(",")}


def supabase_public_link_types(schema: str) -> set[str]:
    match = re.search(r"item_type in \(([^)]+)\)", schema)
    if not match:
        return set()
    return {value.strip().strip("'") for value in match.group(1).split(",")}


def main() -> int:
    failures: list[str] = []
    openapi = read(OPENAPI_PATH)
    schema = read(SCHEMA_PATH)
    social_plan = read(SOCIAL_PLAN_PATH)
    api_contract = read(API_CONTRACT_PATH)

    print("== SAVI OpenAPI contract check ==")

    for route in REQUIRED_ROUTES:
        fail_if(route not in openapi, f"OpenAPI missing route {route}", failures)

    for schema_name in REQUIRED_SCHEMAS:
        fail_if(f"    {schema_name}" not in openapi, f"OpenAPI missing schema {schema_name}", failures)

    for phrase in [
        "bearerAuth:",
        "scheme: bearer",
        "bearerFormat: JWT",
        "Delete current account and social data",
        "revoke",
        "Sign in with Apple",
        "Self-follow and duplicate follow must be rejected",
        "Creates a private copy",
    ]:
        fail_if(phrase not in openapi, f"OpenAPI missing phrase `{phrase}`", failures)

    for phrase in EXCLUDED_PUBLIC_CONTENT:
        fail_if(phrase not in openapi, f"OpenAPI public-link exclusion missing `{phrase}`", failures)

    openapi_public_types = enum_values_for("itemType", openapi)
    schema_public_types = supabase_public_link_types(schema)
    fail_if(not openapi_public_types, "OpenAPI missing public itemType enum", failures)
    fail_if(
        openapi_public_types != schema_public_types,
        "OpenAPI public itemType enum does not match Supabase constraint: "
        f"{sorted(openapi_public_types)} vs {sorted(schema_public_types)}",
        failures,
    )

    forbidden_terms = ["public PDFs", "public screenshots", "private files", "Private Vault"]
    for phrase in forbidden_terms:
        fail_if(phrase not in social_plan, f"Social plan missing exclusion `{phrase}`", failures)

    for phrase in [
        "DELETE /me/account",
        "delete/cascade profile, follows, public links, likes, reports, and blocks",
        "delete account and social data",
    ]:
        fail_if(phrase not in api_contract, f"API contract missing account-deletion phrase `{phrase}`", failures)

    if failures:
        print("SAVI OpenAPI contract check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: {len(REQUIRED_ROUTES)} required Social V1 routes present")
    print(f"OK: public-link itemType enum matches Supabase: {', '.join(sorted(openapi_public_types))}")
    print("OK: account deletion, bearer auth, public-link exclusions, and report/block routes are documented")
    print("SAVI OpenAPI contract check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
