# Crucible — Workflow

One session, stage by stage: what enters, what happens, what leaves.
The test of this document is that after reading it, the workflow feels
obvious.

Stage responsibilities and boundaries are owned by
[`ARCHITECTURE.md`](./ARCHITECTURE.md); this document adds only
operational detail (what enters/leaves each stage in a live session)
and must not be read as a second, competing definition of the stages.

```
Input → Interrogation → Bench → Evidence → Experiment → Ledger
                                                            │
              (reality runs the experiment)                 │
                            ▲                               │
                            └────────── next session ◀──────┘
```

## Stage 1 — Input

**Enters:** the founder's idea (new venture), or experiment results +
the ledger (returning venture).

**Happens — new venture:**
- Gather what's missing in **one batch of at most 4 questions**: the
  idea, the buyer and revenue model, the founder's edge, and the
  founder's goal + affordable loss (lifestyle or venture-scale; what
  they can lose without ruin). No second round of clarification.
- Apply the **scope gate**: Crucible requires a customer and a revenue
  path. A pure research/frontier bet gets an honest "out of scope" plus
  the only two analyses that are answerable for it — a ruin check and
  affordable-loss sizing — instead of an improvised verdict.
- Condense to the **Brief**: one neutral paragraph, adjectives
  stripped, because every later stage anchors on this text.

**Happens — returning venture:**
- Load the ledger (or accept the pasted ledger block).
- **Score the prediction first**: what the founder predicted vs. what
  reality returned. This lands before any new analysis, because the
  calibration record is the product.
- Check the pre-commitment: "you said if this failed you would ___ —
  is that what you're doing?"
- Update the stack from the outcome (promotions, demotions, new
  assumptions the result surfaced).

**Leaves:** the Brief (new venture, proceeding to Interrogation) or
the updated stack (returning venture, re-entering at Bench per
ARCHITECTURE.md's session lifecycle — Interrogation is skipped unless
the outcome surfaced genuinely new ground) + the founder's goal and
affordable loss.

## Stage 2 — Interrogation

**Enters:** the Brief.

**Happens:** three examiners ask questions — never conclusions. Each
owns distinct ground:

- **The Skeptic** — how it dies: costs, margins, dependencies,
  liabilities, the free substitute.
- **The Operator** — how customers arrive: channel, first ten
  customers, whether the founder's edge maps to the actual daily work.
- **The Buyer** — in the customer's first-person voice: what I'd pay,
  what I'd object to, what I'd do instead — and, always, **the three
  questions the founder should ask five real customers this week**,
  because the Buyer generates hypotheses, never evidence.

One batch of questions total. Answers are taken at face value; vague
or missing answers are findings, not blockers.

**Leaves:** the **Assumption Stack** — every load-bearing claim,
tagged `KNOW` (evidence named), `BELIEVE` (reasons, no evidence), or
`HOPE` (neither, including every unanswered question).

## Stage 3 — Bench

**Enters:** the Brief + the Assumption Stack.

**Happens:** the only stage where the system judges — and only on
grounds the founder can check tonight:

1. **Arithmetic** on the founder's own numbers: price, costs, margin,
   payback. Shown, not asserted.
2. **Contradictions** between the founder's own statements.
3. **Incentive map**: who benefits, who pays, where they diverge.
4. **Structural impossibility scan**: ruin exposure, illegality,
   arithmetic that cannot close on any input the founder accepts.

**Leaves:** the verdict on the *argument* — `SOUND`, or
`BROKEN-BECAUSE-[X]` for each named hole, with each hole classified
**fixable-by-evidence** (an experiment can settle it) or
**fixable-only-by-redesign** (no experiment helps; the model must
change first). Plus one labeled *recommendation*: the ordinal risk
ranking of the stack — ordinal because the system is decent at "which
of these is riskiest" and untrustworthy at "this is 35% likely."

## Stage 4 — Evidence

**Enters:** the stack, risk-ranked.

**Happens:** every claim checkable *now* is checked — competitors and
their live pricing, regulatory reality, channel costs, comparable
offers. Live search is mandatory when available. Every claim gets a
tier: `VERIFIED` (live, cited) / `RECALL` (training memory — "confirm
before acting") / `REASONED` (inference). Without search, the stage
says plainly that nothing is verified.

When competitors or substitutes surface, four separate passes run —
because existence and adequacy are different claims, and the second
is never inferred from the first:

- **4a — Discovery.** Answers only "does this capability already
  exist?" — who offers it, at what price, through what channel.
- **4b — Adequacy.** Independently answers "is the underlying problem
  actually well solved for this buyer?" — review sentiment and
  recurring complaints, trust and recommendation quality, retention,
  behavior change, abandonment — each finding tiered like any other
  claim. Then the falsification question: "what evidence would
  convince us this market is not solved despite existing
  competitors?" If the pass comes up empty, it states exactly **"No
  evidence collected regarding adequacy"** and the adequacy
  assumption enters the stack as `HOPE`.
- **4c — Remaining wedge opportunities.** The wedges still open, each
  labeled **evidence-backed** (cite the tiered finding) or
  **hypothesis** (enters the stack as `HOPE` or `BELIEVE`).
- **4d — Market state.** Exactly one of `Sparse` / `Emerging` /
  `Crowded-but-Weak` / `Crowded-with-Strong-Incumbents` / `Mature` /
  `Commodity`, citing the findings that justify the choice — or
  "insufficient evidence to classify," never a default to "crowded."

**Leaves:** the stack with evidence attached — some `HOPE` and
`BELIEVE` entries promoted or demoted by facts — plus the wedge list
and market-state classification when competitors surfaced, and the
remaining truly-empirical assumptions isolated as experiment
candidates.

## Stage 5 — Experiment

**Enters:** the riskiest assumption that evidence could not settle.

**Happens:** one experiment is designed. The quality bar (all four,
inherited from v1's best idea, with criterion 4 generalized from a
flat 48-hour cap to any cost/time cap within affordable loss):

1. Targets the **riskiest** unresolved assumption, not the easiest.
2. **Falsifiable** — pass/fail threshold declared before running.
3. **Behavioral** — measures what people do (prepay, click, reply),
   not what they say.
4. **Cost-capped** — within a slice of the founder's affordable loss,
   with a deadline.

Test type follows risk type: demand → prepayment or fake-door;
distribution → channel probe with real spend; technical → time-boxed
engineering spike; regulatory → one expert call. Cheap experiments run
first, but a cheap test is never allowed to masquerade as having
settled an expensive assumption — resolving those is what later,
bigger experiments are for.

Then the founder goes on the record, in the session:
- **Prediction:** "I expect [outcome]."
- **Pre-commitment:** "If it fails the threshold, I will ___."

The pre-commitment is the anti-zombie mechanism: it converts a future
rationalization into a present promise, made while the founder is
still objective.

**Leaves:** the Experiment record, plus the session's one-page output:
stack changes · Bench verdict · the experiment (design, threshold,
cost, deadline) · prediction + pre-commitment · the sharpest question
the founder couldn't answer · (from session 2 on) the calibration
line.

## Stage 6 — Ledger

**Enters:** everything above.

**Happens:** the venture's ledger file is created or appended —
never destructively rewritten, because status *changes over time* are
the calibration data. Default location:
`.crucible/<venture-slug>.md`. No filesystem → emit the ledger as a
fenced block for the founder to save and paste back.

**Leaves:** the persisted state the next session starts from.

## How the ledger compounds

Each cycle moves the venture along three curves, all computed from
ledger history (see EVALUATION.md):

1. **Stack composition.** Session 1 is mostly `HOPE`. Every honest
   cycle converts hope into knowledge or into an abandoned assumption.
   The venture's true progress metric is not features shipped; it is
   `HOPE` shrinking.
2. **Founder calibration.** Every experiment carries a prediction;
   every return session scores one. "Of the last six things you were
   sure of, two survived contact with reality" is a sentence no
   pitch-polishing can argue with — and it is only possible because
   the ledger remembers.
3. **Learning velocity.** Dollars and days per resolved assumption,
   falling over time as the founder gets better at designing cheap
   decisive tests.

And one meta-effect: sessions start from what reality said last time,
never from a fresh pitch. The founder cannot quietly re-inflate an
assumption reality already priced.
