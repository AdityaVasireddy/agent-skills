# Session Handoff

A skill that produces a disciplined end-of-session summary so you can clear your context window — or hand work to a teammate — without losing the reasoning behind what was done.

The output is written for one reader: the **next agent** (or the next you). It captures intent and decisions, not implementation, so a fresh session can pick up the work by reading a single document instead of re-deriving lost context from the diff.

## What problem it solves

Long agentic sessions accumulate context that lives only in the conversation: why a design was chosen over the obvious alternative, which assumption a fix depended on, what was tested versus merely attempted, which background process is still running. When the context window clears, all of that is gone — and the next session either rediscovers it slowly or, worse, silently contradicts it.

Session Handoff writes that reasoning down in a fixed structure before it's lost. It is deliberately **not** a status report or a retrospective. Anything recoverable in seconds from the code, the diff, or a file is left out on purpose; only what disappears when context clears is kept.

## What makes it different

- **Manifestation-based classification.** Outstanding Issues, Risks, Technical Debt, and Deferred Work compete for the same content. The skill uses a single decision tree — has it manifested yet? does a compromise live in the code? — so the same fact lands in the same bin every time, instead of by gut feel.
- **A precision-claims rule.** The skill forbids stating a file path, line number, or numeric value it didn't actually observe in the session. A vague-but-honest pointer beats a precise-sounding guess the next agent will trust blindly.
- **A self-consistency pass.** Sections that describe the same system from different angles must agree on ordering, naming, and locations before the document is saved — no shipping a handoff that contradicts itself.
- **Required vs. situational sections.** A five-minute session and an eight-hour session use the same template; situational sections are omitted entirely (not filled with "none") so their absence carries signal.

## When it triggers

Say any of: "session handoff", "wrap up session", "hand off", "handoff summary", "let's wrap up", "summarize before I clear" — or tell the agent you're about to clear context and it will offer one proactively.

## Where the output goes

- **In a coding agent with a project filesystem:** written to `docs/handoffs/HANDOFF_YYYY-MM-DD_<slug>.md` in the repo.
- **In a chat environment without a project directory:** saved to the working directory and offered as a downloadable file.

Either way, the full document is never dumped into the chat — only a short confirmation with the file location, the one-line objective, and the next action.

## Install

See [INSTALL.md](INSTALL.md). It's a pure-markdown skill — no scripts, no dependencies, no hooks. Drop the folder in and start a new session.

## Portability

The skill's core discipline (the classifier, the precision-claims rule, the self-consistency pass, the section model) is tool-neutral and works in any capable LLM. A few file-path references in the "how to produce" step are written for Claude Code conventions and degrade gracefully elsewhere. See [INSTALL.md](INSTALL.md#portability-notes) for the specifics if you're running it outside Claude Code.

## License

See the repository root license.
