# AGENTS.md

Context for AI agents working in this repository.

## Project Overview

`myshell` — shell environment setup for macOS and Ubuntu. One idempotent installer, safe to rerun. See `README.md` for usage and `scripts/install`'s header banner for the cross-cutting design rules.

## Workflow

- **This is a single-developer repo. Do not create branches or pull requests.** Commit directly to `main`.
- Commit (and push) only when the user asks.
- Run `scripts/check` before committing (syntax + byte-identical output helpers). CI re-runs it plus two headless container round-trips on every push.

## Architecture

Two stages:

1. `bootstrap` — POSIX-sh. Installs Homebrew + bash 5 on macOS, or refreshes apt on Ubuntu, then runs stage 2 (no `exec` — bootstrap's cleanup trap must outlive it).
2. `scripts/install` — bash 5. The source of truth. Gathers all interactive answers up front (recorded under `~/.local/state/myshell/` — the decision, not system state, is the idempotency key), then runs six phases in a fixed order: **system** (locale, timezone, passwordless apt/snap), **shell** (zsh + prompt + plugins, the generated dotfiles, `~/bin/myshell-update` + `update.d/*.sh`, git identity, `chsh`), **fonts**, **packages** (the CLI toolbox, tealdeer, docker group, purge, unminimize), **runtimes** (uv, pnpm + Node LTS, bun), **agents** (the chosen AI agents + CodeGraph). `--phase LIST` runs a subset; `--list-phases` prints them. Read its header banner for the design rules (phases and their ordering constraints, Python-via-uv-only, locale, timezone, AI agent install pattern, zsh file layout).

## Conventions

- Idempotent: every step is safe to rerun.
- Failure policy: required tools (brew/apt base packages, uv, starship, zinit) fail hard; optional steps (pnpm, bun, AI agents, fetched configs, fonts) fail soft — a transient network/TLS issue must not abort the bootstrap.
- Output vocabulary: `log`/`sublog`/`warn`/`die`, duplicated byte-identical across all three scripts (a sourced lib can't reach them all — see the header rule in `scripts/install`). `warn` goes to stderr and is counted into the final Done line; fail-soft failures must `warn`, not `sublog`.
- Phases: every step belongs to exactly one `phase_<name>` function, and `PHASES` is the canonical order — a subset selected with `--phase` is intersected with it, never reordered, because three orderings are correctness rather than tidiness (locale before all apt work; `purge_conflicts` before `install_agents`; `unminimize_ubuntu` after the last apt install and the purge). They are spelled out in the `scripts/install` header. A new phase also has to be taught to `sudo_work_pending`, which predicts per phase so an unselected phase's work can't trigger a password prompt, and get a line in `scripts/ci-roundtrip`.
- Step grammar and OS-branch tiers (guard clause for one-OS steps, inline `if` for small divergence, `_macos`/`_ubuntu` pair only for large parallel implementations) are documented in the `scripts/install` header — follow them when adding steps. New third-party apt repos go through `apt_keyring_repo`.
- Pairing rule: a tool added to `scripts/install` that has its own update path gets its `scripts/myshell-update` section in the same commit.
- `update.d`: machine-local update steps go in `~/.config/myshell/update.d/*.sh`, not in `~/bin/myshell-update` (the installer overwrites that file every run). `myshell-update` **sources** them last, so a drop-in is just another section — it gets `log`/`sublog`/`warn` and its warnings reach the Done line. Three consequences, documented in the runner and in every shipped drop-in: guard each step with its own `|| warn` (sourcing under `|| warn` suspends `set -e`), wrap any `cd` in a subshell with `warn` outside it, and end the file with `true` so a skipped guard `if` isn't reported as a failure. Drop-ins myshell ships live in `update.d/` and must be no-ops where their target is absent; the installer rewrites those and leaves other files in the directory alone.
- Headless runs are a supported interface: pre-seed the answer store (`~/.local/state/myshell/`) and git identity — the exact contract is in the `scripts/install` header; `scripts/ci-roundtrip` is the reference implementation. A new `choose_*` question updates both in the same commit.
- Prompt coverage: because the round-trips seed every answer so that nothing prompts, they can never exercise `ask`/`confirm` or `normalize_agent_choice` — `scripts/test-prompts` does, sourcing `scripts/install` (hence its `main "$@"` guard) and driving the tty-reading helpers under a real pty. A new `choose_*` question gets a case there too.
- Never call `warn` inside a subshell (`$(...)` capture, including a helper invoked that way) — the `WARNINGS` counter increment is silently lost even though the line still prints, so the Done line and CI's `grep -c '^warning:'` disagree about the same run. A helper that warns returns its result in a global instead: `normalize_agent_choice` sets `AGENT_CHOICE`, as `gather_git_identity` sets `GIT_NAME`/`GIT_EMAIL`.
- **Out of scope:** SSH keys, host naming, VM bootstrap, Git identity.
