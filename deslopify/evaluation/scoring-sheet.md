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

Grade canonical grounding, not adherence to one preferred candidate decomposition.

The report must account for these four canonical candidates unless it gives a valid suppression under the existing Detect precedence contract:

1. Binary contrast — canonical rule: Binary contrasts; span: `we're not just building tools — we're redefining what's possible`
2. Banned word-family match — canonical entry: `redefine`; span: `redefining`
3. Portability failure — canonical rule: Portability failure; span: `we're redefining what's possible`
4. Em dash — canonical rule: Em dashes; span: `—`

The opener may be reported as a fifth candidate: Portability failure — canonical rule: Portability failure; span: `In today's rapidly evolving AI landscape`. Accept a natural reader-facing label such as `Generic scene-setting / portability failure` only when the canonical Portability failure mapping is explicit and identifiable. Reject `Generic scene-setting` when it is presented as a standalone canonical pattern. The same canonical rule may apply independently to this span and the later `we're redefining what's possible` span.

For an unsuppressed report, accept either:

- `Patterns evaluated: 4 | reported: 4 | suppressed: scope 0, meaning 0, instruction 0, voice 0`
- `Patterns evaluated: 5 | reported: 5 | suppressed: scope 0, meaning 0, instruction 0, voice 0`

If the opener is evaluated as a Portability failure and then suppressed for a legitimate precedence reason, accept the corresponding counter only when the report identifies that reason and the arithmetic remains valid under the existing Detect contract. Do not require the fifth candidate, force exactly five, or permit candidates beyond the four required candidates and the canonically grounded opener variant.

Fail if the report:

- includes any candidate that cannot be traced to a canonical `patterns.md` or `words.md` entry;
- treats `generic scene-setting`, `AI-sounding language`, `corporate tone`, or a similar impressionistic label as a standalone canonical pattern;
- misses one of the four required canonical candidates without a valid suppression;
- collapses binary contrast and portability solely because their spans overlap;
- counts the opener as a fifth candidate without grounding it to Portability failure;
- returns inconsistent Detect counter arithmetic; or
- rewrites the text in Detect-only mode.

## Compression case

Pass requires: target met, minimum-edit suspended, every dropped idea named. Even thinning across all sentences is a fail regardless of word count.
