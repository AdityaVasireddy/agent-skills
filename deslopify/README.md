# Deslopify

Edit, draft, or audit nonfiction prose while preserving facts, meaning, and the writer's voice. Detect mode identifies named prose patterns; it cannot determine whether AI wrote a text.

## Use

- Edit: `Make this less generic without flattening my voice: <draft>`
- Detect: `Audit this for slop. Do not rewrite it: <draft>`
- Draft: `Write a release note from these facts, in the voice of this sample: <facts and sample>`

Deslopify preserves technical terminology and source quotations. Explicit requests take precedence over style defaults. Missing facts produce `BLOCKED`; incompatible constraints produce `CLOSEST COMPLIANT` with an explanation. Samples supply style, not permission to invent facts or personal experiences. Fiction, poetry, screenwriting, code, translation, and internal summaries are outside its activation scope.

## Install

Use the generated **install archive** as the canonical installation artifact. Verify it with the matching source version's builder, then extract its contents into a directory named `deslopify` under your agent's skills directory. Do not extract the development or reviewer archive there.

The install archive contains `SKILL.md`, `eval.md`, three reference files, `agents/openai.yaml`, the MIT license, version, and integrity manifest. It contains no development README, test harness, build scripts, or scoring answers. No Python dependency is needed to use the installed skill. UI metadata supplies the display name, short description, and invocation prompt; automatic discovery remains enabled.

The package root is the skill's contents, so extraction must create the enclosing `deslopify` directory. Preserve the license when redistributing. See [known limitations](KNOWN-LIMITATIONS.md) before choosing it for a consequential workflow.

## Develop and build

Requirements: Python 3.11 or later and the pinned development dependency. Bash is needed only for the compatibility wrapper and its release test. From the `deslopify` directory:

```sh
python -m pip install -r requirements-dev.txt
python scripts/validate.py .
python -m unittest discover -s tests -v
python scripts/bundle.py --kind reviewer --output dist/reviewer.zip
python scripts/bundle.py --kind install --output dist/deslopify-install.zip
python scripts/bundle.py --kind source --output dist/deslopify-source.zip
python scripts/bundle.py --verify dist/reviewer.zip
python scripts/bundle.py --verify dist/deslopify-install.zip
python scripts/bundle.py --verify dist/deslopify-source.zip
```

The compatibility command `bash scripts/bundle.sh dist/custom-name` creates `dist/custom-name.zip`. With no argument it creates `reviewer-bundle.zip`. Set `PYTHON` to a Python executable if `python3` is unavailable, including with Git Bash on Windows.

Builds refuse existing outputs. Choose a new destination when rebuilding. All profiles have exact, declared membership, fixed ZIP metadata, LF-normalized UTF-8 text, and SHA-256/size entries in `BUILD_MANIFEST.json`. Identical inputs produce identical archives across supported operating systems. Verification checks content integrity and package membership; a self-contained manifest does not authenticate the publisher. Obtain archives and checksums from a trusted release or build them from a reviewed commit.

| Profile | Contents | Intended reader |
|---|---|---|
| install | Runtime, UI metadata, license, version, manifest | Agent installation |
| reviewer | Runtime, evaluation instructions, canonical raw cases, manifest | Independent reviewer |
| source | Declared skill development files, tests and operator material | Maintainer |

Source is the skill development package, not a snapshot of the entire monorepo. Generated ZIPs, `dist`, caches, logs, and arbitrary local files never enter it. CI configuration lives at the repository root. Update the source inventory in `scripts/bundle.py` when adding development files.

## Validation and release evidence

`validate.py` parses actual YAML with duplicate-key rejection, validates required fields and files, and checks named contract references and precedence aliases. Tests execute the Bash wrapper, all three package profiles, package verification failures, repeated builds, corpus encoding, and package boundaries. GitHub Actions runs the suite on Windows and Linux with Python 3.11 and 3.14.

`evaluation/cases.json` is the sole fixed corpus. The reviewer prompt references it without repeating drafts or expected answers. Give only the reviewer ZIP to a fresh evaluator, freeze its full report, then apply `evaluation/scoring-sheet.md` separately. Both overcorrection and undercorrection must be at most 20%, and confirmed Critical/High behavioral findings must be resolved. Model-predicted writer reversions remain a proxy, not measured author acceptance.

Version and readiness are recorded in [VERSION](VERSION), [CHANGELOG.md](CHANGELOG.md), and [KNOWN-LIMITATIONS.md](KNOWN-LIMITATIONS.md). Structural tests do not prove writing quality; the skill's self-check does not replace independent evaluation or review of consequential copy.

## License

MIT. See [LICENSE](LICENSE).
