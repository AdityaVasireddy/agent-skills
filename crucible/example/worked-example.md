# Worked example — a full Crucible v2 session

One venture, run end to end, plus the opening of the follow-up
session — because the follow-up is where v2 differs most from a
one-shot verdict tool. The idea is invented for illustration.

---

## Stage 1 — Input

Founder's pitch, condensed to the neutral Brief (adjectives
stripped), plus the two intake facts v2 always collects:

> **PlateShare** — subscription meal delivery for people with chronic
> kidney disease (CKD stages 3–4, pre-dialysis), who must track
> potassium, phosphorus, and sodium. $95/week for 10 meals designed
> by a renal dietitian. Buyer: patients and their caregivers, out of
> pocket. Founder: a registered renal dietitian, 12 years in a
> nephrology clinic, 4,000-person patient email list. Budget $15k;
> wants first revenue within 60 days.
>
> **Goal:** lifestyle business (replace clinic salary). **Affordable
> loss:** $8k and 4 months before needing income again.

Scope gate: customer and revenue path exist — in scope.

## Stage 2 — Interrogation

**Skeptic** — What does one delivered meal cost you, all-in: renal
ingredients, cold-chain shipping, spoilage? What's your liability
exposure if an immunocompromised customer gets a food-safety
incident? What does the patient do today for $0 — and why is that not
enough?

**Operator** — Of your 4,000 emails, how many opened anything in the
last 90 days? Who cooks, packs, and ships week one — you? What in
your 12 clinical years maps to logistics work, and what's your plan
for the part that doesn't?

**Buyer** *(as a stage-3 patient, 61, fixed income)* — I already get
a renal-diet sheet from my clinic and my daughter cooks Sundays. What
does $380/month get me that costs me nothing today? Would my
nephrologist tell me to buy this? — And the 3 questions to ask 5 real
patients this week: (1) "What did you eat last Tuesday, and how did
you decide it was safe?" (2) "What do you currently pay for anything
diet-related?" (3) "If this existed at $95/week, what would you give
up to afford it?"

The founder can answer the clinical questions cold; the food-cost,
list-engagement, and liability questions come back vague. Those go in
as `HOPE`.

**The Assumption Stack**

| # | Assumption | Status | Evidence / source |
|---|---|---|---|
| 1 | CKD nutrient management is hard and matters | KNOW | 12 years clinical practice |
| 2 | The founder can design compliant meals | KNOW | Credential + practice |
| 3 | Patients will pay $95/week out of pocket | HOPE | No purchase evidence; list has never been sold to |
| 4 | $95/week leaves a viable margin after cold-chain delivery | HOPE | Founder has no all-in cost number |
| 5 | The 4,000-person list is a live channel | BELIEVE | List exists; engagement unknown |
| 6 | Free substitute (clinic sheet + family cooking) won't retain the customer | BELIEVE | Clinical intuition, no data |
| 7 | Food-safety liability is insurable at small scale | HOPE | Unexamined |

## Stage 3 — Bench

**Arithmetic (founder's own numbers):** $95 ÷ 10 = $9.50/meal.
Founder's guessed food cost $4.50 + insulated shipping $18–25/box
(≈ $2/meal) + packaging + spoilage buffer → $7–8/meal *before* labor,
kitchen, insurance. Margin per meal ≈ $1.50–2.50, i.e. ≤ $25/week per
customer before the founder pays herself. To replace a clinic salary
(~$6k/month) needs ≈ 240+ steady subscribers — from a 4,000-person
list of unknown engagement. The math *can* close only if assumptions
4 and 5 both break favorably.

**Incentive map:** the party that saves money when CKD progression
slows (the insurer, ~$90k/patient/year on dialysis) is not the party
being charged (a fixed-income patient). Charging the poorest
stakeholder for a benefit that accrues to the richest is an incentive
inversion — the strongest structural finding on the stack.

**Verdict: `BROKEN-BECAUSE`:**
- **B1 — margin arithmetic does not close** at $95/10 meals on the
  founder's own cost guesses → *fixable-by-evidence* (real cost
  quote) **and** by redesign (price, meal count, or payer).
- **B2 — incentive inversion:** payer ≠ beneficiary →
  *fixable-only-by-redesign* (someone other than the patient pays:
  insurer, Medicare renal-nutrition coverage, or family as buyer).

**Risk ranking (recommendation, non-binding):** #3 willingness to
prepay → #4 true unit cost → #5 list liveness → #7 liability → #6
retention vs. free.

## Stage 4 — Evidence

*(This run had no web search — so nothing below is VERIFIED, and the
session says so.)*

- `RECALL — confirm before acting:` medically-tailored-meal companies
  that scaled did so through health-plan and Medicaid contracts, not
  direct-to-consumer subscriptions.
- `RECALL — confirm before acting:` Medicare covers medical nutrition
  therapy for CKD when referred — a reimbursement path relevant to B2.
- `REASONED:` a caregiver cooking from the clinic's free sheet is a
  substitute with zero cost and an emotional moat; retention risk #6
  is real even if trial succeeds.

No stack promotions this session — evidence added leads, not proof.

## Stage 5 — Experiment

**Target:** assumption #3 (prepayment) — riskiest, and it
simultaneously tests #5 (list liveness) for free.

**Design:** email a segment of 800 from the list: a 2-week
manually-cooked renal meal pilot, 15 spots, at the real $95/week
price, "reply and prepay to claim a spot." Manual cooking only if
money arrives — zero build.

**Threshold (declared now):** ≥ 15 prepayments from 800 emails =
pass. **Cost cap:** < $500 and 10 days — well inside affordable loss.

**On the record — the founder:**
- **Prediction:** "I expect 25–30 people to try to prepay."
- **Pre-commitment:** "If fewer than 15 prepay, I will stop pursuing
  patient-paid subscriptions and spend two weeks investigating the
  Medicare/insurer route (B2's redesign) before spending anything
  else."

## Stage 6 — Ledger (written to `.crucible/plateshare.md`)

```markdown
# Crucible ledger — PlateShare
Goal: lifestyle · Affordable loss: $8k / 4 months
Sessions: 1 · Predictions scored: 0/0

## Assumption stack
| # | Assumption | Status | Evidence / source | Last change |
| 1 | CKD nutrition is hard/matters | KNOW | 12y practice | S1 |
| 3 | Patients prepay $95/wk | HOPE | none — E1 pending | S1 |
| 4 | Margin viable at $95/10 | HOPE | founder guess; math ≈$2/meal | S1 |
| … | | | | |

## Experiments
### E1 — S1
Assumption: #3 · Design: 800-email prepaid pilot, 15 spots ·
Threshold: ≥15 prepay · Cost: <$500 / 10 days
Prediction: 25–30 prepay · Pre-commitment: <15 ⇒ stop patient-paid,
investigate payer route · Result: pending

## Session log
S1: Bench=BROKEN-BECAUSE (B1, B2) · Evidence tiers
VERIFIED/RECALL/REASONED=0/2/1

## Open questions
- All-in cost per delivered meal (get a real quote)
- 90-day list engagement rate
- Liability insurance cost at pilot scale
```

**Sharpest unanswered question:** what does one delivered meal
actually cost you? (You are three months from betting your savings on
a number you haven't looked up.)

---

## Session 2, three weeks later — the part v1 couldn't do

Founder returns: **9 prepayments** from 800 emails.

The session opens with the score, before any analysis:

> **Prediction scored:** you predicted 25–30; reality returned 9.
> Predictions: 0/1. Your confidence in patient demand ran ~3× ahead
> of the market — worth remembering the next time a forecast of
> yours feels obvious.
>
> **Pre-commitment check:** below threshold. You said you'd stop
> pursuing patient-paid subscriptions and spend two weeks on the
> payer route. Is that what you're doing?
>
> **Stack updates:** #3 patient-prepay → *demoted, evidence against*
> (9/800 at threshold 15). #5 list liveness → *promoted to KNOW* —
> the list is real (9 strangers prepaid ~$200 each off one email);
> the channel works, the offer doesn't. That combination is exactly
> what the payer-route redesign (B2) needs: a live patient panel is
> an asset an insurer pilot can be built on.

Then the loop continues: Bench re-ranks, and E2 targets the payer
route — one expert call with a health-plan care-management contact,
threshold declared, prediction on the record.

Note what the founder has after two sessions: not a verdict — a
scored calibration record, a stack where hope is turning into
knowledge, one dead assumption that cost $0 to kill, and one live
asset (the list) they didn't know they'd proven. That is the product.
