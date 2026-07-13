# ADR-001: The capture gate proves triviality; it never estimates significance

- **Status:** accepted
- **Date:** 2026-07-13
- **Release:** Engineering Historian v3.1

## Context

The v3.0 sweep decided whether to run with a single test: skip when the session had fewer than `HISTORIAN_MIN_TURNS` (default 10) user turns. That gate measured **conversation volume** as a proxy for "was this a real working session," and the proxy broke with agentic workflows: a session of three prompts ("implement issue #42" / "fix the failing tests" / "commit") followed by hours of autonomous engineering counted as 3 turns and was silently skipped. The failure was observed in production shape, not hypothesized — prompt-light/work-heavy is now the normal shape of a coding session.

The two error costs are wildly asymmetric:

- A **false skip** permanently loses engineering history. Trigger reliability — day-file coverage of active days approaching 100% — is the core thing the v3 automation exists to provide (pre-registered Day-60 criterion in `SKILL.md`).
- A **false run** costs one cheap headless model call that concludes `NOTHING` and never interrupts the user.

The system already takes a position on this kind of asymmetry twice: `SWEEP.md`'s tie-break rule (unsure at the cheap-error gates → capture) and vault principle P-001 (never enforce an invariant with a mechanism that can silently no-op). A gate that silently drops significant sessions is silent degradation of the system's core invariant.

## Decision

The capture gate changes from a **significance gate** to a **triviality gate**, under one invariant:

> Skip a sweep only when every **available** deterministic signal proves the session was trivial. Otherwise, run the sweep.

Structurally: independent evidence collectors, each answering `WORK` / `TRIVIAL` / `UNAVAILABLE`, combined by pure boolean logic — any single `WORK` runs the sweep; skip requires every available signal to read `TRIVIAL`; an `UNAVAILABLE` signal can never argue for skipping. No signal estimates significance — that is the sweep model's job (`SWEEP.md` gates G1–G4), and no deterministic gate can do it without being broken by the next workflow shift, exactly as user-turns was.

Signals, in portability tiers:

- **Tier 0 (always available — the transcript is the sweep's own input):**
  raw transcript size on disk (`HISTORIAN_WORK_BYTES`, default 50000) and extracted user turns (`HISTORIAN_MIN_TURNS`, default 10, retained with its v3.0 meaning as a threshold). Raw size is deliberately primitive: tool-heavy sessions are huge on disk however few prompts they contain, and the signal survives transcript schema drift that would silence extraction (turns=0 must never imply trivial by itself).
- **Tier 1 (available whenever the vault is in a repo):** non-historian commits inside a time window (`HISTORIAN_GIT_WINDOW`, default "12 hours ago"; the sweep's own `history(auto):` commits are excluded). A property of the repository, not of the AI tool — portable to any environment.
- **Tier 2 (optional, environment-specific):** tool-event counts where a hook system exposes them. Enrichment only; never required, and not implemented in the Tier A adapter because Tier 0+1 already cover its cases there.

Session dedup (PreCompact → SessionEnd idempotency) is re-keyed from user turns to raw bytes with a growth delta (`HISTORIAN_DEDUP_DELTA`, default 4096): turns-keyed dedup wrongly discarded autonomous post-compact work (PreCompact sweeps at N turns, the model keeps working, SessionEnd arrives still at N turns).

Every gate decision logs as one sentence over the signals, e.g. `SKIP trivial: 3 turns < 10, 8412B < 50000B, git: no commits since 12 hours ago — every available signal trivial` or `GATE run: transcript 812340B >= 50000B`.

## Alternatives rejected

- **A — user-turn threshold alone (v3.0):** measures dialogue, not work; not independent of prompt style or user verbosity; "turn" is not even well-defined across environments. Retained only as one signal among equals.
- **B — transcript size alone:** the portability floor, but false-skips short decision-only sessions and its absolute thresholds don't port across environments' transcript formats. Retained as a signal.
- **C — engineering activity alone:** git is the strongest single signal (direct evidence of G1's "state change in force") and fully portable; but tool-event parsing couples the gate to each environment's transcript schema, and activity alone misses artifact-less decisions — the highest-value capture class under G3. Git retained as a signal; tool events optional; C-alone rejected.
- **D — weighted multi-factor scoring:** keeps determinism, sacrifices explainability ("score 0.42 < 0.5" explains nothing), demands per-environment weight normalization, and adds no sensitivity: a weighted score only beats an OR when one signal should overrule another *toward skipping*, which the invariant forbids. When signals can only add reasons to run, the score collapses into an OR — so the OR is built directly.

## Consequences

- v3.1 sweeps a strict superset of the sessions v3.0 swept (skip now requires turns-trivial AND size-trivial AND git-quiet, versus turns alone). Backward compatible in the safe direction; the cost increase is bounded and observable via `OK nothing capture-worthy` rates in `sweep.log` — if that rate runs persistently high, tighten thresholds, citing the log.
- **Accepted residual hole:** a short decision-only session — few turns, tiny transcript, no commit — still skips, and the distill-time coverage check cannot catch it either (no commits → no git-day to flag). This is the least automatable corner; it is what manual `/case` and `/history` exist for.
- Known cheap false-runs, accepted by design: commits by a concurrent session or a human inside the git window; long read-only exploration sessions crossing the size threshold.
- `sessions.log` rows written by v3.1 store bytes (column 2) where v3.0 stored turns; the first v3.1 sweep of a session previously logged by v3.0 may re-sweep once, which the SWEEP prompt's merge rule (Hard Rule 6) absorbs without duplication.
