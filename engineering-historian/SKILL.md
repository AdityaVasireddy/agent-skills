---
name: engineering-historian
description: Capture engineering knowledge as a promotion pipeline (CASE → JUDGMENT → PRINCIPLE → STANDARD) and retrieve answers from it. Capture is automatic — a post-session sweep drafts cases with status:auto; the user reviews them at /distill. Use whenever the user types "/history", "/case", or "/distill", says "log this session", "wrap up and record", "capture this decision", or ends a working session where decisions, deployments, debugging, or configuration happened. ALSO use for retrieval whenever the user asks about their own past work or rules — "how did I deploy X", "why did I stop using Y", "what did we decide about Z", "do we have a rule/standard for W" — by searching the knowledge/ vault (standards first, then principles, then cases) before answering from general knowledge. Every retrieval must be logged to the retrieval log.
---

# Engineering Historian (v3.1)

Storage is stupid; retrieval is smart — meaning the storage layer stays deliberately dumb (plain markdown, minimal taxonomy) so that intelligence is applied at read and distillation time, not speculated into folder structures. And **wisdom is earned through cited evidence, not asserted**. This system captures specific decisions as CASES, distills their reasoning into JUDGMENTS, promotes recurring patterns into PRINCIPLES, and hardens checkable principles into STANDARDS. Nothing enters as a rule without a cited case behind it. A principle without provenance is invalid in this system: delete it on sight.

**What v3 changes from v2.5:** nothing in the pipeline, formats, promotion rules, retrieval, or vault layout. v3 only changes *when capture fires*. In v2.5 a human had to remember to type `/history` or `/case`; that is where the system died in practice. v3 replaces the human trigger with an automatic post-session **sweep** that drafts cases (`status: auto`) from the transcript, reviewed in one batch at `/distill`. Manual `/case` and `/history` still work as overrides. Everything below the "Automation layer" heading is the only new material; everything above it is v2.5 verbatim.

**What v3.1 changes from v3:** nothing in what is captured or how — only the sweep's *pre-filter*. v3.0 skipped sessions with few user turns, which silently dropped prompt-light agentic sessions (three prompts, hours of autonomous work). v3.1 replaces that significance guess with a **triviality gate**: skip only when every available deterministic signal — transcript size, user turns, git activity — proves the session trivial; otherwise sweep. When uncertain, capture: a false run costs one cheap `NOTHING` call, a false skip loses history. Rationale and rejected alternatives: `docs/adr/ADR-001-capture-gate-triviality.md`; release notes: `CHANGELOG.md`.

Three modes: **capture** (Tier 1, now sweep-driven), **distillation** (Tier 2, periodic), **retrieval**.

## The pipeline

| Tier | What it is | Written when | Written by |
|---|---|---|---|
| CASE | A specific problem, the decision made, one-line why | Session end (sweep) or solve time (`/case`) | Sweep / user |
| JUDGMENT | Reasoning distilled from a case: rejected alternatives, tradeoffs, tipping factor | Distillation pass | Any competent model, from the record |
| PRINCIPLE | A general rule; requires 2+ cases across 2+ dates, or 1 case with explicit early-promotion justification | Distillation pass, per promotion rules | Any competent model, mechanically |
| STANDARD | A principle rewritten as pass/fail checks — no adjectives — enforceable by a less capable model | Distillation pass, only if binarizable | Any competent model, mechanically |

The pipeline is a filter, not a conveyor: a case is a legitimate terminal record, and most decisions (tool picks, architecture choices) should live and die as distilled cases — retrievable, never promoted. A case replaced by a later decision gets status `superseded (by <case-id>)`.

Full graduation criteria: `references/promotion-rules.md`. Read it before running any distillation pass. Entry formats: `references/templates.md`. Fully populated end-to-end examples: `references/worked-examples.md`.

## Vault location and layout

`knowledge/` at the repository root (or, if no repo, at the user's designated vault path — ask once, then remember via a note in `knowledge/README.md`).

```
knowledge/
  <project>/
    YYYY-MM-DD.md      # session records; CASE blocks live inside these
  principles.md         # vault-wide: all principles + judgments they cite + declined promotions
  standards.md          # vault-wide: all standards
  retrieval-log.md      # append-only value log
  capture-rules.md      # sweep's binding negative rules + health counters (see Automation layer)
  README.md             # vault path/config notes only
  .sweep/               # sweep machinery (logs, dedup, retry queue, failed/ raw-output archive) — gitignored, never cited
```

Do NOT create any other folders or files (no events/, playbooks/, judgments/, topic folders). Principles and standards are vault-wide single files because promotion is cross-project by design. If a second session happens the same day for the same project, append under a `## Session 2 (HH:MM)` header.

## Tier 1 — capture

Capture normally happens automatically at session end via the sweep (see Automation layer), producing cases with `status: auto` for later review. Two manual paths remain, unchanged:

**`/case` (solve-time override).** When a decision is made mid-session (or the user types `/case`), append a CASE block to today's day file for that project (create a minimal file with frontmatter if none exists yet). The block MUST take under 60 seconds to write:

```markdown
### CASE: <slug>
status: raw
problem: <one line>
decision: <one line>
why: <one line>
tags: [tag, tag]
promote-early: <justification — ONLY if warranted; omit this line otherwise>
```

The case ID is `<project>/<YYYY-MM-DD>#<slug>` — this is how provenance citations work, so slugs must be stable: never rename one after a principle cites it. If the decision has a known horizon at capture time ("pause X until the experiment ends"), add an optional `until:` line naming the condition — without it, future retrieval may treat a temporary decision as standing. `promote-early` may only be written at capture time by the capturer; the distiller is forbidden from inventing it later. Do not write more than these few lines. Elaboration is the distiller's job, from the surrounding session record.

Manual `/case` writes `status: raw` (human-confirmed at capture); the sweep writes `status: auto` (awaiting confirmation). That is the only difference between the two capture paths.

**`/history` (manual session capture override).** At the end of a session, review the full conversation/session context and write (or complete) `knowledge/<project>/YYYY-MM-DD.md`. Reconstruct from what actually happened — do not invent. If a section has nothing, write `None.` The "Cases" section holds CASE blocks in the format above. Any decision worth recording is a case. Full template in `references/templates.md`. Use this when the sweep didn't fire (a tool with no hook) or the user explicitly asks to capture now.

Section order: What I worked on / Cases / Commands that worked / Problems solved / Mistakes / Prompts worth keeping / Questions I still have / TODOs for next session.

After writing, if the vault is inside a git repository: `git add knowledge/ && git commit -m "history: <project> YYYY-MM-DD"`. Do not push unless the user's normal workflow pushes automatically. Confirm in ONE line (file path + commit hash). No recap — the file is the summary.

### Capture rules

- Frontmatter fields are mandatory and exactly as specified.
- Prose over structure inside sections; no tables, no nested bullets beyond one level. (CASE blocks are the one structured exception.)
- Never editorialize about the system itself. Record and stop.
- One file per project per day; multi-project sessions get one file each.
- Commands verbatim and verified, or marked UNVERIFIED.

## Tier 2 — distillation pass (`/distill`)

Run when the user types `/distill`, asks to "promote", "distill", or "review the vault", or roughly weekly if cases are accumulating. This pass is deliberately mechanical: read `references/promotion-rules.md` and apply it as written. It must not require frontier judgment — where the rules don't clearly authorize a promotion, the answer is "no promotion", never "use discretion".

**Two automation steps run FIRST, before the mechanical procedure** — see "Distill: automation steps" under the Automation layer. They are step −1 (coverage/health check) and step 0 (auto-case review). Only after those does the pass below run.

Procedure:

1. **Collect** all CASE blocks with `status: raw` across all day files. (Auto cases are NOT collected here — they must be confirmed to `raw` in step 0 first.)
2. **Distill judgments**: for each raw case, append a `#### JUDGMENT (distilled YYYY-MM-DD)` block beneath it (template in `references/templates.md`), using ONLY the case and its surrounding session record — never invented content. Set case `status: distilled`. If the record names no rejected alternative, mark the judgment `thin:` — thin judgments cannot count toward promotion until the user thickens them.
3. **Scan for promotions**: group distilled cases by shared tipping factor (tags are hints, the tipping factor sentence is the test). Apply promotion rule R3. Draft qualifying principles into `principles.md`; set contributing cases to `status: cited`.
4. **Attempt standards**: for each new or existing unstandardized principle, apply rule R4. If it binarizes cleanly, write it to `standards.md`; if not, record "not standardizable" with the reason, in the principle entry.
5. **Invalidation review**: check every `status: active` principle against (a) its own stated invalidation conditions and (b) direct contradiction by any newly distilled case. On a hit, set `status: challenged` with the citing case ID — the human resolves to `active` (with note) or `retired`. Never delete retired principles; retirement rationale is itself vault content. Also flag any case whose `until:` horizon has passed — the user confirms `superseded`, extends the horizon, or drops the line.
6. **Log declined promotions** in the `## Declined promotions` section of `principles.md` with a one-line reason, so future passes don't re-litigate them.
7. Commit: `git commit -m "distill: YYYY-MM-DD"`. Report to the user in a few lines: coverage/health line (from step −1), N auto cases reviewed (from step 0), N judgments written, promotions made, promotions declined, principles challenged.

Declining is a success mode. Forced generalizations are worse than no principle — the schema exists to keep weak wisdom out.

## Retrieval mode

When the user asks about their own past work or rules, search `knowledge/` FIRST — before answering from general knowledge — in this order:

1. `standards.md` — if a standard answers the question, apply/quote it; it's the hardest-tested knowledge in the vault.
2. `principles.md` — active principles next; mention status if `challenged`.
3. Day files (grep frontmatter, tags, case slugs, command fragments) — cases and session prose last.

Cite the source and date ("From P-003, provenance seller-engine/2026-06-24: …" or "From stockagent/2026-03-14: …"). When citing a principle, state its evidence weight and scope in the same breath — "P-003: 2 cases, recurrence, domain-scoped" — so its maturity is visible. Confidence is read off provenance (case count, promotion path), never stored or asserted as a field. **An `auto` case is the weakest provenance in the vault** — when retrieval surfaces one, say so: "From seller-engine/2026-07-09#<slug> (auto, unreviewed): …". When citing a case that carries an `until:` horizon, state the horizon and whether it has passed. Retired/challenged principles may be cited only with their status stated; respect `scope` and `does-not-apply` boundaries when applying a principle outside its original project. If the vault has no answer, say so explicitly, then answer from general knowledge if possible.

### Retrieval log (mandatory)

Every time the vault materially answers a question, append one line to `knowledge/retrieval-log.md`:

```
| YYYY-MM-DD | <question, abbreviated> | <source: file or P-/S- ID> | <est. minutes saved> |
```

Ask the user for the minutes-saved estimate in the same breath as delivering the answer — or estimate it yourself marked `(est.)`. This log remains the falsification instrument for the system: cumulative minutes saved vs. cumulative capture + distillation time. Do not skip it and do not log retrievals that didn't actually help.

---

# Automation layer (v3 — the only new material)

The automation layer changes WHEN capture happens, never WHAT is captured or how it is promoted. It has three parts: a **trigger** (a tool hook that fires the sweep), a **sweep** (a separate prompt file that drafts cases from the transcript), and **review** (two new steps at the front of `/distill`). Two support files ship alongside this SKILL rather than inside it, for mechanical reasons: `scripts/historian-sweep.sh` (a shell script the tool executes from disk — hooks are registered by path, not by SKILL content) and `assets/SWEEP.md` (a prompt read in a separate headless model call, in a context where this SKILL is not loaded). `assets/capture-rules.seed.md` is the starting `knowledge/capture-rules.md` for a new vault. Everything else is here.

## The `auto` status

A CASE with `status: auto` was drafted by the sweep, not confirmed by a human. Semantics:

- **Invisible to promotion.** Distillation collects `status: raw` only; `auto ≠ raw`. An auto case cannot receive a judgment, count toward a principle, or be cited as provenance until confirmed at step 0.
- **Citeable in retrieval, status stated** (see Retrieval mode) — it is the weakest provenance in the vault.
- **Confirmed to `raw`** at step 0 → it then flows through the pipeline exactly like a manual case.

## How the sweep works (conceptually)

At session end (or before a long conversation is compacted), the tool's hook runs `historian-sweep.sh`. The script first runs the **capture gate** (v3.1): a deterministic, no-model-call triviality check — any single WORK signal (transcript size, user turns, or git commits in a window) runs the sweep, and skipping requires every available signal to read trivial, so environments exposing fewer signals sweep more, never less. The script then assembles a prompt — `SWEEP.md` + the current `capture-rules.md` + today's existing day file + a git delta + the session transcript — and calls whatever model binary is configured (a cheap, distiller-grade model is correct here; sweeps fire often and the work is reconstruction, not frontier reasoning). The model applies the capture test and outputs a complete v3 day file with cases marked `status: auto`, or the single word `NOTHING` if the session held nothing worth recording. The script writes the file atomically and commits it. Failures never interrupt the user: they queue in `knowledge/.sweep/pending.log` for retry at the next `/distill`.

The capture test the sweep applies (four gates, plus an asymmetry rule that does the calibration a model can't) lives in `SWEEP.md` so it runs in the sweep's own context. It is summarized here for reference: a segment is captured only if it (G1) resolved into a state change still in force at session end, (G2) had a real alternative present in the record, (G3) is not reconstructible from the surviving code/config alone, and (G4) would cost material time to re-derive. Unsure at G1/G2 → skip (protects provenance); unsure at G3/G4 → capture (only risks noise, which review removes cheaply).

## Distill: automation steps (run BEFORE the Tier 2 procedure)

**Step −1 — Coverage & pending check (dead-hook guard).** Compare git activity against day-file existence: list distinct author-dates of commits since the last distill (`git log --since=<last distill date> --format=%ad --date=short | sort -u`) and check each against `knowledge/<project>/` day files. `<last distill date>` is the author-date of the most recent `distill:` commit (`git log --grep='^distill:' -1 --format=%ad --date=short`); if none exists yet, use the date of the earliest day file in the vault. Open the distill report with one line: `Coverage: N/N active days recorded`, or `WARNING: commits on <dates> with no session record — check the sweep hook`. Then process `knowledge/.sweep/pending.log`: for each entry whose transcript still exists, run `historian-sweep.sh --replay <transcript> <cwd> <session-id>` (the three tab-separated fields of that pending.log line) — this re-runs the sweep through the same validator/writer/committer as a live hook, bypassing the triviality gate and dedup (a queued entry already earned a sweep), and removes the line from `pending.log` itself on success; for each whose transcript is gone, report it as a permanent gap (one line) and drop the entry by hand.

**Step 0 — Auto-case review.** Collect all `status: auto` cases across day files and present them as ONE batch (slug, problem, decision, why — nothing more). Three verbs per case:

- **Confirm** → set `status: raw`. Enters this same distillation pass immediately — one sitting.
- **Decline** → set `status: declined — <one-line reason>`. Append the reason to `knowledge/capture-rules.md` (consolidate with an existing rule rather than adding a near-duplicate). Declined cases remain in the day file as a record; never collected again.
- **Edit** → amend the wording (usually the `why:` line), then set `status: raw`.

After the batch, update the two counters in the `## Sweep health` section of `capture-rules.md` (cumulative confirmed, cumulative declined). Then run the Tier 2 procedure from step 1.

## Pre-registered sweep health band (2026-07-07, before first live sweep)

Read from the Sweep health counters at each distill, evaluated once `capture-rules.md` holds 15+ rules:

- Confirm rate **below ~30% sustained** → the sweep generates noise faster than the rules teach it. Disable the hook; fall back to manual `/history` + `/case`.
- Confirm rate **above ~90% sustained** → the sweep is too conservative, dropping real cases at G3/G4. Loosen the tie-break toward capture.
- **Friction ceiling:** if step-0 review routinely exceeds ~5 minutes/week, the layer failed its own hypothesis regardless of confirm rate.
- **Displacement signature (success):** manual `/case` usage falling toward zero while confirm rate stays in-band means the sweep replaced memory rather than adding volume.

## Migration from v1/v2.5

Existing day files remain valid untouched. On the first `/distill`, mine old "Decisions made" sections: where an entry is a promotion candidate, append a retroactive CASE block (dated to the original file's date, `status: raw`) beneath that section rather than rewriting prose. The retrieval log continues unchanged. No files are renamed or moved. A vault created under v2.5 needs only two additions to become a v3 vault: a `capture-rules.md` (seed provided) and a gitignored `.sweep/` — both created automatically on first sweep.

## Explicitly out of scope (do not build or suggest)

Vector databases, embeddings, knowledge graphs, dashboards, terminal/build-log ingestion, folder taxonomies beyond the layout above, or any Python tooling. The sweep is a single prompt calling one model; it is not a framework. Additional tool adapters (beyond the Claude Code hook) and any packaging split are deferred until the retrieval log and sweep health band earn them — tooling is earned, not speculated.

## Day-60 evaluation — criteria pre-registered 2026-07-07, before first live use

Evaluate against these thresholds, not against impressions:
- **Trigger reliability (new in v3):** day-file coverage of active git days should approach 100%. This is the core thing the automation exists to fix.
- **Sweep confirm rate (new in v3):** inside the 30–90% band once capture-rules matures (see health band).
- **Capture friction:** step-0 review ≤ 5 minutes/week. If manual capture is still relied upon, ask why the sweep didn't catch it.
- **Promotion rate:** of distilled cases, outside roughly 5–20% promoted → revisit the promotion rules (above: too permissive; near zero despite meaningful work: too strict). Heuristic band, pre-registered as such.
- **Retrieval ROI:** cumulative minutes saved (retrieval log) vs. cumulative capture + distillation time. Negative → the system is a diary, not a tool. Note: automation makes the vault grow regardless of whether retrieval pays, so this criterion is more load-bearing in v3 than v2.5 — watch it.
- **Challenge rate:** zero challenged principles by day 60 means the invalidation review isn't being exercised — a healthy vault tests its own rules.

The design is frozen until this evaluation. Improvements after it must cite the log.
