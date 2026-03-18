---
name: shell-operator
description: Orchestrates and maintains the 'shell-state' environment. Use to 'Converge' the system to the target state, 'Capture' local changes into the repo, or 'Drift' to report differences between the repo and the active system.
---

# shell-operator

This skill enables the AI to act as a declarative operator for the 'shell-state' environment.

## ⚠️ CRITICAL CONSTRAINT: THE ARCHIVE
- **DO NOT READ `.archive/`**: The AI is strictly forbidden from reading or using content inside the `.archive/` directory. 
- **Legacy & Ignored**: This directory is git-ignored and contains outdated configurations (Oh-My-Zsh, p10k) that must not contaminate the current state.
- **Source of Truth**: Always use `layers/` and `specs/` as the only sources of truth.

## Workflow: `Converge` (The Sync Task)
Bring the host machine into alignment with the repository:
1.  **System Synchronization:**
    - Apply `specs/system.md` using `brew` (Darwin) or `apt` (Linux).
    - Apply `specs/apps.md` using `brew install --cask` (Darwin only).
    - Apply `specs/binaries.md` by executing installation scripts (Linux only).
2.  **Layer Configuration:**
    - Symlink `layers/zsh/env.zsh` -> `~/.zsh/env.zsh`.
    - Symlink `layers/zsh/aliases.zsh` -> `~/.zsh/aliases.zsh`.
    - Update `~/.zshrc` to initialize `starship` and source `~/.zsh/env.zsh`.
3.  **Resource Installation:**
    - Fetch and install the latest `.ttf` fonts from `enstw/font`.

## Workflow: `Capture` (The Snapshot Task)
Update the repository from the live local environment:
1.  **Config Capture:** Detect changes in `~/.zsh/` and propose updates to the `layers/` directory.
2.  **Manifest Update:** Detect manually installed `brew` or `apt` packages and suggest adding them to `specs/system.md`.

## Workflow: `Drift` (The Audit Task)
Report the "drift" between desired and actual state:
1.  **Check Symlinks:** Verify if `~/.zsh/` files correctly point to the `layers/` directory.
2.  **Check Packages:** Verify if all items in `specs/` are installed on the system.
3.  **Content Audit:** Diff the content of active shell files against the repo's versions.

## Reference
See [PROTOCOLS.md](../PROTOCOLS.md) for the detailed management manual.
