# Install — engineering-historian v3 (Claude Code)

v3 captures automatically: a hook fires when a session ends, drafts a day file, and you review the drafts once a week at `/distill`. Nothing to remember day to day.

## What's in this folder

```
engineering-historian/
  SKILL.md                       the skill — pipeline + automation, load this
  references/
    promotion-rules.md           graduation criteria for CASE → JUDGMENT → PRINCIPLE → STANDARD
    templates.md                 exact formats for every entry type
    worked-examples.md           fully populated end-to-end examples
  scripts/
    historian-sweep.sh           the Claude Code hook — runs the sweep at session end
  assets/
    SWEEP.md                     the sweep's prompt (model-agnostic, read by the hook)
    capture-rules.seed.md        starting knowledge/capture-rules.md for a new vault
```

`scripts/` and `assets/` are not documentation — `historian-sweep.sh` is executed, and `SWEEP.md` is fed to a model as a prompt. They must exist as standalone files no matter where you install; the skill can't "contain" them because Claude Code invokes hooks by path, and the sweep runs in a separate headless call where SKILL.md isn't loaded.

## Requirements

`jq`, `git`, and the `claude` CLI on PATH. Install `jq` with `brew install jq` (Mac) or `apt-get install jq` (Linux).

## Step 1 — Place the files

```bash
# the skill itself (global; drop the -g pathing if you want it project-only instead)
mkdir -p ~/.claude/skills
cp -r engineering-historian ~/.claude/skills/engineering-historian

# the two files the hook needs at runtime
mkdir -p ~/.claude/historian
cp ~/.claude/skills/engineering-historian/assets/SWEEP.md ~/.claude/historian/SWEEP.md
cp ~/.claude/skills/engineering-historian/scripts/historian-sweep.sh ~/.claude/historian/historian-sweep.sh
chmod +x ~/.claude/historian/historian-sweep.sh
```

(The skill folder is the source of truth; `~/.claude/historian/` is just where the hook and prompt live so `settings.json` can point at a stable path. If you'd rather point the hook straight at the skill folder, set `HISTORIAN_SKILL_DIR=~/.claude/skills/engineering-historian/assets` and skip the SWEEP.md copy — either layout works.)

## Step 2 — Register the hook

Merge into `~/.claude/settings.json` (global) or `.claude/settings.json` (project-only):

```json
{
  "hooks": {
    "SessionEnd": [
      { "hooks": [ { "type": "command", "command": "~/.claude/historian/historian-sweep.sh", "async": true, "timeout": 400 } ] }
    ],
    "PreCompact": [
      { "hooks": [ { "type": "command", "command": "~/.claude/historian/historian-sweep.sh", "async": true, "timeout": 400 } ] }
    ]
  }
}
```

`"async": true` is Claude Code's own documented mechanism for "run this without waiting for it to finish" — it's why the script doesn't do any manual backgrounding itself. `"timeout": 400` gives the sweep's model call (internally capped at 300s) room to finish before Claude Code would give up on it.

**Windows:** this exact JSON works unmodified. Claude Code automatically runs shell-form hook commands through Git Bash on Windows when Git for Windows is installed (which you need anyway, for `git`) — no explicit path to `bash.exe` required. If Claude Code ever fails to auto-detect it, point it explicitly via `~/.claude/settings.json`: `{ "env": { "CLAUDE_CODE_GIT_BASH_PATH": "C:\\Program Files\\Git\\bin\\bash.exe" } }`.

Done. `SessionEnd` fires when a session closes; `PreCompact` is a safety net that saves the transcript's content before a long conversation gets compressed. `knowledge/capture-rules.md` (seeded from `assets/capture-rules.seed.md`) and the gitignored `knowledge/.sweep/` are created automatically per project on the first sweep — no per-project setup step.

## Verify

End a real (10+ turn) session in a git repo that has this skill active, then:

```bash
cat knowledge/.sweep/sweep.log            # expect: OK wrote knowledge/<project>/<date>.md
grep "status: auto" knowledge/*/"$(date +%F)".md
```

Failures never interrupt you — they queue in `knowledge/.sweep/pending.log` and retry at the next `/distill`.

## Optional config (env vars)

- `HISTORIAN_MODEL` — model for the sweep call (a cheap model is correct; sweeps fire often, the work is reconstruction not frontier reasoning)
- `HISTORIAN_MIN_TURNS` — skip sessions shorter than this many user turns (default 10)
- `HISTORIAN_SKILL_DIR` — where `SWEEP.md` lives (default `~/.claude/historian`)

## Other tools

This install is Tier A (Claude Code's native `SessionEnd`/`PreCompact` hooks). Kiro has similar agent hooks (also Tier A). Tools that save session logs but have no hook system — Codex CLI, Gemini CLI — are Tier B: wrap the launch command so the sweep runs on exit. Anything else, including ChatGPT, is Tier C: paste the transcript and run the sweep manually. `SKILL.md` and `assets/SWEEP.md` are identical across every tier — only the trigger mechanism changes. Add other tiers only after the Claude Code version has run through the day-60 evaluation in `SKILL.md`.
