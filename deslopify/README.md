# Deslopify

An LLM editing skill that removes identifiable AI-writing patterns while preserving factual meaning and the writer's own voice.

**It is not an AI-content detector.** It never guesses who or what wrote a text. It names specific, checkable prose patterns — the throat-clearing opener, the "not X, it's Y" contrast, the fake-profound closer — that you can verify yourself.

## Three modes

**Edit** — sharpen a draft, keep the voice.
```
Make this less AI without flattening my voice: <paste draft>
```

**Detect** — audit without rewriting.
```
Audit this for slop. Don't rewrite it: <paste draft>
```

**Draft** — write new prose under the same constraints.
```
Write this in my voice, using this sample: <sample> ... <what to write>
```

## What makes it different

Most de-slop tools flatten everything into the same clean, safe register — a second recognizable machine voice. Deslopify is built around *not* doing that:

- **Voice is modeled, then protected.** A fixed eight-signal inventory records what's yours (deliberate fragments, repetition, bluntness, admissions). Those are protected from removal.
- **Content and form are separated.** A fact worth keeping doesn't grant its broken syntax immunity, and a slop-shaped sentence doesn't earn protection just by sitting in a voiced draft.
- **It knows jargon from slop.** `robust`, `leverage`, and `harness` survive when they're the accurate technical word.
- **It never invents facts,** and never rewrites verbatim or source quotations to smooth the prose; quoted copy you explicitly mark editable follows normal editing rules.
- **You outrank its defaults.** An explicitly requested format or style beats the skill's own conventions.
- **It stops honestly.** When a task needs facts it doesn't have, it returns `BLOCKED` and names the missing facts instead of fabricating them. When a constraint can't be met without breaking a fact or your voice, it returns `CLOSEST COMPLIANT` and names what blocked it.

## Installation

Copy the `deslopify/` folder into your agent's skills directory. `SKILL.md` is the entry point; it loads `references/` on demand.

```
deslopify/
  SKILL.md            entry point
  eval.md             the quality gate
  KNOWN-LIMITATIONS.md
  references/
    patterns.md       the full pattern catalogue
    words.md          banned words + terms-of-art exceptions
    formats.md        per-format rules (email, blog, docs, ...)
```

## Supported formats

Email, Slack, LinkedIn, X, blog post, long-form essay, newsletter, landing/marketing copy, release notes, documentation/README, cover letters and bios. Unlisted formats fall back to the general rules and the skill states what it was unsure about.

## How precedence works

When rules conflict, they resolve in this fixed order, highest first:

1. **Factual accuracy** — never invent or alter a real-world fact
2. **Meaning** — preserve the point, claim strength, and caveats (unless the author explicitly revises them)
3. **Explicit user instruction** — a requested format or style beats a default
4. **Writer voice** — protected voice signals beat pattern removal
5. **Pattern removal** — everything in `patterns.md` and `words.md`; loses every tie

## Evaluation

The skill ships with its own test harness in `evaluation/`:

- **`review-prompt.md`** — an adversarial review prompt with a fixed corpus.
- **`EVALUATION.md`** — two independent kill criteria: overcorrection (good writing wrongly edited, fails above 20%) and undercorrection (slop wrongly left in, fails above 20%). They are never blended.
- **`scoring-sheet.md`** — a hidden oracle of expected decisions, kept out of the blind reviewer bundle by `scripts/bundle.sh`.

Build a blind reviewer bundle (excludes the oracle, fingerprints the contents):
```
bash scripts/bundle.sh reviewer-bundle
```

`scripts/validate.py` enforces two structural invariants: no numeric precedence-tier aliases outside the canonical list, and no dangling contract references between `eval.md` and `SKILL.md`.

## Size

Runtime is ~6.3k words. An early draft targeted 4,708 words; development showed that number was arbitrary — no failure traced to length, several traced to duplicated rules — so the budget is now the evidence-backed ~6,300-word working size. See [KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md).

## Status

**v1.0.0-rc.1 — release candidate.** Runtime behavior now removes unsourced attributed population claims when no source is supplied. Structural validation and package builds are deterministic; behavioral v1.0 readiness still depends on a fresh independent review and operator scoring.

Build and verify packages from the skill directory:

```
python scripts/bundle.py --kind reviewer --output reviewer.zip
python scripts/bundle.py --verify reviewer.zip
python scripts/bundle.py --kind install --output deslopify-install.zip
python scripts/bundle.py --kind source --output deslopify-source.zip
```

The reviewer package contains raw cases and evaluator instructions but excludes the scoring oracle and known limitations. The install package contains runtime files only. The source package contains the complete project and operator material.

## Tested with

Claude (Opus/Sonnet class), via the Claude Code / skills interface. Model-agnostic in design; the rules assume a capable instruction-following LLM.

## License

MIT — see [LICENSE](LICENSE).
