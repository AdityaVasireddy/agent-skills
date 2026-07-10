# Examples

`HANDOFF_2026-05-14_auth-rate-limiting.md` is a worked handoff from a realistic (fictional) coding session — adding rate limiting to an auth endpoint. It's here to make the abstract concrete: it shows how a real handoff uses the required sections, pulls in only the situational sections that apply, and applies the skill's core disciplines.

Things worth noticing in it:

- **Situational sections are omitted, not emptied.** There's no "Technical Debt: none" or "Architecture Changes: n/a" — sections that don't apply are simply absent. Their absence is the signal.
- **The precision-claims rule in action.** The commit SHA and file paths are stated because they were observed; the rate-limit threshold is explicitly tagged LOW confidence because it was a guess, not a measurement.
- **Manifestation-based classification.** The unvalidated limit lands under *Risks* (it hasn't caused a problem yet), not Outstanding Issues — and the entry says exactly what event would promote it.
- **Next Action is one step, not a roadmap.** It names the single highest-priority next move and lets the next agent reason about ordering from there.

This is illustrative sample content, not a real handoff from this repository.
