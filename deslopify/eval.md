# Gate

Run before returning anything. Every item is pass or fail. There is no score and no threshold, because a threshold lets a failing draft through on aggregate.

## What this gate is for

**SKILL.md owns the rule. This file owns the test.** Items naming a contract in `CAPS` do not restate its algorithm; they test an observable consequence of it.

Items without a contract name are stable factual checks, deliberately spelled out in full.

**Authorization applies to every check, not just Section D.** A check that enforces a default — a scope guard, a format convention, an output convention — passes when a higher tier authorized overriding that default and the override was recorded. A user-supplied correction, an explicitly requested format, or explicitly-editable quoted copy all authorize the corresponding default to yield. Enforcing a default against an authorized override is a gate defect, the same way re-flagging an authorized preservation is.

The gate checks **authorization**, not unconditional re-application of the pattern rules. A pattern is a pass when it was removed, or when it was preserved under a named higher tier or scope guard with the reason recorded. Re-flagging an authorized preservation is a gate defect.

## A. Precedence (any fail here blocks the output)

1. **Edit:** is every real-world assertion preserved in truth conditions and claim strength, with nothing invented? A fact's value or form may change only where the user authorized a correction, non-assertive transformation, or reformatting. Exact-form protection of names, identifiers, code, and verbatim quotations is item 5's job, not this one. **Draft:** do claims match the supplied facts?
2. Does the edit preserve the writer's point, including caveats and the strength of their claims?
2a. **VOICE-OBSERVATION:** were `observed` and `protected` recorded separately, and was each protected item protected for its *form* (recurrence or personal cadence) rather than merely for carrying important content?
3. **VOICE-PROTECTION / DRAFT-VOICE-TRANSFER:** in Edit, is every protected item still present, verbatim or in function? In Draft, were only sample traits compatible with the format and supplied facts used, with none manufactured to satisfy the sample?
4. **PRECEDENCE:** did any lower tier override a higher one? Observable test: for each edit, can you name the tier that authorized it and confirm no higher tier objected?

## B. Scope guards

5. **SCOPE-PROTECTION:** where retained, are quoted material, proper nouns, product names, job titles, citations, and code unaltered, except where item 1 authorizes a change (correction, non-assertive transformation, reformatting) or the user marked quoted copy editable? Deleting a span containing one passes when the deletion was independently authorized.
5a. Was any quotation deleted to satisfy a style rule rather than because its surrounding passage went for an independent reason?  Pass only if no.
6. Were banned words kept where they are terms of art, with a note explaining why?
7. Were genuine-uncertainty hedges ("I think", "maybe", "I could be wrong") left in place?

## C. Voice

8. **ZERO-VOICE:** if the protected count is 0, did processing continue without requesting a sample? Pass unless the user asked for close voice matching and gave no sample.
9. Are strong human sentences left alone rather than rewritten for consistency?
10. Is the amount of cutting proportional to the actual slop, with no even thinning across every sentence?

## D. Patterns

11. For each category below: was every instance removed, **or** preserved under a named tier or scope guard with the reason recorded? Only an unaddressed instance fails.

- Throat-clearing openers, faux-insight setups, rhetorical setups, meta-joiners
- Binary contrasts, negative listings, colon reveals, dramatic fragmentation, synonym cycling
- Superficial `-ing` analysis, importance puffery, interpretive metadiscourse, vague declaratives, fake-strong verbs
- Weasel attribution: sourced or cut when the source is absent; never retain an unsupported attributed population claim as a warning-only edit
- Portability failures in claims, framing, bios, and marketing copy. Accurate procedural and behavioral statements are out of scope
- Fake-profound kicker deleted rather than improved
- Summary-recap ending cut
- False agency, meaning misattributed intention or emotion. Institutional and system actors performing their specified behavior are out of scope

11a. **Detect only:** can every reported candidate be traced to one canonical pattern or listed word or phrase family? Fail an invented umbrella category or an impressionistic complaint; keep independently matched canonical rules separate when their spans overlap.

## E. Overcorrection (these pass only if the answer is no)

12. Were any adverbs cut that are not on the `words.md` list?
13. Was any passive construction changed where the actor is genuinely unknown or irrelevant?
14. Was any three-item list reduced to two for rhythm rather than accuracy?
15. Was any true, memorable sentence cut only because it read as quotable?
16. Was a question or a when/why/what opener restructured for no reason beyond its shape?
17. Was any institutional or system actor rewritten around a human who does not perform the action?

## F. Format and length

18. Do the relevant `formats.md` rules hold, or were they overridden by an explicit user instruction (a requested header, tense, or shape), or was the unlisted-format fallback used and stated?
19. Em dashes handled per the em-dash rule, with any preserved under writer voice or explicit user instruction counted as authorized, not as a fail?
20. If the user gave a length target, was minimum-edit suspended, the target met (or the `CONSTRAINT-CONFLICT` exit correctly taken when the target cannot coexist with a higher tier), and every dropped idea listed?

## G. Output

21. **MODE-OUTPUT:** does the output match the contract for the mode used? Edit has What changed (transformations only), Preserved, and `E`/`S` counted independently. Draft has the text plus Constraints applied — unless the user asked for output-only, in which case the note is withheld from the delivered text and the overrides recorded internally.

---

## BLOCKED exit

**This overrides "fix and rerun."** When a fail can only be cleared by inventing a fact, do not loop and do not invent. Return:

```
BLOCKED

<the best permissible draft>

Failing gate items: <numbers>
Missing facts required to pass:
- <the specific fact, named precisely enough to look up or measure>
```

Return this instead of a compliant draft, not alongside one. Applies only to factual insufficiency. A fail caused by a user constraint colliding with a higher tier takes the **CONSTRAINT-CONFLICT** exit in `SKILL.md` instead. A fail you can clear by editing is neither.

This gate is a self-check of the proposed output, not an independently measured quality score.
