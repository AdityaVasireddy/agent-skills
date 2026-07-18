# Crucible — Roadmap

Crucible v2's philosophy and architecture are frozen as of v2.0.0
(current release: v2.1.0). This document does not propose changes to either — it
outlines how the project intends to *learn* before any future version
is even considered. If a phase below produces evidence that the
architecture itself needs to change, that's a new design review, not
a roadmap item; nothing here pre-authorizes it.

## Phase 1 — Real-world founder testing

**Goal:** run the released version against real ventures and see
whether it behaves the way the design docs claim it will.

- Use it on live ideas — your own, or founders willing to try it —
  across at least a handful of full session-then-return cycles per
  venture, since v2's defining claims (calibration improving, `HOPE`
  shrinking) only show up across repeated sessions, not in one run.
- Watch specifically for: does the Bench ever smuggle in an outcome
  opinion under `SOUND`/`BROKEN-BECAUSE`? Does the experiment design
  actually stay cost-capped and behavioral, or does it drift toward
  "would you use this?" surveys? Does the pre-commitment protocol get
  honored, ignored, or quietly renegotiated?
- Collect ledgers (anonymized if shared) as the raw material for
  Phase 2 — they're the only data source `EVALUATION.md`'s
  indicators can be computed from.

No feature work happens in this phase. The only output is evidence.

## Phase 2 — Improve based on observed evidence

**Goal:** let Phase 1's ledgers answer the questions the design
couldn't answer on paper.

- Compute the `EVALUATION.md` indicators (stack health, founder
  calibration, learning velocity, pre-commitment follow-through,
  Bench discipline, experiment quality, evidence integrity) across
  collected ledgers.
- Look for systematic failure patterns, not one-off complaints: does
  the Bench verdict drift toward `SOUND` more than the arithmetic
  supports? Do experiments cluster on cheap-and-easy assumptions
  instead of the riskiest one? Does the session-log data actually
  match what a manual transcript read would show?
- Any change proposed from this phase must cite the specific
  indicator or failure pattern that motivated it, and must be checked
  against `PHILOSOPHY.md`'s invariants before it's accepted —
  the same discipline the v1→v2 migration was held to.

This is where a future version (or a documented decision *not* to change
anything) gets proposed — not before.

## Phase 3 — Developer experience

**Goal:** make the ledger and evaluation data easier to work with,
without touching what the skill does during a session.

- A small script to compute the `EVALUATION.md` indicators from
  a ledger file mechanically, instead of by hand — the ledger schema
  was designed in this release specifically to make that possible.
- Better guidance for teams or communities pooling anonymized ledgers
  to compare system-side indicators (Bench discipline, experiment
  quality, evidence integrity) across users, as `EVALUATION.md`
  already describes as a valid aggregation.
- Packaging and distribution polish for runtimes beyond Claude Code,
  once real usage reports come in from them.

## Phase 4 — Potential productization

**Goal:** only relevant if Phases 1–3 show sustained real-world use
and a clear need that a markdown skill can't meet.

- Possible directions if the evidence supports them: a lightweight
  ledger viewer, a way to track multiple ventures, or integration
  with wherever founders already keep notes — all deferred until
  there's a demonstrated need, not speculated in advance.
- This phase explicitly requires evidence from Phase 1–2 before any
  design work starts. Building a product around a tool that hasn't
  been used yet is exactly the kind of premature confidence Crucible
  itself is built to catch.
