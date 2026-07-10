# Installing Session Handoff

This is a pure-markdown skill. There are no scripts, no runtime dependencies (no `jq`, no shell hooks), and nothing to compile. Installation is copying one folder into your skills directory and starting a new session.

## Claude Code

Skills live in one of two places:

- **Personal** (available in every project): `~/.claude/skills/`
- **Project** (scoped to one repo, shared with anyone who clones it): `.claude/skills/` at the repo root

The skill folder must be named `session-handoff` and contain `SKILL.md` directly inside it — not nested an extra level deep.

### macOS / Linux

```bash
# Personal install
mkdir -p ~/.claude/skills
cp -r session-handoff ~/.claude/skills/
```

### Windows (PowerShell, native — no WSL needed)

```powershell
# Personal install
New-Item -ItemType Directory -Force -Path "$HOME\.claude\skills"
Copy-Item -Recurse -Force .\session-handoff "$HOME\.claude\skills\"
```

If you're installing from a downloaded zip instead of a clone:

```powershell
Expand-Archive -Path "$HOME\Downloads\session-handoff.zip" -DestinationPath "$HOME\.claude\skills" -Force
```

### Verify it loaded

Start a **new** Claude Code session (skills are scanned at session start, not mid-session), then either:

```powershell
Get-ChildItem "$HOME\.claude\skills"    # confirm the folder is there
```

or, inside a session, ask: *"what skills do you have available?"* — `session-handoff` should appear. Then type **"wrap up session"** and confirm it produces a structured handoff rather than a generic summary.

> **Note on new sessions:** If a Claude Code session was already running before you copied the folder in, it won't see the skill until you exit (`/exit` or `Ctrl+D`) and start a fresh one. You do **not** need to close your editor — just restart the Claude Code session inside it.

## Claude.ai (chat)

Upload the skill through **Settings → Capabilities/Features → Skills** (requires code execution enabled on your plan). In a chat environment there's no project filesystem, so the skill saves the handoff as a downloadable file instead of writing into a repo — this behavior is built in and needs no configuration.

## Portability notes

The skill runs on any capable LLM. Its core discipline — the manifestation classifier, precision-claims rule, self-consistency pass, and required/situational section model — is entirely tool-neutral.

A few references in the "How to produce the handoff" step assume Claude Code conventions and should be read as *examples of where session state lives*, not hard requirements:

- `~/.claude/plans/` (plan files)
- `~/.claude/projects/<project>/memory/` (memory files)
- `TodoWrite` state and `run_in_background` shell IDs
- the `/clear` command as the trigger for producing a handoff

Running in Cursor, Codex, or another agent, the skill still functions — it simply pulls session state from wherever that tool keeps it, and writes to `docs/handoffs/` in the project the same way. No edits are required to use it; the paths above are the only tool-specific lines, and they fail gracefully (the agent notes the source isn't present rather than breaking).

## Uninstall

Delete the folder:

```powershell
Remove-Item -Recurse -Force "$HOME\.claude\skills\session-handoff"
```
