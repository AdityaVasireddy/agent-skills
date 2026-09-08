#!/usr/bin/env bash
# Builds the reviewer bundle as a single ZIP.
#
# Why a ZIP and not loose files: the delivery channel flattens directories, and
# SKILL.md loads references/ by relative path. A zip is the only artifact that
# survives delivery with its structure intact.
#
# Three file classes, deliberately separated:
#   runtime        SKILL.md, eval.md, references/*  -> size recorded for visibility
#   evaluator      EVALUATION.md                    -> reviewer-visible, not runtime
#   oracle         scoring-sheet.md                 -> NEVER in the bundle, NEVER delivered alongside it
set -euo pipefail
OUT="${1:-reviewer-bundle}"
rm -rf "$OUT" "$OUT.zip"; mkdir -p "$OUT/deslopify/references"

# Locate sources whether the tree is nested (deslopify/SKILL.md) or flat (SKILL.md).
find_src() {
  for c in "deslopify/$1" "deslopify/references/$1" "evaluation/$1" "$1" "references/$1" "../deslopify/$1" "../evaluation/$1"; do
    [ -f "$c" ] && { echo "$c"; return 0; }
  done
  echo "FATAL: cannot locate $1 in nested or flat layout" >&2; exit 1
}
for f in SKILL.md eval.md EVALUATION.md; do cp "$(find_src $f)" "$OUT/deslopify/"; done
# KNOWN-LIMITATIONS.md ships with the skill but is withheld from the blind review bundle,
# because it hands the reviewer pre-made break inputs. Same class as the oracle: reviewer-blind.
if [ "${INCLUDE_LIMITATIONS:-0}" = "1" ]; then cp "$(find_src KNOWN-LIMITATIONS.md)" "$OUT/deslopify/"; fi
for f in patterns.md words.md formats.md; do cp "$(find_src $f)" "$OUT/deslopify/references/"; done
cp "$(find_src review-prompt.md)" "$OUT/"

RUNTIME=$(cat "$OUT"/deslopify/SKILL.md "$OUT"/deslopify/eval.md "$OUT"/deslopify/references/*.md | wc -w)
SKILLWC=$(wc -w < "$OUT/deslopify/SKILL.md")

python3 - "$OUT/review-prompt.md" "$SKILLWC" "$RUNTIME" << 'PY'
import re, sys
p, s, r = sys.argv[1], *map(int, sys.argv[2:])
line = (f"**Runtime size (recorded for visibility, not a hard ceiling).** Generated at bundle time by "
        f"`wc -w`: SKILL.md {s:,}; runtime total (SKILL.md + eval.md + references/) {r:,}. There is no hard "
        f"word-count limit, but any proposed addition must still name what it displaces, to discourage "
        f"unnecessary growth. `EVALUATION.md` is evaluator machinery and is not part of runtime. If your own "
        f"count differs, use yours and say which tool you used.")
marker = "{{RUNTIME_SIZE}}"
t = open(p).read()
if t.count(marker) != 1:
    raise SystemExit(f"FATAL: expected exactly one {marker} in review-prompt, found {t.count(marker)}")
open(p, "w").write(t.replace(marker, line))
PY

# --- leak checks: file, then content, then structure ---
if find "$OUT" -iname "*scoring*" | grep -q .; then echo "FAIL: oracle file in bundle"; exit 1; fi
if grep -rqF "Must survive" "$OUT"; then echo "FAIL: oracle content in bundle"; exit 1; fi
if [ "${INCLUDE_LIMITATIONS:-0}" != "1" ] && find "$OUT" -name "KNOWN-LIMITATIONS.md" | grep -q .; then
  echo "FAIL: limitations file leaked into blind review bundle"; exit 1
fi
[ -d "$OUT/deslopify/references" ] || { echo "FAIL: references/ missing"; exit 1; }
[ -f "$OUT/deslopify/EVALUATION.md" ] || { echo "FAIL: EVALUATION.md missing"; exit 1; }
python3 "$(dirname "$0")/validate.py" "$OUT/deslopify" >/dev/null || { echo "FAIL: dangling contract reference"; exit 1; }

( cd "$OUT" && zip -qr "../$OUT.zip" . )

# Verify the ARCHIVE, not the staging dir. Capture the listing once: piping into
# `grep -q` under `set -o pipefail` SIGPIPEs unzip and fails the pipeline on a match.
LISTING=$(unzip -l "$OUT.zip")
case "$LISTING" in
  *scoring*) echo "FAIL: oracle in archive"; exit 1 ;;
esac
case "$LISTING" in
  *deslopify/references/patterns.md*) : ;;
  *) echo "FAIL: archive flattened"; exit 1 ;;
esac

# fingerprint: hash the runtime files so the delivered artifact self-identifies
BUILD_ID=$(cat "$OUT"/deslopify/SKILL.md "$OUT"/deslopify/eval.md "$OUT"/deslopify/references/*.md | sha256sum | cut -c1-12)
{ echo; echo "BUILD $BUILD_ID"; echo "aliases_outside_precedence=0 detect_buckets=5 draft_contract=split"; } >> "$OUT/BUILD_MANIFEST.txt"
( cd "$OUT" && zip -q "../$OUT.zip" BUILD_MANIFEST.txt )
echo "BUILD $BUILD_ID (verify this string matches the manifest inside the zip you open)"
echo "built: $OUT.zip"
echo "SKILL.md $SKILLWC | runtime $RUNTIME"
echo "$LISTING" | sed -n '4,12p'
echo "leak checks: pass | structure preserved: pass"
