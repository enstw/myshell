# AGENTS.md

Context for AI agents working in this repository.

## Project Overview

`myshell` — shell environment setup for macOS and Ubuntu. One idempotent installer, safe to rerun. See `README.md` for usage and `scripts/install`'s header banner for the cross-cutting design rules.

## Workflow

- **This is a single-developer repo. Do not create branches or pull requests.** Commit directly to `main`.
- Commit (and push) only when the user asks.

## Architecture

Two stages:

1. `bootstrap` — POSIX-sh. Installs Homebrew + bash 5 on macOS, or refreshes apt on Ubuntu, then runs stage 2 (no `exec` — bootstrap's cleanup trap must outlive it).
2. `scripts/install` — bash 5. The source of truth. Gathers all interactive answers up front (recorded under `~/.local/state/myshell/` — the decision, not system state, is the idempotency key), then installs apps, writes `~/.zshenv` + `~/.zsh/*.zsh` + `~/.zshrc`, deploys `scripts/myshell-update`, configures locale/timezone/pnpm, and installs the chosen AI agents and fonts. Read its header banner for the design rules (Python-via-uv-only, locale, timezone, AI agent install pattern, zsh file layout).

## Conventions

- Idempotent: every step is safe to rerun.
- Failure policy: required tools (brew/apt base packages, uv, starship, zinit) fail hard; optional steps (pnpm, bun, AI agents, fetched configs, fonts) fail soft — a transient network/TLS issue must not abort the bootstrap.
- Output vocabulary: `log`/`sublog`/`warn`/`die`, duplicated byte-identical across all three scripts (a sourced lib can't reach them all — see the header rule in `scripts/install`). `warn` goes to stderr and is counted into the final Done line; fail-soft failures must `warn`, not `sublog`.
- **Out of scope:** SSH keys, host naming, VM bootstrap, Git identity.
