# Install — crucible

One file, no dependencies: no scripts, no hooks, nothing
platform-specific. Install is "put the folder where your agent looks."

## What's in this folder

```
crucible/
  SKILL.md                  the skill — the six-stage session loop
  README.md                 what it is and why
  INSTALL.md                this file
  CHANGELOG.md              release history (Keep a Changelog format)
  docs/
    PHILOSOPHY.md           the constitution — invariant principles
    ARCHITECTURE.md         components, data flow, who judges what
    WORKFLOW.md             one session, stage by stage
    EVALUATION.md           how "it works" is measured
    MIGRATION_V1_TO_V2.md   what changed from the council version
    RELEASE_NOTES_v2.0.0.md the GitHub Release writeup for v2.0.0
    RELEASE_CHECKLIST.md    the release gate this version shipped against
    ROADMAP.md               what happens next (evidence, not features)
  example/
    worked-example.md       a full v2 session + the follow-up opening
```

Only `SKILL.md` is loaded by the agent. Everything else is for humans.
New to the project? Read `README.md`, then `docs/PHILOSOPHY.md` first
— it's the shortest path to understanding *why* the skill is shaped
the way it is before you read *what* it does.

## Claude Code

Copy the folder into your skills directory:

- **Per-project:** `.claude/skills/crucible/` in the repo
- **Global:** `~/.claude/skills/crucible/`
  (`%USERPROFILE%\.claude\skills\crucible\` on Windows)

Invoke it by typing `/crucible [your idea]`, or just ask it to
"pressure-test" or "red-team" an idea — or return with your
experiment results and say so.

The skill writes a per-venture ledger to `.crucible/<venture-slug>.md` in
your working directory. Commit it if you want the history in your
repo; add `.crucible/` to `.gitignore` if you don't.

## Claude.ai / Claude Desktop

Upload the packaged `.skill` file (or the bare `SKILL.md`) in a chat
and use the **Save skill** button, if your plan/org allows skill
creation. Otherwise, paste the `SKILL.md` body into project
instructions — it works identically. With no file access, the skill
emits the ledger as a fenced markdown block at the end of each
session — save it, and paste it back to start the next one.

## Cursor, Codex CLI, Gemini CLI, and other Agent Skills runtimes

Same open [Agent Skills](https://agentskills.io) spec — drop the
folder into that tool's skills location per its docs. Untested by me
on these runtimes so far; reports welcome.

## Any other LLM (the fallback that always works)

The skill body is plain instructions with no tool or vendor coupling.
Paste everything below the frontmatter into the system prompt or the
top of a conversation and give it your idea. One caveat specific to
Crucible: the **Evidence** stage is strongest when web search is
available — with it, claims get `VERIFIED` against live sources;
without it, everything is labeled `RECALL` or `REASONED` and the
session says explicitly that nothing is verified. The session still
works either way; the experiment carries the burden instead.

## Verify it loaded

Give it an idea and check the output shape: an assumption stack
tagged `KNOW`/`BELIEVE`/`HOPE`, a Bench verdict of `SOUND` or
`BROKEN-BECAUSE-[X]` on the *argument* (never GO/KILL on the idea, no
1–10 scores), exactly one experiment with a pre-declared threshold,
and a request for your prediction and pre-commitment before it closes.
If you get generic encouragement — or a five-persona jury with
scores — the v2 skill isn't in context.
