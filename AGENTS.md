# AGENTS.md

Context for AI agents working in this repository.

## Project Overview

`myshell` — shell environment setup for macOS and Ubuntu. One idempotent installer, safe to rerun. See `README.md` for usage and `scripts/install`'s header banner for the cross-cutting design rules.

## Workflow

- **This is a single-developer repo. Do not create branches or pull requests.** Commit directly to `main`.
- Commit (and push) only when the user asks.

## Architecture

Two stages:

1. `bootstrap` — POSIX-sh. Installs Homebrew + bash 5 on macOS, or refreshes apt on Ubuntu, then `exec`s stage 2.
2. `scripts/install` — bash 5. The source of truth. Installs apps, writes `~/.zshenv` + `~/.zsh/*.zsh` + `~/.zshrc`, deploys `scripts/myshell-update`, configures locale/timezone/npm, prompts for AI agents and fonts. Read its header banner for the design rules (Python-via-uv-only, locale, timezone, AI agent install pattern, zsh file layout).

## Conventions

- Idempotent: every step is safe to rerun.
- Optional upstream installers and npm agents fail soft — a transient network/TLS issue must not abort the bootstrap.
- **Out of scope:** SSH keys, host naming, VM bootstrap, Git identity.
