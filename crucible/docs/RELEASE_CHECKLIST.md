# Crucible v2.0.0 — Release Checklist

The official release gate. All items must be checked before tagging
and publishing. This file is a record for this release, not a living
template — future releases should copy its structure into a new
checklist rather than editing this one after the fact.

## Design

- [x] **Architecture approved** — three design-review passes
  (proposal critique, v2 breakdown, philosophy-vs-evidence-engine
  synthesis) completed; final architecture accepted and frozen.
- [x] **Philosophy documented** — `PHILOSOPHY.md` states the
  invariant principles the architecture and implementation are held
  to.

## Documentation

- [x] **Documentation complete** — `PHILOSOPHY.md`,
  `ARCHITECTURE.md`, `WORKFLOW.md`, `EVALUATION.md`, and
  `MIGRATION_V1_TO_V2.md` all present and cross-consistent.
- [x] **Migration guide complete** — `MIGRATION_V1_TO_V2.md`
  covers what changed, why, what was removed, what was preserved, and
  why v2 should produce better founder outcomes.
- [x] **CHANGELOG complete** — `CHANGELOG.md` follows Keep a
  Changelog format with Added/Changed/Removed/Fixed sections for
  2.0.0.
- [x] **Release notes complete** — `RELEASE_NOTES_v2.0.0.md`
  covers overview, rationale, highlights, breaking changes, migration
  summary, user expectations, and roadmap pointer.
- [x] **README updated** — `crucible/README.md` reflects the v2
  workflow, links to all design docs, and states the current version.
- [x] **Root README updated** — top-level `README.md`'s crucible
  entry reflects v2.0.0 and no longer contains stale claims (e.g. the
  "single-file" description that predated `docs/`).
- [x] **Cross-document consistency verified** — terminology (stage
  names, tags, tiers, verdict vocabulary), the ledger schema, and
  version references checked pairwise across all documents in a
  dedicated review pass.

## Implementation

- [x] **Implementation complete** — `SKILL.md` implements all six
  stages (Input, Interrogation, Bench, Evidence, Experiment, Ledger)
  as specified in `ARCHITECTURE.md` and `WORKFLOW.md`.
- [x] **Every documented behavior exists in the implementation** —
  verified stage by stage against `ARCHITECTURE.md`'s data flow and
  `WORKFLOW.md`'s enter/leave contracts, including the session log,
  the Bench re-entry rule on returning sessions, and the Warranted
  Bet answer.
- [x] **Every implemented behavior is documented** — no undocumented
  branches or fields in `SKILL.md`'s ledger template or session
  output shape.

## Examples & installation

- [x] **Installation verified** — `INSTALL.md` file tree matches the
  actual folder contents; per-runtime instructions (Claude Code,
  Claude.ai/Desktop, other Agent Skills runtimes, generic LLM
  fallback) all reference the current v2 output shape.
- [x] **Examples verified** — `example/worked-example.md` runs the
  full six-stage loop plus a follow-up session, and its numbers
  (arithmetic, evidence-tier counts, session-log line) check out
  against each other.

## Versioning

- [x] **Version verified** — every version-identifying reference
  (root README skill entry, `crucible/README.md` Status line,
  `CHANGELOG.md`, `RELEASE_NOTES_v2.0.0.md`) consistently reads
  **v2.0.0**. Descriptive prose uses of "v2" as shorthand (e.g. "a
  full v2 session") are left as-is, matching the convention already
  used by `engineering-historian`.

## Release readiness

- [x] **Ready for GitHub Release** — `RELEASE_NOTES_v2.0.0.md`
  is written for the release page; `CHANGELOG.md` is written for the
  repo.
- [x] **Ready for production testing** — `ROADMAP.md` Phase 1
  defines what real-world testing looks like and what evidence to
  collect from it.

## Sign-off

All items checked. No open blockers. See the final release audit for
the sign-off statement.
