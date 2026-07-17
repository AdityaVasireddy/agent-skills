# Migration — Crucible v1 → v2

## The one-line difference

v1 told founders what the model thought of their idea. v2 makes the
founder tell *it* — on the record, against their own predictions —
and keeps score. The score is the product.

## How the philosophy evolved

v1's founding insight was correct and survives untouched: LLMs
default to agreeing with the person in front of them, and a
validation tool must be engineered against that. v1's error was the
*mechanism* it chose: simulating an investment committee that issues
outcome verdicts. Three design reviews dismantled that mechanism:

1. **Simulated independence isn't independence.** v1's five personas
   share one model and one prior; their convergence measures how
   obvious a flaw is, not how true. The council was bad epistemology —
   but good pedagogy (a voiced Buyer is memorable), so the voices
   survive as *question-askers* and die as judges.
2. **Outcome verdicts are unpayable checks.** GO/RESHAPE/KILL claims
   knowledge of the future no one has. Worse, run against history
   (Airbnb '08, Stripe '10, Figma '12, pre-CUDA Nvidia), the
   committee pattern reliably kills category-creating companies —
   and an "upward veto" patch just deletes KILL instead. The honest
   scope of ex-ante analysis is the *argument*, not the outcome.
3. **The cheap-test doctrine had an anti-moat bias.** v1's single
   48-hour test silently selects for ideas whose riskiest assumption
   is cheaply testable — exactly the ideas with no moat. v2 keeps
   cheap-first but types tests to risks (technical → spike,
   distribution → paid probe) and forbids claiming a cheap test
   settled an expensive assumption.
4. **A tool used repeatedly must compound.** v1 reset to zero every
   run. The judgment worth improving at founder sample sizes is the
   *founder's* — measurable only if the system remembers predictions
   and scores them.

The result is v2's constitution (docs/PHILOSOPHY.md): judge arguments
not outcomes · reality owns empirical truth · the founder owns the
bet · compounding founder judgment is the product.

## What changed, and why each change materially improves outcomes

| Change | v1 | v2 | Why it matters |
|---|---|---|---|
| Role of personas | 5 judges issuing scores and stances | 3 examiners (Skeptic, Operator, Buyer) asking questions only | Keeps coverage and memorability; removes vote-counting among correlated simulacra. Adds the missing seat — nobody in v1 owned distribution; the Operator does |
| Verdict | GO / RESHAPE / KILL on the venture | `SOUND` / `BROKEN-BECAUSE-X` on the argument, + hard stop only for structural impossibility | Every v2 judgment is checkable by the founder that night, so the tool's authority survives contact with reality — the requirement for five-year trust |
| Scoring | 1–10 per persona, averaged-ish into confidence | None. Ordinal risk ranking only, labeled a recommendation | LLMs are decent at "which is riskiest," untrustworthy at "7/10" or "35%." Numbers without rubrics were vibes with digits |
| Customer voice | Buyer's role-play treated as demand signal | Buyer generates the 3 questions for 5 real customers | A hallucinated customer is a hypothesis source, never evidence |
| Evidence | Researcher persona; search optional | Dedicated Evidence stage; search mandatory when available; every claim tiered VERIFIED / RECALL / REASONED | The evidence pass is the only stage where information *enters* the system; v1 made it optional and let recall pose as fact |
| The test | One 48-hour test, demand-flavored | One experiment per cycle, typed to the risk, cost-capped to affordable loss, cheap-first with escalation | Fixes the anti-moat selection effect and gives technical/regulatory risk a valid test for the first time |
| Founder's role | Recipient of a verdict | On the record: prediction + pre-commitment before every experiment | The pre-commitment converts future rationalization into a present promise — the anti-zombie mechanism. The prediction feeds the only calibration loop that works at N = one founder |
| Memory | None — every run cold | The ledger: per-venture file, appended every session, never rewritten | Without memory nothing compounds; with it, sessions start from what reality said, and the founder's calibration curve becomes visible |
| Intake | Idea, buyer, edge, constraints | + founder's goal (lifestyle vs. venture-scale) and affordable loss | v1 silently applied portfolio logic to single-shot founders; the correct analysis depends on the loss function, so v2 asks for it |
| Scope | Any idea | Requires a customer + revenue path; research bets get ruin check + affordable-loss only | Converts confident category errors (an OpenAI-shaped brief) into honest refusals |

## What was removed entirely

- The Judge persona and verdict synthesis.
- GO / RESHAPE / KILL, veto floors, and confidence levels.
- All numeric scoring.
- The Contrarian, Expansionist, Logician, and Researcher as judging
  seats (the Skeptic absorbs the Contrarian's ground as questions;
  the Evidence stage absorbs the Researcher's; the Bench's incentive
  map and arithmetic absorb the Logician's; the Expansionist's bull
  case had no owner-worthy content that the founder doesn't already
  supply).
- Persona role-play as a source of evidence anywhere.

## What was preserved

- The anti-sycophancy stance — now aimed both ways: flattery and
  performative brutality are equally forbidden performances.
- The four-part experiment quality bar (riskiest / falsifiable /
  behavioral / cost-capped) — v1's best idea, now applied to every
  experiment instead of one.
- Brief discipline: one neutral paragraph all stages anchor on
  (hardened: adjectives stripped).
- One-batch clarification, max 4 questions, never over-interrogate.
- One-page, skimmable session output ending in a concrete next test.

## How the architecture evolved

v1 was a pipeline that ran once: brief → five parallel judges → one
synthesis → verdict. v2 is a loop with an external edge: brief →
interrogation → bench → evidence → experiment → ledger → *reality*
→ next session. The defining property of v2 is that its
highest-information edge — the experiment outcome — is generated
outside the system, by the world. Everything inside exists to make
that edge cheap, frequent, and honestly scored.

## Why v2 should produce better founder outcomes

v1's theory of change was: a better verdict → a better decision. That
theory fails at both ends — the verdict claimed unknowable things,
and a verdict, even a right one, changes nothing unless the founder
acts. v2's theory of change is: a scored prediction → a cheaper
collision with reality → an updated founder. Each loop measurably
shrinks `HOPE`, sharpens calibration, and drops the cost per resolved
assumption (docs/EVALUATION.md). And the exit condition is designed
in: a founder who has internalized the interrogation and needs
Crucible less is the success case, not churn.
