# Agent Skills

Small, focused skills built to the open [Agent Skills](https://agentskills.io) standard. Each one ships with a stated purpose, a real example, and — where it applies — a pre-declared kill criterion I test against before calling it "done."

Built and tested on Claude Code. The Agent Skills spec is implemented across other tools (Cursor, Codex CLI, Gemini CLI, and more) — untested on those yet; reports welcome.

## Skills

### [engineering-historian](https://github.com/AdityaVasireddy/agent-skills/blob/main/engineering-historian) — v3

Captures a chronological, per-project engineering record — decisions made (and alternatives rejected), verified commands, mistakes, open questions. The principle: *the log is the asset, the reasoning is rented.*

**v3 adds automatic capture.** v1/v2.5 relied on remembering to type `/history` at session end — the honest failure mode of any manual-trigger system. v3 replaces the trigger with a Claude Code hook that sweeps the session transcript automatically and drafts records (`status: auto`) for review; nothing else about the pipeline, formats, or promotion rules changed. See `engineering-historian/INSTALL.md` for setup. Currently in a 60-day usage trial — criteria pre-registered in `SKILL.md`, including new trigger-reliability and sweep-confirm-rate thresholds specific to v3.

More skills landing here over time.

## Install

Skills are plain folders — drop one into whatever skills directory your agent looks for.

**engineering-historian specifically** ships two extra pieces beyond the skill folder (a hook script and a sweep prompt) because Claude Code hooks are invoked by file path, not by skill content. See `engineering-historian/INSTALL.md` for the two-step setup.

**For skills without an automation layer:** copy the skill's folder into `.claude/skills/<name>/` in your project, or `~/.claude/skills/<name>/` globally. Other Agent Skills–compatible tools use their own convention — check that tool's docs.

---

Built by [Satya Aditya Vasireddy](https://www.linkedin.com/in/satyaadityavasireddy/)
