# myshell

Declarative shell environment for macOS and Ubuntu Linux, configured by an AI agent at runtime.

## Goal

Define the desired shell state in small, readable files so any CLI AI agent can bring a machine into the preferred interactive environment — without a monolithic bootstrap script.

## How It Works

1. Install a CLI AI agent.
2. Start the agent from the **home directory** (`~`).
3. Point it at this repo — the agent reads [SHELLSPEC.md](SHELLSPEC.md) and the package lists, then configures the machine.

Shell scripts are generated at runtime and removed after use. This repo holds **intent**, not automation artifacts.

## Principles

- **Declarative** — describe the desired end state, not step-by-step procedures.
- **Idempotent** — safe to rerun at any time without duplicating config.
- **Modular** — small, single-purpose files over one large script.
- **Agent-agnostic** — works with any capable CLI AI agent.
- **Platform-aware** — supports macOS (Homebrew) and Ubuntu Linux (apt).

## Repo Layout

| File | Purpose |
|------|---------|
| `SHELLSPEC.md` | Full shell state specification (what the agent should configure) |
| `packages.txt` | Cross-platform package list (`brew_name:apt_name`) |
| `packages_cask.txt` | macOS cask packages |
| `packages_curl.txt` | Packages installed via curl (Ubuntu only) |
| `archive/` | Legacy files kept for reference — not used |

## Scope

**In scope:** shell startup, aliases, prompt/theme, plugins, packages for shell workflows, fonts, timezone/locale, small helper scripts.

**Out of scope:** SSH keys, host naming, VM bootstrap, personal Git identity in tracked files.
