# Install — engineering-historian v3.1 (Claude Code)

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
  tests/
    run-tests.sh                 end-to-end regression suite (stubbed model binary)
  docs/adr/                      architecture decision records
  CHANGELOG.md                   release notes per version
```

`scripts/` and `assets/` are not documentation — `historian-sweep.sh` is executed, and `SWEEP.md` is fed to a model as a prompt. They must exist as standalone files no matter where you install; the skill can't "contain" them because Claude Code invokes hooks by path, and the sweep runs in a separate headless call where SKILL.md isn't loaded.

## Requirements

`jq`, `git`, and the `claude` CLI. `git` and `claude` you already have if you're running Claude Code. `jq` is the one that trips people up, and *where* it needs to be depends on your platform — because on Windows the hook runs inside Git Bash, not PowerShell, and the two don't share a PATH. Pick your platform below.

### Linux

```bash
sudo apt-get install jq      # Debian/Ubuntu
sudo dnf install jq          # Fedora/RHEL
```

Package managers put `jq` on PATH; nothing else to do.

### macOS

```bash
brew install jq
```

Homebrew puts `jq` on PATH; nothing else to do.

### Windows + WSL

If you run Claude Code *inside* a WSL distro, you're effectively on Linux — install `jq` **inside WSL** (`sudo apt-get install jq`), not on the Windows side. The hook runs in the WSL environment and picks it up from PATH. A `jq` installed on Windows proper is invisible to the WSL shell, and vice-versa.

### Windows (native, no WSL)

This is the fiddly one, and worth reading in full — a `jq` that works fine in PowerShell can still be invisible to the hook.

**The trap:** Claude Code runs `.sh` hooks through **Git Bash**, in a *non-login, non-interactive* shell. That shell does **not** read your `~/.bashrc`, and it does **not** inherit PATH tweaks you made for PowerShell. So `jq` can be installed, resolve perfectly in `where.exe jq`, and the hook still can't find it — at which point the sweep fails silently and queues to `pending.log`, and the skill *looks* broken when it isn't.

`winget install jqlang.jq` makes this worse in a specific way: it drops `jq.exe` under `%LOCALAPPDATA%\Microsoft\WinGet\Packages\...` but does **not** always create a shim in `WinGet\Links`, so `where.exe jq` / `Get-Command jq` come back **empty** even though winget reports the package as installed.

**The durable fix** — put `jq.exe` where Git Bash always looks. `C:\Program Files\Git\bin` maps to Git Bash's `/usr/bin`, which is on PATH for *every* shell type including the non-login one the hook uses:

1. Install jq (or confirm it's already there): `winget install jqlang.jq`
2. Find the actual binary (winget nests it under a versioned folder):
   ```powershell
   Get-ChildItem -Path "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" -Recurse -Filter "jq*.exe" | Select-Object FullName
   ```
3. Copy it into Git's bin — **run PowerShell as Administrator** (`C:\Program Files` is protected):
   ```powershell
   Copy-Item "<PATH_FROM_STEP_2>" "C:\Program Files\Git\bin\jq.exe"
   ```

**Verify it the way that actually matters** — a **non-login** Git Bash shell, because that's how the hook invokes it:

```powershell
& "C:\Program Files\Git\bin\bash.exe" -c "command -v jq"
```

This must print a path. Note the missing `-l` flag: `command -v jq` succeeding *with* `-l` only proves a login shell can see it (via `.bashrc`), which the hook is not. Test without `-l`. If that prints a path, the hook will find jq.

> **VS Code note:** if you launch Claude Code from a VS Code terminal, VS Code caches its environment at startup. After installing jq, fully **restart VS Code** (close every window so the parent process dies) — a new terminal in the old VS Code process still carries the stale PATH. The Git\bin copy above makes this moot, but it's why "it works in a fresh PowerShell but not in VS Code" happens.

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

Done. `SessionEnd` fires when a session closes; `PreCompact` is a safety net that saves the transcript's content before a long conversation gets compressed. `knowledge/capture-rules.md` and `knowledge/.gitignore` (containing `.sweep/`) are created automatically per project on the first invocation of the script — hook or `--doctor`/`--status`/`--replay` — no per-project setup step.

**If you have a vault created before v3.1.2:** `.sweep/` may already be tracked in git (the auto-seed above didn't exist yet). Fix it once per affected vault:
```bash
git rm -r --cached knowledge/.sweep
git commit -m "chore: stop tracking knowledge/.sweep (operational state, not vault content)"
```
The next sweep will (re)create `knowledge/.gitignore` and the `.sweep/` files will simply stop showing up in `git status`.

### End the session gracefully, or the hook won't fire

`SessionEnd` only fires when Claude Code shuts down **gracefully** and gets to run its exit routine. End the session one of these ways:

- `/exit` or `/quit` at the Claude Code prompt, or
- `Ctrl+C` / `Ctrl+D` to exit the REPL cleanly.

**Do not just kill the terminal** (the trash-can / "Kill Terminal" button in VS Code, or closing the window). That hard-terminates the process — the exit routine never runs, so no hook fires and no sweep happens. This is the single most common reason people think the skill is broken: they killed the terminal and nothing got captured. `PreCompact` still gives you a safety net mid-session for long conversations, but a deliberately-ended session must exit cleanly. (Exact exit commands can shift across Claude Code releases — if `/exit` isn't recognized, check `/help`.)

## Verify

End a real (10+ turn) session in a git repo that has this skill active, then:

```bash
cat knowledge/.sweep/sweep.log            # expect: OK wrote knowledge/<project>/<date>.md
grep "status: auto" knowledge/*/"$(date +%F)".md
```

Failures never interrupt you — they queue in `knowledge/.sweep/pending.log` and retry at the next `/distill` (which replays each entry via `--replay`, below). The model's raw output for each failure is preserved at `knowledge/.sweep/failed/` (most recent 20) for inspection.

## Troubleshooting

Start here whenever the skill "looks broken" — most cases are one of the two things `--doctor` checks for directly: `jq` invisible to the hook's shell, or `SWEEP.md` not where `HISTORIAN_SKILL_DIR` expects it.

```bash
~/.claude/historian/historian-sweep.sh --doctor
```

Read-only, never touches stdin, exits in under a second. Reports: whether `jq`/`git`/`claude` resolve **in the shell this command is run from** (run it inside a plain Git Bash window, not PowerShell, to match what the hook actually sees), whether `SWEEP.md` is found, the resolved vault path, the last `OK`/`FAIL` line from `sweep.log`, how many entries are queued in `pending.log`, and how many raw failures are preserved in `failed/`. Exits non-zero if it found a problem.

For a quick daily glance instead of the full diagnostic:

```bash
~/.claude/historian/historian-sweep.sh --status
```

Prints the last 5 `sweep.log` lines and the pending-queue depth.

To manually retry one queued failure without waiting for `/distill` (the three fields are tab-separated in `knowledge/.sweep/pending.log`: date, transcript path, session id):

```bash
~/.claude/historian/historian-sweep.sh --replay <transcript-path> <project-dir> <session-id>
```

This runs the identical validator/writer/committer path a live hook uses, skipping the triviality gate and dedup (a queued entry already earned a sweep), and removes the matching `pending.log` line(s) on success. Exits non-zero and leaves the entry queued if the replay itself fails.

## Optional config (env vars)

- `HISTORIAN_MODEL` — model for the sweep call (a cheap model is correct; sweeps fire often, the work is reconstruction not frontier reasoning)
- `HISTORIAN_SKILL_DIR` — where `SWEEP.md` lives (default `~/.claude/historian`)

The v3.1 capture gate skips a session only when **every** signal below reads trivial (any single one at/over its threshold runs the sweep — see `docs/adr/ADR-001-capture-gate-triviality.md`):

- `HISTORIAN_MIN_TURNS` — user turns at/above which the turns signal reads WORK (default 10; same name and default as v3.0, but no longer sufficient to skip on its own)
- `HISTORIAN_WORK_BYTES` — raw transcript bytes at/above which the size signal reads WORK (default 50000; this is what catches three-prompt sessions with hours of agentic work)
- `HISTORIAN_GIT_WINDOW` — commits since this `git log --since` expression read WORK; the historian's own `history(auto):` commits don't count (default `12 hours ago`)
- `HISTORIAN_DEDUP_DELTA` — bytes the transcript must grow past the last sweep of the same session before re-sweeping (default 4096)

For the hook to see any of these on Windows, set them in `~/.claude/settings.json`'s `"env"` block — the hook's non-login Git Bash shell does not read `.bashrc` or PowerShell profiles (same trap as `jq` above).

**Upgrading from v3.0:** no action needed — old config keeps working, vaults and day files are untouched. One one-time effect: a session the old version already swept may re-sweep once (the dedup log's second column changed from turns to bytes); the sweep's merge rule absorbs it without duplicating cases.

## Tests

`bash tests/run-tests.sh` from the skill root — 20 end-to-end scenarios (62 assertions) driving the real script with a stubbed `claude` binary (no model calls, no cost). Run it after any change to `historian-sweep.sh`, before re-deploying the runtime copy.

## Other tools

This install is Tier A (Claude Code's native `SessionEnd`/`PreCompact` hooks). Kiro has similar agent hooks (also Tier A). Tools that save session logs but have no hook system — Codex CLI, Gemini CLI — are Tier B: wrap the launch command so the sweep runs on exit. Anything else, including ChatGPT, is Tier C: paste the transcript and run the sweep manually. `SKILL.md` and `assets/SWEEP.md` are identical across every tier — only the trigger mechanism changes. Add other tiers only after the Claude Code version has run through the day-60 evaluation in `SKILL.md`.
