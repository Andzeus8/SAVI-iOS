#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FORBIDDEN_TERMS = {
    "private_note_text",
    "private_document_contents",
    "private_pdf_contents",
    "pdf_contents",
    "screenshot_ocr",
    "private_vault_contents",
    "raw_clipboard",
    "keystrokes",
    "contacts",
    "private_file_name",
}


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def load_json(path: str) -> dict:
    with (ROOT / path).open("r", encoding="utf-8") as handle:
        return json.load(handle)


def app_events() -> set[str]:
    source = read("SAVI/Core/SaviCore.swift")
    match = re.search(r"enum SaviAnalyticsEventName:.*?\n\}", source, flags=re.DOTALL)
    if not match:
        return set()
    return set(re.findall(r'case\s+\w+\s*=\s*"([^"]+)"', match.group(0)))


def app_properties() -> set[str]:
    source = read("SAVI/Core/SaviCore.swift")
    match = re.search(r"enum SaviAnalyticsPropertyKey:.*?\n\}", source, flags=re.DOTALL)
    if not match:
        return set()
    return set(re.findall(r'case\s+\w+\s*=\s*"([^"]+)"', match.group(0)))


def schema_events() -> set[str]:
    schema = load_json("Docs/Backend/Schemas/analytics-event.schema.json")
    return set(schema["properties"]["name"]["enum"])


def catalog_events() -> set[str]:
    text = read("Docs/Backend/AnalyticsEventCatalog.md")
    events: set[str] = set()
    for line in text.splitlines():
        match = re.match(r"\|\s*`([^`]+)`\s*\|", line)
        if match:
            events.add(match.group(1))
    return events


def planned_events() -> set[str]:
    text = read("Docs/Architecture/AnalyticsEvents.md")
    match = re.search(r"## Missing Event To Add(?P<section>.*?)(?:\n## |\Z)", text, flags=re.DOTALL)
    if not match:
        return set()
    return set(re.findall(r"`([^`]+)`", match.group("section")))


def fixture_analytics_events_and_properties() -> tuple[set[str], set[str]]:
    events: set[str] = set()
    properties: set[str] = set()
    for directory in [
        ROOT / "Docs/Backend/Fixtures/valid",
        ROOT / "Docs/Backend/Fixtures/invalid",
    ]:
        for path in sorted(directory.glob("analytics-*.json")):
            data = json.loads(path.read_text(encoding="utf-8"))
            if isinstance(data.get("name"), str):
                events.add(data["name"])
            if isinstance(data.get("properties"), dict):
                properties.update(data["properties"].keys())
    return events, properties


def fail_if(condition: bool, message: str, failures: list[str]) -> None:
    if condition:
        failures.append(message)


def main() -> int:
    failures: list[str] = []

    print("== SAVI analytics contract check ==")

    app_event_names = app_events()
    app_property_names = app_properties()
    schema_event_names = schema_events()
    catalog_event_names = catalog_events()
    planned_event_names = planned_events()
    fixture_event_names, fixture_property_names = fixture_analytics_events_and_properties()

    fail_if(not app_event_names, "could not parse app analytics event allowlist", failures)
    fail_if(not app_property_names, "could not parse app analytics property allowlist", failures)

    for label, event_set in [
        ("schema", schema_event_names),
        ("catalog", catalog_event_names),
        ("fixtures", fixture_event_names),
    ]:
        missing = sorted(app_event_names - event_set) if label != "fixtures" else []
        extra = sorted(event_set - app_event_names)
        if missing:
            failures.append(f"{label} missing current app events: {', '.join(missing)}")
        if extra:
            failures.append(f"{label} has events not in current app allowlist: {', '.join(extra)}")

    planned_in_current = sorted(planned_event_names.intersection(app_event_names | schema_event_names | catalog_event_names))
    if planned_in_current:
        failures.append(
            "planned analytics events are already in current contracts without app implementation: "
            + ", ".join(planned_in_current)
        )

    unknown_fixture_properties = sorted(fixture_property_names - app_property_names - FORBIDDEN_TERMS)
    if unknown_fixture_properties:
        failures.append(
            "analytics fixtures use properties outside app allowlist: "
            + ", ".join(unknown_fixture_properties)
        )

    forbidden_valid_properties: list[str] = []
    for path in sorted((ROOT / "Docs/Backend/Fixtures/valid").glob("analytics-*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        properties = data.get("properties", {})
        forbidden = sorted(set(properties.keys()).intersection(FORBIDDEN_TERMS))
        if forbidden:
            forbidden_valid_properties.append(f"{path.relative_to(ROOT)}: {', '.join(forbidden)}")
    if forbidden_valid_properties:
        failures.append("valid analytics fixtures include forbidden properties: " + "; ".join(forbidden_valid_properties))

    for phrase in [
        "No PostHog SDK, autocapture, or session replay is active",
        "Release/TestFlight uses a no-op analytics service",
        "Never send:",
    ]:
        if phrase not in read("Docs/Backend/AnalyticsEventCatalog.md"):
            failures.append(f"analytics catalog missing privacy phrase: {phrase}")

    if failures:
        print("SAVI analytics contract check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"OK: {len(app_event_names)} current analytics events align across app/schema/catalog")
    print(f"OK: {len(app_property_names)} analytics property keys are the fixture allowlist")
    if planned_event_names:
        print("OK: planned events remain out of current contracts: " + ", ".join(sorted(planned_event_names)))
    print("SAVI analytics contract check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
