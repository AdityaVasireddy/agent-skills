# Crucible v2.0.0 — Release Notes

## Overview

Crucible is a skill for [Claude Code](https://claude.com/claude-code)
and other [Agent Skills](https://agentskills.io)–compatible runtimes
that pressure-tests a startup or product idea before you build it.
v2.0.0 is a ground-up redesign: it no longer tries to predict whether
your idea will succeed. Instead, it judges only what can honestly be
judged today — whether your argument holds together — and sends
everything else to the one place that can actually answer it: reality,
through a cheap experiment you run yourself. A persistent ledger
carries what you learn from one session to the next, so the tool gets
more useful to *you specifically* the more you use it.

## Why v2 exists

v1 simulated a five-person investment committee that ended every
session with a `GO` / `RESHAPE` / `KILL` verdict. It worked, but it
had a structural problem: all five "independent" personas were the
same model, so their agreement measured how obvious a flaw was, not
how true it was — and the verdict itself claimed knowledge of the
future that nobody, human or model, actually has. Worse, run against
real history, the committee pattern reliably would have killed
category-defining companies at their earliest, roughest stage.

v2 keeps v1's founding insight — that an LLM asked to evaluate your
idea will default to agreeing with you, and has to be deliberately
engineered against that — but changes the mechanism. Instead of a
jury issuing a verdict, v2 is a loop: it interrogates your idea into
its load-bearing assumptions, judges only the ones you can verify
tonight, and designs one falsifiable experiment for the riskiest one
it can't. You go on the record with a prediction before you run it.
Next session opens by scoring you against what actually happened.

## Highlights

- **No outcome verdicts.** Crucible never says `GO`, `KILL`, or gives
  your idea a score. It says `SOUND` or `BROKEN-BECAUSE-[X]` about
  your *argument*, and shows its work.
- **One experiment per session, matched to the actual risk.** Demand
  risk gets a prepayment probe; technical risk gets a time-boxed
  spike; distribution risk gets a paid channel test. Every experiment
  has a threshold declared before it runs.
- **You go on the record.** Before each experiment: your prediction,
  and what you'll do if it fails. Next session scores you against
  reality before any new analysis happens.
- **A ledger that remembers.** Each venture gets a persistent file.
  Sessions build on the last one instead of starting cold — your
  assumption stack shrinks its `HOPE` entries over time, and you get
  a running calibration record.
- **Full design documentation.** `docs/PHILOSOPHY.md`,
  `ARCHITECTURE.md`, `WORKFLOW.md`, and `EVALUATION.md` describe the
  system independently of the prompt that implements it — useful if
  you want to understand *why* it's built this way, extend it, or
  audit whether a future change stays true to the original intent.

## Breaking changes

v1 and v2 are not compatible. If you used v1:

- Sessions no longer end in `GO`/`RESHAPE`/`KILL` — expect `SOUND` /
  `BROKEN-BECAUSE-[X]` instead.
- The five-persona council (Contrarian, Expansionist, Logician,
  Researcher, Buyer) is gone. Three examiners (Skeptic, Operator,
  Buyer) ask questions; nobody scores or votes.
- No more 1–10 persona scores or confidence levels.
- A new ledger file appears at `.crucible/<venture-slug>.md` after
  your first v2 session — v1 had no persistent state, so there's
  nothing to migrate from.
- The single 48-hour test is now one experiment per session, sized to
  the risk type, not a fixed time box.

There is no automatic migration path, and none is needed — just run
v2 fresh on your idea. See `docs/MIGRATION_V1_TO_V2.md` for the full
reasoning behind every change if you're curious why.

## Migration summary

If you're starting fresh with v2, nothing to do — follow
`INSTALL.md`. If you're coming from v1, treat this as a new tool: your
old council output isn't loaded into v2's ledger, and re-running your
idea through v2 will very likely surface different — and more
specific — findings than v1 did, because v2 forces your own numbers
onto the table instead of asserting a verdict about them.

## What should users expect?

- **The first session** produces an assumption stack, a judgment on
  your argument's internal logic, and one experiment to run this
  week — even if you never come back, that's a complete, useful
  session on its own.
- **Returning sessions** open by scoring your last prediction against
  what actually happened — expect to be told plainly when you were
  overconfident. That's the point.
- **No flattery, and no theatrical brutality either.** Both are
  performances Crucible is explicitly designed not to produce. Expect
  plain statements backed by your own arithmetic or a named
  contradiction.
- **Crucible will decline to predict your outcome.** If you ask "will
  this work," it gives you the Warranted Bet answer — what's known,
  what's hoped, what spend the evidence justifies — not a yes or no.
- **Without web search available**, the Evidence stage will say so
  explicitly and label everything `RECALL` or `REASONED` — the
  experiment carries more of the burden in that mode.

## Future roadmap

See `docs/ROADMAP.md`. In short: v2.0.0 is now frozen for real-world
founder testing. The next phase is gathering evidence from actual use
— not adding features — before any v2.1 changes are considered.
