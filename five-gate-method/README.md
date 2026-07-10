# Five-Gate Method

An agent that reasons brilliantly and an agent that works reliably are
not the same agent. The second one scopes before building, opens the
real file before designing around it, tries to kill its own answer
before committing, verifies the outcome rather than the exit code, and
tells you what it checked versus what it assumed. This skill loads that
discipline as five ordered gates.

Built to the open [Agent Skills](https://agentskills.io) standard —
one plain-markdown `SKILL.md`, no scripts, no dependencies. Tested on
Claude Code; because it's pure instructions, it degrades gracefully on
any runtime — worst case, you paste the body into a rules file and it
works the same (see [`INSTALL.md`](./INSTALL.md)).

## What it does

A hard task — anything where the first idea might be wrong — passes
through five gates, each with a binary pass condition:

1. **Scope before work** — define "done" with a written check;
   prevents solving the wrong problem.
2. **Evidence before reasoning** — training memory is only a
   hypothesis generator; prevents reasoning from false premises.
3. **Reason adversarially** — generate and eliminate a rival
   explanation; prevents fixation on the first diagnosis.
4. **Verify before declaring done** — evidence of the *outcome*, not
   of execution; prevents confusing "it ran" with "it worked."
5. **Report calibrated** — verified and assumed separated out loud;
   prevents overstating certainty.

Rollback goes as deep as the damage: a failed Gate 4 can send the task
back to Gate 1, not just Gate 3. A "smells" list catches skipped gates
mid-task ("you're on attempt three of the same fix" is easier to notice
than "reason adversarially" is to remember). Trivial work skips the
gates entirely — forcing five gates onto a two-minute edit is its own
failure mode, and the skill says so.

## Why

Model intelligence is rented — pricing, availability, and tiers change
under you. Working discipline is the part you can own: it's behavioral
("re-open the file you wrote"), not stylistic ("think carefully"), so
it transfers to whatever model you're running next quarter. This skill
exists so that when the strongest model isn't available, the *process*
that made it effective still is.

## Example

[`example/worked-example.md`](./example/worked-example.md) — a
debugging session (fictional bug, real method) walked through all five
gates, including a rival hypothesis eliminated at Gate 3 and a Gate 4
failure that rolls back to Gate 2.

## Status

Shipped for behavioral testing — editorial review converged after two
external rounds, so further wordsmithing is noise. The pre-declared
test: run the same non-trivial debugging task on a mid-tier model with
and without the skill loaded, and compare where each run goes wrong.
The skill earns its place if the gated run catches failures the bare
run ships — specifically the smells it names (momentum past
invalidating results, "should work" claims, declaring done on
execution evidence). If gated runs are longer but not more correct,
that's the kill signal. Results posted either way.
