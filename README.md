# Arch Linux Installation Script

Automated post-installation setup for Arch Linux with a Hyprland desktop environment, Catppuccin Macchiato theming, and development tooling. Supports both full desktop installs and WSL environments.

## Quick Start

### Install from the web (fresh Arch system)

```bash
curl -fsSL https://raw.githubusercontent.com/ofrogon/linux-arch/refs/heads/main/boot.sh | bash
```

### Install from a local clone

```bash
./boot.sh
```

### Run directly (if already cloned)

```bash
./run.sh
```

## Options

### WSL Mode

To install only the WSL-compatible subset (dotfiles, shell config — no desktop packages):

```bash
./run.sh --wsl-only
```

After the WSL setup completes, you'll be given instructions to configure your distro on the Windows side:

```
wsl --manage archlinux --set-default-user <username>
wsl --set-default archlinux
```

### Interactive Prompts

The script will interactively ask for:

| Prompt | Description |
|--------|-------------|
| **Username** | Local user account name |
| **Git email** | Email for git configuration |
| **Git name** | Display name for git commits |
| **Nvidia** (y/N) | Install Nvidia open-dkms drivers and configure GPU symlinks |
| **Steam** (y/N) | Install Steam with Gamescope and Nvidia utils (requires Nvidia) |

### Bootstrap Environment Variables

When using `boot.sh`, you can override the source repository and branch:

```bash
OFROGON_REPO="youruser/your-fork" OFROGON_REF="dev-branch" \
  curl -fsSL https://raw.githubusercontent.com/ofrogon/linux-arch/refs/heads/main/boot.sh | bash
```

| Variable | Default | Description |
|----------|---------|-------------|
| `OFROGON_REPO` | `ofrogon/linux-arch` | GitHub repository to clone |
| `OFROGON_REF` | `main` | Branch or ref to checkout |

## What Gets Installed

### Full Desktop Setup

| Category | Highlights |
|----------|------------|
| **Desktop** | Hyprland, Waybar, Hyprlock, Hyprpaper, Hypridle, Walker, Plymouth |
| **Apps** | Ghostty, Nautilus, Firefox, Chromium, Discord, Signal, Obsidian, LibreOffice, GIMP, mpv |
| **Audio** | PipeWire (with ALSA, JACK, PulseAudio compat), WirePlumber, SwayOSD |
| **Dev tools** | Neovim, Git, Lazygit, Clang, GCC, Cargo/Rust, .NET SDK 10.0, mise |
| **Terminal** | ZSH, Starship, fzf, ripgrep, bat, eza, fd, zoxide, tmux, stow |
| **Fonts** | JetBrains Mono Nerd, Font Awesome |
| **Theme** | Catppuccin Macchiato (cursors, Plymouth boot screen) |
| **Networking** | iwd, Avahi/mDNS, UFW firewall, WPA |
| **Printing** | CUPS with PDF and network printer discovery |
| **Nvidia** *(optional)* | nvidia-open-dkms, nvidia-settings, libva-nvidia-driver |
| **Steam** *(optional)* | Steam, Gamescope, lib32-nvidia-utils |
| **Razer** | mkinitcpio-firmware |

### WSL Setup

Installs dotfiles only (via [ofrogon/dotfiles](https://github.com/ofrogon/dotfiles) + GNU Stow).

## Utilities

### PWA Desktop File Creator

A standalone tool to create `.desktop` launchers for web apps:

```bash
./utilities/create_desktop_file.sh -n "Notion" -u https://www.notion.so/ -i ~/icons/notion.png
```

Run with `--help` for all options. Supports interactive mode (just run without arguments) or fully non-interactive with `--no-prompt`.

## Project Structure

```
boot.sh              # Remote bootstrap entry point
run.sh               # Main orchestrator script
packages/            # Package lists (bash arrays in .conf files)
install/             # Individual setup scripts (sourced by run.sh)
utilities/
  utils.sh           # Shared helpers (install, logging, file ops)
  logo.sh            # ASCII logo
  create_desktop_file.sh  # Standalone PWA launcher creator
```
