# Known limitations

Current, genuinely unresolved issues as of this release. Everything here is checkable against the runtime; if a claim below no longer matches the files, the file is stale and should be corrected.

## Undercorrection is not yet measured

The evaluation defines two independent kill criteria: overcorrection (good writing wrongly edited) and undercorrection (slop wrongly left in). Overcorrection has read 0/4 across many corpus runs. **Undercorrection has never been scored**, because it requires an operator to run the hidden oracle in `evaluation/scoring-sheet.md` against a reviewer's actual removal decisions — something the blind reviewer bundle cannot produce by design. Until that run happens, only half the quality bar has a number behind it. The one recorded partial observation (round 5) was 1/4: a causal-sounding closing line was preserved that the oracle marks for removal, suggesting the fake-profound-kicker rule may under-fire on closers phrased as lessons.

## Runtime size exceeds the original draft budget

An early draft set a 4,708-word ceiling. The current runtime is ~6,300 words. Across development, every behavioral fix cost more words than the available cuts recovered, and the applied cut list reclaimed ~90 words against a ~1,600-word gap. The evidence is that the original number was arbitrary: no failure in development traced to length, while several traced to duplicated rules across files. The budget has been reset to an evidence-backed ~6,300 words (see README). This is logged as a limitation only in the sense that the skill is larger than a minimal de-slop prompt; it is not a defect.

## Adversarial-review findings are in the deep tail

Thirteen rounds of adversarial review drove findings from ~9 per round to ~2, with no Critical since round 6. The remaining findings tend to be constructed edge cases (e.g. "cut this to 10 words") rather than common inputs, and the ordinary case — a person's honest draft — has been handled correctly in every run. The most useful next findings will come from real usage, which orders problems by frequency, rather than from further adversarial review, which orders them by ingenuity.
