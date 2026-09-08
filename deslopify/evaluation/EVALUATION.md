# Evaluation

Evaluator machinery for `deslopify`. Not loaded at runtime and not referenced by `SKILL.md`. Ships with the skill so the criteria travel with the artifact they judge.

Declared before use, so a later run cannot rationalize a fail into a pass.

## Kill criteria

Two independent metrics. **Do not blend them into one score.** A model can fail in opposite directions, and a combined number lets aggressive editing numerically offset missed slop, or the reverse.

**Overcorrection** = writer-reverted edits / total edits. Measures whether the skill damages good writing. **Fails above 20%.** The fix for a fail is loosening the pattern tier, not adding patterns.

**Undercorrection** = required removals missed / required removals in the hidden oracle. Measures whether the skill actually removes slop. **Fails above 20%.** The fix for a fail is sharpening a pattern definition, not widening it.

Overcorrection alone is blind by construction: a wrongly *preserved* piece of slop is not an edit, so it can never be reverted and never enters that denominator. Both numbers are required for a run to count.

An edit is one independently reversible before → after operation, listed as one entry in What changed. Distinct source spans count separately. Removing a setup and repairing the pronoun that followed is one edit, because reverting half leaves broken text. Without this definition the same output falls on either side of a threshold depending on how the counter chunks it.

A draft with nothing to change produces 0/0 on both and tests nothing. It is not evidence of a pass.

Detect regression: a human-voice case must exercise the voice suppression bucket when the candidate form is genuinely protected. A zero suppression count is a failure only when the case contains an independently evidenced protected form; do not hard-code a corpus-specific counter into this evaluator.

## Regression assertion

A successful output must not be able to fail solely because the gate re-flags a decision already authorized by the precedence order or a scope guard.

Test it by running any draft where a pattern is preserved under writer voice and confirming Section D passes. If it does not, the gate has regressed to unconditional style commands and the "What this gate is for" section is not being applied.
