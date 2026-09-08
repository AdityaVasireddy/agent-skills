# Changelog

## v0.9.2 — public beta (2026-09)

- Fixed a dead build-time substitution: the runtime-size regex stopped matching after its target text changed, so counts were silently omitted from the reviewer prompt. Replaced with an asserted {{RUNTIME_SIZE}} sentinel that fails the build if missing
- README now links KNOWN-LIMITATIONS.md at its real path

## v0.9.1 — public beta (2026-09)

- Retired the 4,708-word ceiling everywhere, including the bundler, which still enforced it after the docs removed it
- README quotation wording now reflects provenance (verbatim frozen, user-marked-editable follows Edit rules)
- Runtime size shown as a soft target, not a hard ceiling

## v0.9.0 — public beta (2026-09)

First public release. Core editing behavior hardened across thirteen adversarial review rounds.

**Architecture**
- Three modes: Edit, Detect, Draft
- Five-tier precedence: factual accuracy > meaning > explicit user instruction > writer voice > pattern removal
- Two-pass voice model: observe (fixed eight-signal inventory), then gate for protection on evidence about the form, not the content it carries
- `BLOCKED` exit for factual insufficiency; `CLOSEST COMPLIANT` exit for irreconcilable constraints
- Terms-of-art exceptions so technical vocabulary survives
- Provenance-based quotation protection (verbatim source is frozen; user-marked editable copy is not)

**Evaluation harness**
- Blind reviewer bundle with a withheld scoring oracle
- Independent overcorrection / undercorrection kill criteria (never blended)
- Fixed regression corpus
- `bundle.sh` fingerprinted builds; `validate.py` structural invariants
- Named behavioral contracts to prevent cross-file rule drift

**Known open items** (see KNOWN-LIMITATIONS.md)
- Undercorrection metric not yet scored (requires an operator oracle run)
- Runtime ~6,300 words; original 4,708 ceiling retired as arbitrary
