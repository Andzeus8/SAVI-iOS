#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
TESTER_EMAILS = [
    "altatecrd@gmail.com",
    "matti.lamminsalo@gmail.com",
    "andreusbl@icloud.com",
    "andreusbl@mac.com",
    "luimi2k1@gmail.com",
    "j.rodriguez28@icloud.com",
]
STALE_BUILD_PHRASES = [
    "1.0 (27)",
    "build `27`",
    "build 27",
    "Build 4",
    "build 4",
]


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


def current_build() -> str:
    pbxproj = read("SAVI.xcodeproj/project.pbxproj")
    matches = sorted(set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", pbxproj)))
    if not matches:
        raise AssertionError("Could not detect CURRENT_PROJECT_VERSION")
    return matches[-1]


def main() -> int:
    failures: list[str] = []

    print("== SAVI TestFlight operations check ==")

    build = current_build()
    ops = read("Docs/Architecture/Runbooks/TestFlightOperations.md")
    readiness = read("Docs/TestFlightReadiness.md")
    metadata = read("Docs/Architecture/Runbooks/AppStoreConnectMetadata.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    preflight = read("scripts/savi-preflight.sh")

    for path in [
        "Docs/Architecture/Runbooks/TestFlightOperations.md",
        "Docs/TestFlightReadiness.md",
        "Docs/Architecture/Runbooks/AppStoreConnectMetadata.md",
    ]:
        require((ROOT / path).exists(), f"TestFlight source exists: {path}", failures)

    for phrase in [
        "SAVI Internal",
        f"1.0 ({build})",
        "Add Builds",
        "Invite Testers",
        "What to Test",
        "TestFlight app",
        "pull down to refresh",
        "delete/reinstall SAVI",
        "90 days",
        "com.altatecrd.savi",
        "com.altatecrd.savi.ShareExtension",
        "social hidden",
        "Add internal testers",
        "Add testers to builds",
        "TestFlight overview",
    ]:
        require(phrase in ops, f"TestFlightOperations contains `{phrase}`", failures)

    for email in TESTER_EMAILS:
        require(email in ops.lower(), f"TestFlightOperations tracks tester {email}", failures)

    for text_name, text in [
        ("TestFlightOperations", ops),
        ("TestFlightReadiness", readiness),
        ("AppStoreConnectMetadata", metadata),
        ("AppStoreSubmissionPacket", packet),
    ]:
        require(
            f"1.0 ({build})" in text or f"build `{build}`" in text,
            f"{text_name} mentions current build {build}",
            failures,
        )
        for stale in STALE_BUILD_PHRASES:
            require(stale not in text, f"{text_name} does not contain stale `{stale}`", failures)

    require(
        "scripts/savi-testflight-ops-check.py" in preflight,
        "preflight runs TestFlight operations checker",
        failures,
    )

    if failures:
        print("\nSAVI TestFlight operations check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI TestFlight operations check passed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as exc:
        print(f"SAVI TestFlight operations check failed: {exc}")
        raise SystemExit(1)
