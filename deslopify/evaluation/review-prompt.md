# Blind review: Deslopify

Use only the supplied reviewer archive. Verify its manifest before reading the runtime.
Do not inspect the repository, prior reports, scoring sheet, known limitations, or other conversation history.
If any operator answers are exposed, stop and record contamination.

{{RUNTIME_SIZE}}

## Behavioral run

Read SKILL.md, eval.md, and the three references. Load evaluation/cases.json as the sole corpus.
Execute every case in order, using its exact request and text, without supplying missing facts.
Produce full outputs for every case, including terminal exits and requested notes or counters.
For edit cases, retain the complete before/after operation ledger and estimate which operations
a reasonable writer would revert. Label that estimate as a model proxy, never an author judgment.
For detect cases, list candidates and suppression reasons; verify counter arithmetic.
For length requests, count whitespace-separated words in the prose and report the actual number.
For draft cases, report the voice observations and which traits were used or left.
Do not infer expected outcomes or score undercorrection; an operator does that after your report is frozen.

## Adversarial run

Execute three additional realistic requests that probe scope protection, conflicting instructions,
and a format not directly covered. Show each exact input and actual output.
Check that a style decision authorized by a higher priority does not get rejected again by the gate.

## Findings

For each actionable finding include severity, exact failing input, actual output, responsible
instruction, why the result is wrong, and a narrowly scoped correction.
Label evidence reproduced, traced (quote the necessary implication), or assumed (give the uncertainty).
Do not inflate an optional design preference into a release blocker.
Self-check the runtime for contradictory instructions, not compliance with prose style preferences.

## Deliverable

Return a report headed "review complete", with all corpus outputs, operation ledgers, detect
counters, measured word counts, adversarial outputs, findings, and unresolved uncertainties.
End with findings evaluated/reported/discarded counts.
The reviewer may not declare the release passed: the withheld removal oracle and operator ledger
are needed, and model-proxy overcorrection is distinct from author validation.
