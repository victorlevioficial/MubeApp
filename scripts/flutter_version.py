#!/usr/bin/env python3

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

VERSION_PATTERN = re.compile(r"\b(\d+\.\d+\.\d+)\b")


def repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def load_required_version(root: Path) -> str:
    config_path = root / ".fvmrc"
    if not config_path.is_file():
        raise SystemExit(f"Missing Flutter version source: {config_path}")

    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"Invalid JSON in {config_path}: {error}") from error

    version = str(config.get("flutter", "")).strip()
    if not version:
        raise SystemExit(f"Missing 'flutter' version in {config_path}")

    return version


def extract_version(text: str) -> str:
    match = VERSION_PATTERN.search(text)
    if not match:
        raise SystemExit(f"Unable to extract Flutter version from: {text!r}")
    return match.group(1)


def read_current_flutter_version() -> str:
    try:
        result = subprocess.run(
            ["flutter", "--version"],
            check=True,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise SystemExit("Flutter is not available on PATH") from error
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.stderr.strip() or error.stdout.strip()) from error

    output = "\n".join(filter(None, [result.stdout, result.stderr]))
    return extract_version(output)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Resolve and validate the repository Flutter version.",
    )
    parser.add_argument(
        "--repo-root",
        default=str(repo_root()),
        help="Repository root containing .fvmrc.",
    )
    parser.add_argument(
        "--check-current",
        action="store_true",
        help="Validate the current flutter on PATH against .fvmrc.",
    )
    parser.add_argument(
        "--current-version",
        help="Explicit version or flutter --version output to validate.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.repo_root).resolve()
    required_version = load_required_version(root)

    if not args.check_current:
        print(required_version)
        return 0

    current_version = (
        extract_version(args.current_version)
        if args.current_version
        else read_current_flutter_version()
    )

    if current_version != required_version:
        print(
            (
                "Flutter version mismatch: "
                f"required {required_version} from {root / '.fvmrc'}, "
                f"but current is {current_version}."
            ),
            file=sys.stderr,
        )
        return 1

    print(required_version)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
