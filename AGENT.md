# AI Operator Guide

This file contains everything an AI agent needs to manage this shell environment.

## Working Rules

1. Inspect the current host state before editing files.
2. Prefer minimal, targeted changes over broad rewrites.
3. Make changes safe to run more than once (idempotent).
4. Preserve unrelated user customizations.
5. Use guarded blocks when modifying shell startup files.
6. Avoid interactive steps.
7. Avoid storing secrets or personal data in the repo.
8. Maintain `~/.install.log` using the format in [Install Log](#install-log).
9. Treat shell commands in spec files as **intent**, not literal scripts — prefer official install methods.
10. Generate shell scripts at runtime and remove them after use.

## Operator Protocols

### Converge

Bring the host system into alignment with the repo state.

1. **Install apps** — parse `spec/apps.txt` and resolve the best install method for each app on the current platform. Prefer: native package manager > official install script > binary release > build from source. Verify the correct binary is present after install (e.g., tealdeer not python-tldr, docker-ce not docker.io). See `spec/shell.md` for app-specific install notes.
2. **Configure shell** — generate files defined in `spec/shell.md` and place them at their target paths. Initialize zinit, starship, and plugins.
3. **Install fonts** — fetch the latest `.ttf` from `https://ent.tw/font`. Install to `~/Library/Fonts/` (macOS) or `~/.local/share/fonts/` (Ubuntu, then `fc-cache -f`).
4. **Set timezone/locale** — apply settings from `spec/shell.md`.

**Outcome:** all specs applied, `~/.zshrc` and `~/.zsh/` are in the target state.

### Capture

Extract the current system state into the repo.

1. Compare `~/.zsh/` files with the spec definitions in `spec/shell.md`.
2. Detect manually installed packages and suggest additions to `spec/apps.txt`.
3. Propose updates to spec files where the live system has diverged.

**Outcome:** the repo becomes the source of truth for the active environment.

### Drift

Report differences without making changes.

1. Verify files at target paths match the spec.
2. Check all packages in `spec/` are installed.
3. Diff active shell files against spec definitions.

**Outcome:** a drift report detailing what is missing or different.

## App List Format

### apps.txt

```
app_name                # optional description / disambiguation
[mac] app_name          # macOS only
[ubuntu] app_name       # Ubuntu only
```

- One app per line. Comments after `#` provide hints to the agent (e.g., which variant to install).
- The agent determines the correct package name and install method per platform.
- Install priority: native package manager > official install script > binary release > build from source.
- After install, verify the expected binary is available and log the result.

## Install Log

**Location:** `~/.install.log` (git-ignored, never committed)

**Format:**

```
## [YYYY-MM-DD HH:MM:SS] <category>: <description>
status: ok|skipped|failed
detail: <explanation>
```

**Categories:** `session`, `package`, `config`, `plugin`, `font`, `docker`, `locale`, `starship`, `zinit`, `npm`, `verify`

**Rules:**
- Append-only; never truncate.
- Start each session with `## [timestamp] session: start`.
- Use `skipped` when a step was already complete.

## Decision Policy

If choosing between a big bootstrap script or expressing desired state in small spec files plus documentation — prefer the second. If a value is personal or machine-specific, leave a placeholder.
