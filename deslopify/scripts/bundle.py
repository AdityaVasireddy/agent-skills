#!/usr/bin/env python3
"""Build and verify deterministic Deslopify packages."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import zipfile

SCHEMA = 1
ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ("SKILL.md", "eval.md", "references/formats.md", "references/patterns.md", "references/words.md")
REVIEWER = RUNTIME + ("evaluation/EVALUATION.md", "evaluation/review-prompt.md", "evaluation/cases.json")
INSTALL = RUNTIME + ("README.md", "LICENSE", "VERSION")
EXCLUDED = {"reviewer-bundle", "reviewer-bundle.zip", "source.zip", "install.zip", "__pycache__"}

def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

def read_members(root: Path, names: tuple[str, ...]) -> dict[str, bytes]:
    members: dict[str, bytes] = {}
    for name in names:
        path = root / name
        if not path.is_file():
            raise SystemExit(f"missing required package member: {name}")
        members[name] = path.read_bytes()
    return members

def source_members(root: Path) -> dict[str, bytes]:
    names = []
    for path in sorted(root.rglob("*")):
        if path.is_file():
            relative = path.relative_to(root).as_posix()
            parts = set(relative.split("/"))
            if not any(relative == item or relative.startswith(item + "/") for item in EXCLUDED):
                if relative != "BUILD_MANIFEST.json" and "__pycache__" not in parts and not relative.endswith(".pyc"):
                    names.append(relative)
    return read_members(root, tuple(names))

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
        names = archive.namelist()
        if len(names) != len(set(names)) or names != sorted(names):
            raise SystemExit("archive member order or uniqueness is invalid")
        if "BUILD_MANIFEST.json" not in names:
            raise SystemExit("archive is missing BUILD_MANIFEST.json")
        raw = json.loads(archive.read("BUILD_MANIFEST.json"))
        if raw.get("schema") != SCHEMA or not isinstance(raw.get("files"), dict):
            raise SystemExit("manifest schema or files map is invalid")
        kind = raw.get("kind")
        expected = {"reviewer": set(REVIEWER), "install": set(INSTALL), "source": None}
        listed = set(raw.get("files", {}))
        if kind not in expected:
            raise SystemExit(f"unknown package kind: {kind!r}")
        if expected[kind] is not None and listed != expected[kind]:
            raise SystemExit(f"{kind} package member set is invalid")
        if kind == "source" and any(name.startswith("reviewer-bundle") for name in listed):
            raise SystemExit("source package contains generated reviewer output")
        if set(names) != listed | {"BUILD_MANIFEST.json"}:
            raise SystemExit("archive members do not match the manifest")
        for name, metadata in raw["files"].items():
            if not isinstance(metadata, dict) or set(metadata) != {"sha256", "size"}:
                raise SystemExit(f"archive member metadata is invalid: {name}")
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
    raise SystemExit(main())
