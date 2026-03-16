# mac terminal setup

## github
modify .zshrc
```bash
umask 0077
```
change mode
```bash
chmod -R go-rwx .
```
gen key
```bash
mkdir .ssh
chmod go-rwx .ssh
cd .ssh
ssh-key-gen -b 256 -t ed25519
```
.ssh/config
```bash
GSSAPIAuthentication no
ForwardX11Trusted yes
ForwardX11 yes
ServerAliveInterval 300
ServerAliveCountMax 3
ForwardAgent yes

Host github.com
	HostName github.com
	IdentityFile ~/.ssh/id_ed25519
	IdentitiesOnly yes
	User git
```

## homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
## terminal
* change system name
```bash
sudo scutil --set HostName <new host name> 
```
* oh-my-zsh
```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
* add ~/.oh-my-zsh/custom/aliases.zsh
```bash
alias ll='ls -alFG'
alias ubrew='brew autoremove && brew cleanup && brew update && brew upgrade -g && brew cleanup && brew autoremove && brew cleanup ; brew doctor ; omz update ; find ~/.oh-my-zsh/custom/{plugins,themes} -mindepth 1 -maxdepth 1 -type d -exec git -C {} pull \;'
alias qrencode='qrencode -t ansi256utf8 -r'
```
* JetBrains NF Fonts
```bash
brew tap homebrew/cask-fonts
brew install font-jetbrains-mono-nerd-font
```
 * powerlevel10k
```bash
git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```
```
set ZSH_THEME="powerlevel10k/powerlevel10k" in ~/.zshrc.
```
 * zsh-autosuggestion
```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```
edit .zshrc
```
plugins=(git zsh-autosuggestions)
```
* Import terminal profiles.

## misc packages
```bash
brew install --cask xquartz insomnia pulsar
brew install qrencode p7zip glow RfidResearchGroup/proxmark3/proxmark3 ffmpeg jq
```
* Misc configuration
```bash
git config --global user.email "j@roc.one"
git config --global user.name "jz"
```
## linux shell
Read more [here](./README.md)
## docker
```bash
brew install docker
docker context create lima-default --docker "host=unix://$HOME/.lima/default/sock/docker.sock"
docker context use lima-default
```
