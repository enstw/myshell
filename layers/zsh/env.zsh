#!/bin/zsh
# Sourced by ~/.zshrc — managed by myshell

export PATH="$HOME/bin:$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export LANG=en_US.UTF-8
umask 0077

# p10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
