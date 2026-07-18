# Crucible

You are the worst person to judge your own idea, and the model you ask
is the second worst — it's built to agree with you. Crucible is
engineered against that, but not by play-acting a brutal jury: it
never claims to know whether your idea will work. It judges what can
actually be judged today — whether your *argument* holds — and then
makes reality answer the rest, one cheap experiment at a time, while
keeping score of your own predictions.

**One sentence: Crucible is the shortest path between conviction and
evidence.**

Built to the open [Agent Skills](https://agentskills.io) standard —
plain-markdown `SKILL.md`, no scripts, no dependencies. Tested on
Claude Code; because it's pure instructions, it runs anywhere (see
[`INSTALL.md`](./INSTALL.md)).

## What a session does

**Input → Interrogation → Bench → Evidence → Experiment → Ledger.**

1. **Interrogation** — three examiners (Skeptic, Operator, Buyer) ask
   the questions you can't comfortably answer. No verdicts, no
   scores. Output: your **assumption stack**, every load-bearing
   claim tagged `KNOW` / `BELIEVE` / `HOPE`. What you couldn't answer
   is a finding, not a failure.
2. **Bench** — the only judgment stage, and only on what you can
   verify tonight: your own arithmetic, contradictions, incentive
   alignment, structural impossibility. Verdict on the argument:
   `SOUND` or `BROKEN-BECAUSE-X` — never GO/KILL on the venture.
3. **Evidence** — live search on everything checkable now; every
   claim tiered `VERIFIED` / `RECALL` / `REASONED`. Recall never
   poses as fact.
4. **Experiment** — one falsifiable, behavioral, cost-capped test of
   your riskiest untested assumption — and *you* go on the record
   first: your predicted result, and what you'll do if it fails.
5. **Ledger** — a per-venture file that persists across sessions.
   Next time, the session opens by scoring your prediction against
   what reality returned. Over time it shows the three curves that
   matter: hope shrinking, calibration improving, cost-per-answer
   falling.

## Why this shape

Because the judgment worth compounding is *yours*. A verdict — even a
correct one — changes nothing unless you act; a scored prediction
changes you. Full reasoning in [`docs/PHILOSOPHY.md`](./docs/PHILOSOPHY.md)
(the constitution), [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md)
(who judges what, and why), [`docs/WORKFLOW.md`](./docs/WORKFLOW.md)
(one session, stage by stage), and
[`docs/EVALUATION.md`](./docs/EVALUATION.md) (how "it works" is
measured — founder judgment, never venture outcomes).

Coming from v1's five-persona council? The full account of what
changed and why is [`docs/MIGRATION_V1_TO_V2.md`](./docs/MIGRATION_V1_TO_V2.md).

## Example

[`example/worked-example.md`](./example/worked-example.md) — a full
v2 session on a sample idea, including the ledger it writes and the
opening of the follow-up session where the founder's prediction gets
scored.

## Status

**v2.1.0**, in use. See [`CHANGELOG.md`](./CHANGELOG.md) for release
history and [`docs/ROADMAP.md`](./docs/ROADMAP.md) for what happens
next. Crucible's own success metric is defined in
[`docs/EVALUATION.md`](./docs/EVALUATION.md): not venture outcomes —
founder calibration, stack health, and learning velocity, all
computable from the ledger it maintains.
