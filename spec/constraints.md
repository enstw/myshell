# App Constraints

Requirements the agent must respect when installing or configuring specific apps. The agent should check this file before installing anything from `apps.txt`.

## Python tooling (global rule)

For anything Python-related — packages, virtual environments, or CLI tools — **`uv` is the priority and only sanctioned tool**. Never use `pip`, `pipx`, `python -m venv`, `python -m pip`, `pyenv`, or `poetry`. If an app's official docs specify `pip install` or `pipx install`, translate to the `uv` equivalent (`uv tool install`, `uvx`, or a `uv venv` + `uv pip install --python <venv>/bin/python`) before running.

## git

After installing git, ask the user for their preferred `user.name` and `user.email`, then set them with `git config --global`.

## docker

- **macOS:** Docker Desktop (GUI app).
- **Ubuntu:** must be `docker-ce` from Docker's official repository, not the `docker.io` snap/apt package.

## tealdeer

Must be the Rust-based tealdeer, not the Python-based `tldr` package. After installing, configure to download and search in `zh_TW` and `en` languages.

## proxmark3

Use the RRG/Iceman fork (`brew tap RfidResearchGroup/proxmark3` then `brew install proxmark3`).

## bat

On platforms where the binary is named `batcat`, the agent must ensure the alias or symlink resolves to `bat`.

## fd

On platforms where the binary is named `fdfind`, the agent must ensure the alias or symlink resolves to `fd`.

## eza

Fetch the `tokyonight.yml` theme from `https://github.com/eza-community/eza-themes/blob/main/themes/tokyonight.yml` and deploy it as `theme.yml` to the platform-appropriate configuration directory.

## quarto

- **macOS:** `brew install --cask quarto`
- **Ubuntu:** download the latest `.deb` from <https://quarto.org/docs/download/> and install with `dpkg -i`.

After installing Quarto, also install TinyTeX via `quarto install tinytex`.

## pandoc

Install `pandoc` together with a working `xelatex` engine — pandoc's PDF output (and CJK-friendly typesetting) requires it.

- **macOS:** `brew install pandoc` and ensure a TeX distribution providing `xelatex` is present (e.g. `brew install --cask mactex-no-gui`, or BasicTeX + `tlmgr install xetex`).
- **Ubuntu:** `apt install pandoc texlive-xetex`.

Verify with `pandoc --version` and `xelatex --version`.

## npm

Set the global prefix so globally installed packages do not require sudo. PATH must include the npm global bin directory.

## uv

Install `uv` first — most other Python tooling in this spec depends on it. Use the official installer or the platform package manager:

- **macOS:** `brew install uv`
- **Ubuntu:** `curl -LsSf https://astral.sh/uv/install.sh | sh`

`uv` replaces `pip`, `pipx`, `venv`, and `pyenv`. Never use `pip install --break-system-packages` — create a uv-managed venv or use `uv tool install` instead.

## yt-dlp

CLI tool. Install with `uv tool install yt-dlp` to get the latest version rather than the distro package, which is often outdated. Upgrade with `uv tool upgrade yt-dlp`.

## fonts

Fetch the latest `.ttf` files from `https://ent.tw/font` (redirects to the GitHub releases API). Install to `~/Library/Fonts/` (macOS) or `~/.local/share/fonts/` (Ubuntu, then run `fc-cache -f`).
