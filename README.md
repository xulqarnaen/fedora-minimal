# linux-minimal

A minimal Linux desktop setup built around **Hyprland**, with reproducible installation scripts for **Arch Linux** and **Fedora**.

The goal is simple: start from a relatively bare system and get to a lightweight, functional Wayland desktop without dragging along a full desktop environment or a pile of unnecessary software.

## Features

- 🪟 **Hyprland** — Wayland compositor
- 🎨 **Noctalia** — desktop shell and theming
- 🔐 **greetd + Noctalia Greeter** — graphical login
- 🚀 **UWSM** — Wayland session management
- 🐟 **Fish** — interactive shell
- 🦶 **Foot** — terminal emulator
- 📝 **Neovim** — editor
- 🌐 **Brave Origin** — web browser
- 📁 **Nautilus** — file manager
- 🎵 **mpv** — media playback 
- 📸 **GPU Screen Recorder** — screen recording
- 🔤 **JetBrains Mono Nerd Font**
- 🖼️ **imv** — image viewer
- 📄 **Evince** — PDF viewer
- 🔒 **UFW** — firewall
- 📋 **wl-clip-persist** — Wayland clipboard persistence
- ⭐ **Starship** — shell prompt

The configuration also includes Hyprland rules, keybindings, Noctalia configuration, wallpapers, and user-local utilities.

## Supported Systems

| Distribution | Installer | Status |
|---|---|---|
| Arch Linux | `arch.sh` | Supported |
| Fedora Linux | `fedora.sh` | Supported |

The scripts are intended for **fresh or minimally configured installations** rather than existing desktop environments.

## Installation

### Arch Linux

Install a minimal Arch system first, then clone this repository:

```bash
git clone https://github.com/xulqarnaen/linux-minimal.git
cd linux-minimal
sudo ./arch.sh
```

The Arch installer uses `pacman` for official packages and an AUR helper for packages that are not available in the official repositories.

### Fedora Linux

Install a minimal Fedora system first, then:

```bash
git clone https://github.com/xulqarnaen/linux-minimal.git
cd linux-minimal
sudo ./fedora.sh
```

The Fedora installer uses `dnf` and configures the additional repositories required by the setup.

Both installers perform environment checks before making changes and require the repository to contain the expected configuration tree.

## What the Installers Do

The installers are deliberately more than package lists. They configure the system into a usable desktop environment.

### System setup

Depending on the distribution, the installer handles:

- System package updates
- Required repositories
- Core desktop packages
- Hyprland
- Wayland portals
- PipeWire audio
- Bluetooth
- Power management
- Firewall configuration
- greetd
- Noctalia Greeter
- UWSM

### User configuration

The repository's configuration is deployed into the user's home directory:

```text
~/.config/
~/.local/
```

The installers also configure application defaults and other desktop integration where required.

### Fonts

The setup installs **JetBrains Mono Nerd Font** system-wide.

## Repository Structure

```text
linux-minimal/
├── .config/          # Desktop and application configuration
├── .local/bin/       # User-local scripts and utilities
├── walls/            # Wallpapers
├── arch.sh           # Arch Linux installer
├── fedora.sh         # Fedora Linux installer
└── README.md
```

## Design Philosophy

This project is intentionally opinionated.

It is **not** intended to provide every possible desktop application or configuration option. The point is to keep the base small while providing the components needed for a practical daily-driver Wayland desktop.

The setup favors:

- Minimal dependencies
- Native packages
- Wayland-first software
- Explicit configuration
- Simple shell scripts
- Reproducible setup
- No traditional desktop environment
- No unnecessary services

You should be able to read the script and understand what it is doing.

## Important

These scripts modify your system.

They can:

- Install and remove packages
- Enable and disable services
- Modify system configuration
- Replace configuration files
- Change the user's default shell
- Configure the login manager
- Configure firewall rules
- Install system-wide fonts

**Read the relevant installer before running it.**

This project is best suited to a fresh installation where the configuration can be applied without conflicting with an existing desktop environment.

## Customization

The repository is intended to be forked and modified.

Most user-facing configuration lives under:

```text
.config/
.local/
walls/
```

The installers can also be edited directly if you want to change the package set or system setup.

For example, package lists are explicitly defined in the installer scripts rather than generated dynamically, making them easy to audit and modify.

## Contributing

There is no strict contribution framework yet.

If you find a bug or have an improvement:

1. Open an issue describing the problem.
2. Include relevant command output or logs.
3. If possible, submit a pull request with the fix.

Keep changes focused and avoid adding dependencies unless they provide a clear benefit.

## License

See the repository's license file for licensing information.
