#!/usr/bin/env bash
# run-tests.sh — end-to-end regression suite for historian-sweep.sh (v3.1)
#
# Drives the REAL script through its real entry point: hook JSON on stdin, a
# stub `claude` binary on PATH, generated JSONL transcripts, and a throwaway
# git repo per test. No mocking of internals — every test exercises the gate,
# dedup, model call, validator, and write/commit path exactly as production
# does. Requires: bash, jq, git, timeout (same as the script itself).
#
# Usage: bash tests/run-tests.sh        (from the engineering-historian root)

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$HERE/../scripts/historian-sweep.sh"
SWEEP_MD="$HERE/../assets/SWEEP.md"
[ -f "$SCRIPT" ] || { echo "FATAL: $SCRIPT not found"; exit 2; }
[ -f "$SWEEP_MD" ] || { echo "FATAL: $SWEEP_MD not found"; exit 2; }

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT
TODAY="$(date +%Y-%m-%d)"

# Pin gate config to defaults so a caller's environment can't skew results.
export HISTORIAN_MIN_TURNS=10
export HISTORIAN_WORK_BYTES=50000
export HISTORIAN_GIT_WINDOW="12 hours ago"
export HISTORIAN_DEDUP_DELTA=4096
unset HISTORIAN_MODEL 2>/dev/null || true
unset HISTORIAN_SWEEP_ACTIVE 2>/dev/null || true

# SWEEP.md lives where the script expects HISTORIAN_SKILL_DIR to point.
mkdir -p "$SANDBOX/skill"
cp "$SWEEP_MD" "$SANDBOX/skill/SWEEP.md"
export HISTORIAN_SKILL_DIR="$SANDBOX/skill"

# ---- Stub claude: drains stdin, records that it was called (and whether the
# recursion guard was exported), then emits the configured fixture or fails.
mkdir -p "$SANDBOX/bin"
cat > "$SANDBOX/bin/claude" <<'STUB'
#!/usr/bin/env bash
cat > /dev/null
if [ -n "${STUB_CALLED_FILE:-}" ]; then
  printf 'called guard=%s\n' "${HISTORIAN_SWEEP_ACTIVE:-unset}" >> "$STUB_CALLED_FILE"
fi
[ "${STUB_EXIT:-0}" -ne 0 ] && exit "${STUB_EXIT}"
cat "${STUB_OUTPUT_FILE:?stub needs STUB_OUTPUT_FILE}"
STUB
chmod +x "$SANDBOX/bin/claude"
export PATH="$SANDBOX/bin:$PATH"

# ---- Fixtures the stub can emit ----
mk_dayfile_fixture() {  # $1 = dest; a minimal valid v3 day file
  cat > "$1" <<EOF
---
project: proj
date: $TODAY
type: [decision]
stack: [bash]
status: test fixture status line
---

# Proj — $TODAY

## What I worked on
Test fixture day file.

## Cases

### CASE: fixture-case
status: auto
problem: fixture problem
decision: fixture decision
why: fixture why
tags: [test, fixture]
EOF
}
FIX_CLEAN="$SANDBOX/fix-clean.md";       mk_dayfile_fixture "$FIX_CLEAN"
FIX_NOTHING="$SANDBOX/fix-nothing.md";   printf 'NOTHING\n' > "$FIX_NOTHING"
FIX_APOLOGY="$SANDBOX/fix-apology.md";   printf 'I need permission to write the file — please approve the write.\n' > "$FIX_APOLOGY"
FIX_EMPTY="$SANDBOX/fix-empty.md";       : > "$FIX_EMPTY"
FIX_WRAPPED="$SANDBOX/fix-wrapped.md"
{
  printf 'Here is the day file you asked for:\n\n```markdown\n'
  cat "$FIX_CLEAN"
  printf '```\n\nLet me know if you want changes.\n'
} > "$FIX_WRAPPED"

# ---- Transcript generator: N countable user turns, N assistant turns, then
# pad with tool_result user entries (bytes that must NOT count as turns).
mk_transcript() {  # $1 = dest, $2 = user turns, $3 = min total bytes
  local dest="$1" turns="$2" min_bytes="$3" i
  : > "$dest"
  for ((i = 1; i <= turns; i++)); do
    printf '{"type":"user","message":{"content":"user prompt number %s asking for some work"}}\n' "$i" >> "$dest"
    printf '{"type":"assistant","message":{"content":[{"type":"text","text":"assistant reply number %s"}]}}\n' "$i" >> "$dest"
  done
  local pad='{"type":"user","message":{"content":[{"type":"tool_result","content":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"}]}}'
  while [ "$(wc -c < "$dest")" -lt "$min_bytes" ]; do
    printf '%s\n' "$pad" >> "$dest"
  done
}

# ---- Per-test project setup ----
mk_project() {  # $1 = name, $2 = "repo"|"norepo"; prints project dir
  local dir="$SANDBOX/$1"
  mkdir -p "$dir"
  if [ "$2" = "repo" ]; then
    git -C "$dir" init -q
    git -C "$dir" config user.email test@test.local
    git -C "$dir" config user.name "Test"
    # Ancient commit so a bare repo never trips the gate's git-window signal.
    GIT_AUTHOR_DATE="2020-01-01T00:00:00 +0000" GIT_COMMITTER_DATE="2020-01-01T00:00:00 +0000" \
      git -C "$dir" commit -q --allow-empty -m "ancient init"
  fi
  printf '%s' "$dir"
}

run_sweep() {  # $1 = project dir, $2 = transcript, $3 = event, $4 = session id
  printf '{"transcript_path":"%s","cwd":"%s","hook_event_name":"%s","session_id":"%s"}' \
    "$2" "$1" "$3" "$4" | bash "$SCRIPT"
}

# ---- Assertion helpers ----
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); printf 'PASS  %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); printf 'FAIL  %s\n' "$1"; }
assert_grep()    { if grep -q "$1" "$2" 2>/dev/null; then ok "$3"; else bad "$3 — pattern '$1' not in $2"; fi; }
assert_no_grep() { if grep -q "$1" "$2" 2>/dev/null; then bad "$3 — pattern '$1' unexpectedly in $2"; else ok "$3"; fi; }
assert_file()    { if [ -f "$1" ]; then ok "$2"; else bad "$2 — missing $1"; fi; }
assert_no_file() { if [ -f "$1" ]; then bad "$2 — $1 should not exist"; else ok "$2"; fi; }

echo "== T1: trivial session (3 turns, tiny transcript, quiet repo) skips without a model call =="
P="$(mk_project t1 repo)"; T="$SANDBOX/t1.jsonl"; mk_transcript "$T" 3 2000
export STUB_CALLED_FILE="$SANDBOX/t1.called"; export STUB_OUTPUT_FILE="$FIX_CLEAN"; export STUB_EXIT=0
run_sweep "$P" "$T" SessionEnd t1-session
assert_grep "SKIP trivial: 3 turns" "$P/knowledge/.sweep/sweep.log" "T1 gate skips and names every signal"
assert_grep "git: no commits since" "$P/knowledge/.sweep/sweep.log" "T1 skip line shows the git signal was consulted"
assert_no_file "$P/knowledge/$(basename "$P")/$TODAY.md" "T1 no day file written"
assert_no_file "$STUB_CALLED_FILE" "T1 no model call made"

echo "== T2: prompt-light / work-heavy (3 turns, 80KB transcript) sweeps — the headline regression =="
P="$(mk_project t2 repo)"; T="$SANDBOX/t2.jsonl"; mk_transcript "$T" 3 80000
export STUB_CALLED_FILE="$SANDBOX/t2.called"
run_sweep "$P" "$T" SessionEnd t2-session
assert_grep "GATE run: transcript .*B >= 50000B" "$P/knowledge/.sweep/sweep.log" "T2 size signal fires despite 3 turns"
assert_grep "OK wrote" "$P/knowledge/.sweep/sweep.log" "T2 sweep completes"
assert_file "$P/knowledge/$(basename "$P")/$TODAY.md" "T2 day file written"
assert_grep "called guard=1" "$STUB_CALLED_FILE" "T2 recursion guard exported during the model call"

echo "== T3: conversational session (12 turns, small transcript) still sweeps =="
P="$(mk_project t3 repo)"; T="$SANDBOX/t3.jsonl"; mk_transcript "$T" 12 0
export STUB_CALLED_FILE="$SANDBOX/t3.called"
run_sweep "$P" "$T" SessionEnd t3-session
assert_grep "GATE run: 12 user turns >= 10" "$P/knowledge/.sweep/sweep.log" "T3 turns signal fires"
assert_grep "OK wrote" "$P/knowledge/.sweep/sweep.log" "T3 sweep completes"

echo "== T4: trivial conversation but a fresh commit in the window sweeps =="
P="$(mk_project t4 repo)"; T="$SANDBOX/t4.jsonl"; mk_transcript "$T" 3 2000
git -C "$P" commit -q --allow-empty -m "feat: real work happened"
export STUB_CALLED_FILE="$SANDBOX/t4.called"
run_sweep "$P" "$T" SessionEnd t4-session
assert_grep "GATE run: 1 commit(s) since" "$P/knowledge/.sweep/sweep.log" "T4 git signal fires"
assert_grep "OK wrote" "$P/knowledge/.sweep/sweep.log" "T4 sweep completes"

echo "== T5: historian's own auto-commit does NOT count as work =="
P="$(mk_project t5 repo)"; T="$SANDBOX/t5.jsonl"; mk_transcript "$T" 3 2000
git -C "$P" commit -q --allow-empty -m "history(auto): t5 $TODAY"
export STUB_CALLED_FILE="$SANDBOX/t5.called"
run_sweep "$P" "$T" SessionEnd t5-session
assert_grep "SKIP trivial" "$P/knowledge/.sweep/sweep.log" "T5 auto-commit excluded from git signal"
assert_no_file "$STUB_CALLED_FILE" "T5 no model call made"

echo "== T6: no git repo — gate degrades gracefully, tier-0 signals decide =="
P="$(mk_project t6 norepo)"; T="$SANDBOX/t6.jsonl"; mk_transcript "$T" 3 2000
export STUB_CALLED_FILE="$SANDBOX/t6.called"
run_sweep "$P" "$T" SessionEnd t6-session
assert_grep "SKIP trivial: .*git: unavailable" "$P/knowledge/.sweep/sweep.log" "T6 skip states git was unavailable"
assert_no_file "$STUB_CALLED_FILE" "T6 no model call made"

echo "== T7: PreCompact sweeps, unchanged SessionEnd dedups =="
P="$(mk_project t7 repo)"; T="$SANDBOX/t7.jsonl"; mk_transcript "$T" 3 80000
export STUB_CALLED_FILE="$SANDBOX/t7.called"
run_sweep "$P" "$T" PreCompact t7-session
run_sweep "$P" "$T" SessionEnd t7-session
assert_grep "\[PreCompact\] OK wrote" "$P/knowledge/.sweep/sweep.log" "T7 PreCompact sweep ran"
assert_grep "\[SessionEnd\] SKIP already swept at .*B" "$P/knowledge/.sweep/sweep.log" "T7 unchanged SessionEnd deduped on bytes"
[ "$(grep -c '^called' "$STUB_CALLED_FILE")" -eq 1 ] && ok "T7 exactly one model call" || bad "T7 expected 1 model call, got $(grep -c '^called' "$STUB_CALLED_FILE")"

echo "== T8: transcript grows past the delta after PreCompact — SessionEnd re-sweeps =="
P="$(mk_project t8 repo)"; T="$SANDBOX/t8.jsonl"; mk_transcript "$T" 3 80000
export STUB_CALLED_FILE="$SANDBOX/t8.called"
run_sweep "$P" "$T" PreCompact t8-session
mk_transcript "$SANDBOX/t8-extra.jsonl" 0 6000; cat "$SANDBOX/t8-extra.jsonl" >> "$T"
run_sweep "$P" "$T" SessionEnd t8-session
[ "$(grep -c '^called' "$STUB_CALLED_FILE")" -eq 2 ] && ok "T8 grown transcript re-swept (post-compact work not lost)" || bad "T8 expected 2 model calls, got $(grep -c '^called' "$STUB_CALLED_FILE")"

echo "== T9: NOTHING response logs OK-nothing and writes no day file =="
P="$(mk_project t9 repo)"; T="$SANDBOX/t9.jsonl"; mk_transcript "$T" 12 0
export STUB_CALLED_FILE="$SANDBOX/t9.called"; export STUB_OUTPUT_FILE="$FIX_NOTHING"
run_sweep "$P" "$T" SessionEnd t9-session
assert_grep "OK nothing capture-worthy" "$P/knowledge/.sweep/sweep.log" "T9 NOTHING handled"
assert_no_file "$P/knowledge/$(basename "$P")/$TODAY.md" "T9 no day file written"

echo "== T10: malformed output fails safe — preserved in failed/, queued in pending.log =="
P="$(mk_project t10 repo)"; T="$SANDBOX/t10.jsonl"; mk_transcript "$T" 12 0
export STUB_OUTPUT_FILE="$FIX_APOLOGY"
run_sweep "$P" "$T" SessionEnd t10-session
assert_grep "FAIL output not a day file (reason=no-front-matter" "$P/knowledge/.sweep/sweep.log" "T10 rich diagnostic logged"
assert_file "$P/knowledge/.sweep/failed/$TODAY-t10-session.raw.md" "T10 raw output preserved"
assert_grep "t10-session" "$P/knowledge/.sweep/pending.log" "T10 queued for retry"
assert_no_file "$P/knowledge/$(basename "$P")/$TODAY.md" "T10 no day file written"

echo "== T11: empty output fails safe with its own diagnostic =="
P="$(mk_project t11 repo)"; T="$SANDBOX/t11.jsonl"; mk_transcript "$T" 12 0
export STUB_OUTPUT_FILE="$FIX_EMPTY"
run_sweep "$P" "$T" SessionEnd t11-session
assert_grep "reason=empty-output" "$P/knowledge/.sweep/sweep.log" "T11 empty output diagnosed"
assert_grep "t11-session" "$P/knowledge/.sweep/pending.log" "T11 queued for retry"

echo "== T12: preamble + fenced + postamble output is tolerantly extracted =="
P="$(mk_project t12 repo)"; T="$SANDBOX/t12.jsonl"; mk_transcript "$T" 12 0
export STUB_OUTPUT_FILE="$FIX_WRAPPED"
run_sweep "$P" "$T" SessionEnd t12-session
DF="$P/knowledge/$(basename "$P")/$TODAY.md"
assert_grep "OK wrote" "$P/knowledge/.sweep/sweep.log" "T12 wrapped output accepted"
[ "$(head -1 "$DF" 2>/dev/null)" = "---" ] && ok "T12 day file starts at front matter" || bad "T12 day file first line is '$(head -1 "$DF" 2>/dev/null)'"
assert_no_grep '```' "$DF" "T12 no fence residue in day file"
assert_no_grep "Let me know" "$DF" "T12 no postamble residue in day file"

echo "== T13: model call failure queues the transcript for retry =="
P="$(mk_project t13 repo)"; T="$SANDBOX/t13.jsonl"; mk_transcript "$T" 12 0
export STUB_OUTPUT_FILE="$FIX_CLEAN"; export STUB_EXIT=1
run_sweep "$P" "$T" SessionEnd t13-session
export STUB_EXIT=0
assert_grep "FAIL model call" "$P/knowledge/.sweep/sweep.log" "T13 failure logged"
assert_grep "t13-session" "$P/knowledge/.sweep/pending.log" "T13 queued for retry"

echo
echo "======================================"
printf 'RESULT: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
