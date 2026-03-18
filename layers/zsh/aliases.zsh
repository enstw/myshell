alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias lt='eza --tree --icons'
alias qrencode='qrencode -t ansiutf8 -r'
alias u='~/bin/update'

if [[ "$(uname)" == "Darwin" ]]; then
    alias cat='bat --paging=never'
else
    alias cat='batcat --paging=never'
    alias fd='fdfind'
fi

alias upip='pip3 list -o --format=json | python3 -c "import sys,json;[print(p[\"name\"])for p in json.load(sys.stdin)]" | xargs -n1 pip3 install -U'
