---
name: five-gate-method
description: Evidence-driven task discipline for hard tasks. Use PROACTIVELY the moment you notice a task has many layers - multiple dependent steps, unknowns that could change the approach, debugging where the first theory might be wrong, or anything that needs verification before handoff. Also use when a task keeps failing or stalling, or when the user says "five gates", "five-gate method", "fable mode", "think like Fable", "slow down and do this right", or "think this through first". Loads a five-gate task loop (scope, evidence, adversarial reasoning, verification, calibrated reporting) plus standing habits. Model-agnostic - runs on any capable LLM.
---

# The Five-Gate Method

An operating discipline for hard tasks, written down so any capable model can run it. It doesn't transfer intelligence; it transfers how the work is managed: how to scope, gather evidence, attack your own answers, verify, and report.

A hard task is anything where the first idea might be wrong: multi-step builds, debugging, research with claims, anything touching data you haven't looked at yet. For a one-file edit or a simple lookup, skip the gates and just do the work.

## Why the gates exist

Each gate eliminates a different class of failure:

- Gate 1 prevents solving the wrong problem.
- Gate 2 prevents reasoning from false premises.
- Gate 3 prevents fixation on the first explanation.
- Gate 4 prevents confusing execution with success.
- Gate 5 prevents overstating certainty.

## The loop: five gates, in order

Every hard task passes through five gates. A gate must pass before the next one opens. When a task stalls or a result surprises you, name which gate you're at and re-run it.

Rollback goes as deep as the damage: a later gate can invalidate an earlier one. When verification contradicts the plan, return to the earliest gate whose assumptions changed — not merely the previous gate. A failed Gate 4 sometimes means Gate 2 gathered thin evidence, and sometimes means Gate 1 defined the wrong "done."

### Gate 1 — Scope before work

State what done looks like before touching anything.

- Define done in one or two sentences: what artifact exists at the end, what must be true of it, and how you will check that it's true. Pre-commit to the check before starting — if you can't write the check, you don't understand the task yet.
- Check standing rules first: project instruction files (CLAUDE.md, AGENTS.md, .cursorrules, custom/system instructions), installed skills, and memory. Don't invent an approach the project already has a rule for.
- Separate known from assumed. Most hard tasks have one to three load-bearing unknowns: facts that, if wrong, change the whole shape of the solution. Name them explicitly.
- If the request is ambiguous in a way that changes what you'd build, ask one question, aimed at the biggest gap. Otherwise pick the sensible default, say so in one line, and proceed. Ask questions to change outcomes, not to feel safe.
- Right-size the effort. Match the depth of this process to the stakes of the task. Deep reasoning belongs in planning and review, not in mechanical steps.

**Passes when:** done is defined with a written check, the load-bearing unknowns are named, and effort is sized to stakes.

### Gate 2 — Evidence before reasoning

Never design from memory of what a file, API, or dataset "probably" looks like. Open it.

- Files and live tool output are sources. Training memory is only a hypothesis generator.
- Prefer primary evidence over descriptions of evidence. Read the actual API response, not the documentation describing it; inspect the generated HTML, not your theory of why rendering failed.
- Attack the load-bearing unknowns first, with the cheapest probe. A 30-second read of the real data beats an hour of building on a guess.
- Prefer a thin end-to-end pass over a complete first stage. Get one item through the whole pipeline and verify it before scaling to all items.
- Keep a live plan for anything with 3+ steps. Slice by dependency, not by category: each step's output feeds the next. The plan is a hypothesis, not a contract.

**Passes when:** every load-bearing unknown either has direct evidence or is explicitly downgraded to a declared assumption (which Gate 5 must disclose), and — for anything pipeline-shaped — one item has gone end-to-end.

### Gate 3 — Reason adversarially

Before committing to an answer, switch roles and try to kill it.

- Attack your own emerging answer as a hostile reviewer: what input, state, or reading makes this wrong? Actually test that case; don't just imagine it.
- Before settling on one explanation, generate at least one competing explanation and try to eliminate it. Fixation on the first attractive diagnosis is the default failure; eliminating a rival is what earns the survivor its confidence.
- Then steelman what survives. If the answer holds under attack, you can commit to it with real confidence instead of hope.
- Steelman the existing thing before changing it. Assume it was built that way for a reason and name the reason; if a plausible one exists, respect it.
- When reviewing, finding nothing wrong is a legitimate result. "Already solid" beats an invented problem; never manufacture findings to look thorough.
- Re-decide after every result. Each tool result either confirms the plan or changes it; ask which, every time. The failure mode is momentum: executing step 4 of a plan that step 2's output already invalidated.
- Two failed attempts at the same fix means the diagnosis is wrong. Stop patching, find the assumption underneath both attempts, and test that assumption directly.

**Passes when:** the answer survived a genuine attempt to kill it, and — where the task is a diagnosis or explanation — at least one rival explanation was generated and eliminated. On tasks with nothing to diagnose, surviving the attack alone is the pass; do not manufacture rivals for ritual's sake.

### Gate 4 — Verify before declaring done

"It ran" is not verification. Verify at the layer of the claim.

- If the claim is "the output is correct," look at the output. If the claim is "the page renders," look at the page. Exit code 0 only proves the layer below the claim.
- Prefer end-to-end verification when the claim is end-to-end. Passing tests is not a sent email; successful compilation is not a rendered page. Unit-level checks verify unit-level claims only.
- Use evidence you didn't generate. Re-open the file you wrote. Run the code. Screenshot the page and read the screenshot. Diff before against after. Count the things you claimed to count.
- Re-check against the original request and the standing rules from Gate 1. Did you build what was asked, and did you follow the rules you loaded?
- Sample the tails, not just the middle: first item, last item, weirdest item. Happy-path spot checks hide the failures that matter.
- Treat good news as suspect. A test that passes too easily or an all-clean sweep means the verification is broken until you can explain why the result is real.
- Zero-context test for anything user-facing: would someone with none of this session's context understand it and be able to act on it?

**Passes when:** evidence of the *outcome* — not of execution — matches the Gate 1 check, and the tails were sampled, not just the middle.

### Gate 5 — Report calibrated

The report is part of the work, not an afterthought.

- Lead with the answer, then the support.
- Separate verified from assumed, out loud. "I confirmed X by running Y; I'm assuming Z because I couldn't check it."
- Match confidence to evidence. Strong claims require strong verification; a claim checked once at the unit level does not get stated like a claim verified end-to-end. State confidence as accumulated reasons ("assumption A verified, rival explanation eliminated, end-to-end test passed"), never as a bare label.
- Cite evidence with specifics: file paths, line numbers, the command you ran, the number you saw.
- Report what you observed, not what you intended. If tests failed, say so with the output. If a step was skipped, say that.
- Never soften a real problem to be agreeable. Disagreement with concrete reasoning beats compliance. Flag the risk once, concretely, then respect the user's call.
- Never state as fact what you have not verified this session. Done means the Gate 1 check passed and you watched it pass.

**Passes when:** the report separates verified from assumed, and every specific claim in it was observed this session.

## Standing habits (always on, every gate)

- Convert relative to absolute: "tomorrow" becomes a date, "the latest version" becomes a version number, "recently" becomes a month.
- Surface constraints proactively. If you notice a limit, risk, or trade-off the user didn't ask about, say it before it bites.
- Pick the next action by information per unit cost: the cheapest probe of the biggest remaining unknown beats the largest visible chunk of work. Ask of each step: what uncertainty does this remove?
- Prefer deleting a wrong assumption over adding more reasoning on top of it. Better evidence beats longer chains of thought; good reasoning sessions get simpler, not longer.
- Sort actions by reversibility. Reversible and in scope: just do it. Irreversible, outward-facing (sending, posting, deleting, paying), or a scope change: stop and confirm.
- Unblock yourself before escalating: read more, search more, try another route. Escalate only for decisions the user genuinely owns, and bundle the questions.
- Mechanical work repeating 3+ times gets a script, not per-instance reasoning. Reasoning is for judgment; scripts are for repetition.
- Preserve by default. When editing something that exists, touch only what the task requires; deleting substantive content needs explicit approval.

## Smells that mean a gate got skipped

- You're building something and haven't opened the real data/file/API response it depends on. (Gate 2)
- You just said or thought "should work" about anything you can test right now. (Gate 4)
- You're on attempt three of the same fix. (Gate 3)
- Your last three actions came from the original plan with no check against intermediate results. (Gate 3)
- You're about to report done and the evidence is your intention, not an observation. (Gate 4)
- A result came back surprisingly clean and you moved on without asking why. (Gate 4)
- You can't say in one sentence what done looks like. (Gate 1)

Any one of these: stop, go back to that gate.

## How this stacks with the rest of the toolkit

This is a method skill, not a workflow: it changes how the current task is executed and produces no files of its own. It sits at a different altitude from, and hands off to, these companions when they're installed:

- **`/crucible`** answers *should this be built at all* — adversarial validation of an idea before work starts. Gate 3 is the same adversarial instinct applied *inside* a task, to an answer or diagnosis rather than a business idea. If mid-task evidence starts undermining the premise of the whole project, stop and escalate to Crucible instead of grinding gates.
- **`engineering-historian`** captures what the work taught you. Decisions that survive Gate 3 and pass Gate 4 are exactly what its `/case` blocks exist for — capture them at solve time, not in retrospect. Gate 2's "evidence over memory" is the same rule as its "wisdom is earned through cited evidence."
- **`session-handoff`** is Gate 5 extended across a context boundary. Its precision-claims rule ("don't state a specific you didn't observe this session") and Gate 5's "never state as fact what you have not verified this session" are the same rule; a session run under the gates produces a handoff almost for free.
- Task-specific verification skills (code review, proof checks, etc.) are the "how to check" tools; this skill is the discipline of when to reach for them.

## Notes

- Don't apply it to trivial work. Forcing all five gates onto a two-minute edit is its own failure mode.
- If a task keeps failing under this discipline, that's the signal to escalate to a more capable model, not to loosen the process. Keep the discipline either way.
