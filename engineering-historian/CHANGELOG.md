# Changelog — Engineering Historian

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
