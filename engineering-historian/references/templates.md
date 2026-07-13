# Templates — exact formats for every entry type

These are the only formats the vault contains. Fields are mandatory and exactly as written unless marked optional. Fully populated real examples of each are in `worked-examples.md`.

## Day file — `knowledge/<project>/YYYY-MM-DD.md`

One file per project per day; multi-project sessions get one file each. Written by the sweep (normally) or `/history` (manual override). Section order is fixed; a section with nothing gets the literal line `None.` Prose over structure inside sections — no tables, no nested bullets beyond one level; CASE blocks are the one structured exception.

```markdown
---
project: <project-slug>
date: YYYY-MM-DD
type: [deployment|decision|debugging|feature|learning|mixed]
stack: [technologies, actually, touched]
status: <one line: where the project stands right now>
---

# <Project> — YYYY-MM-DD

## What I worked on
2–5 sentences of plain narrative. Goal, what got done. Reconstructed, not invented.

## Cases
One CASE block per qualifying decision. If none: None.

## Commands that worked
Verbatim commands that verifiably succeeded, with context. Unverifiable: mark UNVERIFIED. If none: None.

## Problems solved
Symptom → root cause → fix. One entry per problem. If none: None.

## Mistakes
What went wrong through error (not external factors) and the correction. If none: None.

## Prompts worth keeping
Verbatim prompts that produced notably good results, one line on purpose. If none: None.

## Questions I still have
Open questions left unresolved. If none: None.

## TODOs for next session
Concrete next actions stated or clearly implied. If none: None.
```

A second same-day session for the same project appends under a header (never a second file):

```markdown
## Session 2 (HH:MM)
```

with its own What I worked on / Cases / etc. content beneath it, numbered upward for further sessions.

## CASE block

Appended inside a day file's `## Cases` section. Must take under 60 seconds to write — elaboration is the distiller's job. The case ID is `<project>/<YYYY-MM-DD>#<slug>`; slugs are lowercase-hyphenated, stable, and specific (`sqlite-over-postgres-for-cache`, not `db-decision`) and are never renamed once anything cites them.

```markdown
### CASE: <slug>
status: raw
problem: <one line — the specific situation, not a category>
decision: <one line — what was actually done/chosen>
why: <one line — the reason as stated or clearly evidenced in the record>
tags: [two, to, five, lowercase, tags]
until: <optional — a condition that bounds the decision's lifetime; omit otherwise>
promote-early: <optional — justification; human capturer only, at capture time only; omit otherwise>
```

Status at creation is exactly one of two values, set by who wrote it:

- `raw` — human-confirmed at capture (`/case`, `/history`).
- `auto` — drafted by the sweep, awaiting step-0 review. The sweep never writes `promote-early`.

Lifecycle after creation (managed by `/distill`, definitions in `promotion-rules.md`): `auto` → `raw` (confirmed) or `declined — <one-line reason>`; `raw` → `distilled` → `cited`; any case → `superseded (by <case-id>)` when a later decision replaces it.

## JUDGMENT block

Appended by `/distill` directly beneath the case it distills. Exactly three lines, one sentence each, traceable to the record only. The Tipping factor sentence is the grouping key for promotion — it names the single consideration that decided the case.

```markdown
#### JUDGMENT (distilled YYYY-MM-DD)
Rejected alternative: <the alternative as it appears in the record>
Tradeoff: <what the rejected path bought vs. what it cost>
Tipping factor: <the single consideration that decided it>
```

If the record names no rejected alternative, the block opens with a `thin:` line instead of fabricating one:

```markdown
#### JUDGMENT (distilled YYYY-MM-DD)
thin: no rejected alternative in the record
Tradeoff: <if recoverable from the record; otherwise omit>
Tipping factor: <the consideration that decided it, as far as the record shows>
```

A thin judgment cannot count toward promotion until the user supplies the missing alternative and removes the `thin:` line.

## PRINCIPLE entry — `knowledge/principles.md`

One `##` section per principle, numbered P-001 upward, vault-wide. Provenance is mandatory: every evidence line is a full case ID plus one sentence tying that case to the rule.

```markdown
## P-NNN: <imperative one-line rule>

status: active
scope: <the projects/domains the evidence actually covers — no broader>
evidence: <N> cases, <M> dates
- <project>/<YYYY-MM-DD>#<slug> — <one sentence: what happened, tied to the rule>
- <project>/<YYYY-MM-DD>#<slug> — <one sentence>

**Statement:** <the full rule: the situation it governs, what to do, what never to do, and the failure mode it prevents>

**Invalidation conditions:** <the concrete future case that would challenge this principle — specific enough that R5 can check it mechanically>

**Standard:** S-NNN — or — **Not standardizable (yet):** <the part that resists binarization, and the narrower future standard if one is apparent>
```

Status transitions: `active` → `challenged` (R5 hit, with citing case ID) → `active` with a dated note, or `retired` with rationale. Retired principles are never deleted.

Declined promotions live at the bottom of the same file, one bullet each:

```markdown
## Declined promotions

- **<candidate-name>** (candidates: <case-id>, <case-id>, <case-id>) — <the specific rule/condition that failed, one line>. <Reopening condition, one line>.
```

## STANDARD entry — `knowledge/standards.md`

Only written when R4 binarizes a principle. Every check is pass/fail with no adjectives, executable by a less capable model (or a grep) against the artifact alone.

```markdown
## S-NNN: <check name>

derived-from: P-NNN
status: active
scope: <mechanical scope — paths, globs, patterns>

Checks (each pass/fail):
- <check 1 — a condition that is true or false of the artifact, nothing else>
- <check 2>

On failure: <the fixed action — fix to pattern X, or escalate to P-NNN for human judgment>
```

## Retrieval log line — `knowledge/retrieval-log.md`

Append-only, one row per retrieval that materially answered a question:

```markdown
| YYYY-MM-DD | <question, abbreviated> | <source: file or P-/S- ID> | <est. minutes saved> |
```

Minutes saved comes from the user in the same breath as the answer, or is self-estimated and marked `(est.)`. Never log retrievals that didn't actually help.

## Capture rule — `knowledge/capture-rules.md`

Added only at `/distill` step 0, from decline reasons. Negative and specific, never aspirational; consolidate near-duplicates rather than accumulating; cap 25. The file also carries the two `## Sweep health` counters (`confirmed:` / `declined:`), updated after each step-0 batch. Seed file: `assets/capture-rules.seed.md`.

```markdown
- Do not draft cases for <the specific class of noise, as observed>. (added YYYY-MM-DD)
```
