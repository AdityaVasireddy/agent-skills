#!/usr/bin/env python3
"""Build and verify deterministic Deslopify packages."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
import subprocess
import sys
import zipfile

SCHEMA = 1
ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ("SKILL.md", "eval.md", "references/formats.md", "references/patterns.md", "references/words.md")
REVIEWER = RUNTIME + ("evaluation/EVALUATION.md", "evaluation/review-prompt.md", "evaluation/cases.json")
INSTALL = RUNTIME + ("agents/openai.yaml", "LICENSE", "VERSION")
# Source is the complete skill development package, not the monorepo or a disk snapshot.
# Explicit membership prevents logs, local secrets, symlinks, and prior builds from shipping.
SOURCE = tuple(sorted(set(INSTALL + REVIEWER + (
    '.gitattributes', '.gitignore', 'README.md', 'CHANGELOG.md', 'KNOWN-LIMITATIONS.md',
    'requirements-dev.txt', 'evaluation/scoring-sheet.md',
    'scripts/bundle.py', 'scripts/bundle.sh', 'scripts/validate.py',
    'tests/test_tooling.py', 'tests/test_release.py',
))))

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def unique_json(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'duplicate manifest key: {key}')
        result[key] = value
    return result

def read_members(root: Path, names: tuple[str, ...]) -> dict[str, bytes]:
    members: dict[str, bytes] = {}
    for name in names:
        path = root / name
        if path.is_symlink() or not path.is_file() or root.resolve() not in path.resolve().parents:
            raise SystemExit(f"missing required package member: {name}")
        # All declared members are UTF-8 text. Normalize checkout line endings.
        members[name] = path.read_bytes().decode('utf-8').replace('\r\n', '\n').encode('utf-8')
    return members

def source_members(root: Path) -> dict[str, bytes]:
    return read_members(root, SOURCE)

def manifest(kind: str, members: dict[str, bytes]) -> bytes:
    payload = {"schema": SCHEMA, "kind": kind, "files": {
        name: {"sha256": digest(data), "size": len(data)} for name, data in sorted(members.items())
    }}
    return (json.dumps(payload, indent=2, sort_keys=True) + "\n").encode("utf-8")

def reviewer_members(root: Path) -> dict[str, bytes]:
    members = read_members(root, REVIEWER)
    prompt = members["evaluation/review-prompt.md"].decode("utf-8")
    marker = "{{RUNTIME_SIZE}}"
    if prompt.count(marker) != 1:
        raise SystemExit(f"review prompt must contain exactly one {marker} marker")
    runtime_words = sum(len(members[name].decode("utf-8").split()) for name in RUNTIME)
    line = (
        "**Runtime size (recorded for visibility, not a hard ceiling).** "
        f"Generated at bundle time: runtime total (SKILL.md + eval.md + references/) {runtime_words:,} words."
    )
    members["evaluation/review-prompt.md"] = prompt.replace(marker, line).encode("utf-8")
    return members

def write_zip(output: Path, kind: str, members: dict[str, bytes]) -> None:
    if output.exists():
        raise SystemExit(f"refusing to overwrite existing output: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    all_members = dict(members)
    all_members["BUILD_MANIFEST.json"] = manifest(kind, members)
    with zipfile.ZipFile(output, "x", compression=zipfile.ZIP_STORED, strict_timestamps=False) as archive:
        for name, data in sorted(all_members.items()):
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_STORED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)

def verify(archive_path: Path) -> None:
    with zipfile.ZipFile(archive_path) as archive:
        if archive.comment:
            raise SystemExit('archive comment is not permitted')
        for info in archive.infolist():
            if (info.create_system != 3 or info.external_attr != 0o100644 << 16
                    or info.date_time != (1980, 1, 1, 0, 0, 0)
                    or info.compress_type != zipfile.ZIP_STORED or info.flag_bits & 1
                    or info.extra or info.comment):
                raise SystemExit(f'noncanonical or unsafe ZIP member metadata: {info.filename}')
        names = archive.namelist()
        if len(names) != len(set(names)) or names != sorted(names):
            raise SystemExit("archive member order or uniqueness is invalid")
        if "BUILD_MANIFEST.json" not in names:
            raise SystemExit("archive is missing BUILD_MANIFEST.json")
        raw = json.loads(archive.read("BUILD_MANIFEST.json"), object_pairs_hook=unique_json)
        if not isinstance(raw, dict) or type(raw.get("schema")) is not int or raw.get("schema") != SCHEMA or not isinstance(raw.get("files"), dict):
            raise SystemExit("manifest schema or files map is invalid")
        kind = raw.get("kind")
        expected = {"reviewer": set(REVIEWER), "install": set(INSTALL), "source": set(SOURCE)}
        listed = set(raw.get("files", {}))
        if not isinstance(kind, str) or kind not in expected:
            raise SystemExit(f"unknown package kind: {kind!r}")
        if listed != expected[kind]:
            raise SystemExit(f"{kind} package member set is invalid")
        if set(names) != listed | {"BUILD_MANIFEST.json"}:
            raise SystemExit("archive members do not match the manifest")
        for name, metadata in raw["files"].items():
            if not isinstance(metadata, dict) or set(metadata) != {"sha256", "size"}:
                raise SystemExit(f"archive member metadata is invalid: {name}")
            if type(metadata['size']) is not int or metadata['size'] < 0 or not isinstance(metadata['sha256'], str) or not re.fullmatch(r'[0-9a-f]{64}', metadata['sha256']):
                raise SystemExit(f"archive member metadata types are invalid: {name}")
            data = archive.read(name)
            if len(data) != metadata["size"] or digest(data) != metadata["sha256"]:
                raise SystemExit(f"archive member failed manifest verification: {name}")
    print(f"verified {kind} package: {archive_path}")

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--kind", choices=("reviewer", "install", "source"))
    parser.add_argument("--output", type=Path)
    parser.add_argument("--verify", type=Path)
    args = parser.parse_args()
    if bool(args.verify) == bool(args.output):
        parser.error("choose exactly one of --verify or --output")
    if args.verify:
        verify(args.verify.resolve())
        return 0
    if not args.kind:
        parser.error("--kind is required with --output")
    subprocess.run(
        [sys.executable, str(Path(__file__).with_name("validate.py")), str(ROOT)],
        check=True,
    )
    names = {"reviewer": REVIEWER, "install": INSTALL, "source": None}[args.kind]
    members = source_members(ROOT) if names is None else (
        reviewer_members(ROOT) if args.kind == "reviewer" else read_members(ROOT, names)
    )
    write_zip(args.output.resolve(), args.kind, members)
    verify(args.output.resolve())
    print(f"built {args.kind} package: {args.output.resolve()}")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        raise SystemExit(f'package operation failed: {error}') from None
