#!/bin/zsh
set -e

MYSHELL_DIR="${0:A:h}"

install_brew() {
    [[ "$(uname)" != "Darwin" ]] && return
    if ! command -v brew &>/dev/null; then
        echo "* Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
}

install_packages() {
    echo "* Installing packages"
    local pkgs="$MYSHELL_DIR/packages.txt"

    if [[ "$(uname)" == "Darwin" ]]; then
        local brew_list=()
        while IFS= read -r line; do
            [[ "$line" =~ ^\s*(#|$) ]] && continue
            [[ "$line" =~ ^\[linux\] ]] && continue
            line="${line#\[mac\] }"
            brew_list+=("${line%%:*}")
        done < "$pkgs"
        brew install "${brew_list[@]}"

        local cask_list=()
        while IFS= read -r line; do
            [[ "$line" =~ ^\s*(#|$) ]] && continue
            cask_list+=("$line")
        done < "$MYSHELL_DIR/packages_cask.txt"
        brew install --cask "${cask_list[@]}"
    else
        local apt_list=()
        while IFS= read -r line; do
            [[ "$line" =~ ^\s*(#|$) ]] && continue
            [[ "$line" =~ ^\[mac\] ]] && continue
            line="${line#\[linux\] }"
            apt_list+=("${line##*:}")
        done < "$pkgs"
        sudo apt-get update
        sudo apt-get -y install "${apt_list[@]}"

        # curl-installed packages
        while IFS=: read -r name url; do
            [[ "$name" =~ ^\s*(#|$) ]] && continue
            echo "  Installing $name"
            curl -fsSL "$url" | sh
        done < "$MYSHELL_DIR/packages_curl.txt"
    fi
}

install_omz() {
    echo "* Installing Oh-My-Zsh"
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi
    local custom="$HOME/.oh-my-zsh/custom"
    [[ -d "$custom/plugins/zsh-autosuggestions" ]] || \
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
    [[ -d "$custom/themes/powerlevel10k" ]] || \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$custom/themes/powerlevel10k"
}

setup_zshrc() {
    echo "* Configuring ~/.zshrc"
    local zshrc="$HOME/.zshrc"
    [[ -f "$zshrc" ]] || touch "$zshrc"

    # Prepend p10k instant prompt if missing
    if ! grep -q 'p10k-instant-prompt' "$zshrc"; then
        local tmp=$(mktemp)
        cat > "$tmp" <<'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

EOF
        cat "$zshrc" >> "$tmp" && mv "$tmp" "$zshrc"
    fi

    # Set ZSH_THEME
    if grep -q '^ZSH_THEME=' "$zshrc"; then
        sed -i.bak 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$zshrc"
    fi

    # Set plugins (guarded block)
    local plugins_block='# BEGIN myshell\nplugins=(\n  git\n  python\n  docker\n  history-substring-search\n  zsh-autosuggestions\n)\n# END myshell'
    if grep -q '# BEGIN myshell' "$zshrc"; then
        perl -i -0pe 's/# BEGIN myshell.*?# END myshell/'"$plugins_block"'/s' "$zshrc"
    elif grep -q '^plugins=' "$zshrc"; then
        perl -i -0pe 's/^plugins=\(.*?\)/'"$plugins_block"'/s' "$zshrc"
    else
        printf '\n%b\n' "$plugins_block" >> "$zshrc"
    fi

    # Symlink aliases
    ln -sf "$MYSHELL_DIR/aliases.zsh" "$HOME/.oh-my-zsh/custom/aliases.zsh"

    # Append source line
    local source_line="source $MYSHELL_DIR/env.zsh"
    if ! grep -qF "$source_line" "$zshrc"; then
        printf '\n%s\n' "$source_line" >> "$zshrc"
    fi

    rm -f "$zshrc.bak"

    # Copy p10k config if not already present
    if [[ ! -f "$HOME/.p10k.zsh" ]]; then
        cp "$MYSHELL_DIR/p10k.zsh" "$HOME/.p10k.zsh"
        echo "* Copied p10k config. Run 'p10k configure' to customize."
    fi
}

install_fonts() {
    echo "* Installing fonts"
    local api="https://api.github.com/repos/enstw/font/releases/latest"
    local urls
    urls=$(curl -fsSL "$api" | grep -o 'https://[^"]*\.ttf')

    if [[ "$(uname)" == "Darwin" ]]; then
        local font_dir="$HOME/Library/Fonts"
    else
        local font_dir="$HOME/.local/share/fonts"
        mkdir -p "$font_dir"
    fi

    echo "$urls" | while read -r url; do
        local name=$(basename "$url")
        echo "  Downloading $name"
        curl -fsSL "$url" -o "$font_dir/$name"
    done

    [[ "$(uname)" != "Darwin" ]] && fc-cache -f "$font_dir"
    echo "* Fonts installed"
}

# Main
install_brew
install_packages
install_omz
setup_zshrc
install_fonts

echo "* Done. Restart your shell or run: source ~/.zshrc"
