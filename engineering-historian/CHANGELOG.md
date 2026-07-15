# Changelog — Engineering Historian

## v3.1.2 — 2026-07-15 — production hardening review (Phase 1)

Nothing changes in what is captured, promoted, retrieved, or stored. This release closes gaps found during a production-readiness review of v3.1: a host-repo integrity defect, two places where the vault's own stated guarantees ("`.sweep/` is gitignored", "capture-rules.md is seeded automatically") weren't actually true in a live vault, a case-loss path with no deterministic guard, and no way to run the sweep or diagnose it outside of waiting for a hook to fire.

- `scripts/historian-sweep.sh` — **(I1, Critical)** the auto-commit is now pathspec-limited to `knowledge/` (`git commit ... -- "$VAULT"`) and skipped outright — with an explicit `SKIP commit: git operation in progress` log line — during a merge, rebase, cherry-pick, or bisect. Previously `git add "$VAULT" && git commit` staged and committed the *entire index* with no pathspec, so anything a user had staged elsewhere in the same repo could be swept into a `history(auto):` commit under the wrong message; the in-progress guard also only checked `rebase-merge`, missing merge/cherry-pick/bisect.
- `scripts/historian-sweep.sh` — **(I2)** every invocation now self-heals `knowledge/.gitignore` to contain `.sweep/` if it doesn't already. `.sweep/` was documented as "gitignored, never cited" but nothing ever created the gitignore; a live vault (`issue-runtime`) had `.sweep/pending.log`/`sessions.log`/`sweep.log` tracked in git until a manual fix.
- `scripts/historian-sweep.sh` — **(I3)** `knowledge/capture-rules.md` is now seeded on first touch (embedded, no longer depends on a separate copy step). INSTALL.md claimed this already happened automatically; it didn't — the file was only ever created by a distill pass improvising it.
- `scripts/historian-sweep.sh` — **(I4)** before overwriting an existing day file, every `### CASE:` slug already on disk must still be present in the new output, or the write is treated exactly like a validation failure: the old file is kept untouched, the raw model output is preserved to `failed/`, and the transcript is queued to `pending.log`. Previously a day file was replaced wholesale on trust in the model's own "never delete a case" instruction (SWEEP.md Hard Rule 6), with no deterministic check.
- `scripts/historian-sweep.sh` — new `--doctor` (read-only diagnostic: tool visibility in the invoking shell, `SWEEP.md` resolution, vault state, pending/failed counts, exits non-zero on a problem) and `--status` (short `sweep.log` tail + pending count) entry points. Neither touches stdin, so — unlike hook mode — they return immediately when run by hand instead of hanging on an unclosed pipe; this was the fastest path to "is this broken" and previously didn't exist.
- `scripts/historian-sweep.sh` — new `--replay <transcript> <cwd> <session-id>` entry point: re-runs the full validator/writer/committer pipeline for one `pending.log` entry, bypassing the triviality gate and dedup (a queued entry already earned a sweep), and removes matching `pending.log` line(s) on success. `/distill` step −1 previously said "re-run the sweep" with no real entry point for that — the two live recoveries on 2026-07-12 and 2026-07-13 were hand-improvised by the distilling agent instead of going through the script's own validator.
- `scripts/historian-sweep.sh` — portability (I6): the model-call argument expansion (`"${MODEL_ARGS[@]}"` on a possibly-empty array) is now the `${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"}` idiom, which doesn't abort under `set -u` on bash 3.2 (macOS's shipped default) the way the original did; the one `sed -i` call (BSD/GNU incompatible syntax) is replaced with a portable temp-file rewrite.
- `scripts/historian-sweep.sh` — the cleanup trap now also covers `$EXTRACTED`/`$TMP_DAY`, not just `$PROMPT_FILE`/`$OUT_FILE`; an abnormal exit between validation and the atomic `mv` could previously leave a stray `tmp.XXXX` file inside `knowledge/<project>/` for the next auto-commit to sweep up.
- `SKILL.md` — step −1 now defines `<last distill date>` (author-date of the most recent `distill:` commit, or the earliest day file if none exists yet) and points at `--replay` as the concrete retry mechanism instead of the vaguer "re-run the sweep".
- `INSTALL.md` — corrected the "created automatically" claim to match what now actually happens; added a **Troubleshooting** section anchored on `--doctor`/`--status`/`--replay`; added the one-time `git rm -r --cached knowledge/.sweep` fix for vaults created before this release.
- `tests/run-tests.sh` — six new end-to-end scenarios (T15–T20, 23 new assertions, 62 total): decoy file staged elsewhere never enters the auto-commit and stays staged; first sweep seeds `.gitignore` and `capture-rules.md` and neither leaks into the commit; an existing case survives a rewrite or the old file is kept with the failure queued; `--doctor`/`--status` return promptly without touching stdin and correctly report a hidden `jq`; `--replay` clears a queued entry and is idempotent on a second run; a merge in progress skips the commit without losing the day file.

### Migration

None required. All changes are additive or fail-safe: existing hooks, config, vaults, and day files are untouched; `--doctor`/`--status`/`--replay` are opt-in troubleshooting commands, never part of the normal flow. Redeploy = copy `scripts/historian-sweep.sh` over the runtime copy per `INSTALL.md` step 1. Vaults created before this release should run the one-time `.sweep` untrack noted in `INSTALL.md`.

## v3.1.1 — 2026-07-13 — validator repairs a missing closing front-matter delimiter

First live v3.1 sweep (issue-runtime, session `735eee11`): the gate and the tool lockdown both worked, and the model returned a complete, well-formed 9KB day file — minus exactly one line, the closing `---` of the front matter. The validator, which requires a bare `---` pair, correctly-per-spec rejected an output that was 99% perfect.

- `scripts/historian-sweep.sh` — `classify_and_extract()` gains a repair path: a lone opening `---` directly followed by 2+ `key: value` lines (at least one a known front-matter key) has the missing closing `---` inserted before the first non-key line, then re-validates. Structural normalization only, same class as the existing fence/preamble stripping; guarded to one attempt. Successful repairs are visible in the `OK wrote` log line as `repaired=inserted-missing-front-matter-close`.
- `assets/SWEEP.md` — Hard Rule 8 now demands the closing `---` explicitly (it previously stressed only the opening delimiter, which is likely why a distiller-grade model dropped the close).
- `tests/run-tests.sh` — T14 reproduces the failure (clean fixture minus its closing delimiter) and asserts repair, both delimiters in the written day file, intact case content, and nothing queued. The fix was additionally replayed against the preserved raw output of the real failure before release: byte-identical result plus the one inserted line.

## v3.1 — 2026-07-13 — production hardening

Nothing changes in what is captured, how it is promoted, retrieved, or stored. v3.1 hardens the automation layer: when the sweep fires, how its output is validated, and how failures are diagnosed.

### The problem

The v3.0 capture gate skipped any session with fewer than 10 user turns. That measured conversation volume as a proxy for engineering work, and agentic workflows broke the proxy: three prompts plus hours of autonomous coding read as "3 turns → skip", silently losing exactly the history the automation exists to capture.

### Root cause

The gate tried to estimate whether a session was *significant enough* to sweep — a judgment no deterministic, model-call-free test can make robustly. Any single proxy for significance gets broken by the next shift in how people work.

### The architectural decision

The gate is now a **triviality gate** (full rationale: `docs/adr/ADR-001-capture-gate-triviality.md`):

> Skip only when every available deterministic signal proves the session was trivial. Otherwise, run the sweep.

Signals: raw transcript bytes, user turns, and git commits in a window (the historian's own auto-commits excluded). Any single WORK signal runs the sweep; a signal that's unavailable (e.g. git outside a repo) can never argue for skipping — the gate degrades toward running. False runs cost one cheap `NOTHING` model call; false skips lose history. Estimating significance remains where it belongs, in the sweep model's four capture gates.

### Changes

- `scripts/historian-sweep.sh` — triviality gate replaces the turn-count gate; every gate decision (run or skip) logs one explainable line naming the deciding signal. New config: `HISTORIAN_WORK_BYTES` (default 50000), `HISTORIAN_GIT_WINDOW` (default "12 hours ago"), `HISTORIAN_DEDUP_DELTA` (default 4096). `HISTORIAN_MIN_TURNS` keeps its old name and meaning as the turns signal's threshold.
- `scripts/historian-sweep.sh` — PreCompact→SessionEnd dedup re-keyed from user turns to transcript bytes: turns-keyed dedup wrongly discarded autonomous post-compact work.
- `tests/run-tests.sh` — new end-to-end regression suite (13 scenarios, 34 assertions) driving the real script with a stub model binary: trivial-skip, prompt-light/work-heavy, conversational, git signal, auto-commit exclusion, non-repo degradation, PreCompact/SessionEnd dedup and regrowth, NOTHING, malformed output → `failed/` + `pending.log`, empty output, fenced/preamble extraction, model-call failure.
- Retained from the 2026-07-12 hardening (now versioned as part of v3.1): tolerant day-file extraction with validated front-matter detection (no byte-0 contract), rich failure diagnostics, raw failed output preserved under `knowledge/.sweep/failed/` (last 20), pending-queue retry unchanged, and the headless model call locked down with `--permission-mode dontAsk` + `--disallowedTools` (the model is text-in/text-out and must never attempt a tool).

### Behavioral differences you may notice

- Sessions that v3.0 skipped now sweep: short-prompt agentic sessions (size signal), and quiet conversations right after real commits (git signal). Expect a modest rise in sweeps that conclude `NOTHING` — that is the accepted cost of never silently losing history, and it's observable in `sweep.log`.
- `sweep.log` now records the gate's reasoning on every decision, and `sessions.log` rows store `session-id<TAB>bytes<TAB>turns` (was `session-id<TAB>turns`).

### Migration

None required. Config is backward compatible (`HISTORIAN_MIN_TURNS` keeps working; new vars are optional). Existing vaults, day files, pipeline, and hooks are untouched. One one-time effect: a session already logged by v3.0 that fires again under v3.1 may re-sweep once (old sessions.log rows stored turns, not bytes); the sweep prompt's merge rule absorbs this without duplication. Redeploy = copy `scripts/historian-sweep.sh` over the runtime copy per `INSTALL.md` step 1.

## v3.0 — 2026-07-07

Automatic capture: `SessionEnd`/`PreCompact` hook + headless sweep drafts day files with `status: auto` cases, reviewed in batch at `/distill` (step −1 coverage check, step 0 auto-case review). Pipeline, formats, promotion rules, retrieval unchanged from v2.5.
