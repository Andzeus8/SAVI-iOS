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

    print("== SAVI sample content safety check ==")

    review = read("Docs/Architecture/SampleContentReview.md")
    sources = read("Docs/Design/SampleLibrarySources.md")
    packet = read("Docs/Architecture/Runbooks/AppStoreSubmissionPacket.md")
    compliance = read("Docs/Architecture/AppStoreComplianceMatrix.md")
    seeds = read("SAVI/Services/LegacyAndUtilities.swift")
    safety_scan = read("scripts/savi-safety-scan.sh")
    preflight = read("scripts/savi-preflight.sh")

    for phrase in [
        "removable sample library",
        "questions-for-doctor",
        "not medical advice",
        "remote provider metadata",
        "invented demo data",
        "visible `SAMPLE`",
        "fact-checking",
        "Docs/Design/SampleLibrarySources.md",
        "Common Cancer Myths and Misconceptions",
    ]:
        require_text(review, phrase, "SampleContentReview", failures)

    for phrase in [
        "Safety Notes",
        "Pexels License",
        "third-party thumbnails loaded as normal link metadata",
        "generated fake sample art with invented data",
        "Health examples are saved as research/questions-for-doctor material, not medical advice",
        "Rabbit-hole examples are framed as curiosity and fact-checking",
        "folder-cover-memes-laughing-kid",
    ]:
        require_text(sources, phrase, "SampleLibrarySources", failures)

    for phrase in [
        "The sample library is removable",
        "Health-related sample links are saved",
        "not medical advice or treatment claims",
    ]:
        require_text(packet, phrase, "AppStoreSubmissionPacket", failures)

    for phrase in [
        "Sample Content",
        "Docs/Architecture/SampleContentReview.md",
        "Health Claims",
        "No medical advice/treatment claims",
    ]:
        require_text(compliance, phrase, "AppStoreComplianceMatrix", failures)

    health_required = [
        "sample-research-mebendazole",
        "Parasite medication and cancer remission?",
        "PubMed case-report",
        "questions-for-doctor",
        "not as medical advice",
        "sample-health-fasting-autophagy",
        "Intermittent fasting and cancer: cure?",
        "clinician discussion",
        "not medical advice or a proven treatment",
        "Common Cancer Myths and Misconceptions",
        "https://www.cancer.gov/about-cancer/causes-prevention/risk/myths",
        "Does your microbiome control your thoughts?",
        "curiosity note, not medical advice",
    ]
    for phrase in health_required:
        require_text(seeds, phrase, "sample seed health copy", failures)

    media_required = [
        'youtubeThumb("dQw4w9WgXcQ")',
        'youtubeThumb("Cqd1Gvq-RBY")',
        'youtubeThumb("0EqSXDwTq6U")',
        'youtubeThumb("WePNs-G7puA")',
        "metadataPolicy: .liveMetadata",
        "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        "https://www.youtube.com/watch?v=Cqd1Gvq-RBY",
        "https://www.youtube.com/watch?v=0EqSXDwTq6U",
    ]
    for phrase in media_required:
        require_text(seeds, phrase, "sample seed video/link copy", failures)

    private_required = [
        "Fake insurance card",
        "clear SAMPLE watermark",
        "Watermarked fake ID copy",
        "invented demo data",
        "SAMPLE banking note",
        "SAMPLE password note",
        "sample-private-passport",
        "invented renewal reminder",
        "SAMPLE only",
    ]
    for phrase in private_required:
        require_text(seeds, phrase, "sample seed private-document copy", failures)

    banned_claim_patterns = [
        r"\bcures cancers?\b",
        r"\bcure[s]? cancer\b",
        r"\bis a cancer cure\b",
        r"\bguaranteed treatment\b",
        r"\bproven cancer treatment\b",
        r"\bdoctors don't want you to know\b",
    ]
    for pattern in banned_claim_patterns:
        match = re.search(pattern, seeds, flags=re.IGNORECASE)
        require(match is None, f"sample seeds avoid banned claim pattern `{pattern}`", failures)

    require_text(
        safety_scan,
        "Docs/Architecture/SampleContentReview.md",
        "savi-safety-scan.sh",
        failures,
    )
    require_text(
        preflight,
        "scripts/savi-sample-content-check.py",
        "savi-preflight.sh",
        failures,
    )

    if failures:
        print("\nSAVI sample content safety check failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print("SAVI sample content safety check passed")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except AssertionError as exc:
        print(f"SAVI sample content safety check failed: {exc}")
        sys.exit(1)
