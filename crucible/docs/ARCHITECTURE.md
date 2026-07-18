# Crucible — Architecture

How the system is structured, independent of any prompt. The
implementation (`../SKILL.md`) must be derivable from this document;
if they diverge, this document wins and the implementation is a bug.

## Core philosophy (from PHILOSOPHY.md)

Three judges, strictly scoped:

| Judge | Owns | Why |
|---|---|---|
| **The LLM** | What is checkable *now* from stated facts: arithmetic, contradictions, incentive alignment, structural impossibility, experiment-design quality | These judgments can be verified by the founder tonight; asserting them costs no credibility. LLM judgment is high-precision at *invalidity* ("broken because X" names its own check) and unreliable at *validity* ("this will work" is unfalsifiable at t=0) |
| **Reality** | Everything empirical: demand, willingness to pay, channel economics, technical feasibility, timing | These are only verifiable later, by the world. Simulated versions of them (a role-played buyer, a remembered market size) are hypotheses, never evidence |
| **The founder** | The bet: whether to spend the next unit of time and money, and on what | Only the founder holds the loss function (one shot vs. many, affordable loss, life goals). The system's job is to make this judge better, not replace it |

A fourth category — **recommendations** (risk rankings, experiment
designs, question selection) — is LLM output that is *not* verifiable
now. It is permitted, but always labeled non-binding and overridable
by the founder. The verifiability constraint applies to *judgments*
(assertions of fact about the argument), not to recommendations.

## System components

Each component has a single responsibility. No component performs
another's.

| Component | Single responsibility | Explicitly forbidden |
|---|---|---|
| **Input** | Establish the Brief (new venture) or load the Ledger (returning venture); apply the scope gate | Analysis of any kind |
| **Interrogation** | Produce the Assumption Stack by questioning the founder | Verdicts, conclusions, advice |
| **Bench** | Judge the argument on verifiable-now grounds; rank risks (as recommendation) | Outcome predictions, probabilities, market sizes from memory, scores |
| **Evidence** | Check every searchable claim against live sources; tier all claims | Treating recall or reasoning as verification; inferring adequacy from existence (a competitor existing is never evidence the buyer's problem is well solved) |
| **Experiment** | Design one real-world test for the riskiest unresolved assumption; record the founder's prediction and pre-commitment | Running more than one test at a time; tests that require building the product to learn the answer |
| **Ledger** | Persist the venture's state: stack, experiments, predictions, outcomes, calibration | Interpretation — the ledger records, it does not opine |

## Key data structures

**The Brief** — the venture in one paragraph: idea, buyer and revenue
model, founder's edge, constraints, founder's goal (lifestyle vs.
venture-scale) and affordable loss. Written in neutral language —
adjectives stripped — because every downstream stage anchors on it.

**The Assumption Stack** — every load-bearing claim, tagged:

- `KNOW` — evidence in hand; the evidence must be named.
- `BELIEVE` — reasons but no evidence.
- `HOPE` — neither. Unanswered interrogation questions land here.

Status changes only via the Evidence and Experiment components.
Promotion by argument is prohibited (invariant 5).

**Evidence tiers** — every factual claim carries one:

- `VERIFIED` — confirmed against a live source this session, cited.
- `RECALL` — from training memory; labeled "confirm before acting."
- `REASONED` — pure inference from stated facts.

If no live search is available, nothing can be `VERIFIED`, and the
session says so explicitly.

**The Experiment record** — assumption under test, design, pre-declared
pass/fail threshold, cost cap, deadline, the founder's **prediction**
(expected outcome, on the record), and the founder's
**pre-commitment** ("if this fails the threshold, I will ___").

**The Ledger** — one file per venture. Default location:
`.crucible/<venture-slug>.md` in the founder's working directory.
Runtimes without a filesystem degrade to a fenced ledger block the
founder saves and pastes back next session. Alongside the stack and
experiment records, the ledger carries a **session log**: one line
per session recording the Bench verdict and the evidence-tier counts
for that session. This is what makes the system-side indicators in
EVALUATION.md computable from the ledger alone, without a transcript.

## Data flow

```
                 founder's brief / pasted ledger
                              │
                              ▼
                         ┌─────────┐
             scope gate  │  INPUT  │  ledger load + prediction scoring
                         └────┬────┘
                              ▼
                      ┌───────────────┐
   questions only ──▶ │ INTERROGATION │ ──▶ Assumption Stack
                      └───────┬───────┘     (KNOW / BELIEVE / HOPE)
                              ▼
                         ┌─────────┐        SOUND / BROKEN-BECAUSE-X
    verifiable-now  ──▶  │  BENCH  │  ──▶   + risk ranking
                         └────┬────┘        (recommendation)
                              ▼
                        ┌──────────┐        claims tiered
      live search  ──▶  │ EVIDENCE │  ──▶   VERIFIED / RECALL / REASONED
                        └────┬─────┘        stack promotions/demotions
                              ▼
                       ┌────────────┐       one test · threshold ·
   founder's bet  ──▶  │ EXPERIMENT │ ──▶   prediction · pre-commitment
                       └─────┬──────┘
                              ▼
                         ┌─────────┐
                         │ LEDGER  │  ──▶  persisted venture state
                         └────┬────┘
                              │
                              ▼
                    reality runs the experiment
                    (outside the system, between sessions)
                              │
                              └──────▶ next session's INPUT
```

The loop's defining property: the highest-information edge in the
graph — the experiment outcome — is generated *outside the system*,
by the world. Everything inside the system exists to make that edge
cheap, frequent, and honestly scored.

## Session lifecycle

1. **First session:** Brief → Interrogation → Bench → Evidence →
   Experiment → Ledger created. Standalone value: even if the founder
   never returns, they leave with a tagged assumption stack, a
   verifiable judgment on their argument, and one decisive experiment.
2. **Between sessions:** the founder runs the experiment. Cadence is
   set by the experiment's deadline, not by a calendar.
3. **Returning session:** Ledger loaded → founder's prediction scored
   against the actual outcome → stack updated (promotions, demotions,
   new assumptions surfaced by the result) → pre-commitment checked
   ("you said you would ___ — did you?") → the loop **re-enters at
   Bench** with the next-ranked assumption, skipping Interrogation —
   unless the outcome surfaced genuinely new ground the founder
   hasn't been questioned on, in which case Interrogation runs again
   for that ground only.
4. **Pivot:** a pivot starts a new Assumption Stack in the *same*
   ledger. History survives; calibration continues.
5. **Abandonment:** recorded, with the deciding evidence. A clean
   kill by the founder, on evidence, against their own pre-commitment,
   is the system working — not failing.

## Ledger lifecycle

Created at first session close. Appended every session. Never
rewritten destructively — status *changes* are the calibration data.
Over time it accumulates the three curves EVALUATION.md measures:
stack composition (HOPE shrinking), founder calibration (predictions
vs. outcomes), and learning velocity (cost and days per resolved
assumption).

## Information ownership

| Question | Owner | Mechanism |
|---|---|---|
| Is the argument internally coherent? | LLM | Bench judgment |
| Does the math close on the founder's numbers? | LLM | Bench judgment |
| Do the incentives align? | LLM | Bench judgment |
| Is this structurally impossible (ruin, legality, arithmetic)? | LLM | Bench judgment — the one place a hard stop is issued |
| Which assumption is riskiest? | LLM proposes, founder disposes | Bench recommendation |
| Will customers pay? | Reality | Experiment |
| Does the channel work? | Reality | Experiment |
| Is it technically feasible? | Reality | Experiment (time-boxed spike) |
| What do competitors charge today? | Reality via live search | Evidence tier `VERIFIED` |
| Should I spend the next month on this? | Founder | Warranted Bet answer + their own recorded calibration |

## Degradation modes

- **No web search:** Evidence emits `RECALL`/`REASONED` only, states
  that nothing is verified, and the experiment inherits the burden.
- **No filesystem:** Ledger becomes a paste-back block.
- **Founder won't answer questions ("just run it"):** Interrogation
  asks one batch, then proceeds; unanswered questions become `HOPE`
  entries. The inability to answer is recorded as a finding, never
  used as a blocker.
- **Founder demands an outcome verdict ("should I build it?"):** the
  system gives the **Warranted Bet** answer — what is
  known vs. hoped, the spend the current evidence justifies, and the
  founder's own calibration record — and explicitly declines the
  oracle role. This response is designed, not improvised, because the
  question is guaranteed to be asked.
