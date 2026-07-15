#!/usr/bin/env bash
# historian-sweep.sh — Engineering Historian automation layer, Tier A adapter (Claude Code)
# Fired by SessionEnd and PreCompact hooks. Reads hook JSON on stdin, extracts the
# input contract (transcript, project_dir, timestamp, git_range), runs SWEEP.md
# through a headless model call, and writes/updates the v2.5 day file.
#
# Modes:
#   (no args)             hook mode — reads hook JSON on stdin (SessionEnd/PreCompact)
#   --doctor              read-only diagnostic: tool visibility, vault state, queue depth
#   --status              short tail: last sweep.log lines + pending count
#   --replay T CWD SID    re-run the pipeline for one pending.log entry directly,
#                         bypassing the triviality gate and dedup (the entry already
#                         earned a sweep); on success, removes matching pending.log
#                         lines for that transcript. Used by /distill step -1.
#
# Design guarantees:
#   - Never blocks or delays the user: registered with "async": true in
#     settings.json (Claude Code's own non-blocking hook mechanism), so the
#     script's own runtime never holds up session close or compaction.
#   - Never recurses: the headless sweep session is guarded by HISTORIAN_SWEEP_ACTIVE.
#   - Never loses evidence silently: failures append the transcript path to
#     knowledge/.sweep/pending.log for retry at next sweep or /distill --replay.
#   - Idempotent across PreCompact -> SessionEnd: skips if the transcript has not
#     meaningfully grown since the last sweep of this session; otherwise the
#     SWEEP prompt merges rather than duplicates.
#   - Skips only provably trivial sessions (v3.1 triviality gate): any single
#     deterministic WORK signal — transcript size, user turns, or git activity —
#     runs the sweep. See docs/adr/ADR-001-capture-gate-triviality.md.
#   - Never commits anything outside knowledge/: the auto-commit is pathspec-limited
#     and skipped outright during any git operation in progress (merge/rebase/
#     cherry-pick/bisect), so it can never absorb the user's own staged work.
#   - Never silently drops an existing case: before overwriting a day file, every
#     case slug already on disk must still be present in the new output, or the
#     write is treated as a validation failure (old file kept, raw preserved).
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

# ---- Mode dispatch ----
MODE="hook"
REPLAY_TRANSCRIPT=""
REPLAY_CWD=""
REPLAY_SESSION_ID=""
case "${1:-}" in
  --doctor) MODE="doctor" ;;
  --status) MODE="status" ;;
  --replay)
    MODE="replay"
    REPLAY_TRANSCRIPT="${2:-}"
    REPLAY_CWD="${3:-}"
    REPLAY_SESSION_ID="${4:-replay-$$}"
    ;;
esac

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

# ---- Vault contract self-heal (I2/I3): idempotent, cheap, safe to run every time ----
# INSTALL.md promises capture-rules.md and a gitignored .sweep/ are "created
# automatically ... on the first sweep" — this is what actually does that; prior
# versions relied on a distill pass to improvise it, which is why a live vault
# (issue-runtime) shipped .sweep/ tracked in git until a manual fix.
ensure_gitignore() {
  local f="$VAULT/.gitignore"
  if [ -f "$f" ]; then
    grep -qxF '.sweep/' "$f" 2>/dev/null || printf '.sweep/\n' >> "$f"
  else
    printf '.sweep/\n' > "$f"
  fi
}

ensure_capture_rules() {
  local f="$VAULT/capture-rules.md"
  [ -f "$f" ] && return 0
  cat > "$f" <<'SEED'
# Capture rules — binding negative rules for the sweep

The sweep reads this file before drafting cases. Each rule below is binding: a candidate case matching a rule is not drafted. Rules are added only at `/distill` step 0, from decline reasons.

Discipline:
- **Consolidate, don't accumulate.** A third decline for the same class of noise becomes ONE general rule, not a third near-duplicate.
- **Cap: 25 rules.** At the cap, generalize existing rules before adding; a rules file the sweep can't hold in attention teaches nothing.
- Rules are negative and specific ("do not draft cases for X"), never aspirational.

## Rules

(none yet)

## Sweep health

confirmed: 0
declined: 0
SEED
}

# ---- Slug-preservation guard (I4): a case already on disk must survive a rewrite ----
# The write path replaces the whole day file with model output; SWEEP.md's "never
# delete an existing case" rule (Hard Rule 6) is otherwise enforced by nothing
# deterministic. Returns 0 (all preserved) or 1 (at least one slug vanished).
check_slug_preservation() {
  local old="$1" new="$2" slug
  [ -f "$old" ] || return 0
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    grep -Fxq "$slug" "$new" 2>/dev/null || return 1
  done < <(grep -E '^### CASE: ' "$old" 2>/dev/null)
  return 0
}

# ---- Validate model output: locate genuine front matter, tolerate preamble/fences ----
# Model output is untrusted, non-deterministic text that should CONTAIN a day
# file (or the word NOTHING) — not a byte-exact contract on line 1. This
# locates validated front matter (an opening '---' with a closing '---'
# within 15 lines AND at least one key:value line between them — this
# rejects a stray horizontal rule in conversational filler) and extracts
# from there to EOF, dropping any wrapping code fence and post-fence chatter.
#
# Portability note (I6): uses only grep, sed, cut, tr, wc, tail, head, and bash
# builtins — no awk, no mapfile/readarray, no `sed -i` (BSD/GNU sed disagree on
# its syntax; the fence-strip below rewrites through a temp file instead).
classify_and_extract() {
  local raw="$1" dest="$2" mode="${3:-}"

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

  # Repair path (v3.1.1): a lone opening '---' directly followed by front-matter
  # key:value lines means the model emitted the day file but omitted the CLOSING
  # delimiter (observed live 2026-07-13: a 9KB otherwise-perfect day file lost to
  # one missing line). Insert the missing '---' after the last consecutive
  # key:value line and re-validate. Structural normalization only — the same
  # class as the fence/preamble stripping above; no content is added, removed,
  # or reordered. Guarded to one attempt, and only when the key block contains
  # a known front-matter key, so a stray horizontal rule followed by prose
  # colons can't fake it.
  if [ -z "$start_line" ] && [ "$mode" != "no-repair" ]; then
    local open="" insert_at="" kv seen_known ln
    for d in $dash_lines; do
      kv=0; seen_known=0; ln=$((d+1))
      while [ "$kv" -lt 20 ] && sed -n "${ln}p" "$raw" | grep -qE '^[A-Za-z_-]+:[[:space:]]*'; do
        sed -n "${ln}p" "$raw" | grep -qE '^(project|date|type|stack|status):' && seen_known=1
        kv=$((kv+1)); ln=$((ln+1))
      done
      if [ "$kv" -ge 2 ] && [ "$seen_known" -eq 1 ]; then
        open="$d"; insert_at="$ln"; break
      fi
    done
    if [ -n "$open" ]; then
      local repaired rc2
      repaired="$(mktemp)"
      { head -n "$((insert_at - 1))" "$raw"; printf '%s\n' '---'; tail -n +"$insert_at" "$raw"; } > "$repaired"
      classify_and_extract "$repaired" "$dest" no-repair
      rc2=$?
      rm -f "$repaired"
      [ "$rc2" -eq 0 ] && printf 'repaired=inserted-missing-front-matter-close'
      return "$rc2"
    fi
  fi

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

  # If chatter followed a closing fence, the fence line survives mid-file; cut
  # there via a temp-file rewrite (portable — no `sed -i`, see I6 note above).
  local fence_line
  fence_line="$(grep -n '^```' "$dest" | head -1 | cut -d: -f1)"
  if [ -n "$fence_line" ]; then
    local fence_tmp
    fence_tmp="$(mktemp)"
    sed "${fence_line},\$d" "$dest" > "$fence_tmp"
    local buf2=() line2
    while IFS= read -r line2 || [ -n "$line2" ]; do buf2+=("$line2"); done < "$fence_tmp"
    rm -f "$fence_tmp"
    local n2=${#buf2[@]}
    while [ "$n2" -gt 0 ] && [ -z "$(printf '%s' "${buf2[$((n2-1))]}" | tr -d '[:space:]')" ]; do
      n2=$((n2-1))
    done
    : > "$dest"
    for ((i = 0; i < n2; i++)); do printf '%s\n' "${buf2[$i]}" >> "$dest"; done
  fi

  return 0
}

# ---- Core pipeline: given one event's inputs, gate -> sweep -> validate -> write -> commit ----
# Sets globals (ROOT, PROJECT, VAULT, SWEEPDIR, DAYFILE, LOG, ...) as a side effect so
# callers (replay mode) can inspect them afterward. Returns 0 on a clean outcome
# (wrote a day file, or concluded NOTHING), 1 on a failure queued to pending.log,
# 2 on a gate/dedup skip (never returned when SKIP_GATE=1).
run_pipeline() {
  local SKIP_GATE="$1"   # 1 for --replay: the entry already earned a sweep

  [ -n "$CWD" ] && cd "$CWD" 2>/dev/null || return 2

  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  PROJECT="$(basename "$ROOT")"
  TODAY="$(date +%Y-%m-%d)"
  VAULT="$ROOT/knowledge"
  SWEEPDIR="$VAULT/.sweep"
  DAYFILE="$VAULT/$PROJECT/$TODAY.md"
  SKILL_DIR="${HISTORIAN_SKILL_DIR:-$HOME/.claude/historian}"
  LOG="$SWEEPDIR/sweep.log"

  mkdir -p "$SWEEPDIR" "$VAULT/$PROJECT"
  ensure_gitignore
  ensure_capture_rules

  log() { printf '%s [%s] %s\n' "$(date +'%F %T')" "$EVENT" "$1" >> "$LOG"; }

  if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
    log "SKIP no transcript ($SESSION_ID)"; return 2
  fi

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

  if [ "$SKIP_GATE" = "1" ]; then
    log "GATE bypassed: replay of a queued entry ($SESSION_ID)"
  else
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
      return 2
    fi
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
  if [ "$SKIP_GATE" != "1" ]; then
    PREV_BYTES="$(grep "^$SESSION_ID	" "$SESSLOG" 2>/dev/null | tail -1 | cut -f2)"
    if [ -n "${PREV_BYTES:-}" ] && [ "$RAW_BYTES" -le "$((PREV_BYTES + DEDUP_DELTA))" ]; then
      log "SKIP already swept at ${PREV_BYTES}B, now ${RAW_BYTES}B (growth <= ${DEDUP_DELTA}B) ($SESSION_ID)"; return 2
    fi
    log "GATE run: $GATE_RUN_REASON [turns=$USER_TURNS bytes=$RAW_BYTES] ($SESSION_ID)"
  fi

  # ---- Assemble the sweep prompt from the input contract ----
  SWEEP_PROMPT="$SKILL_DIR/SWEEP.md"
  if [ ! -f "$SWEEP_PROMPT" ]; then log "FAIL SWEEP.md not found at $SWEEP_PROMPT"; return 1; fi

  PROMPT_FILE="$(mktemp)"
  OUT_FILE="$(mktemp)"
  EXTRACTED=""
  TMP_DAY=""
  trap 'rm -f "$PROMPT_FILE" "$OUT_FILE" "$EXTRACTED" "$TMP_DAY"' RETURN

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
  # I6: empty-array-safe expansion under `set -u` (bash 3.2 / macOS default
  # otherwise dies here with "unbound variable" — before anything is queued).
  if ! timeout 300 claude -p ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} "${SAFETY_ARGS[@]}" < "$PROMPT_FILE" > "$OUT_FILE" 2>>"$LOG"; then
    printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
    log "FAIL model call — transcript queued in pending.log ($SESSION_ID)"
    return 1
  fi
  unset HISTORIAN_SWEEP_ACTIVE

  EXTRACTED="$(mktemp)"
  DIAG="$(classify_and_extract "$OUT_FILE" "$EXTRACTED")"
  RC=$?

  if [ "$RC" -eq 10 ]; then
    printf '%s\t%s\t%s\n' "$SESSION_ID" "$RAW_BYTES" "$USER_TURNS" >> "$SESSLOG"
    log "OK nothing capture-worthy ($USER_TURNS turns, ${RAW_BYTES}B, $SESSION_ID)"
    return 0
  fi

  if [ "$RC" -eq 20 ]; then
    FAILEDDIR="$SWEEPDIR/failed"
    mkdir -p "$FAILEDDIR"
    KEEP="$FAILEDDIR/$TODAY-$SESSION_ID.raw.md"
    cp "$OUT_FILE" "$KEEP" 2>/dev/null
    ls -1t "$FAILEDDIR" 2>/dev/null | tail -n +21 | while read -r f; do rm -f "$FAILEDDIR/$f"; done
    printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
    log "FAIL output not a day file ($DIAG) — raw preserved at $KEEP — queued in pending.log"
    return 1
  fi

  # I4: an existing day file's cases must all survive the rewrite, or this is
  # treated exactly like a validation failure — the old file is never overwritten.
  if ! check_slug_preservation "$DAYFILE" "$EXTRACTED"; then
    FAILEDDIR="$SWEEPDIR/failed"
    mkdir -p "$FAILEDDIR"
    KEEP="$FAILEDDIR/$TODAY-$SESSION_ID.raw.md"
    cp "$OUT_FILE" "$KEEP" 2>/dev/null
    ls -1t "$FAILEDDIR" 2>/dev/null | tail -n +21 | while read -r f; do rm -f "$FAILEDDIR/$f"; done
    printf '%s\t%s\t%s\n' "$TODAY" "$TRANSCRIPT" "$SESSION_ID" >> "$SWEEPDIR/pending.log"
    log "FAIL output would drop an existing case (reason=slug-regression) — raw preserved at $KEEP — queued in pending.log — existing $DAYFILE kept untouched"
    return 1
  fi

  TMP_DAY="$(mktemp -p "$(dirname "$DAYFILE")")"
  cp "$EXTRACTED" "$TMP_DAY" && mv "$TMP_DAY" "$DAYFILE"
  printf '%s\t%s\t%s\n' "$SESSION_ID" "$RAW_BYTES" "$USER_TURNS" >> "$SESSLOG"
  N_AUTO="$(grep -c '^status: auto' "$DAYFILE" || true)"
  log "OK wrote $DAYFILE ($N_AUTO auto cases, $USER_TURNS turns, ${RAW_BYTES}B${DIAG:+, $DIAG}, $SESSION_ID)"

  # ---- Commit, mirroring v2.5 /history behavior (never push) ----
  # I1: pathspec-limited to $VAULT so the auto-commit can never absorb anything
  # a user has staged elsewhere in the repo, and skipped outright — with an
  # explicit log line instead of silence — during any git operation in progress
  # (a bare rebase-merge check previously missed merge/cherry-pick/bisect).
  if git rev-parse --git-dir >/dev/null 2>&1; then
    GITDIR="$(git rev-parse --git-dir)"
    if [ -d "$GITDIR/rebase-merge" ] || [ -d "$GITDIR/rebase-apply" ] || \
       [ -f "$GITDIR/MERGE_HEAD" ] || [ -f "$GITDIR/CHERRY_PICK_HEAD" ] || \
       [ -f "$GITDIR/BISECT_LOG" ]; then
      log "SKIP commit: git operation in progress (rebase/merge/cherry-pick/bisect)"
    else
      git add "$VAULT" 2>/dev/null
      if git commit -q -m "history(auto): $PROJECT $TODAY" -- "$VAULT" 2>>"$LOG"; then
        log "OK committed"
      else
        log "WARN commit failed or nothing to commit"
      fi
    fi
  fi

  return 0
}

# ---- Doctor mode (I5): read-only diagnostic, never touches stdin, never hangs ----
doctor_mode() {
  echo "== Engineering Historian doctor =="
  local problems=0

  echo "-- Tools visible to THIS shell (the hook runs in a non-login Git Bash on Windows — see INSTALL.md) --"
  if command -v jq >/dev/null 2>&1; then
    echo "jq:     OK  ($(command -v jq))"
  else
    echo "jq:     MISSING — the sweep exits silently before logging anything. See INSTALL.md 'Windows (native, no WSL)'."
    problems=1
  fi
  if command -v git >/dev/null 2>&1; then
    echo "git:    OK  ($(command -v git))"
  else
    echo "git:    missing (optional — vault falls back to cwd; the gate loses its git signal and auto-commit is skipped)"
  fi
  if command -v claude >/dev/null 2>&1; then
    echo "claude: OK  ($(command -v claude))"
  else
    echo "claude: MISSING — every sweep will fail the model call and queue to pending.log."
    problems=1
  fi

  local skill_dir="${HISTORIAN_SKILL_DIR:-$HOME/.claude/historian}"
  if [ -f "$skill_dir/SWEEP.md" ]; then
    echo "SWEEP.md: OK  ($skill_dir/SWEEP.md)"
  else
    echo "SWEEP.md: MISSING at $skill_dir — set HISTORIAN_SKILL_DIR or re-run INSTALL.md step 1."
    problems=1
  fi

  local root vault sweepdir
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  vault="$root/knowledge"
  sweepdir="$vault/.sweep"
  echo "-- Vault --"
  echo "resolved project root: $root"
  if [ -d "$vault" ]; then echo "vault: $vault (exists)"; else echo "vault: $vault (not created yet — the first sweep creates it)"; fi

  if [ -f "$sweepdir/sweep.log" ]; then
    echo "-- Recent sweep.log activity --"
    echo "last OK:   $(grep ' OK ' "$sweepdir/sweep.log" 2>/dev/null | tail -1)"
    local lastfail
    lastfail="$(grep 'FAIL' "$sweepdir/sweep.log" 2>/dev/null | tail -1)"
    echo "last FAIL: ${lastfail:-(none)}"
  else
    echo "sweep.log: not found at $sweepdir (no sweep has run in this project yet)"
  fi

  local pending=0
  [ -f "$sweepdir/pending.log" ] && pending="$(grep -c . "$sweepdir/pending.log" 2>/dev/null || echo 0)"
  echo "pending queue: $pending entries (retry with: $0 --replay <transcript> <cwd> <session-id>, or via /distill)"

  local failed=0
  [ -d "$sweepdir/failed" ] && failed="$(ls -1 "$sweepdir/failed" 2>/dev/null | wc -l | tr -d '[:space:]')"
  echo "failed/ archive: $failed raw output(s) preserved (most recent 20 kept)"

  echo
  if [ "$problems" -eq 0 ]; then
    echo "Result: OK — required tools and SWEEP.md are visible to this shell."
    exit 0
  else
    echo "Result: PROBLEMS FOUND — see MISSING lines above."
    exit 1
  fi
}

# ---- Status mode (I5): short tail for a quick daily check, never part of workflow ----
status_mode() {
  local root vault sweepdir
  root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  vault="$root/knowledge"
  sweepdir="$vault/.sweep"
  if [ ! -f "$sweepdir/sweep.log" ]; then
    echo "No sweep activity recorded yet at $sweepdir"
    exit 0
  fi
  echo "== Last 5 sweep.log lines ($sweepdir/sweep.log) =="
  tail -5 "$sweepdir/sweep.log"
  local pending=0
  [ -f "$sweepdir/pending.log" ] && pending="$(grep -c . "$sweepdir/pending.log" 2>/dev/null || echo 0)"
  echo "pending: $pending"
}

# ---- Replay mode (I7): deterministic retry for one pending.log entry ----
# /distill step -1 previously had no real entry point for "re-run the sweep on
# this queued transcript" and the two live recoveries (2026-07-12, 2026-07-13)
# were hand-improvised by the distilling agent instead of going through the
# validator/writer/committer this script already has. This gives it one.
replay_mode() {
  if [ -z "$REPLAY_TRANSCRIPT" ] || [ -z "$REPLAY_CWD" ]; then
    echo "usage: $0 --replay <transcript-path> <cwd> [session-id]" >&2
    exit 2
  fi
  TRANSCRIPT="$REPLAY_TRANSCRIPT"
  CWD="$REPLAY_CWD"
  EVENT="replay"
  SESSION_ID="$REPLAY_SESSION_ID"

  run_pipeline 1
  local rc=$?

  if [ "$rc" -eq 0 ] && [ -f "$SWEEPDIR/pending.log" ]; then
    # I9: drop every pending.log line for this transcript, not just the one
    # entry replayed — PreCompact-then-SessionEnd can queue the same session twice.
    local tmp
    tmp="$(mktemp)"
    grep -vF "	$REPLAY_TRANSCRIPT	" "$SWEEPDIR/pending.log" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$SWEEPDIR/pending.log"
  fi

  exit "$rc"
}

# ---- Dispatch ----
case "$MODE" in
  doctor) doctor_mode ;;
  status) status_mode ;;
  replay) replay_mode ;;
esac

# ---- Hook mode (default): read hook JSON from stdin ----
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

run_pipeline 0
exit 0
