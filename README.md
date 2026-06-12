# myshell

Shell environment setup for macOS and Ubuntu. One installer, idempotent, safe to rerun.

## Usage

One-liner (bare box, no git needed — bootstrap fetches stage 2 into a tmp dir and cleans up):

```sh
curl -fsSL https://github.com/enstw/myshell/raw/main/bootstrap | sh
```

From a checkout (uses local `scripts/install`, good for iterating):

```sh
./bootstrap
```

Two stages:

1. `bootstrap` — POSIX-sh. Installs Homebrew + bash 5 on macOS (skips either if already present), or refreshes apt on Ubuntu, then runs stage 2 (no `exec` — bootstrap's cleanup trap must outlive it).
1. `scripts/install` — bash 5. Asks every question up front — git identity, which AI agents, fonts, login shell — and records the answers in `~/.local/state/myshell/` so re-runs don't re-ask (delete a file there to be asked again). Then it runs unattended: installs apps (including standalone `pnpm`, which also provisions the Node LTS runtime), writes `~/.zshenv` + `~/.zsh/*.zsh` + `~/.zshrc`, deploys `scripts/myshell-update` to `~/bin/myshell-update` (aliased to `u`), configures locale/timezone/pnpm/tealdeer, unminimizes a minimized Ubuntu (restores man pages/docs — this machine is for interactive use), installs the chosen AI agents (Codex via pnpm; Claude Code, OpenCode, and Antigravity CLI `agy` as standalone self-updating binaries), optionally installs fonts, and finishes with `chsh` to zsh (which may prompt for your password). Optional upstream installers and agent installs fail soft so a transient network/TLS issue does not abort the whole bootstrap.

This machine is **pnpm-only**: pnpm replaces npm (installed standalone via `get.pnpm.io`, supplies Node via `pnpm runtime`), and `npx` is aliased to `pnpm dlx`. The bundled `npm` is left unused and guarded behind a shell function.

The generated files (`~/.zshenv`, `~/.zshrc`, and the `~/.zsh/*.zsh` files the installer writes) are rewritten on every run — don't hand-edit them. Personal config goes in your own `~/.zsh/<name>.zsh`: everything in that directory is sourced, and the installer only ever rewrites its own files.

Read the header banner at the top of `scripts/install` for the cross-cutting rules (Python-via-uv-only, Node/pnpm-only, locale, timezone, AI agent install pattern, zsh file layout).

## Scope

**In:** shell startup, aliases, prompt/theme, plugins, packages, fonts, timezone/locale, helper scripts.

**Out:** SSH keys, host naming, VM bootstrap, Git identity (prompted at install time; not stored in the repo).

## Files

| Path | Purpose |
|------|---------|
| `bootstrap` | Stage 1. Run this. |
| `scripts/install` | Stage 2. The source of truth — read its header for design rules. |
| `scripts/myshell-update` | Deployed to `~/bin/myshell-update` (alias `u`). Refreshes brew/apt/zinit/pnpm/claude/opencode/agy/gstack. |
| `scripts/check` | Static gate: syntax-checks all three scripts, verifies the output-helper blocks are byte-identical. Run before committing. |
| `scripts/ci-roundtrip` | Headless container round-trip (seeds the recorded answers, runs bootstrap twice, asserts). Used by CI. |
| `.github/workflows/ci.yml` | CI: `scripts/check` + both round-trips (sudo user and root) in minimized `ubuntu:24.04` containers. |
| `TODO.md` | What's deferred, what's untested. |
