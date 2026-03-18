# Shell State Specification

This file defines the exact desired shell state. The AI agent should read this
file and the package lists, then configure the machine accordingly.

Shell scripts needed during setup should be generated at runtime and removed
after use — do not commit generated scripts to this repo.

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
9. **Maintain `~/.install.log`** using the format defined in [Install Log Format](#install-log-format) to track each installation step, decision, and result. This allows subsequent agent sessions to pick up where the previous one left off.
10. **Treat shell commands in this file as intent, not literal scripts.** The commands shown illustrate the desired outcome. The AI agent should prefer the current official installation method (e.g. from upstream docs) over copying commands verbatim, as they may become outdated. When deviating, log the difference in `~/.install.log`.

## Configuration Boundaries

This repo manages shell configuration, not full machine bootstrap.

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

## zsh

The AI agent should ensure zsh as login shell:

- installs and initializes `zinit` for plugin management
- initializes `starship` in the normal supported way
- keeps changes localized and identifiable

## zinit Installation

The AI agent should install `zinit` if not already present:

```sh
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
```

## zinit Plugins

The AI agent should ensure the following plugins are enabled via `zinit` in `~/.zshrc`:

```zsh
# Load Oh My Zsh library for git support
zinit snippet OMZL::git.zsh

# Load plugins
zinit snippet OMZP::git
zinit snippet OMZP::fzf
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions
```

- `fzf` is a standard plugin.
- `zsh-autosuggestions`, `fast-syntax-highlighting`, and `zsh-completions` are high-performance alternatives managed by `zinit`.

## Configuration File Layout

Personal shell customization should be placed in `~/.zsh/` as individual `*.zsh` files. These should be sourced manually in `~/.zshrc` since we are no longer using Oh My Zsh's automatic sourcing.

The recommended layout:

| File | Purpose |
|------|---------|
| `~/.zsh/aliases.zsh` | All aliases (modern CLI replacements, update, etc.) |
| `~/.zsh/env.zsh` | Environment variables, PATH additions, PATH dedup, `LANG`, plus Ubuntu-only `XAUTHORITY` and `DOCKER_DEFAULT_PLATFORM` |
| `~/.zsh/motd.zsh` | Dynamic MOTD display (Ubuntu Linux only — do not create on macOS) |
| `~/.zsh/zoxide.zsh` | zoxide init (`eval "$(zoxide init zsh)"`) |

`~/.zshrc` itself should only contain:

- `zinit` initialization block (typically at the top)
- `zinit` plugin loading block
- Custom config sourcing loop: `for f in ~/.zsh/*.zsh(N); do source $f; done`
- `[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found` (Ubuntu only, guarded)
- `eval "$(starship init zsh)"` (Starship initialization, stays at bottom)

## aliases.zsh

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
alias upip='pip3 list -o --format=json | python3 -c "import sys,json;[print(p[\"name\"])for p in json.load(sys.stdin)]" | xargs -n1 pip3 install -U'

# System update (delegates to ~/bin/update for readability)
alias u='~/bin/update'
```

## ~/bin/update

The `u` alias delegates to `~/bin/update`. The AI agent should create this script with the following content:

```sh
#!/usr/bin/env zsh
set -e

update_zinit() {
    # Source zinit explicitly — it is not available in non-interactive scripts.
    local zinit_home="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
    if [[ -f "$zinit_home/zinit.zsh" ]]; then
        source "$zinit_home/zinit.zsh"
        zinit self-update
        zinit update --all
    else
        echo "zinit not found at $zinit_home — skipping plugin update."
    fi
}

if [ "$(uname)" = "Darwin" ]; then
    brew update && brew upgrade -g
    brew autoremove && brew cleanup
    brew doctor
else
    sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove
    # Include snap refresh if snap is in use; remove otherwise
    if command -v snap >/dev/null 2>&1; then
        sudo snap refresh
    fi
fi

update_zinit
```

The script should be executable (`chmod +x ~/bin/update`). `~/bin` is already on PATH via `env.zsh`.

## env.zsh

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

## zoxide.zsh

```zsh
eval "$(zoxide init zsh)"
```

This replaces the default `cd` workflow with a smarter directory jumper (used via the `z` command).

## motd.zsh

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

## command-not-found

On Ubuntu Linux, the AI agent should ensure the `command-not-found` handler is sourced in `~/.zshrc` (not in the custom folder, as not all systems have this file). Use a guard so it is safe on macOS:

```zsh
[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found
```

This provides package suggestions when a user runs a command that is not installed.

## Timezone and Locale

The AI agent should ensure the machine is configured with the correct timezone and locale:

- **Timezone:** Set to `Asia/Taipei`.
- **Locale:** Ensure `en_US.UTF-8`, `en_GB.UTF-8`, and `zh_TW.UTF-8` are generated, and `LANG` is set to `zh_TW.UTF-8`.

## Packages

The AI agent should install packages from the platform-aware package lists and keep package definitions declarative.

Package handling should explicitly support:

- Homebrew on macOS
- `apt` on Ubuntu Linux

## Docker (Ubuntu)

On macOS, Docker is installed as a cask via Homebrew (`brew install --cask docker`), which provides Docker Desktop.

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

## tldr (tealdeer)

After installing `tldr`, the AI agent should generate the default config via `tldr --seed-config` and update it so that only `zh_TW` and `en` languages are used. The config file path varies by platform — use `tldr --show-paths` to locate it (e.g. `~/.config/tealdeer/config.toml` on Ubuntu, `~/Library/Application Support/tealdeer/config.toml` on macOS):
```toml
[updates]
download_languages = ["zh_TW", "en"]

[search]
languages = ["zh_TW", "en"]
```

## npm

The `npm` package is listed in `packages.txt` and pulls in Node.js as a dependency on both platforms. Node is not installed explicitly — it is only needed as a runtime for npm-based tools (e.g. AI agents). If a project requires a specific Node version, use a version manager like `fnm` or `nvm` on a per-project basis — that is out of scope for this repo.

The AI agent should ensure the npm global prefix is set to `~/.npm-global` so that globally installed packages do not require `sudo`:

```sh
npm config set prefix "$HOME/.npm-global"
```

The PATH should include `~/.npm-global/bin` (covered in `env.zsh` above).

## Proxmark3 (Iceman fork) — opt-in

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

## Starship Configuration

After Starship is installed, the prompt is configured by initializing it in zsh. Use Starship's built-in defaults. Do not create or manage `~/.config/starship.toml` unless the user explicitly requests custom prompt configuration. If no `starship.toml` exists, Starship uses sensible defaults that work well with Nerd Fonts.

## Fonts

The AI agent should ensure a Nerd Font or the configured prompt font is installed when needed for prompt rendering. Starship works best with Nerd Fonts (e.g., FiraCode Nerd Font).

## packages_curl.txt Format

The file uses the format: `[ubuntu] name install_url`

The `[ubuntu]` prefix means macOS agents should skip that line (macOS equivalents are in `packages_cask.txt`).

When executing a curl-installed package, the AI agent should:

1. Verify the URL matches the official project's documented install method before executing.
2. Download the script to a temporary file first — do **not** pipe curl directly to a shell.
3. Inspect the downloaded script for obvious issues (e.g., unexpected `rm -rf`, credential harvesting).
4. Execute with `bash /tmp/<name>-install.sh` (or `sh` if the script specifies it).
5. Remove the temporary script after execution.
6. Log the result in `~/.install.log` with the URL used and the verified source.
7. After execution, confirm the installed binary is available (e.g., `command -v zed`).

## Install Log Format

**Location:** `~/.install.log`

**Purpose:** Allows subsequent agent sessions to understand what was already done and pick up where the previous session left off.

**Format:** One entry per logical step. Each entry is a block:

```
## [YYYY-MM-DD HH:MM:SS] <category>: <short description>
status: <ok|skipped|failed>
detail: <free-text explanation, may be multi-line indented>
```

**Categories** (not exhaustive — agents may add more): `session`, `package`, `config`, `plugin`, `font`, `docker`, `locale`, `starship`, `zinit`, `npm`, `verify`

**Rules:**

- Append-only; never truncate.
- Each agent session should start with a `## [timestamp] session: start` entry.
- Use `skipped` when a step was already complete.
- The file is listed in `.gitignore` and must never be committed.

**Example:**

```
## [2026-03-18 14:00:00] session: start
status: ok
detail: macOS arm64, zsh already default shell

## [2026-03-18 14:00:05] package: install eza
status: ok
detail: brew install eza (v0.20.6)

## [2026-03-18 14:00:10] package: install bat
status: skipped
detail: already installed (v0.24.0)

## [2026-03-18 14:00:15] config: write ~/.zsh/aliases.zsh
status: ok
detail: created from SHELLSPEC.md aliases.zsh section
```

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
- `~/.install.log` exists and accurately reflects the steps taken to configure the machine

## Decision Policy

If the AI agent finds a choice between:

- adding more logic to a big bootstrap script, or
- expressing the desired state in small repo-managed files plus documentation

it should prefer the second option.

If a required value is personal or machine-specific, the AI agent should leave a clear placeholder or request that value instead of inventing one.
