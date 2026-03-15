alias ll='ls -alFG'
alias qrencode='qrencode -t ansiutf8 -r'

if [[ "$(uname)" == "Darwin" ]]; then
    alias u='brew autoremove && brew cleanup && brew update && brew upgrade -g && brew cleanup && brew autoremove && brew cleanup ; brew doctor ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \; ; omz update'
else
    alias u='sudo apt update && sudo apt -y full-upgrade && sudo apt -y autoremove ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \; ; omz update'
fi
