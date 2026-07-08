# Engineering Historian

Six months from now you won't remember why you abandoned an
architecture, or the exact firewall command that fixed your Oracle
deployment. Git doesn't record *why*. This does.

Built to the open [Agent Skills](https://agentskills.io) standard —
plain markdown and a `SKILL.md`, no proprietary format. Tested on
Claude Code; should work in any Agent Skills–compliant runtime.

## What it does

**v3: capture is automatic.** A hook fires when a Claude Code session
ends, sweeps the transcript, and drafts a dated markdown record —
decisions made (with rejected alternatives and reasons), verified
commands, problems solved, mistakes, open questions — without you
doing anything. Once a week, `/distill` shows you the drafts to
confirm or decline.

`/history` and `/case` still exist as manual overrides, for tools
that don't support the automatic hook, or when you want to capture
something yourself, in the moment.

No database. No embeddings. No dashboard. Just markdown + git.

See [`INSTALL.md`](./INSTALL.md) for setup.

## Why

Future models will get better at *reasoning* over your history for
free, every year. What they can't do is retroactively capture the
present. The only thing worth building is the capture habit — v3's
bet is that automating the trigger is what actually makes the habit
stick, since remembering to type a command is where these systems
usually die.

## Example output

Two files show both halves:

- [`example/2026-07-05.md`](./example/2026-07-05.md) — a capture-mode
  session record (fictional project, real template)
- [`example/retrieval-example.md`](./example/retrieval-example.md) —
  what asking your history a question looks like six months later,
  including the retrieval log that decides the 60-day trial

## Status

Running a 60-day trial with pre-declared kill criteria — full list in
[`SKILL.md`](./SKILL.md). Core one, unchanged since v1: every
retrieval gets logged with estimated minutes saved, and if cumulative
savings don't beat cumulative capture time by day 60, this gets
deleted. v3 adds two more, specific to automatic capture: day-file
coverage of active coding days (should approach 100%), and the
confirm rate on auto-drafted cases at `/distill` (target band:
30–90%). Results posted either way.
