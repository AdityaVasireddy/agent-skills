# Engineering Historian

Six months from now you won't remember why you abandoned an
architecture, or the exact firewall command that fixed your Oracle
deployment. Git doesn't record *why*. This does.

Built to the open [Agent Skills](https://agentskills.io) standard —
plain markdown and a `SKILL.md`, no proprietary format. Tested on
Claude Code; should work in any Agent Skills–compliant runtime.

## What it does
One command at the end of a coding session — `/history` — and the
agent writes a dated markdown record of that session: decisions made
(with rejected alternatives and reasons), verified commands, problems
solved, mistakes, open questions.

No database. No embeddings. No dashboard. Just markdown + git.

## Why
Future models will get better at *reasoning* over your history for
free, every year. What they can't do is retroactively capture the
present. The only thing worth building is the capture habit — so
that's all this is.

## Example output
Two files show both halves:
- [`example/2026-07-05.md`](./example/2026-07-05.md) — a capture-mode
  session record (fictional project, real template)
- [`example/retrieval-example.md`](./example/retrieval-example.md) —
  what asking your history a question looks like six months later,
  including the retrieval log that decides the 60-day trial

## Status
Running a 60-day personal trial with a pre-declared kill criterion:
every retrieval gets logged with estimated minutes saved. If
cumulative savings don't beat cumulative capture time by day 60, I
delete this. Results posted either way.