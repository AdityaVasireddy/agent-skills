#!/usr/bin/env bash
# Compatibility wrapper for the deterministic Python builder.
set -euo pipefail
OUT="${1:-reviewer-bundle}"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
exec "${PYTHON:-python3}" "$SCRIPT_DIR/bundle.py" --kind reviewer --output "$OUT.zip"
