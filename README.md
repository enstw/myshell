# shell-state

A modular, AI-managed environment definition for macOS and Linux.

## Philosophy

This repository follows the **Environment-as-State** philosophy. It contains declarative specifications of the desired system state, which is maintained and converged by an AI operator (`shell-operator`).

## Getting Started

1. Clone this repository to `~/shell-state`.
2. Open the directory with Gemini CLI.
3. Refer to [PROTOCOLS.md](./PROTOCOLS.md) for the AI operational manual.

## Operator Directives

The AI can be given high-level directives to manage the environment:
- **`Converge`**: Sync all packages, configs, and fonts to the defined state.
- **`Capture`**: Snapshot the current system's live config back into this repo.
- **`Drift`**: Compare the repo state with the active system and report differences.

## Structure

- `specs/`: Declarative requirements for system packages, apps, and binaries.
- `layers/`: Modular configuration layers for shell components (e.g., zsh).
- `brain/`: The operational "Skill" for Gemini CLI.
