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
#   - Idempotent across PreCompact -> SessionEnd: skips if the transcript has not
#     meaningfully grown since the last sweep of this session; otherwise the
#     SWEEP prompt merges rather than duplicates.
#   - Skips only provably trivial sessions (v3.1 triviality gate): any single
#     deterministic WORK signal — transcript size, user turns, or git activity —
#     runs the sweep. See docs/adr/ADR-001-capture-gate-triviality.md.
#
# Requirements: bash, jq, git (optional), claude CLI on PATH.
# Config (env): HISTORIAN_MODEL       optional model override for the sweep call
#               HISTORIAN_MIN_TURNS   default 10 — user turns at/above which the
#                                     turns signal reads WORK (one gate signal;
#                                     no longer the whole gate as in v3.0)
#               HISTORIAN_WORK_BYTES  default 50000 — raw transcript bytes
#                                     at/above which the size signal reads WORK
#               HISTORIAN_GIT_WINDOW  default "12 hours ago" — non-historian
#                                     commits since this read WORK
#               HISTORIAN_DEDUP_DELTA default 4096 — bytes the transcript must
#                                     grow beyond the last sweep to re-sweep

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

# ---- Capture gate (v3.1): a triviality gate, not a significance gate ----
# Invariant: skip ONLY when every AVAILABLE deterministic signal proves the
# session trivial. Any single WORK signal runs the sweep; an unavailable
# signal can never argue for skipping. A false run costs one cheap model call
# that concludes NOTHING; a false skip silently loses engineering history —
# so the gate always degrades toward running. No signal here estimates
# significance; that is the sweep model's job (SWEEP.md gates G1-G4).
# Rationale and rejected alternatives: docs/adr/ADR-001-capture-gate-triviality.md.
RAW_BYTES="$(wc -c < "$TRANSCRIPT" | tr -d '[:space:]')"
RAW_BYTES="${RAW_BYTES:-0}"
USER_TURNS="$(extract_transcript | grep -c '^\[user\]' || true)"
USER_TURNS="${USER_TURNS:-0}"

TURNS_WORK="${HISTORIAN_MIN_TURNS:-10}"
BYTES_WORK="${HISTORIAN_WORK_BYTES:-50000}"
GIT_WINDOW="${HISTORIAN_GIT_WINDOW:-12 hours ago}"

GATE_RUN_REASON=""

# Tier 0a — raw transcript size. Deliberately reads the file on disk, not
# parsed content: tool-heavy agentic sessions are huge on disk however few
# prompts they contain, and this signal keeps firing even if the transcript
# schema drifts and extraction goes quiet (turns=0 must never imply trivial
# on its own).
if [ "$RAW_BYTES" -ge "$BYTES_WORK" ]; then
  GATE_RUN_REASON="transcript ${RAW_BYTES}B >= ${BYTES_WORK}B"
fi

# Tier 0b — user turns (the entire v3.0 gate, demoted to one signal among equals).
if [ -z "$GATE_RUN_REASON" ] && [ "$USER_TURNS" -ge "$TURNS_WORK" ]; then
  GATE_RUN_REASON="$USER_TURNS user turns >= $TURNS_WORK"
fi

# Tier 1 — git evidence, when a repo is present. Commits in the window count
# as work; the historian's own auto-commits do not. Outside a repo the signal
# is unavailable, which per the invariant just means one fewer way to prove
# triviality — never a reason to skip.
GIT_SIGNAL="unavailable"
if [ -z "$GATE_RUN_REASON" ] && git rev-parse --git-dir >/dev/null 2>&1; then
  RECENT_COMMITS="$(git log --since="$GIT_WINDOW" --oneline --grep='^history(auto):' --invert-grep 2>/dev/null | grep -c . || true)"
  if [ "${RECENT_COMMITS:-0}" -gt 0 ]; then
    GATE_RUN_REASON="$RECENT_COMMITS commit(s) since $GIT_WINDOW"
  else
    GIT_SIGNAL="no commits since $GIT_WINDOW"
  fi
fi

if [ -z "$GATE_RUN_REASON" ]; then
  log "SKIP trivial: $USER_TURNS turns < $TURNS_WORK, ${RAW_BYTES}B < ${BYTES_WORK}B, git: $GIT_SIGNAL — every available signal trivial ($SESSION_ID)"
  exit 0
fi

# ---- Dedup: skip if already swept and the transcript has not meaningfully grown ----
# Keyed on raw bytes, not user turns (v3.0): turns miss autonomous post-compact
# work — PreCompact sweeps at N turns, the model keeps working, SessionEnd
# arrives still at N turns and was wrongly deduped. Bytes grow with any
# activity, so a real continuation re-sweeps (SWEEP.md rule 6 merges, never
# duplicates), while the few bytes of a bare exit stay under the delta.
SESSLOG="$SWEEPDIR/sessions.log"
touch "$SESSLOG"
DEDUP_DELTA="${HISTORIAN_DEDUP_DELTA:-4096}"
PREV_BYTES="$(grep "^$SESSION_ID	" "$SESSLOG" 2>/dev/null | tail -1 | cut -f2)"
if [ -n "${PREV_BYTES:-}" ] && [ "$RAW_BYTES" -le "$((PREV_BYTES + DEDUP_DELTA))" ]; then
  log "SKIP already swept at ${PREV_BYTES}B, now ${RAW_BYTES}B (growth <= ${DEDUP_DELTA}B) ($SESSION_ID)"; exit 0
fi

log "GATE run: $GATE_RUN_REASON [turns=$USER_TURNS bytes=$RAW_BYTES] ($SESSION_ID)"

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

# The sweep is pure text generation: the entire prompt (rules, existing day
# file, git delta, transcript) is already assembled and piped via stdin, and
# the wrapper script — not the model — writes $OUT_FILE to disk afterward.
# The model should never call a tool. Enforced two ways: disallowedTools
# removes these tools from the model's context entirely (it can't attempt
# what it can't see), and dontAsk denies anything unlisted immediately
# instead of prompting or hanging — there is no human here to approve.
SAFETY_ARGS=(
  --permission-mode dontAsk
  --disallowedTools "Read,Write,Edit,NotebookEdit,Bash,Task,WebFetch,WebSearch,Glob,Grep"
)

export HISTORIAN_SWEEP_ACTIVE=1
if ! timeout 300 claude -p "${MODEL_ARGS[@]}" "${SAFETY_ARGS[@]}" < "$PROMPT_FILE" > "$OUT_FILE" 2>>"$LOG"; then
  printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
  log "FAIL model call — transcript queued in pending.log ($SESSION_ID)"
  exit 0
fi
unset HISTORIAN_SWEEP_ACTIVE

# ---- Validate model output: locate genuine front matter, tolerate preamble/fences ----
# Model output is untrusted, non-deterministic text that should CONTAIN a day
# file (or the word NOTHING) — not a byte-exact contract on line 1. This
# locates validated front matter (an opening '---' with a closing '---'
# within 15 lines AND at least one key:value line between them — this
# rejects a stray horizontal rule in conversational filler) and extracts
# from there to EOF, dropping any wrapping code fence and post-fence chatter.
#
# Portability note: uses only grep, sed, cut, tr, wc, tail, head, and bash
# builtins — no awk, no mapfile/readarray. Every tool here is one this
# script's ORIGINAL code already exercised successfully (grep, sed via the
# old fence-strip line, mktemp, cut is POSIX-baseline), so it should run
# wherever the rest of the script already runs — Git Bash, WSL, or Linux —
# without introducing a new untested dependency.
classify_and_extract() {
  local raw="$1" dest="$2"

  if [ ! -s "$raw" ] || ! grep -q '[^[:space:]]' "$raw"; then
    printf 'reason=empty-output bytes=%s' "$(wc -c < "$raw")"
    return 20
  fi

  local stripped
  stripped="$(sed -e 's/^```.*$//' -e 's/\r$//' "$raw" | tr -d '[:space:]')"
  if printf '%s' "$stripped" | grep -qiE '^nothing\.?$'; then
    return 10
  fi

  # Candidate '---' delimiter line numbers (CR-tolerant, trailing-space-tolerant).
  local dash_lines
  dash_lines="$(grep -nE '^---[[:space:]]*\r?$' "$raw" | cut -d: -f1)"

  local start_line="" prev="" d
  for d in $dash_lines; do
    if [ -n "$prev" ]; then
      local gap=$((d - prev))
      if [ "$gap" -ge 2 ] && [ "$gap" -le 16 ]; then
        if sed -n "$((prev+1)),$((d-1))p" "$raw" | grep -qE '^[A-Za-z_-]+:[[:space:]]*'; then
          start_line="$prev"
          break
        fi
      fi
    fi
    prev="$d"
  done

  if [ -z "$start_line" ]; then
    local bytes lines dashes head200
    bytes="$(wc -c < "$raw")"; lines="$(wc -l < "$raw")"
    dashes="$(printf '%s\n' "$dash_lines" | grep -c . || true)"
    head200="$(head -c 200 "$raw" | tr '\n\t' '  ')"
    printf "reason=no-front-matter bytes=%s lines=%s bare-dashes=%s head='%s'" "$bytes" "$lines" "$dashes" "$head200"
    return 20
  fi

  # Extract from the opening delimiter to EOF, then trim trailing blanks and
  # a trailing wrapper fence (and anything a model appended after it).
  local buf=() line
  while IFS= read -r line || [ -n "$line" ]; do
    buf+=("${line%$'\r'}")
  done < <(tail -n +"$start_line" "$raw")

  local n=${#buf[@]}
  while [ "$n" -gt 0 ] && [ -z "$(printf '%s' "${buf[$((n-1))]}" | tr -d '[:space:]')" ]; do
    n=$((n-1))
  done
  if [ "$n" -gt 0 ] && [[ "${buf[$((n-1))]}" == '```'* ]]; then
    n=$((n-1))
    while [ "$n" -gt 0 ] && [ -z "$(printf '%s' "${buf[$((n-1))]}" | tr -d '[:space:]')" ]; do
      n=$((n-1))
    done
  fi

  : > "$dest"
  local i
  for ((i = 0; i < n; i++)); do
    printf '%s\n' "${buf[$i]}" >> "$dest"
  done

  # If chatter followed a closing fence, the fence line survives mid-file; cut there.
  local fence_line
  fence_line="$(grep -n '^```' "$dest" | head -1 | cut -d: -f1)"
  if [ -n "$fence_line" ]; then
    sed -i "${fence_line},\$d" "$dest"
    local buf2=() line2
    while IFS= read -r line2 || [ -n "$line2" ]; do buf2+=("$line2"); done < "$dest"
    local n2=${#buf2[@]}
    while [ "$n2" -gt 0 ] && [ -z "$(printf '%s' "${buf2[$((n2-1))]}" | tr -d '[:space:]')" ]; do
      n2=$((n2-1))
    done
    : > "$dest"
    for ((i = 0; i < n2; i++)); do printf '%s\n' "${buf2[$i]}" >> "$dest"; done
  fi

  return 0
}

# ---- Validate and write atomically ----
EXTRACTED="$(mktemp)"
DIAG="$(classify_and_extract "$OUT_FILE" "$EXTRACTED")"
RC=$?

if [ "$RC" -eq 10 ]; then
  rm -f "$EXTRACTED"
  printf '%s\t%s\t%s\n' "$SESSION_ID" "$RAW_BYTES" "$USER_TURNS" >> "$SESSLOG"
  log "OK nothing capture-worthy ($USER_TURNS turns, ${RAW_BYTES}B, $SESSION_ID)"
  exit 0
fi

if [ "$RC" -eq 20 ]; then
  rm -f "$EXTRACTED"
  FAILEDDIR="$SWEEPDIR/failed"
  mkdir -p "$FAILEDDIR"
  KEEP="$FAILEDDIR/$TODAY-$SESSION_ID.raw.md"
  cp "$OUT_FILE" "$KEEP" 2>/dev/null
  ls -1t "$FAILEDDIR" 2>/dev/null | tail -n +21 | while read -r f; do rm -f "$FAILEDDIR/$f"; done
  printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
  log "FAIL output not a day file ($DIAG) — raw preserved at $KEEP — queued in pending.log"
  exit 0
fi

TMP_DAY="$(mktemp -p "$(dirname "$DAYFILE")")"
cp "$EXTRACTED" "$TMP_DAY" && mv "$TMP_DAY" "$DAYFILE"
rm -f "$EXTRACTED"
printf '%s\t%s\t%s\n' "$SESSION_ID" "$RAW_BYTES" "$USER_TURNS" >> "$SESSLOG"
N_AUTO="$(grep -c '^status: auto' "$DAYFILE" || true)"
log "OK wrote $DAYFILE ($N_AUTO auto cases, $USER_TURNS turns, ${RAW_BYTES}B, $SESSION_ID)"

# ---- Commit, mirroring v2.5 /history behavior (never push) ----
if git rev-parse --git-dir >/dev/null 2>&1 && [ ! -d "$(git rev-parse --git-dir)/rebase-merge" ]; then
  git add "$VAULT" 2>/dev/null
  git commit -q -m "history(auto): $PROJECT $TODAY" 2>/dev/null && log "OK committed" || true
fi

exit 0
