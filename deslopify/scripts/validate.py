#!/usr/bin/env python3
"""Validate the runtime contract and its structural references."""
from __future__ import annotations

import re
import sys
from pathlib import Path

REQUIRED = ("SKILL.md", "eval.md", "references/formats.md", "references/patterns.md", "references/words.md")
CONTRACT = re.compile(r"\*\*([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*(?:\s*/\s*[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)*)\s*:?\*\*")
DEFINED = re.compile(r"\*\*Contract " + chr(96) + r"([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)" + chr(96) + r"\*\*")
ORDINAL = re.compile(r"\btiers?\s*[-–]?\s*\d|\bfirst\s+(?:two|three|four)\s+tiers|\btier-\d", re.I)


def main() -> int:
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
    errors: list[str] = []
    missing = [name for name in REQUIRED if not (root / name).is_file()]
    if missing:
        errors.append("missing required files: " + ", ".join(missing))
    skill = (root / "SKILL.md").read_text(encoding="utf-8") if (root / "SKILL.md").is_file() else ""
    gate = (root / "eval.md").read_text(encoding="utf-8") if (root / "eval.md").is_file() else ""
    if not skill.startswith("---\n") or "\n---\n" not in skill[4:]:
        errors.append("SKILL.md is missing YAML frontmatter")
    else:
        header = skill[4 : skill.index("\n---\n", 4)]
        name = re.search(r"^name:\s*([a-z0-9-]+)\s*$", header, re.M)
        description = re.search(r"^description:\s*\S", header, re.M)
        if not name or name.group(1) != root.name:
            errors.append("frontmatter name must match the skill directory")
        if not description:
            errors.append("frontmatter description is missing")
    defined_list = DEFINED.findall(skill)
    defined = set(defined_list)
    if not defined:
        errors.append("no named contracts are defined")
    if len(defined_list) != len(defined):
        errors.append("duplicate contract definitions")
    used_list = [part.strip() for match in CONTRACT.findall(gate) for part in match.split("/")]
    used = set(used_list)
    if used - defined:
        errors.append("dangling contract references: " + ", ".join(sorted(used - defined)))
    if defined - used:
        errors.append("orphaned contracts: " + ", ".join(sorted(defined - used)))
    violations = []
    for file in sorted(root.rglob("*.md")):
        body = file.read_text(encoding="utf-8")
        start = body.find("## Precedence") if file.name == "SKILL.md" else -1
        end = body.find("\n## ", start + 1) if start >= 0 else -1
        for match in ORDINAL.finditer(body):
            if start >= 0 and start <= match.start() < (end if end >= 0 else len(body)):
                continue
            line = body[:match.start()].count(chr(10)) + 1
            violations.append(f"{file.relative_to(root)}:{line}: {match.group()!r}")
    if violations:
        errors.append("ordinal tier aliases outside the canonical precedence list: " + "; ".join(violations))
    if errors:
        for error in errors:
            print("FAIL " + error)
        return 1
    print(f"defined {len(defined)} contracts: {', '.join(sorted(defined))}")
    print(f"referenced {len(used)} contracts: {', '.join(sorted(used))}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
