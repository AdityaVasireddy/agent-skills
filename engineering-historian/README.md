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

**v3.1** hardened the trigger: the sweep now skips only sessions that
are *provably trivial* — transcript size, user turns, and recent git
activity all quiet — instead of guessing significance from a turn
count. Three-prompt sessions where the agent worked for hours are
captured; when in doubt, it captures. Details in
[`CHANGELOG.md`](./CHANGELOG.md) and
[`docs/adr/ADR-001-capture-gate-triviality.md`](./docs/adr/ADR-001-capture-gate-triviality.md).

No database. No embeddings. No dashboard. Just markdown + git.

One thing to know up front: the hook fires only when Claude Code
**exits gracefully** (`/exit`, `/quit`, or `Ctrl+C`/`Ctrl+D`).
Killing the terminal skips the exit routine and no sweep runs — the
usual reason people think it's broken. Setup, the `jq` gotcha on
native Windows, and platform-by-platform install are all in
[`INSTALL.md`](./INSTALL.md).

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
