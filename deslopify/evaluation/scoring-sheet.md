# Scoring sheet

Do not show this to the reviewer. Open it after their answer is in.

## Draft D — expected decisions

**Must survive** (writer voice):
- `which was stupid, and I'd do it again` — blunt first-person admission
- `Nobody caught that. I didn't catch that.` — deliberate repetition plus self-criticism
- `Four hours of downtime. Four hours.` — deliberate repetition, fragment
- `honestly` — carries real self-reproach, not an empty adverb

**Must be removed:**
- `Here's the thing:` — throat-clearing opener
- `What most people get wrong about migrations is the dry run.` — faux-insight setup
- `Industry reports suggest most teams underinvest in database observability` — weasel attribution, unsourced
- `A migration is only as strong as the environment you test it in.` — fake-profound kicker

**Must NOT be touched:** the numbers (90, 40, 12,000, 4.1 million, 2 million, 2023, four hours).

## Scoring

4 required removals, 4 required survivals.

**Overcorrection** = writer-reverted edits / total independently reversible edits. Fails above 20%. Record every edit operation; the four required survivals are a separate regression ledger, not the numerator.
**Undercorrection** = required removals missed / 4. Fails above 20%, so missing even one of four is a fail.

Report both. Round 5 read 0/4 overcorrection and 1/4 undercorrection: the closing aphorism was preserved. The reviewer argued it states the causal lesson; the draft already showed that concretely with 12,000 vs 4.1 million rows, so the line restates rather than adds. Defensible enough that the fake-profound-kicker rule is not discriminating well on causal-sounding closers, and worth watching rather than treating as a settled reviewer error.

## Draft mode

D1: note produced, no sample request. D3: BLOCKED with named missing facts.
D2 is the regression test — `Four releases last month.` protected, `A paradigm shift.` not. Protecting both means the evidence gate is not running.

## Constraint conflict

`Cut Draft D to 10 words` must return CLOSEST COMPLIANT. Any 10-word output that keeps the numbers intact is impossible; check it did not fabricate one.

## Draft D — contaminated in round 3

The round-3 run had this sheet. That produced **no kill-criterion result**, not a weak one. Re-run only from a bundle built by `bundle.sh`, which excludes this file.

## Draft B detect

A refusal is a failure. Expected shape: several reported patterns, `voice 0`.

## Detect named-pattern grounding

Expected candidates: exactly 4.

1. Binary contrast — span: `we're not just building tools — we're redefining what's possible`
2. `redefine` word family — span: `redefining`
3. Portability failure — span: `we're redefining what's possible`
4. Em dash — span: `—`

Expected counter: `Patterns evaluated: 4 | reported: 4 | suppressed: scope 0, meaning 0, instruction 0, voice 0`.

Fail if the report adds `generic scene-setting` or another category without a canonical rule; collapses binary contrast and portability solely because they overlap; reports fewer than four canonical candidates without a valid precedence or suppression reason; or returns inconsistent counter arithmetic.

## Compression case

Pass requires: target met, minimum-edit suspended, every dropped idea named. Even thinning across all sentences is a fail regardless of word count.
