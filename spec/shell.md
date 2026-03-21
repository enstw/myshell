# Shell State Specification

This file defines the desired shell state. The AI agent reads this file, `apps.txt`, and `constraints.md`, then configures the machine accordingly.

## zsh

Ensure zsh is the login shell.

### zinit

Install zinit if not present. Load these plugins in `~/.zshrc`:

```zsh
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
zinit snippet OMZP::fzf
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions
```

### Starship

Initialize at the bottom of `~/.zshrc`:

```zsh
eval "$(starship init zsh)"
```

Deploy the Starship configuration from `https://github.com/enstw/myshell-starship` (specifically `starship.toml`) to `~/.config/starship.toml`. This preset uses Nerd Font symbols and a powerline-style prompt with time, directory, and git segments.

## File Layout

All personal shell config goes in `~/.zsh/` as individual `*.zsh` files, sourced from `~/.zshrc`.

| File | Purpose |
|------|---------|
| `~/.zsh/aliases.zsh` | Aliases (modern CLI replacements, update, etc.) |
| `~/.zsh/env.zsh` | PATH, LANG, umask, platform-specific vars |
| `~/.zsh/motd.zsh` | Dynamic MOTD (Ubuntu only — do not create on macOS) |
| `~/.zsh/zoxide.zsh` | zoxide init |

### ~/.zshrc Structure

```zsh
# zinit initialization block (top)
# zinit plugin loading block
# Source custom configs:
for f in ~/.zsh/*.zsh(N); do source $f; done
# Ubuntu command-not-found handler:
[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found
# Starship (bottom):
eval "$(starship init zsh)"
```

## File Definitions

### aliases.zsh

The agent generates this file during Converge. Alias targets must match the actual binary names present after install (see `spec/constraints.md` for bat/fd).

| Alias | Target | Notes |
|-------|--------|-------|
| `ls` | `eza --icons` | |
| `ll` | `eza -la --icons --git` | |
| `lt` | `eza --tree --icons` | |
| `cat` | `bat --paging=never` | binary may be `batcat` — see constraints |
| `fd` | `fd` | binary may be `fdfind` — see constraints |
| `qrencode` | `qrencode -t ansiutf8 -r` | |
| `upip` | upgrade all outdated pip packages | user-only (`--user`) to avoid breaking system packages |
| `u` | `~/bin/update` | |

### env.zsh

The agent generates this file during Converge based on what is actually installed.

- **PATH** must include directories for: user scripts (`~/bin`), user-local binaries (`~/.local/bin`), npm global, and Homebrew (if on macOS). Only add directories that exist. Deduplicate PATH.
- **LANG:** `zh_TW.UTF-8`
- **umask:** `0077` (no group/other access on new files)
- **Ubuntu-only:** set `XAUTHORITY=$HOME/.Xauthority`. On aarch64, set `DOCKER_DEFAULT_PLATFORM=linux/arm64`.

### zoxide.zsh

```zsh
eval "$(zoxide init zsh)"
```

### motd.zsh (Ubuntu only)

```zsh
if [[ -x "/usr/bin/run-parts" ]] && [[ -d "/etc/update-motd.d" ]]; then
    if [[ ! -f "$HOME/.hushlogin" ]]; then
        /usr/bin/run-parts --lsbsysinit /etc/update-motd.d/ 2>/dev/null
    fi
fi
```

## ~/bin/update

The `u` alias delegates to this script. The agent generates it during Converge with `chmod +x`, based on what is actually installed on the machine.

**Intent:** update all installed package managers (Homebrew, apt, snap, etc.), clean up unused packages, and update zinit and all its plugins. Do not use `brew upgrade --greedy`.

## Timezone and Locale

- **Timezone:** `Asia/Taipei`
- **Locale:** Generate `en_US.UTF-8`, `en_GB.UTF-8`, `zh_TW.UTF-8`. Set `LANG=zh_TW.UTF-8`.

## App-specific configuration

See `spec/constraints.md` for install requirements and post-install configuration of individual apps (Docker, tealdeer, npm, Proxmark3, fonts, bat, fd).

## Acceptance Criteria

- New shell starts with no errors
- zsh loads expected prompt and plugins
- Aliases and environment settings are active
- Safe to rerun without duplicating config
- Works with any capable CLI AI agent
- Valid on both macOS and Ubuntu
- No secrets committed
- `~/.install.log` exists and reflects steps taken
