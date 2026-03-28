# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Arch Linux post-installation setup script collection ("XOBRUX"). It automates system configuration for a Hyprland desktop environment with Catppuccin theming, Nvidia support, and development tooling. The scripts are designed to run on a fresh Arch Linux install (or WSL).

## Entry Points

- **`boot.sh`** — Remote bootstrap: clones this repo and invokes `run.sh`. Meant to be piped from curl on a fresh system.
- **`run.sh`** — Main orchestrator: prompts the user for config (username, git info, Nvidia/Steam), sources package lists, installs packages, then runs install scripts in sequence. Supports `--wsl-only` flag for WSL-specific subset.

## Architecture

### Execution Flow

`boot.sh` → clones repo → `run.sh` → sources `utilities/utils.sh` + `utilities/logo.sh` → sources all `packages/*.conf` → installs packages via `yay` → runs `install/*.sh` scripts in order.

### Directory Layout

- **`packages/`** — `.conf` files defining bash arrays of package names (e.g., `DEVELOPMENT`, `HYPRLAND`, `NVIDIA`). Each file is `source`d by `run.sh` to populate arrays passed to `install_packages`.
- **`install/`** — Individual setup scripts for specific subsystems (pacman, dotfiles, git, theme, plymouth, networking, etc.). These are sourced (`. script.sh`) from `run.sh`, not executed as subprocesses.
- **`utilities/`** — Shared helper functions:
  - `utils.sh` — Package management (`install_package`, `install_packages`, `is_installed`), logging (`info`, `warn`, `err`, `ok`, `die`), file helpers (`backup_file`, `restore_backup_file`, `add_or_update_block`, `ensure_dir`), and `have_cmd` for command detection.
  - `logo.sh` — ASCII logo printer.
  - `create_desktop_file.sh` — Standalone CLI tool to create PWA `.desktop` launchers.

### Conventions

- Install scripts source `../utilities/utils.sh` for shared functions — always use `install_package`/`install_packages` (which check before installing) rather than calling `yay`/`pacman` directly.
- Use logging helpers (`info`, `warn`, `err`, `ok`, `die`) from `utils.sh` for consistent output.
- Package lists in `packages/*.conf` are plain bash arrays — one package per line, alphabetically sorted.
- Install scripts that need root use `require_root` from `utils.sh`.
- The `have_cmd` function checks command availability — use it instead of `which` or `command -v` directly.

## Shell Script Style

- All scripts use `#!/bin/bash`
- Use `set -e` or `set -euo pipefail` for error handling
- Quote variables, use `[[ ]]` for conditionals
- No build system, linter, or test suite — validate by reading and tracing script logic
