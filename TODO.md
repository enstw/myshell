# myshell bootstrap — work in progress

Two-stage installer so a colleague runs one command on a bare Mac or minimal Ubuntu.

## Status

- `bootstrap` — POSIX-sh stage 1. Installs brew + bash 5 on macOS, refreshes apt on Ubuntu, then runs stage 2 (no `exec` — the cleanup trap must outlive it).
- `scripts/install` — bash 5 stage 2. Self-documenting; cross-cutting rules live in its header banner.

CI (GitHub Actions) runs `scripts/check` and `scripts/test-prompts`, plus three headless round-trips — sudo user and root in minimized `ubuntu:24.04` containers, and a `macos-latest` runner leg — fresh run + idempotent re-run, asserting zero warnings, on every push. **All green since 2026-07-04.** **Not yet run end-to-end on a real bare Mac** (a runner is not bare). The prompt layer itself is now covered by `scripts/test-prompts`, which drives it under a real pty.

Completed work and resolved incidents are archived in [.archive/TODO-done.md](.archive/TODO-done.md) (and `git log`); current behavior is documented by the `scripts/install` header banner and `README.md`.

## Deferred (not yet in `scripts/install`)

1. `yt-dlp` via `uv tool install`.
1. Optional apps: quarto + TinyTeX, pandoc + xelatex, proxmark3, zed. Pattern when these land: one `choose_optional_apps` menu recorded like the agents answer, per-app `install_` functions per the header's step grammar, `apt_keyring_repo` for any new third-party repos — no data-driven package table (that's the abandoned `.archive/setup.sh` design).
1. Ubuntu `command-not-found` data install (`sudo apt install command-not-found && sudo apt update`).
1. A `--yes`-style flag that accepts every default — optional sugar; answer-store seeding is already the documented headless interface (README "Headless / unattended"). Stage 2's flag surface is otherwise deliberately just `--phase` / `--list-phases` / `--help`.
1. `myshell` dispatcher (`myshell update|sync|agents`) — deliberately deferred until a third user-facing verb exists; today `u` + re-running bootstrap cover the whole post-install surface.
1. CI: set `MYSHELL_CI_AGENTS=claude` on one job to exercise the agent installers.

## Known assumptions / risks

1. Ubuntu target is 22.04+ (package names like `bat`, `7zip`, `tealdeer`).
1. `chsh` runs as `sudo chsh -s <shell> <user>` (PAM's root bypass) since 2026-08-31, so a warm sudo covers it and the step is headless-safe; only the no-sudo fallback still reads a password from `/dev/tty`. It now lives in the `shell` phase rather than at the very end of the run.
1. Stage 1 still needs `apt-get update` to succeed; if a minimal image has no sources configured at all, it'll fail — haven't handled that case. (Missing-sudo on root is now handled via the `$SUDO` shim.)
1. `configure_terminal_profile_macos` used to re-open Terminal on every re-run. Diagnosed 2026-09-01 from run 33410797061: the fresh run set `Default Window Settings`, the re-run 43s later could not see it and re-imported, and a third run 1.5s after that one could — i.e. a cold-launching Terminal writes its own preferences *after* our `defaults write` at `sleep 1` and clobbers it. Fixed by keying the import on whether the profile exists (not on whether it is the default) and polling for Terminal's own write instead of sleeping. The already-imported branch is verified on a real Mac; the cold-import branch is only exercised by the macOS CI leg. The read-back after `defaults write` reports via `sublog` — promote it to `warn` once that leg shows a clean re-run.

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
1. Headless variant (what CI runs): `scripts/ci-roundtrip` inside the container — seeds the recorded answers, runs bootstrap twice, asserts artifacts + zero warnings. The two commands above are the same thing with the prompts left in, if you ever want to watch a run interactively.
1. Fresh Mac: harder to sandbox; test on a spare account or VM.
1. To iterate fast on stage 2 only: run `scripts/install` directly under an existing bash 5.

## Where to pick up

(2026-08-31)

1. The remaining untested leg is a fresh bare Mac (brew path, Terminal profile, fonts). CI's `roundtrip-macos` runs on a runner, which is not bare.
1. Resume the deferred items (yt-dlp, optional apps, command-not-found) — each new step follows the contract in the `scripts/install` header, and joins one of the six phases.
