---
name: session-handoff
description: Use when the user says "session handoff", "wrap up session", "hand off", "handoff summary", "let's wrap up", "summarize before I clear", or wants a structured end-of-session summary before clearing context. Also use proactively when the user says they are about to /clear and no handoff has been produced yet. Generates a handoff document saved as a file (in the project's docs/handoffs/ directory, or as a downloadable file in chat environments) with required sections (objective, status, decisions + rationale, key files, next action) plus situational sections included only when they apply, so a fresh agent can continue seamlessly without re-deriving lost context.
---

# Session Handoff

Produce a repeatable end-of-session summary so the user can `/clear` and start a fresh agent without losing continuity. The next agent should be able to pick up by reading this document alone.

This is a **context-handoff artifact**, not a status report or a retrospective. The audience is a future instance of you. Capture intent and reasoning, not implementation — anything the next agent can recover in seconds from the diff, the code, or the file itself doesn't belong here.

## When to invoke

User says: "session handoff", "wrap up session", "hand off", "handoff summary", "let's wrap up", "summarize before I clear", or any near-equivalent. Also invoke proactively if the user says they're about to `/clear` without having run it yet.

## How to produce the handoff

1. **Review the whole session**, not just the last few turns. If something was compacted or truncated before this instruction ran, you can't recover it — note that under Open Questions instead of guessing or inventing it.
2. **Pull state from what you actually did:**
   - Plan files referenced (check `~/.claude/plans/` — `%USERPROFILE%\.claude\plans\` on Windows — if one was mentioned).
   - TodoWrite state — in-progress or pending tasks.
   - Background processes started with `run_in_background` — shell IDs are load-bearing for the next agent; without them the process is orphaned and unkillable.
   - Files created or modified — list what you tracked as you went.
   - Memory files written or updated (`~/.claude/projects/<project>/memory/`).
   - Decisions and why, knowledge discovered, assumptions made, risks/issues found, constraints stated.
   - Unresolved questions — yours that never got a clear answer, or the user's that got deflected.
3. **Verification boundary.** `git status`, `git diff --stat`, and `git rev-parse --short HEAD` are fine to confirm what actually changed and anchor the handoff to a commit. Don't run `git log`, repo-wide sweeps, or grep to rediscover what you already know you touched — synthesize from what you tracked while working. If you didn't track something, say so; don't excavate or invent it after the fact.
4. **Precision-claims rule.** Don't state a specific file path, line number, numeric value, or other precise detail unless you actually observed it this session (via a read, edit, diff, calibration run, test output, or your own tool output). This includes numbers pulled from tables or test results — a specific score, threshold, or before/after value is just as much a precision claim as a line number. It also applies to causal/historical claims (e.g. "X was 0.0, changed to Y this session") — don't assert a change happened this session unless you observed the before-state yourself, not just the current state. If you're recalling, inferring, or unsure, say so explicitly — "exact location not re-verified this session," "approximate," "per earlier handoff, unconfirmed" — rather than stating it as if confirmed. The next agent cannot distinguish a verified specific from a confident guess and will trust whatever you write; a vague-but-honest pointer beats a precise-sounding one that's wrong.
5. **Self-consistency pass, before finalizing.** Reread Architecture Changes, Decisions & Rationale, Key Files, and Assumptions (and any other sections describing the same system or sequence) against each other. They describe the same facts from different angles and must agree on ordering, naming, and file locations. Every fix-claim in Decisions & Rationale should carry a matching confidence tag in Assumptions — a fix-claim with no matching tag is itself a signal to verify before output, not after. Fix any contradiction, or flag it explicitly under Open Questions — never ship two sections of the same handoff that disagree.
6. **Be concise.** Bullets over prose. Include only what's lost when context clears, not what's recoverable from the diff or code. An 8-hour session does not justify a 3,000-word handoff — it justifies a dense one.
7. **Save the document** per Output delivery below. Never update memory from this skill.

## Output delivery

The handoff is a **file, not a chat dump**. Never paste the full document into the chat window.

- **In Claude Code (or any environment with a project filesystem):** write to `docs/handoffs/HANDOFF_YYYY-MM-DD_<slug>.md` inside the project. Create the directory if it doesn't exist. If the same slug already exists for today, append `-2`, `-3`, etc.
- **In a chat environment (Claude.ai / Cowork) without a project directory:** save the same file to the working directory and present it as a downloadable file.
- **In chat, after saving:** post only a 3–5 line confirmation — the file path or download link, the one-line Objective, and the Next Action. Nothing more.

## Section model: Required vs. Situational

- **Required** — always present, regardless of session size. If genuinely empty, say so explicitly (e.g. "Next Action: none — purely exploratory session").
- **Situational** — included only when they apply. **If a section doesn't apply, omit the heading entirely.** Don't write "Risks: none" — omission *is* the signal, and that only works if you're consistent about it.
- **Order is fixed.** When more than one situational section applies, they appear in the order shown in the Output template — don't reorder for narrative flow; the next agent scans for headings, not prose continuity.

## Classifying Outstanding Issues vs. Risks vs. Technical Debt vs. Deferred Work

These sections compete for the same content. Decide with one pass, in this order — **manifestation**, not severity or timing of consequences, is what decides the bin:

```
Has it manifested in any form — even partially (a fixed bug, a recurring
flake, a partial mitigation, an error that already fired once)?
├─ YES → Outstanding Issues, even if the worst-case consequence is still ahead
└─ NO  → Is it a plausible future failure that hasn't happened at all?
         ├─ YES → Risks (moves to Outstanding Issues the moment it occurs, even once)
         └─ NO  → Is it a shortcut or compromise living in shipped code?
                  ├─ YES → Technical Debt
                  └─ NO  → Is it a task explicitly postponed by choice?
                           └─ YES → Deferred Work
```

Boundary case: a deferred *cleanup* is Technical Debt (the compromise exists in the code now); a deferred *task* is Deferred Work (nothing in the code embodies it yet).

## Output template

Required, every time, in this order:

```
# Session Handoff — <one-line title of what this session was about>

## Objective
<2-3 sentences: what the user asked for, the underlying problem it solves, and key framing or constraints that emerged. State the "why," not just the literal ask.>

## Current Status
- Completed: <what's actually done and verified>
- In Progress: <what's started but not finished>
- Blocked: <what can't proceed, and on what>
(Omit a line only if it has nothing to report.)

## Decisions & Rationale
- <decision or change> — <why> — <where it lives, absolute path if a file and only if confirmed this session — see the precision-claims rule>

## Key Files
- Plan file: `<absolute path>` (if one drove the session — list first)
- `<absolute path>` — <why the next agent should read this>
(Not limited to files with diffs — a spec or doc that explains more than the diff does belongs here too.)

## Next Action
<The single highest-priority next step. Note hard blockers if relevant. Don't hand over a multi-step roadmap — the next agent reasons about order itself once it has context.>
```

Situational — include only what applies, in the order below, omit the rest entirely:

```
## Knowledge Captured
<Facts, rules, behaviors, or quirks discovered this session that aren't recoverable from the code, config, diff, or documentation alone, and that aren't already established by a prior handoff for this project. If the fact is obvious from any of those sources, it is not Knowledge Captured.>

## Assumptions
<Include whenever a decision depended on something unverified. Tag confidence (HIGH/MED/LOW) when it isn't obvious.>

## Architecture Changes
<How data/control flow changed, if it did. A short flow sketch if it saves reverse-engineering from code. Rationale and new behavior belong under Decisions or Knowledge Captured instead. Cross-check against Decisions & Rationale and Key Files before finalizing — see the self-consistency pass.>

## Testing / Verification Performed
- PASS: <what was actually tested, and the result>
- NOT TESTED: <gaps matter as much as passes>

## Outstanding Issues
<Defects or operational problems that have already manifested in some form and remain relevant — see the classifier.>

## Risks
<Plausible future failures that have not yet manifested in any form — see the classifier.>

## Technical Debt
<Shortcuts, duplication, deferred cleanup — implementation compromises living in the code, not malfunctions. Tag intentional (deliberate tradeoff, tradeoff stated) vs. accidental (ran out of time) when known.>

## User Constraints
<Hard requirements the user stated that future work must not violate.>

## Runtime & System State
- Commit at handoff: <short SHA from `git rev-parse --short HEAD`>
- Background processes: <shell IDs + what they are + kill command>
- Dev servers / ports: <url + port>
- Open branches / worktrees: <paths>
- Memory files updated: <paths>

## Deferred Work
<Tasks explicitly postponed by choice, and why — see the classifier for the boundary with Technical Debt.>

## Open Questions
**Needs User Input**
- <question requiring the user's decision, with enough context to answer it without re-reading the session>

**Model Uncertainty**
- <thing you're unsure about, couldn't verify, or lost to truncation/compaction>
(Omit either sub-bin if empty; omit the whole section if both are.)
```

## Hard rules — checklist

Each rule is detailed exactly once above; this is the final gate before saving.

1. Handoff is saved as a file per Output delivery — full document never pasted into chat; memory never updated.
2. Required sections always present (say so if empty); situational sections omitted entirely when empty, in fixed order when present.
3. Paths absolute and free of machine-specific usernames — use `~` (or `%USERPROFILE%` on Windows).
4. Plan file, if one drove the session, listed first under Key Files.
5. Decisions carry the why and where, not just the what.
6. No emojis, no hype — the tone of a seasoned engineer handing off at end-of-shift.
7. Background process shell IDs and kill commands recorded when present.
8. Verification lightweight — synthesize from tracking, don't reconstruct (see Verification boundary).
9. Classify by manifestation (see the classifier); Technical Debt tagged intentional vs. accidental when known.
10. Knowledge Captured is new-or-changed this session only.
11. Record intent over implementation.
12. Precision-claims rule applied to every specific path, number, and change-claim.
13. Self-consistency pass completed before saving.

## Anti-patterns — do not do these

- Summarizing only the last few turns and calling it a handoff.
- Pasting the full handoff into chat instead of saving it as a file.
- Turning Next Action into a numbered roadmap instead of one step.
- Mixing a question that needs the user's decision with something you're personally unsure about under one undifferentiated block.
- Re-splitting Knowledge Captured back into subcategories (e.g. "Business Rules" / "Tooling Notes") — that reintroduces the classification ambiguity the merge exists to eliminate.
- Stating a precise file/line number, numeric value, or other specific fact you didn't verify this session, instead of flagging it as unconfirmed (precision-claims rule).
- Letting two sections describe the same fact differently — e.g. one section's flow implies a step happens before X, another implies after — without reconciling before output (self-consistency pass).
