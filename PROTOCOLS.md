# Environment Convergence Protocols

The goal of this project is to maintain a declarative environment state managed by an AI operator (`shell-operator`).

## Project Structure

- `layers/`: Modular configuration layers (e.g., `layers/zsh/`).
- `specs/`: Declarative requirements for the system (`system.md`, `apps.md`, `binaries.md`).
- `brain/`: The AI's operational instructions (`SKILL.md`).

## High-Level Operator Directives

The AI operator is expected to execute the following high-level directives:

### 1. `Converge`
**Goal:** Bring the host system into alignment with the repository state.
- **Process:** Execute **System Synchronization**, **Layer Configuration**, and **Resource Installation**.
- **Outcome:** All specs are applied, layers are symlinked, and `.zshrc` is updated to the target state.

### 2. `Capture`
**Goal:** Extract the current system state into the repository.
- **Process:**
    - Compare `~/.zsh/` files with the `layers/zsh/` directory.
    - Copy any new logic or aliases from the live system into the repo.
    - Detect manually installed packages and suggest adding them to `specs/system.md`.
- **Outcome:** The repository becomes the source of truth for the active local environment.

### 3. `Drift`
**Goal:** Report differences between the repository state and the system reality.
- **Process:**
    - Check if symlinks are intact and pointing to the correct layers.
    - Verify if all packages defined in `specs/` are installed.
    - Diff the contents of `layers/` files against the active system files.
- **Outcome:** A "Drift Report" detailing what is missing or different, without making any changes.

## AI Management Protocols

### 1. System Synchronization
When asked to "Converge" or "Sync Systems":
- **Parse `specs/system.md`**:
    - Common packages: Install directly.
    - `[mac]` prefix: Install via `brew` (Darwin only).
    - `[linux]` prefix: Install via `apt` (Linux only).
    - `brew:apt` format: Use the first name for `brew`, second for `apt`.
- **Parse `specs/apps.md`**: Install via `brew install --cask` (macOS only).
- **Parse `specs/binaries.md`**: Execute the install scripts for the listed tools (Linux only).

### 2. Layer Configuration
- **Symlink layers**:
    - `layers/zsh/env.zsh` -> `~/.zsh/env.zsh`
    - `layers/zsh/aliases.zsh` -> `~/.zsh/aliases.zsh`
- **Initialize `~/.zshrc`**:
    - Ensure `eval "$(starship init zsh)"` is present.
    - Ensure the loop for sourcing `~/.zsh/*.zsh` is correctly configured.

### 3. Resource & Font Installation
- Query the latest release from: `https://api.github.com/repos/enstw/font/releases/latest`.
- Download all `.ttf` assets to:
    - **macOS**: `~/Library/Fonts/`
    - **Linux**: `~/.local/share/fonts/` (and run `fc-cache -f`).
