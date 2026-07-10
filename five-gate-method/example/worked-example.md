# Worked example — a debugging session through the five gates

Fictional bug, real method. The project is a small ETL job: a nightly
script imports `orders.csv` from a vendor into Postgres. The report:
"Since last week, about 2% of imported orders have the wrong total.
Fix it."

What follows is the session annotated by gate. Notice two things: the
rival hypothesis at Gate 3, and the Gate 4 failure that rolls back to
Gate 2 — not to Gate 3 — because verification exposed a bad premise,
not bad reasoning.

---

## Gate 1 — Scope before work

**Done:** every row in `orders.csv` imports with `total` matching the
source file to the cent; the check is a script that diffs 500 randomly
sampled rows between CSV and database, run on last night's file,
returning zero mismatches.

**Standing rules checked:** repo `AGENTS.md` requires migrations over
manual schema edits, and forbids modifying vendor files.

**Load-bearing unknowns:**
1. What changed "last week" — the vendor file format, or our code?
2. Are the wrong totals random rows, or a pattern (locale, size,
   currency)?

**Passes:** done defined with a written check, unknowns named. ✅

## Gate 2 — Evidence before reasoning

The temptation is to read `import.py` first — that's designing from
memory of what the data "probably" looks like. Cheapest probe of the
biggest unknown is the data itself:

- Pulled 20 mismatched rows from the DB, joined against the CSV.
  **Observed pattern:** every wrong row has a `total` over 999.99, and
  the stored value looks like the source value divided by ~1000.
- Diffed last week's CSV header against this week's: identical. But
  opened the raw bytes of both — this week's file quotes large numbers
  with thousands separators (`"1,234.56"`), last week's didn't.

Unknown #2 resolved with primary evidence: not random — every affected
row crosses 1,000. Unknown #1 half-resolved: the vendor file changed.

**Passes:** load-bearing unknowns have direct evidence; one mismatched
row traced end-to-end from CSV byte to DB value. ✅

## Gate 3 — Reason adversarially

**Hypothesis A:** the CSV parser splits on the comma inside
`"1,234.56"`, truncating the total.

**Rival (hypothesis B):** the parser handles quoting fine, and the
bug is downstream — a `Decimal` conversion stripping the comma's
right-hand digits.

Eliminate one, don't argue: fed the single line
`ord-1,"1,234.56"` to the parser in isolation. The parser returned
`1,234.56` intact — quoting handled correctly. **A is dead.** Then fed
`"1,234.56"` to the conversion step: `Decimal("1,234.56")` raises, and
the code's `except` clause falls back to `float(value.split(",")[0])`
— which returns `1.0` for this input. **B survives contact with
evidence.**

Attack the survivor: what input makes B wrong as the *whole*
explanation? A wrong total *under* 1,000 would. Queried for one — zero
rows. B stands.

**Passes:** rival generated and eliminated by test, survivor attacked. ✅

*(Note the smell this gate exists for: without the rival, the obvious
move is patching the parser — attempt one fails, attempt two fails,
and "two failed attempts at the same fix" fires. The rival hypothesis
is cheaper than two failed patches.)*

## Fix

Replaced the silent `except`-fallback with locale-aware parsing and a
hard failure on unparseable totals (a wrong import is worse than a
loud one). Wrote a migration to recompute affected rows from archived
source files, per the standing rule from Gate 1.

## Gate 4 — Verify before declaring done

Ran the Gate 1 check: 500-row sample diff on last night's file.

**Result: 3 mismatches.** Gate 4 fails.

**Rollback — to which gate?** The three rows aren't comma-related:
their totals differ by exactly the shipping amount. That's not a flaw
in the Gate 3 reasoning (the comma diagnosis was verified); it's a
fact Gate 2 never surfaced — the "2% wrong totals" report bundled
*two* defects. Return to Gate 2, not Gate 3: gather evidence on the
new pattern.

Second pass: the 3 rows are the only ones using a new
`shipping_included` flag the vendor added the same week. Separate
one-line fix, separately verified in isolation.

Re-ran the Gate 1 check: **0 mismatches in 500.** Sampled the tails —
first row, last row, the largest order in the file (`"12,345.10"`),
and one `shipping_included` row: all exact. Treated the clean result
as suspect for one beat: is the sampler actually comparing totals?
Deliberately corrupted one DB row, re-ran — the check caught it.
The verification verifies.

**Passes:** outcome evidence matches the Gate 1 check; tails sampled;
the clean result explained. ✅

## Gate 5 — Report calibrated

> **Fixed — two defects, not one.** (1) The vendor started quoting
> totals ≥1,000 with thousands separators on 2026-06-30; our fallback
> conversion silently truncated them (`import.py:47`). (2) The same
> vendor release added a `shipping_included` flag we ignored — 3 rows
> in last night's file.
>
> **Verified:** 500-row source-vs-DB sample diff, 0 mismatches,
> including tails and both defect classes; the checker was itself
> tested against a deliberately corrupted row. Historical rows
> recomputed by migration `0042`.
>
> **Assumed, not verified:** the vendor's format change is permanent
> — I have two files of evidence and no changelog from them.
> Unparseable totals now fail the import loudly rather than guessing;
> flagging in case a silent skip was ever the intended behavior.
>
> Confidence, as reasons: parser hypothesis eliminated by isolated
> test, conversion defect reproduced then fixed, end-to-end sample
> clean, verification itself verified.

**Passes:** verified and assumed separated; every specific observed
this session. ✅

---

## What the gates changed

Without the method, the likely path is: read `import.py`, "fix" the
parser (attempt 1), add a regex (attempt 2), declare done when the
script exits 0 — shipping both the wrong fix and the undiscovered
second defect. The gates didn't add intelligence; they forced the
data open before the code, made the first attractive diagnosis compete
for its life, and refused "it ran" as evidence. That's the whole bet.
