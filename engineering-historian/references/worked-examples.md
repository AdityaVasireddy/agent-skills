# Worked examples — the pipeline end to end, from a real vault

Every example below except the last is **verbatim from a live vault** (the `issue-runtime` project, snapshot 2026-07-13) — real cases, a real judgment pass, a real promotion, and a real declined promotion. They will drift from the living vault as it evolves; they are teaching snapshots, not mirrors. The standard in Example 5 is the one exception: that vault has not yet earned a standard, so the example is hypothetical and labeled as such.

## Example 1 — a full chain: two cases → two judgments → P-001

**Day 1.** The sweep drafted this case on 2026-07-11 (as `status: auto`); the user confirmed it at step 0, and the next `/distill` appended the judgment:

```markdown
### CASE: tamper-detection-raises-not-forges
status: cited
problem: the check-2 seam (`check_unwitnessed_commit`) can encounter a world that was rewritten under the reconciler, where the expected `merge_commit` no longer matches.
decision: raise `ReconcilerTamperError` instead of forging a synthetic `merge_commit` event.
why: ADR-11 join-key integrity requires refusing to fabricate provenance when the underlying git state has been tampered with.
tags: [reconciler, integrity, adr-11, error-handling]

#### JUDGMENT (distilled 2026-07-12)
Rejected alternative: forge a synthetic `merge_commit` event when the expected commit doesn't match, so reconciliation can proceed autonomously without operator intervention.
Tradeoff: forging keeps the system unblocked but silently fabricates provenance; raising halts progress but preserves integrity.
Tipping factor: ADR-11 join-key integrity is a frozen requirement that explicitly forbids fabricating provenance, making this a contract compliance question rather than a case-by-case tradeoff judgment.
```

**Day 2.** A different session, different subsystem, produced this case on 2026-07-12:

```markdown
### CASE: billing-guard-raise-not-assert
status: cited
problem: `_hygienic_env`'s enforcement that `ANTHROPIC_API_KEY` is absent from the spawned subprocess environment was written as `assert "ANTHROPIC_API_KEY" not in env`.
decision: replace the assert with an explicit `raise EngineEnvError`.
why: assert statements disappear under `python -O`, and this is a billing invariant (subscription vs. API billing per ADR-18) that must hold on every spawn regardless of interpreter flags.
tags: [adr-18, billing, python-gotcha, error-handling]

#### JUDGMENT (distilled 2026-07-12)
Rejected alternative: leave the check as `assert "ANTHROPIC_API_KEY" not in env`.
Tradeoff: assert reads as the terser, more idiomatic invariant-check already used elsewhere in the codebase, but silently disappears under `python -O`.
Tipping factor: this specific check guards a billing invariant that must hold unconditionally on every spawn (subscription vs. API billing per ADR-18), so the interpreter-flag fragility of assert is unacceptable no matter how idiomatic it looks.
```

**The R3 test.** Note what grouped these two: not tags (they share only `error-handling`) but the **tipping factors**, which both assert the same underlying rule — *a frozen contract makes this invariant non-negotiable, so a mechanism that can silently fail to enforce it is unacceptable*. Two cases, two distinct day-file dates (2026-07-11, 2026-07-12), both judgments non-thin → R3a authorizes promotion. The resulting entry in `principles.md`:

```markdown
## P-001: Enforce frozen/critical invariants by raising, never by silent degradation

status: active
scope: issue-runtime (durability/contract-enforcement code — reconciler, engine wrapper, anywhere a frozen ADR or doc-03/doc-02 contract is checked at runtime)
evidence: 2 cases, 2 dates
- issue-runtime/2026-07-11#tamper-detection-raises-not-forges — raised `ReconcilerTamperError` instead of forging a synthetic `merge_commit` event when tamper is detected, because ADR-11 join-key integrity forbids fabricating provenance.
- issue-runtime/2026-07-12#billing-guard-raise-not-assert — replaced `assert "ANTHROPIC_API_KEY" not in env` with an explicit `raise EngineEnvError`, because `assert` silently disappears under `python -O` and this guards a billing invariant (ADR-18) that must hold on every spawn.

**Statement:** When code enforces an invariant that a frozen contract (an ADR, doc 02, or doc 03) makes non-negotiable, enforce it with an explicit `raise` of a named exception — never with a mechanism that can silently no-op (a bare `assert`, which vanishes under `python -O`) or that papers over the violation with synthesized data (forging a plausible-looking event/value instead of refusing). Both cases the pipeline observed involve a hidden failure mode that could produce a state that "looks fine" while quietly violating a rule the architecture is not allowed to bend.

**Invalidation conditions:** if a future case shows a frozen invariant is deliberately enforced by a *softer* mechanism (a warning + fallback, an assert kept for a genuinely dev-only path with the flag never stripped in prod) *because the frozen contract itself sanctions graceful degradation there*, that's a direct counter-case and should challenge this principle's scope rather than be treated as an exception.

**Not standardizable (yet):** this doesn't binarize into a project-wide grep/lint check as stated — "which invariants are frozen/critical" requires judgment (an ADR reference nearby is a weak proxy, not a reliable signal, and plenty of legitimate asserts exist for non-frozen internal invariants). A narrower, mechanically checkable version (e.g., "no bare `assert` in `src/runtime/**` guarding a condition whose docstring/comment cites an ADR number") could be proposed as a future standard if the pattern recurs a third time with cases specific enough to pin the boundary.
```

Both contributing cases were then set to `status: cited`, and the scope was kept at `issue-runtime` — both cases come from one project, and R3 forbids claiming broader scope than the evidence covers.

**The R4 verdict.** Standardization was *attempted* and declined, and the decline was recorded in the entry itself. That record is load-bearing: it stops every future pass from re-attempting R4 on P-001, and it pre-registers exactly what a passable narrower standard would look like.

## Example 2 — a declined promotion (R3a fails on dates)

The same distill pass found **three** cases sharing a tipping factor — more raw evidence than P-001 had. It still declined:

```markdown
## Declined promotions

- **Empirical-probe-before-building-dependent-code** (candidates: issue-runtime/2026-07-12#max-turns-cli-flag-removed-reactive-enforcement, issue-runtime/2026-07-12#allowedtools-falsified-denylist-is-the-real-fence, issue-runtime/2026-07-12#pid-in-log-is-writer-not-engine-child) — all three share a "verify against the real system before committing the design" tipping factor, but all three land on the same calendar date (2026-07-12), so the 2-cases/2-dates bar isn't met. Revisit if a case with this tipping factor shows up on a different date.
```

Why the dates clause exists: three same-day cases are usually one working session rediscovering the same lesson three times — one data point, not three. Recurrence across dates is what shows the pattern survives context change. Note the log line does the full job in one bullet: candidate name, all case IDs, the specific failed condition, and the reopening condition — so no future pass re-litigates it from scratch.

## Example 3 — a terminal case (never promoted, and that's success)

Most cases should live and die like this one (from 2026-07-11, `status: distilled`):

```markdown
### CASE: base-commit-carried-on-view
status: distilled
problem: the `preserve_residue` seam receives only the `ExecutionView`, but needs the issue's `base_commit` to do its work.
decision: carry `base_commit` onto the view at spawn time rather than passing it as a separate parameter to the seam.
why: keeps the seam self-contained on a single argument instead of coupling its signature to extra spawn-time context.

#### JUDGMENT (distilled 2026-07-12)
Rejected alternative: pass `base_commit` as a separate parameter to the `preserve_residue` seam alongside the `ExecutionView`.
Tradeoff: a separate parameter leaves the view's schema untouched but couples the seam's signature to extra spawn-time context that every caller must thread through; carrying it on the view keeps the seam single-argument at the cost of enlarging the view.
Tipping factor: seam-signature simplicity was weighted over minimizing the view's surface area, since the view already represents spawn-time state and `base_commit` is legitimately part of that provenance.
```

Its tipping factor is a project-local design weighting, not a transferable rule ("What never promotes", `promotion-rules.md`). It will never become a principle — and it doesn't need to: if anyone ever asks "why does `ExecutionView` carry `base_commit`?", retrieval finds this case and answers with provenance in seconds. Retrievable, never promoted, fully successful.

## Example 4 — retrieval citations with provenance stated

How the three tiers of this vault sound when cited, per SKILL.md's retrieval mode:

- A principle, with evidence weight and scope in the same breath: *"From P-001 (2 cases, 2 dates, scoped to issue-runtime durability code): enforce frozen invariants by raising a named exception, never a bare assert — your `assert` here guards an ADR-18 condition, so it should be a raise."*
- A confirmed case: *"From issue-runtime/2026-07-12#max-turns-cli-flag-removed-reactive-enforcement: CLI 2.1.207 silently ignores `--settings maxTurns`, which is why enforcement is reactive via `num_turns`."*
- An auto case — weakest provenance in the vault, always flagged: *"From issue-runtime/2026-07-12#stdin-write-then-wait-timeout-hole (auto, unreviewed): …"*

Each of these, if it materially answered the question, gets one line in `retrieval-log.md` with a minutes-saved estimate.

## Example 5 — a standard (HYPOTHETICAL — this vault has not earned one yet)

No principle in the source vault has passed R4, so no real standard exists to quote. This illustration is built from the narrower candidate that P-001's own "Not standardizable (yet)" note pre-registered — it shows what `standards.md` would receive *if* the pattern recurs with cases specific enough to pin the boundary:

```markdown
## S-001: No bare assert guarding ADR-cited conditions in runtime code

derived-from: P-001
status: active
scope: src/runtime/**/*.py

Checks (each pass/fail):
- No `assert` statement whose test, or whose adjacent comment/docstring (±3 lines), cites an ADR number (`ADR-\d+`).
- Every such former assert site raises a named exception class (not bare `Exception`, not `AssertionError`).

On failure: replace the assert with a `raise` of a named exception; if the author believes the invariant is genuinely dev-only, escalate to P-001 for human judgment instead of silencing the check.
```

Note what made this binarizable where P-001 as stated was not: the scope became a glob, and "frozen/critical invariant" — the judgment call — was replaced by a mechanical proxy (an ADR citation within ±3 lines) that is deliberately narrower than the principle. A standard is allowed to under-cover its principle; it is never allowed to require judgment.
