# Promotion rules — graduation criteria for the pipeline

Read at the top of every `/distill` pass and applied as written. These rules are deliberately mechanical: any competent model must be able to execute them without frontier judgment. Where a rule does not clearly authorize a promotion, the answer is "no promotion" — never "use discretion". Declining is a success mode; forced generalizations are worse than no principle.

This file formalizes what `SKILL.md` summarizes inline (the pipeline table's "2+ cases across 2+ dates" bar is R3 in shorthand). The two must never disagree; if you find a disagreement, stop and flag it to the user rather than picking one.

Status vocabulary these rules read and write:

- **CASE:** `auto` → `raw` → `distilled` → `cited`; terminal alternatives `declined — <one-line reason>` and `superseded (by <case-id>)`.
- **PRINCIPLE:** `active` → `challenged` → (`active` with a dated resolution note, or `retired`).
- **STANDARD:** `active` → `retired`. A standard never outlives its parent principle.

## R1 — Case eligibility (what may enter the pass)

A CASE block is collected for distillation only if all of:

- `status: raw` — nothing else. `auto` is invisible to this pass (it must be confirmed to `raw` at step 0 first); `declined`, `superseded`, `distilled`, and `cited` are never re-collected.
- It lives in a day file under `knowledge/<project>/`. Cases exist nowhere else; a "case" quoted in a principle or a log is a citation, not a case.
- Its ID (`<project>/<YYYY-MM-DD>#<slug>`) is intact. Slugs are never renamed after anything cites them — if a rename is discovered, restore the original slug and flag it.

**Horizon check (runs on every case regardless of status):** any case carrying an `until:` line whose condition has passed is flagged to the user, who resolves it — confirm `superseded`, extend the horizon, or drop the line. A case with an expired, unresolved horizon cannot count toward promotion this pass.

## R2 — Judgment (CASE → JUDGMENT)

For each eligible case, append one `#### JUDGMENT (distilled YYYY-MM-DD)` block directly beneath it (exact format in `templates.md`) and set the case to `status: distilled`.

- Source material is the case plus its surrounding session record **only**. Every sentence must be traceable there. Never import best practices, never supply an alternative the record does not contain, never sharpen a vague why into a specific one.
- The block states exactly three things, one sentence each: the rejected alternative(s), the tradeoff, and the tipping factor. The tipping factor sentence is load-bearing — it is the grouping key R3 runs on — so it must name the single consideration that decided the case, not restate the decision.
- If the record names no rejected alternative, still write the judgment but open it with a `thin:` line naming what is missing. A thin judgment cannot count toward promotion until the user thickens it with the missing alternative (which converts it to a normal judgment).
- A judgment is written once. Never re-distill a `distilled` or `cited` case; if a judgment is wrong, the user amends it by hand.

## R3 — Principle (JUDGMENT → PRINCIPLE)

Group distilled cases by shared **tipping factor**: the tipping factor sentences must assert the same underlying rule. Tags are hints for finding candidates; they are never the test. Two cases sharing three tags but different tipping factors are not a group.

Promote a group only if exactly one of two clauses holds:

- **R3a — recurrence:** 2+ cases whose case IDs carry 2+ distinct calendar dates. The dates are the day-file dates in the case IDs — not distill dates, not commit dates. Three cases on one date are one date (see the empirical-probe decline in `worked-examples.md`).
- **R3b — early promotion:** exactly 1 case carrying a `promote-early:` line that was written at capture time by the human capturer. The distiller is forbidden from adding this line, ever — including for promotions that look "obviously deserved". Obviously deserved patterns recur; let R3a catch them.

Hard conditions — failing any one means no promotion, no discretion:

- Every contributing judgment is non-thin.
- No contributing case is `declined`, `superseded`, or horizon-expired-unresolved.
- The drafted principle cites every contributing case by full ID. A principle without provenance is invalid in this system: delete it on sight.

Writing the principle (template in `templates.md`): assign the next P-NNN, `status: active`, a `scope:` as narrow as the evidence actually covers (cross-project scope requires cross-project cases), the evidence list with full case IDs, the statement, and concrete invalidation conditions — what future case would challenge it. Then set every contributing case to `status: cited`.

If a candidate group fails: log one line under `## Declined promotions` in `principles.md` — candidate name, the candidate case IDs, and the specific condition that failed — so future passes don't re-litigate. A declined promotion reopens only on new evidence (typically a new case on a new date), never on re-reading the same evidence.

## R4 — Standard (PRINCIPLE → STANDARD)

Attempt once per pass for each `active` principle that has neither a standard nor a recorded "not standardizable" verdict. A principle binarizes only if all of:

- Every check is pass/fail with no adjectives and no judgment words — no "appropriate", "critical", "should", "prefer".
- A less capable model (or a grep) can execute each check with only the artifact in front of it — no session context, no architecture knowledge, no "you'll know it when you see it" scoping.
- The check's scope is mechanically nameable: paths, globs, patterns. "Wherever it applies" fails this rule.

If it binarizes: write S-NNN to `standards.md` (template in `templates.md`) citing the parent principle, and note the standard in the principle's entry.

If it doesn't: record **"Not standardizable (yet)"** in the principle's entry with the reason — name the specific part that resists binarization — and, if apparent, the narrower future standard that could pass this rule later. This verdict prevents re-attempting every pass; re-attempt only when a new contributing case sharpens the boundary that blocked it.

## R5 — Invalidation review (every pass, every active principle)

For each `status: active` principle, check (a) its own stated invalidation conditions and (b) direct contradiction by any case distilled this pass. On a hit: set `status: challenged` with the citing case ID. Only the human resolves a challenge — back to `active` with a dated note, or `retired` with rationale. Never delete a retired principle; the retirement rationale is itself vault content. Retiring a principle retires its standards.

## What never promotes

The pipeline is a filter, not a conveyor. A case is a legitimate terminal record, and most decisions should live and die as distilled cases — retrievable, never promoted. In particular, never promote:

- A group whose shared tipping factor is a project-local fact (a specific tool version, a specific frozen contract's clause) rather than a transferable rule. It will retrieve fine as cases.
- Anything whose general statement needs "usually", "prefer", or "when it makes sense" to be true. That is a heuristic, not a principle; leave it in the judgments.
- Tool picks and architecture choices, absent a tipping factor that transcends the project that made them.
