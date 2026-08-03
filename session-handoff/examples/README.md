# Examples

`HANDOFF_2026-05-14_auth-rate-limiting.md` is a worked handoff from a realistic (fictional) coding session — adding rate limiting to an auth endpoint. It's here to make the abstract concrete: it shows how a real handoff uses the required sections, pulls in only the situational sections that apply, and applies the skill's core disciplines.

Things worth noticing in it:

- **Situational sections are omitted, not emptied.** There's no "Technical Debt: none" or "Architecture Changes: n/a" — sections that don't apply are simply absent. Their absence is the signal.
- **The precision-claims rule in action.** The commit SHA and file paths are stated because they were observed; the rate-limit threshold is explicitly tagged LOW confidence because it was a guess, not a measurement.
- **Manifestation-based classification.** The unvalidated limit lands under *Risks* (it hasn't caused a problem yet), not Outstanding Issues — and the entry says exactly what event would promote it.
- **Next Action is one step, with a discriminating done-test.** It names the single highest-priority next move and a `Done when:` check that fails on a stub — not a component checklist.
- **`Continues from:`** is present even though this is the first handoff for the thread — the field is never skipped, it's stated as "none" so the next agent doesn't have to guess whether a prior one exists.
- **Open Questions is tagged.** The pending product decision is marked `[non-blocking]` because the Next Action doesn't depend on it — it can proceed against the current default.

This example is a normal full-length session — it doesn't demonstrate the Thin-session or Planning-session alternate templates (short exploratory handoff, and decisions-with-no-code respectively). Those templates are in `SKILL.md` under "Section model" directly.

This is illustrative sample content, not a real handoff from this repository.
