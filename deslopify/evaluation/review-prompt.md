# Review prompt: deslopify skill

Paste everything below the line into ChatGPT, Kiro, Gemini, or any other reviewer. Attach the reviewer package and load `evaluation/cases.json` as the fixed corpus. The package contains the runtime files, `EVALUATION.md`, this prompt, and raw cases; it must not contain `scoring-sheet.md` or `KNOWN-LIMITATIONS.md`. If either appears, stop and say the run is contaminated.

Use the same prompt and the same test corpus with every reviewer. Changing either makes the reviews incomparable.

---

You are reviewing an LLM skill called `deslopify`. A skill is a set of instructions loaded into an AI assistant's context to change how it behaves on a task. This one edits prose to remove AI writing patterns while preserving the writer's voice, drafts new prose under the same constraints, and audits drafts without rewriting.

I want to know where it breaks. I have already read it and I am not looking for confirmation that it is good.

## Rules for this review

**No praise section.** Do not open with what the skill does well. If a strength is load-bearing for a finding, mention it inside that finding.

**Every finding needs a failing input.** State the specific text, request, or draft that would make the skill produce a bad result. A finding you cannot demonstrate with an input is an opinion, and I will discard it. If you are reasoning about a failure you have not run, say so in the evidence field rather than presenting it as observed.

**Classify evidence on every finding** using exactly one of:
- `reproduced` — you ran the skill on an input and observed the bad output
- `traced` — you followed specific instruction text to a necessary consequence, and you quote the text
- `assumed(<reason>)` — you believe it will fail but have not shown it

**Attack the design, not the formatting.** Do not tell me to add more examples, break up sections, add a table of contents, or improve headings unless you can show that the current structure causes a wrong output.

{{RUNTIME_SIZE}}

**Disagreeing with a design choice is not a finding.** If you would have built it differently, say so once in a separate section at the end. Findings are for things that produce wrong output.

## Part 1 — Behavioral run (do this first, before reading for flaws)

Apply the skill to all four drafts below. Actually produce the edited output. Then report, per draft:

- The edited text
- Which edits a reasonable writer would revert, and the revert rate as `reverted / total edits`
- Whether the skill's own `eval.md` gate would have caught each reverted edit, by item number
- Whether it took the empty-voice branch when it should have

Then run detect mode on the two detect cases and report the full counter: `evaluated N | reported M | suppressed: scope S, meaning P, instruction I, voice V`, with `N = M + S + P + I + V`. A refusal is a behavioral result to report, not a reason to stop.

### Draft A — human voice, technical

> I spent four days on a bug that turned out to be a trailing slash. Four days. The config loader was doing path joins with string concatenation instead of `path.join`, so `/etc/app/` and `/etc/app` resolved to different cache keys and the second one silently created an empty config. No error. Just an app that booted fine and ignored every setting.
>
> I want to say I found it through disciplined bisection. I found it because I got annoyed and started printing every variable in the loader. Sometimes that is the method. The fix was one character. The test that would have caught it took forty minutes to write and I wrote it after, which is the wrong order and I know it.

### Draft B — machine-generated marketing copy

> In today's rapidly evolving digital landscape, businesses need robust solutions that can seamlessly scale with their needs. Our platform doesn't just streamline your workflow. It transforms it.
>
> Here's what most teams get wrong: they focus on tools instead of outcomes. The reality is that meaningful change requires more than software. It requires a paradigm shift.
>
> That's why we built something different. A platform that empowers your team to delve into what actually matters, highlighting the insights that drive real results. Industry reports suggest that companies leveraging integrated workflows see significant improvements in productivity.
>
> The future of work isn't coming. It's already here.

### Draft C — technical documentation with terms of art

> The estimator is robust to outliers in the tail because it utilizes a trimmed mean rather than the raw sample mean. Leverage in the regression sense is computed per-observation and stored in the diagnostics table. The harness is powered from the 12V rail.
>
> The config is read at startup. If the file is missing, defaults are applied and a warning is logged. The build takes roughly 40 minutes on CI, most of which is the integration suite.
>
> Three components make up the pipeline: the collector, the normalizer, and the writer.

### Draft D — mixed voice and slop (the kill-criterion test)

Some edits should happen here. Some suspicious patterns should survive. Getting both right is the test.

> We shipped the migration on a Friday, which was stupid, and I'd do it again. Here's the thing: the rollback window was 90 minutes and we used 40 of them.
>
> What most people get wrong about migrations is the dry run. Ours passed. It passed because the staging DB had 12,000 rows and production had 4.1 million, and the query planner picks a different plan above about 2 million. Nobody caught that. I didn't catch that.
>
> The fix was an index we should have had since 2023. Industry reports suggest most teams underinvest in database observability, and honestly, we were one of them. Four hours of downtime. Four hours.
>
> A migration is only as strong as the environment you test it in.

Report **overcorrection** (writer-reverted edits / total independently reversible edits, fails above 20%) using the edit unit in `EVALUATION.md`. Record removal decisions separately for operator scoring. Do not infer expected decisions from this prompt.

### Compression case

Take Draft D and request: `cut this to 90 words`. Verify that minimum-edit was suspended, the target was met, and every dropped idea was named so the writer can put one back. Even thinning across all sentences is a fail.

### Blocked marketing case

Request: `This is machine-generated marketing copy. Don't preserve its voice, just clean it up.` applied to Draft B. Report which branch fires, whether facts are invented, and whether the output follows the declared contract.

### Regression assertion

Confirm that a successful output cannot fail solely because the gate re-flags a decision the precedence order or a scope guard already authorized. Use a corpus case and quote the relevant output.

### Draft mode tests (no prior behavioral evidence exists for this mode)

Run all three. Report the output and which branch fired.

**D1 — no sample, neutral technical.** Run the corresponding case from `cases.json` and report whether the no-sample branch is handled.

**D2 — supplied sample with a real and a slop-shaped fragment.** Run the corresponding case from `cases.json`; report voice observations, protected forms, and any unsupported traits transferred.

**D3 — insufficient facts.** Run the corresponding case from `cases.json`; report missing facts and whether unsupported claims were invented.

### Constraint-conflict test

`Cut Draft D to 10 words.` Report the terminal exit, retained facts, and the constraint that prevented further reduction.

## Part 2 — Break it

Construct three inputs designed to make the skill fail, and report what it does with each. Aim at:

1. A request where two of its own rules conflict and the precedence order does not resolve the conflict
2. An input where the scope guards should protect something and do not
3. A mode or format the skill claims to handle but has no actual rules for

Report the input, the output, and the specific instruction that failed.

## Part 3 — Document findings

Now read for problems the runs did not surface. Focus on:

- Instructions an LLM would follow literally and produce a wrong result
- Rules stated as absolutes that have obvious correct exceptions
- Checks in `eval.md` that a model would pass trivially regardless of output quality, or that cannot be answered honestly by the model that just wrote the draft
- Places where the precedence order is stated but not actually usable at the point of decision
- The `description` field in the frontmatter: what should trigger it and does not, what triggers it and should not
- Anything that is asserted rather than made checkable

## Part 4 — Displacement

Name at least three things in the skill you would cut, with a reason. Being redundant with another section counts. This funds your recommendations.

## Part 5 — Self-application

The skill forbids specific patterns. Check whether its own five files violate them, and quote the lines. Be specific about which named pattern each violation matches.

## Output format

Use exactly this structure.

```
## Status
One of: **review complete** (you ran the corpus and reported findings) or **evaluation scored** (an operator has applied the withheld oracle). You can only produce the first. Undercorrection needs the oracle, so an overcorrection figure alone is never a kill-criterion pass.

## Behavioral results
| Draft | Edits | Reverted | Overcorrection | Gate caught it? |
|---|---|---|---|---|
Undercorrection: not scoreable from this bundle. List your removal decisions for the operator to compare.
Detect on Draft A: evaluated N | reported M | suppressed: scope S, meaning P, instruction I, voice V
Detect on Draft B: same format; a refusal here is a failure

## Findings
For each, in severity order (Critical / High / Medium / Low):

### [Severity] Short title
Failing input: <the exact text or request>
What the skill does: <observed or traced behavior>
Instruction responsible: "<direct quote from the file, with filename>"
Why it is wrong: <one or two sentences>
Fix: <specific edit>
Displaces: <what comes out to make room, or "none needed">
Evidence: reproduced | traced | assumed(<reason>)

## Cuts
Three or more, each with a reason.

## Design disagreements
Things you would have built differently that do not produce wrong output. Kept separate from findings on purpose.

## Counters
Findings evaluated: N | reported: M | discarded as unsupported: N-M
Confidence: which of your findings would change if you had run more inputs
```

## What I will discard

- Findings with no failing input
- "Consider adding..." with no displacement
- Praise
- Severity inflation, meaning anything marked Critical that does not produce a wrong output on a realistic input
- Restating the skill's own content back to me as analysis
- A summary of what the skill does

End with the counters. If you evaluated ten candidate findings and reported three, I want to see that, because it tells me whether you were filtering or listing.
