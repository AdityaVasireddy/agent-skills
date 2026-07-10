# Install — five-gate-method

This skill is one file with no dependencies: no scripts, no hooks, no
`jq`, nothing platform-specific. Install is "put the folder where your
agent looks."

## What's in this folder

```
five-gate-method/
  SKILL.md                  the skill — the five gates, standing habits, and smells
  README.md                 what it is and why
  INSTALL.md                this file
  example/
    worked-example.md       a debugging session run through all five gates
```

Only `SKILL.md` is loaded by the agent. Everything else is for humans.

## Claude Code

Copy the folder into your skills directory:

- **Per-project:** `.claude/skills/five-gate-method/` in the repo
- **Global:** `~/.claude/skills/five-gate-method/`
  (`%USERPROFILE%\.claude\skills\five-gate-method\` on Windows)

That's it. The skill triggers automatically on multi-layered tasks, or
on demand — say "five gates" or "slow down and do this right."

## Claude.ai / Claude Desktop

Upload the packaged `.skill` file (or the bare `SKILL.md`) in a chat
and use the **Save skill** button, if your plan/org allows skill
creation. Otherwise, paste the `SKILL.md` body into project
instructions — it works identically; you just invoke it by name
instead of relying on auto-triggering.

## Cursor, Codex CLI, Gemini CLI, and other Agent Skills runtimes

These implement the same open [Agent Skills](https://agentskills.io)
spec — drop the folder into that tool's skills location per its docs.
Untested by me on these runtimes so far; reports welcome.

## Any other LLM (the fallback that always works)

The skill body is plain behavioral instructions with no tool or vendor
coupling. If your runtime has no skill support at all, paste everything
below the frontmatter into the system prompt, rules file
(`AGENTS.md`, `.cursorrules`), or the top of the conversation. You
lose auto-triggering — the runtime feature — but none of the method.

## Verify it loaded

Give the agent a non-trivial task and ask it to name which gate it's
at. If it can't, the skill isn't in context.
