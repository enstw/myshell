# App Constraints

Requirements the agent must respect when installing or configuring specific apps. The agent should check this file before installing anything from `apps.txt`.

## wezterm

- **macOS:** Install as a GUI application (Homebrew Cask).
- **Ubuntu:** Prefer the official APT repository (apt.fury.io) or the `.deb` package. Flatpak is an alternative if the system supports it.

## docker

- **macOS:** Docker Desktop (GUI app).
- **Ubuntu:** must be `docker-ce` from Docker's official repository, not the `docker.io` snap/apt package.

## tealdeer

Must be the Rust-based tealdeer, not the Python-based `tldr` package. After installing, configure to download and search in `zh_TW` and `en` languages.

## proxmark3

Only install when explicitly requested. Use the RRG/Iceman fork.

## bat

On platforms where the binary is named `batcat`, the agent must ensure the alias or symlink resolves to `bat`.

## fd

On platforms where the binary is named `fdfind`, the agent must ensure the alias or symlink resolves to `fd`.

## npm

Set the global prefix so globally installed packages do not require sudo. PATH must include the npm global bin directory.

## fonts

Fetch the latest `.ttf` files from `https://ent.tw/font` (redirects to the GitHub releases API). Install to `~/Library/Fonts/` (macOS) or `~/.local/share/fonts/` (Ubuntu, then run `fc-cache -f`).
