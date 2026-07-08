#!/usr/bin/env bash
# historian-sweep.sh — Engineering Historian automation layer, Tier A adapter (Claude Code)
# Fired by SessionEnd and PreCompact hooks. Reads hook JSON on stdin, extracts the
# input contract (transcript, project_dir, timestamp, git_range), runs SWEEP.md
# through a headless model call, and writes/updates the v2.5 day file.
#
# Design guarantees:
#   - Never blocks or delays the user: registered with "async": true in
#     settings.json (Claude Code's own non-blocking hook mechanism), so the
#     script's own runtime never holds up session close or compaction.
#   - Never recurses: the headless sweep session is guarded by HISTORIAN_SWEEP_ACTIVE.
#   - Never loses evidence silently: failures append the transcript path to
#     knowledge/.sweep/pending.log for retry at next sweep or /distill.
#   - Idempotent across PreCompact -> SessionEnd: skips if user-turn count unchanged;
#     otherwise the SWEEP prompt merges rather than duplicates.
#
# Requirements: bash, jq, git (optional), claude CLI on PATH.
# Config (env): HISTORIAN_MODEL (optional model override for the sweep call)
#               HISTORIAN_MIN_TURNS (default 10 — skip trivial sessions)

set -u

# ---- Recursion guard: the sweep's own headless session must never sweep itself ----
if [ "${HISTORIAN_SWEEP_ACTIVE:-0}" = "1" ]; then exit 0; fi

# ---- Read hook JSON from stdin ----
# No manual backgrounding here: the hook is registered with "async": true in
# settings.json, which is Claude Code's own documented mechanism for "run this
# without blocking, and don't wait for it to finish." That is strictly better
# than a hand-rolled nohup/setsid trick (setsid doesn't even exist on macOS or
# Windows/Git-Bash), so the script runs straight through, synchronously.
HOOK_JSON="$(cat)"

command -v jq >/dev/null 2>&1 || exit 0   # no jq, no sweep — fail closed, silently

TRANSCRIPT="$(printf '%s' "$HOOK_JSON" | jq -r '.transcript_path // empty')"
CWD="$(printf '%s' "$HOOK_JSON" | jq -r '.cwd // empty')"
EVENT="$(printf '%s' "$HOOK_JSON" | jq -r '.hook_event_name // "unknown"')"
SESSION_ID="$(printf '%s' "$HOOK_JSON" | jq -r '.session_id // "unknown"')"

[ -n "$CWD" ] && cd "$CWD" 2>/dev/null || exit 0

# ---- Resolve vault location: repo root if in a repo, else cwd ----
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
PROJECT="$(basename "$ROOT")"
TODAY="$(date +%Y-%m-%d)"
VAULT="$ROOT/knowledge"
SWEEPDIR="$VAULT/.sweep"                       # operational state, not vault content
DAYFILE="$VAULT/$PROJECT/$TODAY.md"
SKILL_DIR="${HISTORIAN_SKILL_DIR:-$HOME/.claude/historian}"   # SWEEP.md lives here
LOG="$SWEEPDIR/sweep.log"

mkdir -p "$SWEEPDIR" "$VAULT/$PROJECT"
log() { printf '%s [%s] %s\n' "$(date +'%F %T')" "$EVENT" "$1" >> "$LOG"; }

# ---- Transcript must exist ----
if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  log "SKIP no transcript ($SESSION_ID)"; exit 0
fi

# ---- Extract user/assistant text from JSONL (tolerant of unparseable lines) ----
extract_transcript() {
  jq -rR '
    fromjson? |
    select(.type == "user" or .type == "assistant") |
    (.message.content // empty) as $c |
    (if ($c | type) == "string" then $c
     elif ($c | type) == "array" then
       ([$c[]? | select(.type == "text") | .text] | join("\n"))
     else empty end) as $t |
    select($t != null and ($t | length) > 0) |
    "[\(.type)] \($t[0:2500])"
  ' "$TRANSCRIPT" 2>/dev/null
}

USER_TURNS="$(extract_transcript | grep -c '^\[user\]' || true)"
MIN_TURNS="${HISTORIAN_MIN_TURNS:-10}"
if [ "${USER_TURNS:-0}" -lt "$MIN_TURNS" ]; then
  log "SKIP trivial session: $USER_TURNS user turns ($SESSION_ID)"; exit 0
fi

# ---- Dedup: skip if this session was already swept at this turn count ----
SESSLOG="$SWEEPDIR/sessions.log"
touch "$SESSLOG"
PREV_TURNS="$(grep "^$SESSION_ID	" "$SESSLOG" 2>/dev/null | tail -1 | cut -f2)"
if [ -n "${PREV_TURNS:-}" ] && [ "$USER_TURNS" -le "$PREV_TURNS" ]; then
  log "SKIP already swept at $PREV_TURNS turns ($SESSION_ID)"; exit 0
fi

# ---- Assemble the sweep prompt from the input contract ----
SWEEP_PROMPT="$SKILL_DIR/SWEEP.md"
if [ ! -f "$SWEEP_PROMPT" ]; then log "FAIL SWEEP.md not found at $SWEEP_PROMPT"; exit 0; fi

PROMPT_FILE="$(mktemp)"
OUT_FILE="$(mktemp)"
trap 'rm -f "$PROMPT_FILE" "$OUT_FILE"' EXIT

{
  cat "$SWEEP_PROMPT"

  printf '\n\n=== CAPTURE RULES (binding negative rules from past declines) ===\n'
  if [ -f "$VAULT/capture-rules.md" ]; then cat "$VAULT/capture-rules.md"; else echo "(none yet)"; fi

  printf '\n\n=== CONTEXT ===\nproject: %s\ndate: %s\ntrigger: %s\n' "$PROJECT" "$TODAY" "$EVENT"

  printf '\n=== EXISTING DAY FILE (%s) ===\n' "knowledge/$PROJECT/$TODAY.md"
  if [ -f "$DAYFILE" ]; then cat "$DAYFILE"; else echo "(does not exist yet)"; fi

  printf '\n\n=== GIT DELTA (corroboration only — may demote or flag, never create) ===\n'
  if git rev-parse --git-dir >/dev/null 2>&1; then
    echo "-- commits (last 12h) --"
    git log --since="12 hours ago" --oneline 2>/dev/null | head -30 || true
    echo "-- working tree + staged, stat --"
    git diff HEAD --stat 2>/dev/null | tail -40 || true
  else
    echo "(not a git repository)"
  fi

  printf '\n\n=== SESSION TRANSCRIPT (authoritative evidence) ===\n'
  extract_transcript | tail -c 400000
} > "$PROMPT_FILE"

# ---- Headless model call: text in, complete day file (or NOTHING) out ----
MODEL_ARGS=()
[ -n "${HISTORIAN_MODEL:-}" ] && MODEL_ARGS=(--model "$HISTORIAN_MODEL")

export HISTORIAN_SWEEP_ACTIVE=1
if ! timeout 300 claude -p "${MODEL_ARGS[@]}" < "$PROMPT_FILE" > "$OUT_FILE" 2>>"$LOG"; then
  printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
  log "FAIL model call — transcript queued in pending.log ($SESSION_ID)"
  exit 0
fi
unset HISTORIAN_SWEEP_ACTIVE

# ---- Validate and write atomically ----
# Strip a leading/trailing markdown fence if the model added one despite instructions.
sed -i '1{/^```/d}; ${/^```$/d}' "$OUT_FILE"
FIRST_LINE="$(head -c 20 "$OUT_FILE" | head -1)"

if grep -qx 'NOTHING' "$OUT_FILE"; then
  printf '%s\t%s\n' "$SESSION_ID" "$USER_TURNS" >> "$SESSLOG"
  log "OK nothing capture-worthy ($USER_TURNS turns, $SESSION_ID)"
  exit 0
fi

if [ "$FIRST_LINE" != "---" ]; then
  printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
  log "FAIL output not a day file (starts: '$FIRST_LINE') — queued in pending.log"
  exit 0
fi

TMP_DAY="$(mktemp -p "$(dirname "$DAYFILE")")"
cp "$OUT_FILE" "$TMP_DAY" && mv "$TMP_DAY" "$DAYFILE"
printf '%s\t%s\n' "$SESSION_ID" "$USER_TURNS" >> "$SESSLOG"
N_AUTO="$(grep -c '^status: auto' "$DAYFILE" || true)"
log "OK wrote $DAYFILE ($N_AUTO auto cases, $USER_TURNS turns, $SESSION_ID)"

# ---- Commit, mirroring v2.5 /history behavior (never push) ----
if git rev-parse --git-dir >/dev/null 2>&1 && [ ! -d "$(git rev-parse --git-dir)/rebase-merge" ]; then
  git add "$VAULT" 2>/dev/null
  git commit -q -m "history(auto): $PROJECT $TODAY" 2>/dev/null && log "OK committed" || true
fi

exit 0
