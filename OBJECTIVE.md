# Shell Configuration Objective

## Purpose

This repository should define the desired shell environment so an AI agent can configure a machine by following explicit objectives, not by relying on one large bootstrap script.

The objective is to make shell setup:

- modular
- idempotent
- inspectable
- safe to rerun
- easy to evolve file by file

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

- `aliases.zsh`
- `env.zsh`
- `p10k.zsh`
- `packages.txt`
- `packages_cask.txt`
- `packages_curl.txt`

There should be no required one-shot bootstrap script. The desired end state matters more than preserving all-in-one automation.

`setup.md` should explain the human workflow: install an AI agent in the CLI and instruct it to follow this objective.

Older machine-bootstrap files such as `myconfig.sh`, `myshell.sh`, `Startup.sh`, `mount_dev.sh`, `unmount_dev.sh`, and `mac_terminal_setup.md` should be treated as legacy reference material unless a task explicitly requires them.

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

### `~/.zshrc`

The AI agent should ensure `~/.zshrc`:

- loads Powerlevel10k in the normal supported way
- enables the required Oh My Zsh theme and plugins
- sources the repo-managed environment file
- keeps changes localized and identifiable

### Repo-managed config

The AI agent should prefer changing repo files such as `aliases.zsh` and `env.zsh` instead of stuffing custom logic directly into `~/.zshrc`.

### Packages

The AI agent should install packages from the platform-aware package lists and keep package definitions declarative.

Package handling should explicitly support:

- Homebrew on macOS
- `apt` on Ubuntu Linux

### tealdeer (tldr)

On Ubuntu Linux, after installing `tldr`, the AI agent should generate the default config with `tldr --seed-config` and then update `~/.config/tealdeer/config.toml` so that only `zh_TW` and `en` languages are used:

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

## Decision Policy

If the AI agent finds a choice between:

- adding more logic to a big bootstrap script, or
- expressing the desired state in small repo-managed files plus documentation

it should prefer the second option.

If a required value is personal or machine-specific, the AI agent should leave a clear placeholder or request that value instead of inventing one.
