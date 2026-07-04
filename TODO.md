# myshell bootstrap — work in progress

Two-stage installer so a colleague runs one command on a bare Mac or minimal Ubuntu.

## Status

- `bootstrap` — POSIX-sh stage 1. Installs brew + bash 5 on macOS, refreshes apt on Ubuntu, then runs stage 2 (no `exec` — the cleanup trap must outlive it).
- `scripts/install` — bash 5 stage 2. Self-documenting; cross-cutting rules live in its header banner.

CI (GitHub Actions) runs `scripts/check` plus three headless round-trips — sudo user and root in minimized `ubuntu:24.04` containers, and a `macos-latest` runner leg — fresh run + idempotent re-run, asserting zero warnings, on every push. **Ubuntu green since 2026-07-04** (run 28699567420 was the first green in the workflow's history — every earlier run failed the zero-warning gate); **macOS green on its first attempt the same day** (run 28700816193), including first-ever real exercise of the purge paths (removed `brew:pipx`, `brew:node@24` from the runner image). **Not yet run end-to-end on a real bare Mac** (a runner is not bare, and the interactive prompt phase is untested).

Completed work and resolved incidents are archived in [.archive/TODO-done.md](.archive/TODO-done.md) (and `git log`); current behavior is documented by the `scripts/install` header banner and `README.md`.

## Deferred (not yet in `scripts/install`)

1. `yt-dlp` via `uv tool install`.
1. Optional apps: quarto + TinyTeX, pandoc + xelatex, proxmark3, zed. (docker: done 2026-07-04 — Ubuntu `docker.io` + docker group; macOS colima + docker CLI formulae, `colima start` boots the daemon. Untested until the bare-Mac leg.) Pattern when these land: one `choose_optional_apps` menu recorded like the agents answer, per-app `install_` functions per the header's step grammar, `apt_keyring_repo` for any new third-party repos — no data-driven package table (that's the abandoned `.archive/setup.sh` design).
1. Ubuntu `command-not-found` data install (`sudo apt install command-not-found && sudo apt update`).
1. Headless/non-interactive mode — largely settled 2026-07-04: pre-seeding the answer store + git identity is now the documented, supported interface (README "Headless / unattended" + the install header's answers rule; `scripts/ci-roundtrip` is the reference). A `--yes`-style flag that accepts every default remains optional sugar on top.
1. `myshell` dispatcher (`myshell update|sync|agents`) — deliberately deferred until a third user-facing verb exists; today `u` + re-running bootstrap cover the whole post-install surface.
1. CI: set `MYSHELL_CI_AGENTS=claude` on one job to exercise the agent installers. (The `macos-latest` round-trip landed 2026-07-04, went green on its first run, and now gates pushes like the Ubuntu legs.)

## Known assumptions / risks

1. Ubuntu target is 22.04+ (package names like `bat`, `7zip`, `tealdeer`).
1. `chsh` on macOS prompts for the user's login password; acceptable but unavoidable (it is the last step, so the unattended phase is not interrupted).
1. Stage 1 still needs `apt-get update` to succeed; if a minimal image has no sources configured at all, it'll fail — haven't handled that case. (Missing-sudo on root is now handled via the `$SUDO` shim.)
1. `configure_terminal_profile`'s check-first guard (`defaults read com.apple.Terminal`) did not hold on the macOS CI runner — the re-run re-opened Terminal and re-wrote the default (run 28700816193; no warning, so the gate still passed). Unverified whether a real Mac behaves the same; investigate before trusting that step's idempotency.

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
