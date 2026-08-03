---
name: session-handoff
description: Use when the user says "session handoff", "wrap up session", "hand off", "handoff summary", "let's wrap up", "summarize before I clear", or wants a structured end-of-session summary before clearing context. Also use proactively when the user says they are about to /clear and no handoff has been produced yet. Generates a handoff document saved as a file (in the project's docs/handoffs/ directory, or as a downloadable file in chat environments) with required sections (objective, status, decisions + rationale, key files, next action) plus situational sections included only when they apply, so a fresh agent can continue seamlessly without re-deriving lost context.
---

# Session Handoff

Produce a repeatable end-of-session summary so the user can `/clear` and start a fresh agent without losing continuity. The next agent should be able to pick up by reading this document and the files it points to, in the order it declares — the handoff is the entry point to the chain, not a replacement for it.

This is a **context-handoff artifact**, not a status report or a retrospective. The audience is a future instance of you. Capture intent and reasoning, not implementation — anything the next agent can recover in seconds from the diff, the code, or the file itself doesn't belong here.

## When to invoke

User says: "session handoff", "wrap up session", "hand off", "handoff summary", "let's wrap up", "summarize before I clear", or any near-equivalent. Also invoke proactively if the user says they're about to `/clear` without having run it yet.

## How to produce the handoff

1. **Review the whole session**, not just the last few turns. If something was compacted or truncated before this instruction ran, you can't recover it — note that under Open Questions instead of guessing or inventing it.
2. **Pull state from what you actually did.** These are the categories to sweep; the tool that produces each one varies by runtime, so capture the category even when the named tool doesn't exist here:
   - **Plan or spec file** that drove the session (in Claude Code, check `~/.claude/plans/` — `%USERPROFILE%\.claude\plans\` on Windows — if one was mentioned).
   - **Unfinished task state** — in-progress or pending items from whatever task tracker was in use (TodoWrite, if present).
   - **Long-lived processes** you started, and the handle the runtime uses to address them (shell ID, terminal ID, PID). The handle is load-bearing: without it the process is orphaned and unkillable by the next agent. Record the kill command in the same form the next agent will need to type.
   - **Files created or modified** — list what you tracked as you went.
   - **Memory or vault files** written or updated (in Claude Code, `~/.claude/projects/<project>/memory/`).
   - **Decisions and why**, knowledge discovered, assumptions made, risks/issues found, constraints stated.
   - **Unresolved questions** — yours that never got a clear answer, or the user's that got deflected.
3. **Locate the prior handoff, if any, and declare precedence.** List `docs/handoffs/` (or the equivalent output directory) and take the most recent file for this thread of work. Record its path in the `Continues from:` line — see the Output template. Reading it is optional; linking it is not. Without the link, the next agent has no way to know the chain exists or that anything in it is still load-bearing. The link alone is not enough: append which document wins on conflict, because newer does not automatically mean authoritative — a detailed architecture record can outrank the summary that points at it. Use one of: *authoritative for `<scope>`* (read it before acting in that area), *superseded by this document*, or *no conflicts*. If the prior handoff is authoritative for anything, it is also the Plan file under Key Files; don't state precedence in one slot and leave the other silent.
4. **Verification boundary.** `git status`, `git diff --stat`, and `git rev-parse --short HEAD` are fine to confirm what actually changed and anchor the handoff to a commit; listing the handoffs directory is fine for step 3. Don't run `git log`, repo-wide sweeps, or grep to rediscover what you already know you touched — synthesize from what you tracked while working. If you didn't track something, say so; don't excavate or invent it after the fact.
5. **Precision-claims rule.** Don't state a specific file path, line number, numeric value, or other precise detail unless you actually observed it this session (via a read, edit, diff, calibration run, test output, or your own tool output). This includes numbers pulled from tables or test results — a specific score, threshold, or before/after value is just as much a precision claim as a line number. It also applies to causal/historical claims (e.g. "X was 0.0, changed to Y this session") — don't assert a change happened this session unless you observed the before-state yourself, not just the current state. If you're recalling, inferring, or unsure, say so explicitly — "exact location not re-verified this session," "approximate," "per earlier handoff, unconfirmed" — rather than stating it as if confirmed. The next agent cannot distinguish a verified specific from a confident guess and will trust whatever you write; a vague-but-honest pointer beats a precise-sounding one that's wrong.
6. **Self-consistency pass, before finalizing.** Reread Architecture Changes, Decisions & Rationale, Key Files, and Assumptions (and any other sections describing the same system or sequence) against each other. They describe the same facts from different angles and must agree on ordering, naming, and file locations. Every fix-claim in Decisions & Rationale must carry a matching confidence tag in Assumptions — which is why Assumptions is conditionally required, not situational (see Section model). A fix-claim with no matching tag is itself a signal to verify before output, not after. Fix any contradiction, or flag it explicitly under Open Questions — never ship two sections of the same handoff that disagree.
7. **Be concise.** Bullets over prose. Include only what's lost when context clears, not what's recoverable from the diff or code. An 8-hour session does not justify a 3,000-word handoff — it justifies a dense one. See Calibrating density below.
8. **Strip environment-specific markup before saving.** Citation tokens, source-reference markers, UI artifacts, and any other runtime-injected syntax must not survive into the file. They render as noise or as a broken reference in a different agent's environment, and a next agent may read one as a real pointer. Paths, code, and commands stay; anything the current interface injected around them goes.
9. **Save the document** per Output delivery below. Never update memory from this skill.

## Calibrating density

Target 400–700 words for a full-day, multi-subsystem session. Past 1,000, recoverable detail is leaking in — cut it. Thin sessions are far shorter (see Section model).

Density is not brevity. A dense bullet carries the same load in fewer words; a short bullet that drops the *why* or the *where* is not dense, it's lossy. Calibrate against these:

- **Bloated:** "We spent a while investigating why the validator was rejecting valid input. After trying several approaches including regex matching and a JSON parser, we determined the issue was that the model sometimes prepends explanatory text before the YAML block, which broke the naive front-matter check that assumed the document starts with `---`."
  **Dense:** "Front-matter validator rejected valid input — model sometimes prepends preamble before the `---`. Replaced the starts-with check with a scan-forward extractor. Regex and JSON-parser approaches rejected first (no reliable parser in target env)."
- **Lossy:** "Fixed the validator."
  (No why, no where, no constraint that shaped the fix — the next agent re-derives all of it.)
- **Bloated:** "Next, you should probably look at adding retry logic, and then once that's in, consider whether the queue needs visibility, and after that we discussed possibly adding a status command."
  **Dense:** "Next Action: add retry logic to the sweep call. Queue visibility and a status command were discussed but deferred — see Deferred Work."

## Output delivery

The handoff is a **file, not a chat dump**. Never paste the full document into the chat window.

- **In Claude Code (or any environment with a project filesystem):** write to `docs/handoffs/HANDOFF_YYYY-MM-DD_<slug>.md` inside the project. Create the directory if it doesn't exist. If the same slug already exists for today, append `-2`, `-3`, etc.
- **In a chat environment (Claude.ai / Cowork) without a project directory:** save the same file to the working directory and present it as a downloadable file.
- **In chat, after saving:** post only a 3–5 line confirmation — the file path or download link, the one-line Objective, and the Next Action. Nothing more.

## Section model: Required vs. Conditionally required vs. Situational

- **Required** — always present, regardless of session size. If genuinely empty, say so explicitly (e.g. "Next Action: none — purely exploratory session").
- **Conditionally required** — Assumptions. Present whenever any decision depended on something unverified, and whenever Decisions & Rationale contains a fix-claim (each one needs a matching confidence tag). Omitted only when neither condition holds. Don't apply the situational omit-silently rule to it — a missing Assumptions section where a fix-claim exists reads as "nothing was assumed," which is the opposite of the truth.
- **Situational** — included only when they apply. **If a section doesn't apply, omit the heading entirely.** Don't write "Risks: none" — omission *is* the signal, and that only works if you're consistent about it.
- **Order is fixed.** When more than one situational section applies, they appear in the order shown in the Output template — don't reorder for narrative flow; the next agent scans for headings, not prose continuity.

### Thin sessions

If the session produced no file changes, no decisions, and no plan — a short exploratory or Q&A exchange — don't pad it into a full-weight document. Write the file anyway (the user asked, and they're about to `/clear`), but include only:

```
# Session Handoff — <title>
Continues from: <path or "none">

## Objective
<what was explored and why>

## Open Questions
<what remains unresolved>

## Next Action
<single step, or "none — exploratory only">
```

Add one line stating why it's thin (e.g. "Thin handoff: exploratory session, no code or config touched"). Never omit the file to save effort — the omission is indistinguishable from a failed invocation.

### Planning sessions (decisions, no code)

The opposite case: a substantial session that produced architecture, scope, and decisions but touched no code. The standing filter — *omit what's recoverable from the diff or the code* — has nothing to filter against here, because there is no diff. The handoff is the only artifact, so it must be self-sufficient in a way a normal handoff needn't be.

Two additions when this applies:

- **State what does not exist yet.** Under Current Status, add a `Not yet built:` line inventorying the absent pieces by name (no repository, no package scaffold, no adapters, no test suite). "Implementation has not started" does not distinguish *nothing exists* from *some stubs exist*, and the next agent will otherwise open a directory expecting to find partial work.
- **Name the spec that governs the work**, if one exists, under Key Files. In a planning session the behavioral specification is usually a file the session referenced but never modified — it is the highest-value pointer in the document and the easiest to omit precisely because it has no diff.
- **A newly settled control flow still goes under Architecture Changes**, marked as decided rather than built (e.g. "Settled this session, not yet implemented:"). Deciding an architecture *is* the change when nothing was built. Don't rename the heading to fit the session — headings are fixed because the next agent scans for them, and a per-session heading vocabulary defeats that. In a *follow-on* planning session that settled nothing new, omit the section and let the prior handoff carry the flow; re-pasting it under a settled-this-session label is a false causal claim.

Do not compensate for the missing code by importing work-order content — acceptance criteria, deliverable manifests, task breakdowns, and stopping conditions belong in the plan or task file, not here. If those artifacts exist, point at them and mark precedence (see step 3). If they don't, creating them is a Next Action, not a section of the handoff.

## Classifying Outstanding Issues vs. Risks vs. Technical Debt vs. Deferred Work

These sections compete for the same content. Decide with one pass, in this order — **manifestation**, not severity or timing of consequences, is what decides the bin:

```
Has it manifested in any form — even partially (a recurring flake, a partial
mitigation, an error that already fired once) — AND is it still unresolved
or unverified?
├─ YES → Outstanding Issues, even if the worst-case consequence is still ahead
└─ NO  → Is it a plausible future failure that hasn't happened at all?
         ├─ YES → Risks (moves to Outstanding Issues the moment it occurs, even once)
         └─ NO  → Is it a shortcut or compromise living in shipped code?
                  ├─ YES → Technical Debt
                  └─ NO  → Is it a task explicitly postponed by choice?
                           └─ YES → Deferred Work
```

Boundary cases:
- **Fixed and verified** → not an issue at all; it belongs under Current Status: Completed.
- **Fixed but unverified** → Outstanding Issues, with the verification gap named explicitly ("fix authored, deployment not confirmed"). A fix you didn't watch land is not done.
- A deferred *cleanup* is Technical Debt (the compromise exists in the code now); a deferred *task* is Deferred Work (nothing in the code embodies it yet).

## Output template

Required, every time, in this order:

```
# Session Handoff — <one-line title of what this session was about>
Continues from: <absolute path to prior handoff> — <authoritative for <scope> | superseded by this document | no conflicts>
(or: "none — first handoff for this thread")

## Objective
<2-3 sentences: what the user asked for, the underlying problem it solves, and key framing or constraints that emerged. State the "why," not just the literal ask.>

## Current Status
- Completed: <what's actually done and verified>
- In Progress: <what's started but not finished>
- Blocked: <what can't proceed, and on what>
- Not yet built: <named absent pieces — required for planning sessions, useful whenever "not started" would be ambiguous>
(Omit a line only if it has nothing to report.)

## Decisions & Rationale
- <decision or change> — <why> — <where it lives, absolute path if a file and only if confirmed this session — see the precision-claims rule>

## Key Files
- Plan file: `<absolute path>` (if one drove the session — list first)
- `<absolute path>` — <why the next agent should read this>

Include: files changed this session; the plan or spec file that drove it; and any spec the work implements or must conform to, even if untouched — an unmodified behavioral spec is often the single most important pointer here.
Exclude: the session-handoff skill itself, prompts, templates, and anything else used to *generate* this document. Generation machinery is not a project input, and listing it at the same prominence as the plan misdirects the next agent.

## Next Action
<The single highest-priority next step — one step, not two joined by "and." Note hard blockers if relevant. Don't hand over a multi-step roadmap; the next agent reasons about order itself once it has context. If over-scoping is a live risk, bound the step inline with a negative clause — "scaffold the package only, no provider calls" — one clause, not a list of exclusions.>
Done when: <one check that is both observable and discriminating: it must fail if the step wasn't done. `--help` exits 0 on an empty stub, so it verifies nothing; `load_config(config.example.yaml) returns a populated object` fails on a stub, so it verifies something. Not a list of components, and not "passes its checks" without naming one. If no single check discriminates, the step is too big — narrow the step until one does, don't lengthen the test.>
```

Conditionally required — present per the Section model:

```
## Assumptions
<Every unverified thing a decision depended on, and every fix-claim from Decisions & Rationale. Tag confidence (HIGH/MED/LOW) when it isn't obvious.>
```

Situational — include only what applies, in the order below, omit the rest entirely:

```
## Knowledge Captured
<Facts, rules, behaviors, or quirks discovered this session that aren't recoverable from the code, config, diff, or documentation alone, and that aren't already established by a prior handoff for this project. If the fact is obvious from any of those sources, it is not Knowledge Captured.>

## Architecture Changes
<How data/control flow changed this session, if it did — new-or-changed only, same discipline as Knowledge Captured. A flow settled but not yet built belongs here too. Label provenance honestly: "Settled this session, not yet implemented" only when this session settled it; otherwise "Carried forward from `<path>`, unchanged" — or omit it entirely and let the prior handoff carry it. Restating an inherited architecture under a settled-this-session label is a precision-claims violation, and it recurs every session once started. A short flow sketch if it saves reverse-engineering from code. Rationale and new behavior belong under Decisions or Knowledge Captured instead. Cross-check against Decisions & Rationale and Key Files before finalizing — see the self-consistency pass.>

## Testing / Verification Performed
- PASS: <what was actually tested, and the result — name the artifact, command, or file checked. "Primary artifacts confirmed present" is unfalsifiable: the next agent can't re-run it and can't tell a real check from a reflexive one. If naming them all runs long, the claim is broader than what you observed — narrow it to what you actually looked at.>
- NOT TESTED: <gaps matter as much as passes>

## Outstanding Issues
<Defects or operational problems that have already manifested in some form and remain unresolved or unverified — see the classifier.>

## Risks
<Plausible future failures that have not yet manifested in any form — see the classifier.>

## Technical Debt
<Shortcuts, duplication, deferred cleanup — implementation compromises living in the code, not malfunctions. Tag intentional (deliberate tradeoff, tradeoff stated) vs. accidental (ran out of time) when known.>

## User Constraints
<Hard requirements the user stated that future work must not violate.>

## Runtime & System State
- Commit at handoff: <short SHA from `git rev-parse --short HEAD`>
- Long-lived processes: <handle (shell/terminal ID, PID) + what it is + kill command>
- Dev servers / ports: <url + port>
- Open branches / worktrees: <paths>
- Memory files updated: <paths>

## Deferred Work
<Tasks explicitly postponed by choice, and why — see the classifier for the boundary with Technical Debt.>

## Open Questions
**Needs User Input**
- [blocks next action | non-blocking] <question requiring the user's decision, with enough context to answer it without re-reading the session>

**Model Uncertainty**
- <thing you're unsure about, couldn't verify, or lost to truncation/compaction>

Sorting test: could a competent agent settle it by checking something — reading a file, running a command, testing an interface? Then Model Uncertainty. Does settling it require a preference, priority, or constraint only the user holds? Then Needs User Input. Environment and tooling choices ("Docker or native?", "which default model?") are usually the user's, not yours — filing them under Model Uncertainty buries a decision the user could have answered in one line.

Tag every Needs User Input item as blocking or non-blocking against the Next Action specifically. Most are non-blocking: a decision needed three tasks from now shouldn't stall the next one, and an untagged question reads as a stop sign. Don't split them into a separate section to convey this — the tag carries it, and a second section would overlap Deferred Work.
(Omit either sub-bin if empty; omit the whole section if both are.)
```

## Hard rules — checklist

Each rule is detailed exactly once above; this is the final gate before saving.

1. Handoff is saved as a file per Output delivery — full document never pasted into chat; memory never updated.
2. Required sections always present (say so if empty); Assumptions present whenever a fix-claim or unverified dependency exists; other situational sections omitted entirely when empty, in fixed order when present.
3. `Continues from:` line present under the title, pointing at the prior handoff *and declaring precedence*, or stating "none."
4. Thin sessions get the short form and never get skipped; planning sessions get the `Not yet built:` inventory and the governing spec under Key Files.
5. Paths absolute and free of machine-specific usernames — use `~` (or `%USERPROFILE%` on Windows).
6. Plan file, if one drove the session, listed first under Key Files; generation machinery excluded from it entirely.
7. Next Action is one step with a done-test naming one check that is observable *and* discriminating — not a component list.
8. Open Questions sorted by the checkable-vs-preference test; every Needs User Input item tagged blocking or non-blocking.
9. Environment-specific markup stripped before saving.
10. Decisions carry the why and where, not just the what.
11. No emojis, no hype — the tone of a seasoned engineer handing off at end-of-shift.
12. Long-lived process handles and kill commands recorded when present.
13. Verification lightweight — synthesize from tracking, don't reconstruct (see Verification boundary).
14. Classify by manifestation and unresolved-status (see the classifier); fixed-but-unverified goes to Outstanding Issues; Technical Debt tagged intentional vs. accidental when known.
15. Knowledge Captured and Architecture Changes are new-or-changed this session only; carried-forward content is labelled as such or omitted.
16. PASS entries name the artifact, command, or file checked — no collective nouns.
17. Record intent over implementation, and don't import work-order content to compensate for a missing diff.
18. Precision-claims rule applied to every specific path, number, and change-claim.
19. Self-consistency pass completed before saving.
20. Density within band (see Calibrating density).

## Anti-patterns — do not do these

- Summarizing only the last few turns and calling it a handoff.
- Pasting the full handoff into chat instead of saving it as a file.
- Turning Next Action into a numbered roadmap instead of one step — or joining two steps with "and" and calling it one.
- Writing a one-step Next Action and then a done-test listing seven components — the roadmap moved, it didn't go away.
- Picking a done-test that passes on an empty stub (`--help` exits 0) — observable but not discriminating, so it certifies nothing.
- Re-pasting an architecture inherited from the prior handoff under "settled this session" — a false causal claim that recurs every session once started.
- Writing a PASS line with a collective noun ("primary artifacts confirmed present") that names nothing the next agent could re-check.
- Leaving a Needs User Input item untagged, so a non-blocking decision reads as a stop sign and the next agent stalls to ask.
- Linking a prior handoff without saying which document wins on conflict, leaving the next agent to guess whether newer means authoritative.
- Listing the session-handoff skill, prompt, or template under Key Files, while the spec the work actually implements goes unlisted because it had no diff.
- Filing an environment or tooling choice the user owns ("Docker or native?") under Model Uncertainty, where it reads as your problem instead of their pending decision.
- Leaving citation tokens or other interface-injected markup in the saved file, where a different agent will read them as real pointers.
- Reporting "implementation has not started" without inventorying what doesn't exist, so the next agent opens the directory expecting partial work.
- Padding a planning handoff with acceptance criteria and deliverable manifests that belong in the task file — the missing diff is not a license to write the work order here.
- Padding a thin session into a full-weight document to make it look substantial — or skipping the file entirely because the session was small.
- Filing a fix you authored but never watched land under Completed instead of Outstanding Issues.
- Mixing a question that needs the user's decision with something you're personally unsure about under one undifferentiated block.
- Re-splitting Knowledge Captured back into subcategories (e.g. "Business Rules" / "Tooling Notes") — that reintroduces the classification ambiguity the merge exists to eliminate.
- Stating a precise file/line number, numeric value, or other specific fact you didn't verify this session, instead of flagging it as unconfirmed (precision-claims rule).
- Letting two sections describe the same fact differently — e.g. one section's flow implies a step happens before X, another implies after — without reconciling before output (self-consistency pass).
- Writing bullets so terse they drop the why or the where — that's lossy, not dense (see Calibrating density).