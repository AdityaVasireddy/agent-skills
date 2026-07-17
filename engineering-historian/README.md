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

**v3.1.2** is Phase 1 of a production-readiness review, run ahead of
the 60-day evaluation. Nothing changes in what is captured, promoted,
retrieved, or stored — this closes gaps in the automation layer
itself: the auto-commit is now pathspec-limited to `knowledge/` and
skips (with a log line) during any merge/rebase/cherry-pick/bisect,
instead of committing a user's entire staged index under a
`history(auto):` message; an existing case can no longer be silently
dropped by a day-file rewrite (every `### CASE:` on disk must survive,
or the old file is kept and the run is queued for retry); and the
vault's own documented guarantees — `.sweep/` gitignored,
`capture-rules.md` seeded on first touch — are now actually true
instead of just claimed. It also adds a way to check the sweep
without waiting for a hook to fire: `--doctor` (read-only health
check), `--status` (queue + log tail), and `--replay` (deterministic
retry of one queued transcript, replacing hand-improvised recoveries).
62/62 tests passing. Full entry in [`CHANGELOG.md`](./CHANGELOG.md).

**v3.1.3** fixes a real bug found in the wild: the sweep hook is
registered machine-wide, so it also runs inside headless `claude -p`
sessions in *other* projects — and until this release, it created a
`knowledge/` vault in whatever directory it woke up in even when it
was about to skip, before it had even checked for a transcript. A
no-op `-p` session in an unrelated repo could silently leave a stray
`knowledge/` folder behind. The sweep now runs every skip check —
transcript exists, session isn't trivial, not a duplicate — before
touching the filesystem at all; a skip leaves the directory exactly
as it found it and logs to a shared location instead
(`~/.claude/historian/skips.log`). This release also closes a related
race where a session ending right after a compaction could fire the
sweep twice and pay for two model calls instead of one. 75/75 tests
passing, including a live reproduction of the original bug. Full
entry in [`CHANGELOG.md`](./CHANGELOG.md).

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
