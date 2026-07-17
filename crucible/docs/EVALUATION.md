# Crucible — Evaluation

What "Crucible works" means, and how to measure it.

The system is **not** evaluated on whether ventures succeed. Venture
outcomes are dominated by execution and luck, arrive years later, and
occur at sample sizes (one founder, a handful of ideas) where no
signal survives. Evaluating on outcomes would be pretending to a
feedback loop that doesn't exist.

Crucible is evaluated on the thing it actually claims to produce:
**compounding founder judgment**. All but one of the indicators below
are computable from ledger data alone — which is deliberate, because
it means evaluation requires no infrastructure beyond the system's
own memory. The one exception (indicator 5) is a manual, optional
practice and is marked as such.

## Founder-side indicators

### 1. Stack health — the HOPE ratio

`HOPE entries ÷ total stack entries`, per session, over time.

Session 1 is legitimately hope-heavy. The trend is the signal: a
falling ratio means beliefs are being converted into knowledge or
killed; a flat ratio across many sessions means the founder is
sparring but not colliding — running sessions instead of experiments.

### 2. Founder calibration

Every experiment records a prediction; every return session scores
one. Track `predictions correct ÷ predictions scored`, and the
direction of the misses (systematic optimism vs. pessimism).

This is the single most important indicator, because it measures the
product directly: a founder whose predictions improve is a founder
whose judgment is compounding. It is also the only calibration loop
that works at founder sample sizes — a dozen scored predictions about
*your own venture* teach you something; a dozen data points about
"startups in general" teach nothing.

### 3. Learning velocity

`(days, dollars) ÷ assumption resolved`, per cycle. Falling velocity
cost means the founder is designing cheaper, more decisive
experiments — the unaided capability PHILOSOPHY.md names as the goal.

### 4. Pre-commitment follow-through

Of experiments that failed their threshold: did the founder do what
they pre-committed to? `honored ÷ triggered`. This measures whether
the anti-zombie mechanism is holding. A founder who repeatedly
overrides their own pre-commitments isn't using a decision tool;
they're collecting permission slips.

### 5. Interrogation delta (internalization) — manual, optional

The standard session flow does not collect this automatically; it
requires a step outside the six-stage loop. A founder or maintainer
who wants to track internalization can, before starting a session,
privately draft the assumption stack they expect the Interrogation to
produce, then compare it after the fact:
`assumptions the examiners added ÷ total assumptions`. A shrinking
delta is the graduation signal — the interrogation has become the
founder's inner voice. This is the one indicator where *declining
engagement with a stage is success*, and it is the one indicator not
computable from the ledger alone, since the founder's private draft
is never recorded.

## System-side indicators (Crucible evaluating itself)

### 6. Bench discipline

The ledger's session log records each session's Bench verdict
(`SOUND` / `BROKEN-BECAUSE-X`). Reading that verdict against the
session's stack changes shows whether the Bench stayed on
verifiable-now grounds (arithmetic, contradiction, incentives,
structural impossibility) or smuggled in an outcome opinion. Target:
100% verifiable-now. For a deeper audit than the logged verdict
supports, reviewing the full session transcript against this same bar
is the fallback — but the ledger's session log is enough for routine
tracking. Every violation is an authority-budget spend the design
forbids.

### 7. Experiment quality

Score each designed experiment against the four-point bar (riskiest
assumption / falsifiable threshold / behavioral / cost-capped) —
`criteria met ÷ 4`, averaged. The bar is mechanically checkable from
the experiment record; an experiment below 4/4 is a Crucible defect,
not a founder defect.

### 8. Evidence integrity

The ledger's session log records the tier mix (`VERIFIED / RECALL /
REASONED`) for each session. Tracking that mix over time, and — when
search was available — the fraction of checkable claims actually
checked, is a routine ledger read. Any `RECALL` claim presented
without its label is a critical defect — it is the system
counterfeiting evidence.

## How these could eventually be measured

- **Now, manually:** indicators 1–4 and 6–8 are each a small
  computation over one ledger file; indicator 5 additionally needs the
  founder's private pre-session draft. A founder (or a maintainer
  reviewing anonymized ledgers) can compute all of them by hand in
  minutes.
- **Next, mechanically:** because the ledger has a stable shape
  (stack entries with statuses and dates; experiment records with
  predictions and outcomes; a session log of Bench verdicts and
  evidence-tier counts), a trivial script can emit indicators 1–4 and
  6–8 per venture. No new data collection is needed — the workflow
  already writes down everything those indicators read. Indicator 5
  stays manual, since it depends on a private draft the ledger never
  captures.
- **Eventually, across ventures:** with multiple consenting founders'
  ledgers, the system-side indicators (6–8) aggregate meaningfully —
  they measure Crucible's discipline, which is comparable across
  ventures in a way founder outcomes never are. Founder-side
  indicators stay per-founder; averaging calibration across founders
  would re-import the portfolio fallacy this design removed.

## What is deliberately not measured

- Venture success or failure (no valid feedback loop at this N).
- Verdict "accuracy" (v2 issues no outcome verdicts to be accurate
  about).
- Founder satisfaction per session (an encouragement machine would win
  that metric; the design explicitly forbids being one).
- Session count or engagement (invariant: a founder who has
  internalized the method and returns less often is a success case —
  see indicator 5).
