# Shell State Specification

This file defines the exact desired shell state. The AI agent reads this file and the package lists, then configures the machine accordingly.

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

Use built-in defaults. Do not create `~/.config/starship.toml` unless explicitly requested.

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

# Upgrade all outdated pip packages (user-only to avoid breaking system packages)
alias upip='pip3 list -o --user --format=json | python3 -c "import sys,json;[print(p[\"name\"])for p in json.load(sys.stdin)]" | xargs -n1 pip3 install --user -U'

# System update (delegates to ~/bin/update)
alias u='~/bin/update'
```

### env.zsh

```zsh
export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export LANG=zh_TW.UTF-8
# Restrictive umask: no group/other access on new files
umask 0077

# Ubuntu-only environment
if [[ "$(uname)" != "Darwin" ]]; then
    export XAUTHORITY=$HOME/.Xauthority
    [[ $(uname -m) == "aarch64" ]] && export DOCKER_DEFAULT_PLATFORM=linux/arm64
fi

# Deduplicate PATH
export PATH="$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')"
```

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

The `u` alias delegates to this script. Create it with `chmod +x`:

```sh
#!/usr/bin/env zsh
set -e

update_zinit() {
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
    brew update && brew upgrade
    brew autoremove && brew cleanup
    brew doctor
else
    sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove
    if command -v snap >/dev/null 2>&1; then
        sudo snap refresh
    fi
fi

update_zinit
```

## Timezone and Locale

- **Timezone:** `Asia/Taipei`
- **Locale:** Generate `en_US.UTF-8`, `en_GB.UTF-8`, `zh_TW.UTF-8`. Set `LANG=zh_TW.UTF-8`.

## npm

Set the global prefix so globally installed packages do not require sudo. PATH includes `~/.npm-global/bin` (covered in env.zsh).

## tldr (tealdeer)

After installing, configure tealdeer to download and search in `zh_TW` and `en` languages.

## Docker

- **macOS:** Docker Desktop (GUI).
- **Ubuntu:** must be `docker-ce` from Docker's official repository, not the `docker.io` snap/apt package.

## Proxmark3 (opt-in)

Only install when explicitly requested. Use the RRG/Iceman fork.

## Fonts

Fetch the latest `.ttf` files from `https://ent.tw/font` (redirects to the GitHub releases API). Install to `~/Library/Fonts/` (macOS) or `~/.local/share/fonts/` (Ubuntu, then run `fc-cache -f`). Starship works best with Nerd Fonts.

## Acceptance Criteria

- New shell starts with no errors
- zsh loads expected prompt and plugins
- Aliases and environment settings are active
- Safe to rerun without duplicating config
- Works with any capable CLI AI agent
- Valid on both macOS and Ubuntu
- No secrets committed
- `~/.install.log` exists and reflects steps taken
