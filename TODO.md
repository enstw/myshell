# myshell bootstrap — work in progress

Two-stage installer so a colleague runs one command on a bare Mac or minimal Ubuntu.

## Status

- `bootstrap` — POSIX-sh stage 1. Installs brew + bash 5 on macOS, refreshes apt on Ubuntu, then `exec`s stage 2.
- `scripts/install` — bash 5 stage 2. Self-documenting; cross-cutting rules live in its header banner.

Both pass `sh -n` / `bash -n`. **Not yet run end-to-end on a real bare box.**

## Done in stage 2

1. Core apps via brew (mac) or apt + upstream installers for uv/starship/eza/glow (Ubuntu).
1. node+npm installed (brew `ca-certificates node` on mac, apt `nodejs npm` on Ubuntu).
1. `batcat`/`fdfind` → `bat`/`fd` symlinks on Ubuntu.
1. zinit cloned to `~/.local/share/zinit/zinit.git`.
1. Writes `~/.zshenv`, `~/.zsh/{aliases,history,zoxide}.zsh`, `~/.zsh/motd.zsh` (Ubuntu), `~/.zshrc`.
1. Copies `scripts/myshell-update` → `~/bin/myshell-update` (aliased to `u`).
1. Fetches `starship.toml` and eza tokyonight `theme.yml`.
1. Prompts for `git user.name` / `user.email`.
1. Locale generation on Ubuntu: `en_US.UTF-8`, `en_GB.UTF-8`, `zh_TW.UTF-8`; default `LANG=zh_TW.UTF-8`, `LANGUAGE=zh_TW:en`.
1. Timezone set to `Asia/Taipei` (systemsetup on mac; timedatectl or `/etc/timezone` fallback on Ubuntu).
1. npm global prefix set to `~/.npm-global` (no-sudo installs); PATH pickup already handled in `~/.zshenv`.
1. AI agents prompt — pick numeric combinations (`0` none, `1` Claude, `2` Codex, `3` Claude+Codex, `4` Gemini, `5` Gemini+Claude, `6` Gemini+Codex, `7` all) or use `all`, `none`, or comma-separated `claude,gemini,codex`. All install globally via npm into `~/.npm-global` (gemini's self-update only works on global installs). npm registry TLS is preflighted and optional agent installs fail soft.
1. tealdeer config written (`auto_update = true`) and page cache fetched with `LANGUAGE=zh_TW:en`.
1. Opt-in ENS font install from `ent.tw/font` (assumes redirect to GitHub releases JSON).
1. Adds zsh to `/etc/shells`, offers `chsh`.
1. Root + no-sudo containers: both stages now route privileged commands through a `$SUDO` shim that is empty when `EUID==0`, `sudo` otherwise, and fails fast with a clear message if non-root and sudo is missing.

## Deferred (not yet in `scripts/install`)

1. `yt-dlp` via `uv tool install`.
1. Optional apps: quarto + TinyTeX, pandoc + xelatex, proxmark3, docker, zed.
1. Ubuntu `command-not-found` data install (`sudo apt install command-not-found && sudo apt update`).

## Known assumptions / risks

1. Ubuntu target is 22.04+ (package names like `bat`, `7zip`, `tealdeer`).
1. `ent.tw/font` is assumed to redirect to the GitHub releases JSON — untested from the script.
1. `chsh` on macOS prompts for the user's login password; acceptable but unavoidable.
1. Stage 1 still needs `apt-get update` to succeed; if a minimal image has no sources configured at all, it'll fail — haven't handled that case. (Missing-sudo on root is now handled via the `$SUDO` shim.)
1. 2026-05-10 fresh Mac bootstrap hit `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` during npm agent installs, and another run appeared to stop around the Bun installer without the final `Done` line. Stage 2 now forces Homebrew CA postinstall, makes Bun and npm agents fail soft, and prints an `ERR` trap diagnostic for unexpected exits.

## How to resume / test

1. Fresh Ubuntu 24.04 container:
   ```sh
   docker run --rm -it -v "$PWD":/myshell ubuntu:24.04 bash -c \
     'apt-get update && apt-get install -y sudo curl git && useradd -m -s /bin/bash t && \
      echo "t ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers && su - t -c "cp -r /myshell ~/myshell && ~/myshell/bootstrap"'
   ```
1. Root + no-sudo container (exercises the `$SUDO` shim):
   ```sh
   docker run --rm -it -v "$PWD":/myshell ubuntu:24.04 bash -c \
     'apt-get update && apt-get install -y curl git && cp -r /myshell /root/myshell && /root/myshell/bootstrap'
   ```
1. Fresh Mac: harder to sandbox; test on a spare account or VM.
1. To iterate fast on stage 2 only: run `scripts/install` directly under an existing bash 5.

## Where to pick up

Decide whether to:

- (a) Smoke-test what's there on a container before adding more, or
- (b) Keep layering in the deferred items, then test once.

Leaning (a) — container round-trip will expose path/sudo/apt issues faster than reading.
