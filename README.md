# myshell

Declarative shell environment for macOS and Ubuntu Linux, configured by an AI agent at runtime.

## Goal

Define the desired shell state in small, readable files so any CLI AI agent can bring a machine into the preferred interactive environment — without a monolithic bootstrap script.

## How It Works

1. Install a CLI AI agent.
2. Start the agent from the **home directory** (`~`).
3. Point it at this repo — the agent reads the specs and configures the machine.

Shell scripts are generated at runtime and removed after use. This repo holds **intent**, not artifacts.

## Principles

- **Declarative** — describe the desired end state, not step-by-step procedures.
- **Idempotent** — safe to rerun at any time without duplicating config.
- **Modular** — small, single-purpose files over one large script.
- **Agent-agnostic** — works with any capable CLI AI agent.
- **Platform-aware** — supports macOS (Homebrew) and Ubuntu Linux (apt).

## Repo Layout

| Path | Purpose |
|------|---------|
| `AGENT.md` | AI operator protocols and working rules |
| `spec/shell.md` | Full shell state specification |
| `spec/packages.txt` | CLI packages (`brew_name:apt_name`) |
| `spec/casks.txt` | macOS GUI apps (brew cask) |
| `spec/scripts.txt` | Packages installed via curl (Ubuntu) |

## Scope

**In scope:** shell startup, aliases, prompt/theme, plugins, packages, fonts, timezone/locale, helper scripts.

**Out of scope:** SSH keys, host naming, VM bootstrap, personal Git identity in tracked files.
