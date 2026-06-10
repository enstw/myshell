# myshell bootstrap — work in progress

Two-stage installer so a colleague runs one command on a bare Mac or minimal Ubuntu.

## Status

- `bootstrap` — POSIX-sh stage 1. Installs brew + bash 5 on macOS, refreshes apt on Ubuntu, then `exec`s stage 2.
- `scripts/install` — bash 5 stage 2. Self-documenting; cross-cutting rules live in its header banner.

Both pass `sh -n` / `bash -n`. **Not yet run end-to-end on a real bare box.**

## Done in stage 2

1. Core apps via brew (mac) or apt + upstream installers for uv/starship/eza/glow (Ubuntu).
1. pnpm installed standalone (`get.pnpm.io` curl|sh, both OSes); pnpm provisions the Node LTS runtime via `pnpm runtime set node lts -g` (migrated off deprecated `pnpm env`). No separate node/npm install — this machine is pnpm-only.
1. `batcat`/`fdfind` → `bat`/`fd` symlinks on Ubuntu.
1. zinit cloned to `~/.local/share/zinit/zinit.git`.
1. Writes `~/.zshenv`, `~/.zsh/{aliases,history,zoxide}.zsh`, `~/.zsh/motd.zsh` (Ubuntu), `~/.zshrc`.
1. Copies `scripts/myshell-update` → `~/bin/myshell-update` (aliased to `u`).
1. Fetches `starship.toml` and eza tokyonight `theme.yml`.
1. Prompts for `git user.name` / `user.email`.
1. Locale generation on Ubuntu: `en_US.UTF-8`, `en_GB.UTF-8`, `zh_TW.UTF-8`; default `LANG=zh_TW.UTF-8`, `LANGUAGE=zh_TW:en`.
1. Timezone set to `Asia/Taipei` (systemsetup on mac; timedatectl or `/etc/timezone` fallback on Ubuntu).
1. pnpm global home is `$PNPM_HOME` (`~/.local/share/pnpm`, no-sudo installs); PATH pickup handled in `~/.zshenv`. `npx` is aliased to `pnpm dlx` and a guard function blocks stray `npm`.
1. AI agents prompt — pick numeric combinations (`0` none, `1` Claude, `2` Codex, `3` Claude+Codex) or use `all`, `none`, or comma-separated `claude,codex`. Both install globally via `pnpm add -g` into `$PNPM_HOME`. npm registry reachability is preflighted and optional agent installs fail soft. (Gemini CLI dropped — replaced by the non-node-managed `agy`.)
1. OpenCode — separate opt-in `confirm` after the pnpm agents. Installs the standalone binary via `curl opencode.ai/install | bash -s -- --no-modify-path` into `~/.opencode/bin` (no npm/node, no sudo); PATH pickup in `~/.zshenv`; self-updates via `opencode upgrade` in `myshell-update`. Kept off pnpm to avoid the self-updater-vs-package-manager conflict.
1. Antigravity CLI (`agy`) — the replacement for the retired Gemini CLI, also a separate opt-in `confirm`. Google's standalone Go binary via `curl antigravity.google/cli/install.sh | bash` into `~/.local/bin/agy` (no npm/node, no sudo; `~/.local/bin` already on PATH); self-updates via `agy update` in `myshell-update`. Standalone like OpenCode, not a pnpm agent.
1. tealdeer config written (`auto_update = true`) and page cache fetched with `LANGUAGE=zh_TW:en`.
1. Opt-in ENS font install from `ent.tw/font` (assumes redirect to GitHub releases JSON).
1. Adds zsh to `/etc/shells`, offers `chsh`.
1. Root + no-sudo containers: both stages now route privileged commands through a `$SUDO` shim that is empty when `EUID==0`, `sudo` otherwise, and fails fast with a clear message if non-root and sudo is missing.
1. 2026-06-10 idempotency pass — every stage-2 step is now check-first on re-run: brew/apt bulk installs filter to missing packages only; `configure_git` skips when identity is set; `install_agents` skips probe+menu when both agents are in `pnpm ls -g`; `configure_tealdeer` skips `tldr --update` when the page cache exists; terminal profile checks the current default before `open`; container timezone branch compares `/etc/timezone` first; `set_login_shell` reads the passwd entry (`dscl`/`getent`) instead of stale `$SHELL`. New `fetch_config` helper: `starship.toml` / eza theme still refresh each run, but a fetch failure keeps the existing copy instead of tripping the ERR trap (an offline re-run previously died halfway). Verified with `bash -n` + isolated function tests; shellcheck unavailable on this box; full container round-trip still pending.

## Deferred (not yet in `scripts/install`)

1. `yt-dlp` via `uv tool install`.
1. Optional apps: quarto + TinyTeX, pandoc + xelatex, proxmark3, docker, zed.
1. Ubuntu `command-not-found` data install (`sudo apt install command-not-found && sudo apt update`).

## Known assumptions / risks

1. Ubuntu target is 22.04+ (package names like `bat`, `7zip`, `tealdeer`).
1. `ent.tw/font` is assumed to redirect to the GitHub releases JSON — untested from the script.
1. `chsh` on macOS prompts for the user's login password; acceptable but unavoidable.
1. Stage 1 still needs `apt-get update` to succeed; if a minimal image has no sources configured at all, it'll fail — haven't handled that case. (Missing-sudo on root is now handled via the `$SUDO` shim.)
1. 2026-05-10 fresh Mac bootstrap hit `UNABLE_TO_GET_ISSUER_CERT_LOCALLY` during agent installs, and another run appeared to stop around the Bun installer without the final `Done` line. Stage 2 now forces Homebrew CA postinstall, makes Bun and the pnpm agent installs fail soft, and prints an `ERR` trap diagnostic for unexpected exits.

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
