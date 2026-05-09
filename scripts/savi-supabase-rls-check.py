#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCHEMA_PATH = "Docs/Backend/Supabase/social_v1_schema.sql"
RLS_TEST_PLAN_PATH = "Docs/Backend/Supabase/rls_test_plan.sql"

TABLES = ["profiles", "follows", "public_links", "link_likes", "reports", "blocks"]
REQUIRED_POLICIES = {
    "profiles": [
        "profiles are visible to signed in users",
        "users edit their own profile",
    ],
    "follows": [
        "users can see their follow graph",
        "users manage their follows",
    ],
    "public_links": [
        "users see non-hidden public links",
        "users manage their public links",
    ],
    "link_likes": [
        "users see likes on visible links",
        "users manage their likes",
    ],
    "reports": [
        "users create their own reports",
        "users can read their own reports",
    ],
    "blocks": [
        "users manage their blocks",
    ],
}


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def policy_blocks(schema: str) -> list[dict[str, str]]:
    blocks: list[dict[str, str]] = []
    pattern = re.compile(
        r'create policy "([^"]+)"\s+on public\.([a-z_]+)\s+for\s+([a-z]+)\s+to\s+([a-z_]+)\s+(.*?);',
        flags=re.DOTALL | re.IGNORECASE,
    )
    for match in pattern.finditer(schema):
        blocks.append(
            {
                "name": match.group(1),
                "table": match.group(2),
                "operation": match.group(3).lower(),
                "role": match.group(4).lower(),
                "body": re.sub(r"\s+", " ", match.group(5).strip()).lower(),
            }
        )
    return blocks


def fail_if(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []
    schema = read(SCHEMA_PATH)
    test_plan = read(RLS_TEST_PLAN_PATH)
    test_plan_lower = test_plan.lower()
    policies = policy_blocks(schema)
    policy_names = {policy["name"] for policy in policies}

    print("== SAVI Supabase RLS check ==")

    for table in TABLES:
        fail_if(
            f"alter table public.{table} enable row level security" not in schema,
            f"RLS is not enabled for {table}",
            failures,
        )
        fail_if(
            f"create table if not exists public.{table}" not in schema,
            f"missing table definition for {table}",
            failures,
        )
        for policy_name in REQUIRED_POLICIES[table]:
            fail_if(policy_name not in policy_names, f"missing policy `{policy_name}`", failures)

    unexpected_roles = sorted({policy["role"] for policy in policies if policy["role"] != "authenticated"})
    if unexpected_roles:
        failures.append("policies use unexpected roles: " + ", ".join(unexpected_roles))

    broad_policies = [
        policy["name"]
        for policy in policies
        if "using (true)" in policy["body"]
        and policy["name"] != "profiles are visible to signed in users"
    ]
    if broad_policies:
        failures.append("unexpected broad using(true) policies: " + ", ".join(broad_policies))

    required_schema_phrases = [
        "constraint username_format",
        "constraint no_self_follow",
        "constraint public_link_web_only",
        "constraint public_link_types",
        "constraint report_target_present",
        "constraint report_status_allowed",
        "constraint no_self_block",
        "auth.uid() = id",
        "auth.uid() = follower_id",
        "auth.uid() = owner_id",
        "auth.uid() = user_id",
        "auth.uid() = reporter_id",
        "auth.uid() = blocker_id",
        "url ~ '^https?://'",
        "item_type in ('link', 'article', 'video', 'place')",
        "b.blocker_id = auth.uid()",
        "b.blocked_id = auth.uid()",
    ]
    for phrase in required_schema_phrases:
        fail_if(phrase not in schema, f"schema missing required phrase `{phrase}`", failures)

    required_test_plan_phrases = [
        "cannot publish screenshots, PDFs, files, or Private Vault content",
        "blocked links should be hidden",
        "blocked likes should be hidden",
        "status = 'random': should fail",
        "account deletion",
    ]
    for phrase in required_test_plan_phrases:
        fail_if(phrase.lower() not in test_plan_lower, f"RLS test plan missing `{phrase}`", failures)

    if failures:
        print("SAVI Supabase RLS check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: {len(TABLES)} tables have RLS enabled")
    print(f"OK: {len(policies)} policies parsed and constrained to authenticated users")
    print("OK: public-link, report, block, follow, and like guardrails are present")
    print("SAVI Supabase RLS check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
