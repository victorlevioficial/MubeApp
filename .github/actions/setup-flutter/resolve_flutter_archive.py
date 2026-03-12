#!/usr/bin/env python3

import json
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 5:
        raise SystemExit(
            "usage: resolve_flutter_archive.py <releases_json> <version> <channel> <arch_hint>"
        )

    releases_path = Path(sys.argv[1])
    version = sys.argv[2]
    channel = sys.argv[3]
    arch_hint = sys.argv[4]

    data = json.loads(releases_path.read_text(encoding="utf-8"))

    candidates = [
        release
        for release in data["releases"]
        if release.get("version") == version
        and release.get("channel") == channel
    ]

    if arch_hint:
        filtered = [
            release
            for release in candidates
            if arch_hint == release.get("dart_sdk_arch")
            or arch_hint in release.get("archive", "")
        ]
        if filtered:
            candidates = filtered

    if not candidates:
        raise SystemExit(
            f"Unable to find Flutter {version} ({channel}) for arch={arch_hint or 'auto'}"
        )

    archive = candidates[0]["archive"]
    print(f"{data['base_url']}/{archive}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
