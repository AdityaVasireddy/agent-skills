#!/usr/bin/env python3
"""Fails if eval.md references a contract SKILL.md does not define, or defines
one nothing tests. Catches the easiest class of stale-copy bug: a dangling name.

It cannot prove semantic synchronization. A contract whose meaning changed while
its name stayed put still passes here, and is caught only by the corpus."""
import re, sys, pathlib

root = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "deslopify")
skill = (root / "SKILL.md").read_text()
gate  = (root / "eval.md").read_text()

defined = set(re.findall(r'\*\*Contract `([A-Z][A-Z-]+)`\*\*', skill))
used    = set(re.findall(r'\*\*([A-Z][A-Z-]{3,})(?:\s*/\s*[A-Z][A-Z-]+)*:?\*\*', gate))
used   |= set(re.findall(r'\*\*[A-Z][A-Z-]+\s*/\s*([A-Z][A-Z-]+)', gate))
used   |= set(re.findall(r'\*\*(CONSTRAINT-CONFLICT)\*\*', gate))
used    = {u for u in used if u in defined or '-' in u}

# --- ordinal tier aliases: legal ONLY inside the canonical Precedence block ---
# Encoded from an actual failure: inserting a precedence row silently invalidated
# nine downstream references across five files. Deliberately dumb and strict --
# this does not try to judge whether a given number is currently correct.
TIER_NAMES = "factual accuracy, meaning, explicit user instruction, writer voice, pattern removal"
ORDINAL = re.compile(r'\btiers?\s*[-\u2013]?\s*\d|\bfirst\s+(?:two|three|four)\s+tiers|\btier-\d', re.I)

def precedence_span(text):
    m = re.search(r'^## Precedence\b', text, re.M)
    if not m: return (0, 0)
    nxt = re.search(r'^## ', text[m.end():], re.M)
    return (m.start(), m.end() + (nxt.start() if nxt else len(text)))

violations = []
for f in sorted(root.rglob("*.md")):
    body = f.read_text(); lo, hi = precedence_span(body) if f.name == "SKILL.md" else (0, 0)
    for m in ORDINAL.finditer(body):
        if lo <= m.start() < hi: continue          # inside the canonical list: allowed
        line = body[:m.start()].count("\n") + 1
        violations.append(f"{f.relative_to(root.parent)}:{line}: {m.group(0)!r}")
if violations:
    print("FAIL ordinal tier alias outside the canonical Precedence block:")
    for x in violations: print("  " + x)
    print(f"  use the stable names instead: {TIER_NAMES}")

dangling = used - defined
orphaned = defined - used
ok = not violations
if dangling:
    print(f"FAIL dangling (referenced in eval.md, not defined in SKILL.md): {sorted(dangling)}"); ok = False
if orphaned:
    print(f"WARN orphaned (defined, never tested): {sorted(orphaned)}")
print(f"defined {len(defined)}: {sorted(defined)}")
print(f"referenced {len(used)}: {sorted(used)}")
sys.exit(0 if ok else 1)
