# Shell Configuration Objective

## Purpose

This repository should define the desired shell environment so an AI agent can configure a machine by following explicit objectives, not by relying on one large bootstrap script.

The objective is to make shell setup:

- modular
- idempotent
- inspectable

## Primary Outcome

An AI agent should be able to use this repository to bring a macOS or Ubuntu Linux machine into the preferred interactive shell state with minimal manual work.

The shell experience should include:

- `zsh` as the interactive shell
- Oh My Zsh installed
- `powerlevel10k` as the prompt theme
- preferred plugins enabled
- repo-managed aliases loaded
- repo-managed environment variables loaded
- required packages installed for the current platform
- fonts installed when needed for prompt rendering

## Compatibility Goals

This project should be compatible with:

- different CLI AI agents
- macOS
- Ubuntu Linux

The repo should not depend on one specific AI agent implementation. Instructions should stay generic enough for any capable CLI agent that can inspect files, edit files, and run shell commands.

## Source Of Truth

The source of truth should be the small, readable files in this repo, especially:

- `packages.txt`
- `packages_cask.txt`
- `packages_curl.txt`
- ~/INSTALLATION_LOG.md

There should be no required one-shot bootstrap script. The desired end state matters more than preserving all-in-one automation.

`README.md` (this file) explains the human workflow: install an AI agent in the CLI and instruct it to follow this objective.

## Human Workflow

To configure a machine, the user should:
1. Install an AI agent in the CLI.
2. Start the AI agent while in the **home directory** (`~`) to ensure it has full privileges for home folder configuration.
3. Instruct the agent to follow this `README.md`.

## AI Agent Working Rules

When configuring a machine from this repo, the AI agent should:

1. Inspect the current host state before editing files.
2. Prefer minimal, targeted changes over broad rewrites.
3. Keep configuration modular and readable.
4. Make changes safe to run more than once.
5. Preserve unrelated user customizations whenever possible.
6. Use guarded blocks or explicit source lines when modifying shell startup files.
7. Avoid interactive steps unless they are unavoidable.
8. Avoid storing secrets, private keys, tokens, host-specific usernames, or personal machine paths in the repo.
9. **Maintain a file named `~/INSTALLATION_LOG.md`** to track each installation step, decision, and result. This allows subsequent agent sessions to pick up where the previous one left off and understand the current state.

## Configuration Boundaries

This repo should manage shell configuration, not full machine bootstrap.

In scope:

- shell startup behavior
- aliases
- prompt/theme
- shell plugins
- package lists needed for shell workflows
- terminal font prerequisites
- small helper scripts directly related to shell use

Out of scope unless explicitly requested:

- copying SSH keys
- host naming
- timezone changes
- global permission changes to the full home directory
- mounting host directories
- VM bootstrap logic
- personal Git identity values hardcoded in tracked files

## Desired Structure

The preferred implementation model is:

- simple repo-managed config files
- small helper scripts where automation is useful
- clear documentation of desired outcomes
- agent-agnostic instructions
- platform-aware behavior for macOS and Ubuntu Linux

The preferred implementation model is not:

- one large script that owns every machine-specific decision
- opaque interactive automation
- hardcoded personal environment assumptions
- instructions tied to one AI agent vendor
- undocumented assumptions about non-Ubuntu Linux distributions

## Shell State Requirements

### zsh

The AI agent should ensure zsh as login shell:

- enables the required Oh My Zsh theme and plugins
- loads Powerlevel10k in the normal supported way
- sources the repo-managed environment file
- keeps changes localized and identifiable

### Aliases

The AI agent should ensure the following aliases are available:

```zsh
alias ll='ls -alFG'
alias qrencode='qrencode -t ansiutf8 -r'

# Platform-aware update alias 'u'
if [[ "$(uname)" == "Darwin" ]]; then
    alias u='brew autoremove && brew cleanup && brew update && brew upgrade -g && brew cleanup && brew autoremove && brew cleanup ; brew doctor ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \; ; omz update'
else
    alias u='sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \; ; omz update'
fi
```

### Environment Variables

The AI agent should ensure the following environment settings are active:

```zsh
export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export LANG=en_US.UTF-8
umask 0077

# Ensure Powerlevel10k config is sourced if it exists
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
```

The AI agent should prefer placing these in a dedicated file (like `~/.aliases.zsh` and `~/.env.zsh`) and sourcing them from `~/.zshrc` to keep the main configuration clean.

### Packages

The AI agent should install packages from the platform-aware package lists and keep package definitions declarative.

Package handling should explicitly support:

- Homebrew on macOS
- `apt` on Ubuntu Linux

### tldr (tealdeer)

On Ubuntu Linux, after installing `tldr`, the AI agent should generate the default configi. ex. `tldr --seed-config` and update it so that only `zh_TW` and `en` languages are used:

ex. tealdeer config file
```toml
[updates]
download_languages = ["zh_TW", "en"]

[search]
languages = ["zh_TW", "en"]
```

### npm

The AI agent should ensure `npm` is installed and its global prefix is set to `~/.npm-global` so that globally installed packages do not require `sudo`:

```sh
npm config set prefix '~/.npm-global'
```

The PATH should include `~/.npm-global/bin`. This should be added to `~/.zshrc` or the repo-managed environment file.

### Proxmark3 (Iceman fork)

On macOS, `proxmark3` is installed via Homebrew.

On Ubuntu Linux, the Iceman fork must be built from source. The AI agent should:

1. Install build dependencies:

```sh
sudo apt install git ca-certificates build-essential pkg-config libreadline-dev gcc-arm-none-eabi libnewlib-dev libbz2-dev libssl-dev
```

2. Clone the repository if not already present:

```sh
git clone https://github.com/RfidResearchGroup/proxmark3.git ~/proxmark3
```

3. Build and install:

```sh
cd ~/proxmark3
make clean && make -j$(nproc)
sudo make install
```

4. Ensure the install is idempotent: skip if `pm3` is already available and up to date.

### Fonts

The AI agent should ensure a Nerd Font or the configured prompt font is installed when needed for prompt rendering.

## Acceptance Criteria

The objective is complete when all of the following are true:

- opening a new shell produces no startup errors
- `zsh` loads the expected prompt and plugins
- aliases from this repo are available
- environment settings from this repo are active
- the setup is safe to rerun without duplicating config
- the instructions remain usable with different CLI AI agents
- the setup logic remains valid on both macOS and Ubuntu Linux
- machine-specific secrets or private data are not committed
- the implementation is understandable without reading a large monolithic script
- `~/INSTALLATION_LOG.md` exists and accurately reflects the steps taken to configure the machine.

## Decision Policy

If the AI agent finds a choice between:

- adding more logic to a big bootstrap script, or
- expressing the desired state in small repo-managed files plus documentation

it should prefer the second option.

If a required value is personal or machine-specific, the AI agent should leave a clear placeholder or request that value instead of inventing one.
