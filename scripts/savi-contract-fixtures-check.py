#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
FIXTURE_ROOT = ROOT / "Docs" / "Backend" / "Fixtures"

FORBIDDEN_ANALYTICS_KEYS = {
    "private_note_text",
    "pdf_contents",
    "screenshot_ocr",
    "private_vault_contents",
    "raw_clipboard",
    "contacts",
    "private_file_name",
    "keystrokes",
}

VALID_ITEM_TYPES = {"link", "video", "image", "screenshot", "audio", "note", "pdf", "file", "place"}
VALID_PUBLIC_LINK_TYPES = {"link", "article", "video", "place"}
VALID_ANALYTICS_EVENTS = {
    "app_opened",
    "session_duration",
    "onboarding_started",
    "onboarding_completed",
    "share_extension_opened",
    "save_completed",
    "save_failed",
    "metadata_success",
    "metadata_failure",
    "folder_created",
    "folder_selected",
    "search_performed",
    "public_link_published",
    "feed_viewed",
    "friend_added",
    "like_added",
    "friend_link_saved",
    "report_submitted",
    "block_action",
}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def is_iso_date(value: str) -> bool:
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        return True
    except ValueError:
        return False


def is_http_url(value: str) -> bool:
    parsed = urlparse(value)
    return parsed.scheme in {"http", "https"} and bool(parsed.netloc)


def validate_item(data: dict) -> list[str]:
    errors: list[str] = []
    required = ["id", "title", "createdAt", "updatedAt", "folderId", "type", "source", "tags", "isPrivate", "isArchived"]
    for key in required:
        if key not in data:
            errors.append(f"missing {key}")

    if data.get("type") not in VALID_ITEM_TYPES:
        errors.append(f"invalid item type {data.get('type')!r}")
    if not isinstance(data.get("tags"), list) or not all(isinstance(tag, str) for tag in data.get("tags", [])):
        errors.append("tags must be a string array")
    for key in ["isPrivate", "isArchived"]:
        if not isinstance(data.get(key), bool):
            errors.append(f"{key} must be boolean")
    for key in ["createdAt", "updatedAt"]:
        if not isinstance(data.get(key), str) or not is_iso_date(data[key]):
            errors.append(f"{key} must be ISO date")
    if "canonicalUrl" in data and not is_http_url(data["canonicalUrl"]):
        errors.append("canonicalUrl must be http(s)")
    return errors


def validate_public_link(data: dict) -> list[str]:
    errors: list[str] = []
    required = ["id", "ownerId", "title", "url", "canonicalUrl", "domain", "itemType", "sharedAt"]
    for key in required:
        if key not in data:
            errors.append(f"missing {key}")

    if data.get("itemType") not in VALID_PUBLIC_LINK_TYPES:
        errors.append(f"invalid public itemType {data.get('itemType')!r}")
    if not isinstance(data.get("url"), str) or not is_http_url(data["url"]):
        errors.append("url must be public http(s)")
    if not isinstance(data.get("canonicalUrl"), str) or not is_http_url(data["canonicalUrl"]):
        errors.append("canonicalUrl must be public http(s)")
    if data.get("folderId") == "f-private-vault":
        errors.append("Private Vault cannot be public")
    if not isinstance(data.get("sharedAt"), str) or not is_iso_date(data["sharedAt"]):
        errors.append("sharedAt must be ISO date")
    return errors


def validate_analytics(data: dict) -> list[str]:
    errors: list[str] = []
    if data.get("name") not in VALID_ANALYTICS_EVENTS:
        errors.append(f"invalid analytics event {data.get('name')!r}")
    if not isinstance(data.get("timestamp"), str) or not is_iso_date(data["timestamp"]):
        errors.append("timestamp must be ISO date")
    properties = data.get("properties")
    if not isinstance(properties, dict):
        errors.append("properties must be an object")
        return errors

    forbidden = sorted(FORBIDDEN_ANALYTICS_KEYS.intersection(properties.keys()))
    if forbidden:
        errors.append(f"forbidden analytics properties: {', '.join(forbidden)}")

    is_public = properties.get("is_public", properties.get("public"))
    if is_public is False and "canonical_url" in properties:
        errors.append("private analytics events must not include canonical_url")
    return errors


def classify_fixture(path: Path, data: dict) -> tuple[str, list[str]]:
    if "name" in data and "properties" in data:
        return "analytics", validate_analytics(data)
    if "itemType" in data:
        return "public-link", validate_public_link(data)
    return "item", validate_item(data)


def check_directory(directory: Path, expect_valid: bool) -> int:
    failures = 0
    for path in sorted(directory.glob("*.json")):
        data = load_json(path)
        kind, errors = classify_fixture(path, data)
        if expect_valid and errors:
            print(f"FAIL: {path.relative_to(ROOT)} ({kind}) should be valid")
            for error in errors:
                print(f"  - {error}")
            failures += 1
        elif not expect_valid and not errors:
            print(f"FAIL: {path.relative_to(ROOT)} ({kind}) should be invalid but passed")
            failures += 1
        else:
            status = "valid" if expect_valid else "invalid as expected"
            print(f"OK: {path.relative_to(ROOT)} ({kind}) {status}")
    return failures


def main() -> int:
    print("== SAVI contract fixture check ==")
    failures = 0
    failures += check_directory(FIXTURE_ROOT / "valid", expect_valid=True)
    failures += check_directory(FIXTURE_ROOT / "invalid", expect_valid=False)

    if failures:
        print(f"SAVI contract fixture check failed with {failures} failure(s)")
        return 1

    print("SAVI contract fixture check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
