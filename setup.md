# Setup

This repository no longer uses a one-shot setup script.

The intended setup flow is:

1. Install an AI agent that runs in your CLI.
2. Open this repository in the terminal.
3. Ask the agent to follow [OBJECTIVE.md](./OBJECTIVE.md) and configure the shell environment.

The setup flow should work with different CLI AI agents. It should not depend on one specific agent vendor or one agent-specific feature set beyond reading files, editing files, and running shell commands.

The target platforms are:

- macOS
- Ubuntu Linux

## Recommended Prompt

Use a prompt like:

```text
Follow OBJECTIVE.md in this repository and configure my shell environment. Inspect the current machine state first, make minimal idempotent changes, and keep user-specific values as placeholders unless I provide them.
```

## What The Agent Should Use

The agent should treat these files as the main source of truth:

- `OBJECTIVE.md`
- `aliases.zsh`
- `env.zsh`
- `p10k.zsh`
- `packages.txt`
- `packages_cask.txt`
- `packages_curl.txt`

## Expected Result

After the agent completes the work:

- a new `zsh` session should start cleanly
- Oh My Zsh and Powerlevel10k should be configured
- repo-managed aliases and environment settings should load
- package installation should match macOS or Ubuntu Linux
- the setup should remain safe to rerun
