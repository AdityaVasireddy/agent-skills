# Agent Skills

Small, focused skills built to the open [Agent Skills](https://agentskills.io) standard. Each one ships with a stated purpose, a real example, and — where it applies — a pre-declared kill criterion I test against before calling it "done."

Built and tested on Claude Code. The Agent Skills spec is implemented across other tools (Cursor, Codex CLI, Gemini CLI, and more) — untested on those yet; reports welcome.

## Skills

### [engineering-historian](https://github.com/AdityaVasireddy/agent-skills/blob/main/engineering-historian) — v3.1.2

Captures a chronological, per-project engineering record — decisions made (and alternatives rejected), verified commands, mistakes, and open questions. The principle: *the log is the asset, the reasoning is rented.*

**v3 introduced automatic capture.** v1/v2.5 relied on remembering to type `/history` at session end — the honest failure mode of any manual-trigger system. v3 replaced the trigger with a Claude Code hook that automatically sweeps the session transcript and drafts records (`status: auto`) for review. **v3.1.2 production-hardens that pipeline** with improved reliability, validation, diagnostics, replay, portability, and safer operational behavior while preserving the same vault format and promotion workflow.

Currently undergoing a **60-day real-world evaluation** with pre-registered success criteria in `SKILL.md`. See `engineering-historian/INSTALL.md` for setup.

### [crucible](https://github.com/AdityaVasireddy/agent-skills/blob/main/crucible) — v2

Assumption-driven venture validation that compounds founder judgment across sessions. Three examiners interrogate the idea into an assumption stack (`KNOW`/`BELIEVE`/`HOPE`), the Bench judges only what's checkable tonight — your own arithmetic, contradictions, incentives — with a `SOUND`/`BROKEN-BECAUSE-X` verdict on the *argument*, and each session ends in one falsifiable, cost-capped experiment with your prediction and pre-commitment on the record. A per-venture ledger persists across sessions; the next one opens by scoring your prediction against what reality returned.

**v2 replaced v1's five-persona jury and GO/RESHAPE/KILL verdict** — it no longer claims to know outcomes at all. The design reviews that led there, and the full philosophy/architecture/evaluation docs, live in `crucible/docs/`. One markdown skill file, no dependencies.

### [five-gate-method](https://github.com/AdityaVasireddy/agent-skills/blob/main/five-gate-method) — v1

Evidence-driven task discipline for hard tasks — anything where the first idea might be wrong. Five ordered gates, each with a binary pass condition: scope before work, evidence before reasoning, adversarial reasoning, verification at the layer of the claim, calibrated reporting. Plus a "smells" list that catches skipped gates mid-task ("you're on attempt three of the same fix" is easier to notice than "reason adversarially" is to remember).

The premise: model intelligence is rented — pricing and availability change under you — but working *discipline* is behavioral, not stylistic, so it transfers to whatever model you run next. One markdown file, no scripts, no dependencies; if a runtime has no skill support at all, the body pastes into a rules file and works the same. Shipped for behavioral testing — the pre-declared check is in `five-gate-method/README.md`.

### [session-handoff](https://github.com/AdityaVasireddy/agent-skills/blob/main/session-handoff) — v1

Produces a structured end-of-session handoff so you can `/clear` and start a fresh agent without losing continuity — the next agent picks up by reading one document. Required sections (objective, status, decisions + rationale, key files, next action) plus situational sections included only when they apply. The audience is a future instance of the model, so it captures intent and reasoning, not implementation — anything recoverable from the diff or the code in seconds is deliberately left out.

The rules that make it trustworthy: a precision-claims rule (never state a path, number, or change you didn't observe this session), a self-consistency pass (sections describing the same system must agree before saving), and classification-by-manifestation for issues vs. risks vs. debt. One markdown file, no dependencies.

## The through-line

The skills aren't a grab bag — they cover a project's lifecycle in order:

- **crucible** — *should this be built at all?* (before work)
- **five-gate-method** — *how do I reason while building it?* (during work)
- **engineering-historian** — *what did the work teach me that's worth keeping?* (after work)
- **session-handoff** — *how do I preserve context for the next agent?* (across the context boundary)

More skills landing here over time.

## Install

Skills are plain folders — drop one into whatever skills directory your agent looks for.

**engineering-historian specifically** ships two extra pieces beyond the skill folder (a hook script and a sweep prompt) because Claude Code hooks are invoked by file path, not by skill content. See `engineering-historian/INSTALL.md` for the two-step setup.

**For skills without an automation layer** (crucible, five-gate-method, and session-handoff are all single-file): copy the skill's folder into `.claude/skills/<name>/` in your project, or `~/.claude/skills/<name>/` globally. Other Agent Skills–compatible tools use their own convention — check that tool's docs.

---

Built by [Satya Aditya Vasireddy](https://www.linkedin.com/in/satyaadityavasireddy/)
