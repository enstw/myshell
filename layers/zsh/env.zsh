#!/bin/zsh
# Sourced by ~/.zshrc — managed by shell-state

export PATH="$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export LANG=zh_TW.UTF-8

# Restrictive umask: no group/other access on new files.
umask 0077

if [[ "$(uname)" != "Darwin" ]]; then
    export XAUTHORITY="$HOME/.Xauthority"
    [[ "$(uname -m)" == "aarch64" ]] && export DOCKER_DEFAULT_PLATFORM=linux/arm64
fi

# Deduplicate PATH entries while preserving order.
export PATH="$(perl -e 'print join(":", grep { not $seen{$_}++ } split(/:/, $ENV{PATH}))')"
