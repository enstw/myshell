# myshell bootstrap — work in progress

Two-stage installer so a colleague runs one command on a bare Mac or minimal Ubuntu.

## Status

- `bootstrap` — POSIX-sh stage 1. Installs brew + bash 5 on macOS, refreshes apt on Ubuntu, then runs stage 2 (no `exec` — the cleanup trap must outlive it).
- `scripts/install` — bash 5 stage 2. Self-documenting; cross-cutting rules live in its header banner.

CI (GitHub Actions) runs `scripts/check` plus two headless container round-trips — sudo user and root, both in minimized `ubuntu:24.04`, fresh run + idempotent re-run, asserting zero warnings — on every push. **Green since 2026-07-04** (run 28699567420 was the first green in the workflow's history — every earlier run failed the zero-warning gate). **Not yet run end-to-end on a real bare Mac.**

Completed work and resolved incidents are archived in [.archive/TODO-done.md](.archive/TODO-done.md) (and `git log`); current behavior is documented by the `scripts/install` header banner and `README.md`.

## Deferred (not yet in `scripts/install`)

1. `yt-dlp` via `uv tool install`.
1. Optional apps: quarto + TinyTeX, pandoc + xelatex, proxmark3, zed. (docker: done 2026-07-04 — Ubuntu `docker.io` + docker group; macOS colima + docker CLI formulae, `colima start` boots the daemon. Untested until the bare-Mac leg.) Pattern when these land: one `choose_optional_apps` menu recorded like the agents answer, per-app `install_` functions per the header's step grammar, `apt_keyring_repo` for any new third-party repos — no data-driven package table (that's the abandoned `.archive/setup.sh` design).
1. Ubuntu `command-not-found` data install (`sudo apt install command-not-found && sudo apt update`).
1. Headless/non-interactive mode — `ask`/`confirm` need `/dev/tty`, so a tty-less run dies at the first question (via the ERR trap). `scripts/ci-roundtrip` pre-seeds `~/.local/state/myshell/*` and git identity (that is how CI runs headless); a `--yes`-style flag would be cleaner for humans.
1. `myshell` dispatcher (`myshell update|sync|agents`) — deliberately deferred until a third user-facing verb exists; today `u` + re-running bootstrap cover the whole post-install surface.
1. CI: set `MYSHELL_CI_AGENTS=claude` on one job to exercise the agent installers; a `macos-latest` job for the brew path.

## Known assumptions / risks

1. Ubuntu target is 22.04+ (package names like `bat`, `7zip`, `tealdeer`).
1. `chsh` on macOS prompts for the user's login password; acceptable but unavoidable (it is the last step, so the unattended phase is not interrupted).
1. Stage 1 still needs `apt-get update` to succeed; if a minimal image has no sources configured at all, it'll fail — haven't handled that case. (Missing-sudo on root is now handled via the `$SUDO` shim.)

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
1. Headless variant (what CI runs): `scripts/ci-roundtrip` inside the container — seeds the recorded answers, runs bootstrap twice, asserts artifacts + zero warnings. The two commands above stay the *interactive* round-trip (run them from macOS Docker Desktop too).
1. Fresh Mac: harder to sandbox; test on a spare account or VM.
1. To iterate fast on stage 2 only: run `scripts/install` directly under an existing bash 5.

## Where to pick up

(2026-07-04)

1. **CI went green for the first time on 2026-07-04** (run 28699567420) after fixing every warning the zero-warning gate had tripped on since 2026-06-14 — full details in `git log` for that day: starship config renamed upstream (now fetches `starship-tokyo-night.toml`, install-once), sudoers drop-in skipped as root, tealdeer < 1.7's dead update URL worked around by seeding the page cache directly, one retry for the pnpm installer download, and `SHELL` exported to that installer (its rc step dies with `ERR_PNPM_UNKNOWN_SHELL` in no-login-env root containers). Both containers now pass fresh + idempotent re-run + the headless no-answer abort.
1. The 2026-06-12 unknowns are settled by the same CI logs: Node LTS via pnpm 11 works (root job reaches "Node LTS active (v24.18.0)") and `yes | unminimize` completes cleanly in the minimized container (fresh run reaches `Done` with no unminimize warning).
1. **Owner (jz): run the interactive docker round-trips on macOS Docker Desktop** — the two commands in "How to resume / test" above. CI covers the headless path; the interactive prompt phase (gather_answers on a real tty: git identity, agent menu, fonts, chsh) is what these exercise.
1. After both are green, the remaining untested leg is a fresh bare Mac (brew path, Terminal profile, fonts).
1. Then resume the deferred items (yt-dlp, optional apps, command-not-found) on a tested base — each new step follows the contract in the `scripts/install` header.
