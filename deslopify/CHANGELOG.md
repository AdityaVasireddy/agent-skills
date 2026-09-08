# Changelog

## v1.0.0-rc.2 — release validation (2026-09-08)

- Parse real YAML with duplicate-key and field-type checks; use folded frontmatter and Codex UI metadata
- Fix Bash output argument expansion and allow an explicit Python interpreter
- Declare exact source/install/reviewer inventories; exclude all incidental artifacts and remove the development README from installs
- Normalize text and ZIP metadata for reproducible Windows/Linux packages; expand invalid-archive checks
- Make cases.json the sole corpus and repair literal escaped paragraph separators
- Preserve separately supported admissions when removing attribution, discriminate redundant causal closers, and prevent voice samples from supplying facts
- Expand CI to Windows/Linux and Python 3.11/3.14 using pinned Node 24 actions
- Retain fresh blind evaluation and operator scoring before making a stable-release claim

## v1.0.0-rc.1 — release candidate (2026-09)

- Unsourced population claims now lose their attribution in Edit mode when no source is supplied; dependent copy reaches BLOCKED instead of retaining a warning-only claim
- Added deterministic reviewer, install, and source package builds with per-file manifests and archive verification
- Added strict required-file, frontmatter, duplicate-contract, dangling-contract, orphan-contract, and precedence-alias validation
- Added raw evaluation cases without expected answers so blind review inputs are separate from operator scoring
- Added deterministic tooling tests and GitHub Actions coverage for structural validation, package reproducibility, and oracle isolation
- Clarified activation exclusions, same-tier conflict handling, high-stakes unlisted-format behavior, and runtime-only scope for style checks

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
