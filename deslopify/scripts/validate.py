#!/usr/bin/env python3
"""Validate the runtime contract and its structural references."""
from __future__ import annotations

import re
import sys
from pathlib import Path

import yaml


class UniqueLoader(yaml.SafeLoader):
    """Safe YAML parsing with duplicate keys rejected, rather than overwritten."""


def unique_mapping(loader, node, deep=False):
    result = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if not isinstance(key, str) or key in result:
            raise yaml.constructor.ConstructorError(None, None, 'duplicate or non-string YAML key', key_node.start_mark)
        result[key] = loader.construct_object(value_node, deep=deep)
    return result


UniqueLoader.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, unique_mapping)

REQUIRED = ("SKILL.md", "eval.md", "references/formats.md", "references/patterns.md", "references/words.md")
CONTRACT = re.compile(r"\*\*([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*(?:\s*/\s*[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)*)\s*:?\*\*")
DEFINED = re.compile(r"\*\*Contract " + chr(96) + r"([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*)" + chr(96) + r"\*\*")
ORDINAL = re.compile(r"\btiers?\s*[-–]?\s*\d|\bfirst\s+(?:two|three|four)\s+tiers|\btier-\d", re.I)


def main() -> int:
    root = (Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]).resolve()
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
        try:
            parsed = yaml.load(header, Loader=UniqueLoader)
            if not isinstance(parsed, dict):
                raise ValueError('frontmatter must be a YAML mapping')
            name, description = parsed.get('name'), parsed.get('description')
            if not isinstance(name, str) or name != root.name or not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', name) or len(name) > 64:
                raise ValueError('frontmatter name must match the skill directory and use hyphen-case')
            if not isinstance(description, str) or not description.strip() or len(description) > 1024 or any(c in description for c in '<>'):
                raise ValueError('frontmatter description must be a nonempty string of at most 1024 characters without angle brackets')
            if set(parsed) - {'name', 'description', 'license', 'allowed-tools', 'metadata'}:
                raise ValueError('unsupported frontmatter properties')
        except (yaml.YAMLError, ValueError) as error:
            errors.append(f'invalid YAML frontmatter: {error}')
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
    ui = root / 'agents' / 'openai.yaml'
    if ui.is_file():
        try:
            metadata = yaml.load(ui.read_text(encoding='utf-8'), Loader=UniqueLoader)
            interface = metadata.get('interface') if isinstance(metadata, dict) else None
            if not isinstance(interface, dict):
                raise ValueError('interface must be a mapping')
            for key in ('display_name', 'short_description', 'default_prompt'):
                if not isinstance(interface.get(key), str) or not interface[key].strip():
                    raise ValueError(f'{key} must be a nonempty string')
            if not 25 <= len(interface['short_description']) <= 64 or '$deslopify' not in interface['default_prompt']:
                raise ValueError('short description length or invocation prompt is invalid')
        except (yaml.YAMLError, ValueError) as error:
            errors.append(f'invalid UI metadata: {error}')
    violations = []
    for file in (root / name for name in REQUIRED if (root / name).is_file()):
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
