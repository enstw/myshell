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
- ~/.install.log

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
9. **Maintain a file named `~/.install.log`** to track each installation step, decision, and result. This allows subsequent agent sessions to pick up where the previous one left off and understand the current state.
10. **Treat shell commands in this repo as intent, not literal scripts.** The commands shown are examples that illustrate the desired outcome. The AI agent should prefer the current official installation method (e.g. from upstream docs) over copying commands verbatim from this file, as they may become outdated. When deviating, log the difference in `~/.install.log`.

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
- timezone and locale configuration

Out of scope unless explicitly requested:

- copying SSH keys
- host naming
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
- keeps changes localized and identifiable

### Oh My Zsh Plugins

The AI agent should ensure the following Oh My Zsh plugins are enabled:

```zsh
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf z)
```

- `zsh-autosuggestions` and `zsh-syntax-highlighting` are custom plugins and must be cloned into `$ZSH_CUSTOM/plugins/` if not already present.
- `git`, `fzf`, and `z` are bundled with Oh My Zsh.

### Configuration File Layout

Personal shell customization should be placed in `~/.oh-my-zsh/custom/` as individual `*.zsh` files. Oh My Zsh automatically sources all `*.zsh` files in this directory (alphabetically) during init, so no explicit `source` lines are needed in `~/.zshrc`.

The recommended layout:

| File | Purpose |
|------|---------|
| `~/.oh-my-zsh/custom/aliases.zsh` | All aliases (modern CLI replacements, update, etc.) |
| `~/.oh-my-zsh/custom/env.zsh` | Environment variables, PATH additions, PATH dedup, `LANG`, plus Ubuntu-only `XAUTHORITY` and `DOCKER_DEFAULT_PLATFORM` |
| `~/.oh-my-zsh/custom/motd.zsh` | Dynamic MOTD display (Ubuntu Linux only — do not create on macOS) |
| `~/.oh-my-zsh/custom/zoxide.zsh` | zoxide init (`eval "$(zoxide init zsh)"`) |

`~/.zshrc` itself should only contain:

- Powerlevel10k instant prompt block (must be at the very top)
- `ZSH_THEME`, `plugins=()`, and `source $ZSH/oh-my-zsh.sh` (core OMZ config)
- `[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found` (Ubuntu only, guarded)
- `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh` (p10k convention, stays at bottom)

### aliases.zsh

```zsh
# Modern CLI replacements
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons'
alias qrencode='qrencode -t ansiutf8 -r'

# Platform-aware aliases (Ubuntu uses different binary names)
if [[ "$(uname)" == "Darwin" ]]; then
    alias cat='bat --paging=never'
else
    alias cat='batcat --paging=never'
    alias fd='fdfind'
fi

# Upgrade all outdated pip packages
alias upip="pip3 list -o | cut -f1 -d' ' | tr \" \" \"\\n\" | awk '{if(NR>=3)print}' | cut -d' ' -f1 | xargs -n1 pip3 install -U"

# Platform-aware update alias 'u'
if [[ "$(uname)" == "Darwin" ]]; then
    alias u='brew autoremove && brew cleanup && brew update && brew upgrade -g && brew cleanup && brew autoremove && brew cleanup ; brew doctor ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \; ; omz update'
else
    alias u='sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \; ; sudo snap refresh ; omz update'
    # Note: `sudo snap refresh` is included because some Ubuntu systems have snap-installed packages.
    # Remove it from the alias if snap is not in use.
fi
```

### env.zsh

```zsh
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export LANG=zh_TW.UTF-8
# Restrictive umask: no group/other access on new files (intentional security hardening)
umask 0077

# Ubuntu-only environment
if [[ "$(uname)" != "Darwin" ]]; then
    export XAUTHORITY=$HOME/.Xauthority
    # aarch64 Docker default (e.g. ARM VMs)
    [[ $(uname -m) == "aarch64" ]] && export DOCKER_DEFAULT_PLATFORM=linux/arm64
fi

# Deduplicate PATH
export PATH="$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')"
```

### zoxide.zsh

```zsh
eval "$(zoxide init zsh)"
```

This replaces the default `cd` workflow with a smarter directory jumper (used via the `z` command).

### motd.zsh

On Ubuntu Linux only:

```zsh
# --- Display Dynamic MOTD for Zsh ---
if [[ -x "/usr/bin/run-parts" ]] && [[ -d "/etc/update-motd.d" ]]; then
    if [[ ! -f "$HOME/.hushlogin" ]]; then
        /usr/bin/run-parts --lsbsysinit /etc/update-motd.d/ 2>/dev/null
    fi
fi
# --- End Dynamic MOTD ---
```

This replicates the login MOTD behavior that zsh does not display by default. The block respects `~/.hushlogin` to allow suppression.

### command-not-found

On Ubuntu Linux, the AI agent should ensure the `command-not-found` handler is sourced in `~/.zshrc` (not in the custom folder, as not all systems have this file). Use a guard so it is safe on macOS:

```zsh
[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found
```

This provides package suggestions when a user runs a command that is not installed.

### Timezone and Locale

The AI agent should ensure the machine is configured with the correct timezone and locale:

- **Timezone:** Set to `Asia/Taipei`.
- **Locale:** Ensure `en_US.UTF-8`, `en_GB.UTF-8`, and `zh_TW.UTF-8` are generated, and `LANG` is set to `zh_TW.UTF-8`.

### Packages

The AI agent should install packages from the platform-aware package lists and keep package definitions declarative.

Package handling should explicitly support:

- Homebrew on macOS
- `apt` on Ubuntu Linux

### Docker (Ubuntu)

On macOS, Docker is installed via Homebrew (`brew install docker`).

On Ubuntu Linux, Docker should be installed from Docker's official `apt` repository (`docker-ce`), not the `docker.io` Ubuntu archive package. The AI agent should:

1. Add Docker's official GPG key and repository if not already configured:

```sh
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
```

2. Install Docker CE packages:

```sh
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

3. Skip if `docker --version` already reports a `docker-ce` installation.

### tldr (tealdeer)

After installing `tldr`, the AI agent should generate the default config via `tldr --seed-config` and update it so that only `zh_TW` and `en` languages are used. The config file path varies by platform — use `tldr --show-paths` to locate it (e.g. `~/.config/tealdeer/config.toml` on Ubuntu, `~/Library/Application Support/tealdeer/config.toml` on macOS):
```toml
[updates]
download_languages = ["zh_TW", "en"]

[search]
languages = ["zh_TW", "en"]
```

### Node.js

Node is installed via system packages (`brew install node` / `apt install nodejs`). This intentionally uses the system-provided version. If a project requires a specific Node version, use a version manager like `fnm` or `nvm` on a per-project basis — that is out of scope for this repo.

### npm

The AI agent should ensure `npm` is installed (it comes with `node`/`nodejs` from `packages.txt`) and its global prefix is set to `~/.npm-global` so that globally installed packages do not require `sudo`:

```sh
npm config set prefix '~/.npm-global'
```

The PATH should include `~/.npm-global/bin` (covered in `env.zsh` above).

### Proxmark3 (Iceman fork) — opt-in

> **Note:** This section involves building from source on Ubuntu and is heavier than typical shell configuration. The AI agent should only perform these steps when explicitly requested by the user.

On macOS, `proxmark3` is installed via Homebrew (handled by `packages.txt`).

On Ubuntu Linux, the Iceman fork must be built from source. When requested, the AI agent should:

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
- `~/.install.log` exists and accurately reflects the steps taken to configure the machine.

## Decision Policy

If the AI agent finds a choice between:

- adding more logic to a big bootstrap script, or
- expressing the desired state in small repo-managed files plus documentation

it should prefer the second option.

If a required value is personal or machine-specific, the AI agent should leave a clear placeholder or request that value instead of inventing one.
