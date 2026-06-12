# myshell bootstrap — work in progress

Two-stage installer so a colleague runs one command on a bare Mac or minimal Ubuntu.

## Status

- `bootstrap` — POSIX-sh stage 1. Installs brew + bash 5 on macOS, refreshes apt on Ubuntu, then runs stage 2 (no `exec` — the cleanup trap must outlive it).
- `scripts/install` — bash 5 stage 2. Self-documenting; cross-cutting rules live in its header banner.

CI (GitHub Actions) runs `scripts/check` plus two headless container round-trips — sudo user and root, both in minimized `ubuntu:24.04`, fresh run + idempotent re-run, asserting zero warnings — on every push. **Not yet run end-to-end on a real bare Mac.**

Completed work and resolved incidents are archived in [.archive/TODO-done.md](.archive/TODO-done.md) (and `git log`); current behavior is documented by the `scripts/install` header banner and `README.md`.

## Deferred (not yet in `scripts/install`)

1. `yt-dlp` via `uv tool install`.
1. Optional apps: quarto + TinyTeX, pandoc + xelatex, proxmark3, docker, zed.
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

(2026-06-12 handoff)

1. **Watch the first CI run** (triggered by this push — `.github/workflows/ci.yml`). It will answer the two open unknowns nobody has verified on a real box: whether `pnpm runtime set node lts -g` is the correct pnpm 11 subcommand, and whether `yes | unminimize` completes cleanly in a minimized `ubuntu:24.04` container. Both are asserted by `scripts/ci-roundtrip` (zero-warning gate), so a red job pinpoints the step.
1. **Owner (jz): run the interactive docker round-trips on macOS Docker Desktop** — the two commands in "How to resume / test" above. CI covers the headless path; the interactive prompt phase (gather_answers on a real tty: git identity, agent menu, fonts, chsh) is what these exercise.
1. After both are green, the remaining untested leg is a fresh bare Mac (brew path, Terminal profile, fonts).
1. Then resume the deferred items (yt-dlp, optional apps, command-not-found) on a tested base — each new step follows the contract in the `scripts/install` header.
