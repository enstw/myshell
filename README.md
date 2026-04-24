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

1. `bootstrap` — POSIX-sh. Installs Homebrew + bash 5 on macOS, or refreshes apt on Ubuntu, then `exec`s stage 2.
1. `scripts/install` — bash 5. Installs apps, writes `~/.zshenv` + `~/.zsh/*.zsh` + `~/.zshrc`, deploys `scripts/myshell-update` to `~/bin/myshell-update` (aliased to `u`), configures locale/timezone/npm/tealdeer/gemini-cli, optionally installs fonts, offers to `chsh` to zsh.

Read the header banner at the top of `scripts/install` for the cross-cutting rules (Python-via-uv-only, locale, timezone, gemini-cli local install, zsh file layout).

## Scope

**In:** shell startup, aliases, prompt/theme, plugins, packages, fonts, timezone/locale, helper scripts.

**Out:** SSH keys, host naming, VM bootstrap, Git identity (prompted at install time; not stored in the repo).

## Files

| Path | Purpose |
|------|---------|
| `bootstrap` | Stage 1. Run this. |
| `scripts/install` | Stage 2. The source of truth — read its header for design rules. |
| `scripts/myshell-update` | Deployed to `~/bin/myshell-update` (alias `u`). Refreshes brew/apt/zinit/npm/claude/gstack. |
| `TODO.md` | What's deferred, what's untested. |
