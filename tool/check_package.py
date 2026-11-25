#!/usr/bin/env python3
"""Run Flutter's package validation on a disposable copy of the checkout."""

import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repository", help="Repository URL for the rehearsal copy")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    files = subprocess.check_output(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=root,
    )

    with tempfile.TemporaryDirectory(prefix="yumeiro-package-") as directory:
        snapshot = Path(directory)
        for name in files.split(b"\0"):
            if not name:
                continue
            relative = Path(os.fsdecode(name))
            source = root / relative
            if source.is_file():
                target = snapshot / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(source, target)

        manifest = snapshot / "pubspec.yaml"
        original = manifest.read_text(encoding="utf-8")
        pubspec = re.sub(r"^publish_to:[^\n]*\n", "", original, flags=re.MULTILINE)
        if args.repository and not re.search(r"^repository:", pubspec, re.MULTILINE):
            pubspec += f"\nrepository: {json.dumps(args.repository)}\n"
        manifest.write_text(pubspec, encoding="utf-8")
        return subprocess.run(
            ["flutter", "pub", "publish", "--dry-run"], cwd=snapshot,
        ).returncode


if __name__ == "__main__":
    raise SystemExit(main())
