#!/usr/bin/env bash

set -u
set -o pipefail

export LC_MESSAGES=C
export LANG=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# ============================================================
# 1. Privileges and Environment Checks
# ============================================================

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (or via sudo)." >&2
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    echo "ERROR: dnf/dnf5 was not found. This installer requires Fedora." >&2
    exit 1
fi

if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
    ACTUAL_USER="$SUDO_USER"
else
    ACTUAL_USER="$(logname 2>/dev/null || true)"
fi

if [[ -z "$ACTUAL_USER" || "$ACTUAL_USER" == "root" ]]; then
    echo "ERROR: Could not determine a non-root target user." >&2
    echo "Run this script via sudo from your normal account." >&2
    exit 1
fi

if ! ACTUAL_USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"; then
    echo "ERROR: Could not determine home directory for user '$ACTUAL_USER'." >&2
    exit 1
fi

if [[ -z "$ACTUAL_USER_HOME" || ! -d "$ACTUAL_USER_HOME" ]]; then
    echo "ERROR: Could not determine valid home directory for user '$ACTUAL_USER'." >&2
    exit 1
fi

if ! ACTUAL_USER_GROUP="$(id -gn "$ACTUAL_USER")"; then
    echo "ERROR: Could not determine primary group for user '$ACTUAL_USER'." >&2
    exit 1
fi

REPO_DIR="$SCRIPT_DIR"
CONFIG_DIR="$ACTUAL_USER_HOME/.config"

if [[ ! -d "$REPO_DIR/.config" || ! -d "$REPO_DIR/.config/hypr" ]]; then
    echo "ERROR: Script must be run from the repository root directory containing .config/hypr." >&2
    exit 1
fi

# ============================================================
# Color Configuration
# ============================================================

if [[ -t 2 ]] && tput setaf 0 &>/dev/null; then
    ALL_OFF="$(tput sgr0)"
    BOLD="$(tput bold)"
    RED="${BOLD}$(tput setaf 1)"
    GREEN="${BOLD}$(tput setaf 2)"
else
    ALL_OFF=$'\e[0m'
    BOLD=$'\e[1m'
    RED=$'\e[31m'
    GREEN=$'\e[32m'
fi

# ============================================================
# 2. Interactive Prompts
# ============================================================

echo "This script will install custom dot-files for Hyprland."
echo "Use at your own risk."

while true; do
    read -r -p "Would you like to proceed? (y/n): " proceed

    case "$proceed" in
        y|Y|yes|YES)
            echo "Proceeding..."
            break
            ;;
        n|N|no|NO)
            echo "Exiting."
            exit 0
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done

# ============================================================
# 3. System Upgrade & Repository Setup
# ============================================================

echo "Updating system packages prior to setup..."

if ! dnf upgrade -y; then
    echo "${RED}Warning: System package upgrade encountered an issue. Proceeding anyway...${ALL_OFF}" >&2
fi

echo "Enabling COPR repositories..."

REPOS=(
    "lionheartp/Hyprland"
    "leloubil/wl-clip-persist"
    "atim/starship"
)

for repo in "${REPOS[@]}"; do
    echo "Enabling COPR: $repo"

    if ! dnf -q -y copr enable "$repo" >/dev/null 2>&1; then
        echo "${RED}ERROR: Failed to enable COPR repository: $repo${ALL_OFF}" >&2
        exit 1
    fi
done

echo "Installing RPM Fusion repositories..."

if ! dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"; then

    echo "${RED}ERROR: Failed to install RPM Fusion repositories.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# Package List
# ============================================================

PACKAGES=(
    dbus
    polkit
    accountsservice
    greetd
    noctalia-greeter-git
    noctalia-hyprland-meta
    bluez

    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xorg-x11-server-Xwayland

    mesa-dri-drivers
    mesa-vulkan-drivers

    fish
    foot
    fastfetch
    nwg-look
    xdg-user-dirs

    thunar
    thunar-media-tags-plugin
    thunar-volman
    thunar-archive-plugin
    tumbler

    power-profiles-daemon

    unrar
    unzip

    cava

    libopenraw
    libgsf
    poppler-glib
    ffmpegthumbnailer
    libgepub

    gvfs
    gvfs-mtp

    dosfstools
    exfatprogs

    matugen

    adw-gtk3-theme
    imv

    upower
    gpu-screen-recorder

    qt6ct


    mpv

    wl-clip-persist
    ImageMagick
    starship
)

# ============================================================
# 4. Core Package Installation
# ============================================================

echo ""
echo "Installing required core packages via dnf..."
echo "Please wait..."

if ! dnf install -y "${PACKAGES[@]}"; then
    echo "${RED}ERROR: Core package installation failed.${ALL_OFF}" >&2
    exit 1
fi

if ! systemctl enable --now bluetooth; then
    echo "${RED}ERROR: Failed to enable Bluetooth service.${ALL_OFF}" >&2
    exit 1
fi

echo ""
echo "--- AccountsService Setup ---"

if systemctl enable accounts-daemon; then
    echo "accounts-daemon service enabled."
else
    echo "${RED}Warning: Failed to enable accounts-daemon.service.${ALL_OFF}"
fi

# ============================================================
# 5. Services & Noctalia Greeter Setup
# ============================================================

setup_noctalia_greeter() {
    echo ""
    echo "--- Noctalia Greeter Setup ---"

    local greetd_config_file="/etc/greetd/config.toml"
    local greeter_user="greeter"
    local session_bin
    local setup_system_script="/usr/share/noctalia-greeter/setup_greeter_system.sh"

    session_bin="$(command -v noctalia-greeter-session 2>/dev/null || true)"

    if [[ -z "$session_bin" ]]; then
        echo "${RED}ERROR: noctalia-greeter-session was not found after package installation.${ALL_OFF}" >&2
        return 1
    fi

    echo "Using Noctalia Greeter session wrapper: $session_bin"

    if ! id -u "$greeter_user" >/dev/null 2>&1; then
        echo "Creating greeter user '$greeter_user'..."

        if ! useradd \
            -r \
            -s /usr/bin/nologin \
            -d /var/lib/noctalia-greeter \
            "$greeter_user"; then

            echo "${RED}ERROR: Failed to create greeter user.${ALL_OFF}" >&2
            return 1
        fi
    fi

    if ! mkdir -p /var/lib/noctalia-greeter /etc/greetd; then
        echo "${RED}ERROR: Failed to create greeter directories.${ALL_OFF}" >&2
        return 1
    fi

    if ! chmod 0750 /var/lib/noctalia-greeter; then
        echo "${RED}ERROR: Failed to set greeter state directory permissions.${ALL_OFF}" >&2
        return 1
    fi

    if ! chown -R "$greeter_user:$greeter_user" /var/lib/noctalia-greeter; then
        echo "${RED}ERROR: Failed to set greeter state directory ownership.${ALL_OFF}" >&2
        return 1
    fi

    if [[ -f "$greetd_config_file" ]]; then
        cp -a \
            "$greetd_config_file" \
            "$greetd_config_file.bak.$(date +%s)"
    fi

    echo "Writing greetd configuration..."

    cat > "$greetd_config_file" <<EOF
[terminal]
vt = 1

[default_session]
command = "$session_bin"
user = "$greeter_user"
EOF

    chmod 0644 "$greetd_config_file"

    if [[ -x "$setup_system_script" ]]; then
        echo "Running Noctalia Greeter system setup..."

        if ! "$setup_system_script" >/dev/null 2>&1; then
            echo "${RED}ERROR: Noctalia Greeter system setup failed.${ALL_OFF}" >&2
            return 1
        fi
    else
        echo "Warning: Noctalia Greeter system setup script was not found."
        echo "The basic greetd configuration was still written."
    fi
}

if ! setup_noctalia_greeter; then
    echo "${RED}ERROR: Noctalia Greeter setup failed.${ALL_OFF}" >&2
    exit 1
fi

echo "Noctalia Greeter setup: Done."

if ! systemctl enable greetd; then
    echo "${RED}ERROR: Failed to enable greetd.service.${ALL_OFF}" >&2
    exit 1
fi

if ! systemctl set-default graphical.target; then
    echo "${RED}ERROR: Failed to set graphical.target as default.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 6. Configuration & File Deployment
# ============================================================

mkdir -p \
    "$CONFIG_DIR" \
    "$ACTUAL_USER_HOME/.config/fish" \
    "$ACTUAL_USER_HOME/.local/share/fish" \
    "$ACTUAL_USER_HOME/.local/state" \
    "$ACTUAL_USER_HOME/Pictures"

deploy_configs() {
    local backup_timestamp
    local item
    local name
    local target

    echo ""
    echo "--- Configuration Deployment ---"

    backup_timestamp="$(date +%s)"

    echo "Backing up existing configuration files..."

    # Back up every top-level .config entry, including hidden entries,
    # without enabling dotglob globally.
    while IFS= read -r -d '' item; do
        name="$(basename "$item")"

        if [[ "$name" == "hypr" ]]; then
            continue
        fi

        target="$CONFIG_DIR/$name"

        if [[ -e "$target" || -L "$target" ]]; then
            echo "Backing up: $name"

            if ! mv "$target" "$CONFIG_DIR/$name.bak.$backup_timestamp"; then
                echo "${RED}ERROR: Failed to back up $target.${ALL_OFF}" >&2
                return 1
            fi
        fi
    done < <(find "$REPO_DIR/.config" -mindepth 1 -maxdepth 1 -print0)

    if [[ -e "$CONFIG_DIR/hypr" || -L "$CONFIG_DIR/hypr" ]]; then
        echo "Backing up: hypr"

        if ! mv \
            "$CONFIG_DIR/hypr" \
            "$CONFIG_DIR/hypr.bak.$backup_timestamp"; then

            echo "${RED}ERROR: Failed to back up $CONFIG_DIR/hypr.${ALL_OFF}" >&2
            return 1
        fi
    fi

    echo "Copying configuration files..."

    # Copy the complete directory contents, including hidden entries.
    if ! cp -a "$REPO_DIR/.config/." "$CONFIG_DIR/"; then
        echo "${RED}ERROR: Failed to copy configuration files.${ALL_OFF}" >&2
        return 1
    fi

    echo "Configuration files deployed successfully."
}

if ! deploy_configs; then
    echo "${RED}ERROR: Failed to deploy configuration files.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# Wallpapers & Assets
# ============================================================

if [[ -f "$REPO_DIR/minimaLinux.png" ]]; then
    mkdir -p "$ACTUAL_USER_HOME/Pictures/Wallpapers"

    cp -f \
        "$REPO_DIR/minimaLinux.png" \
        "$ACTUAL_USER_HOME/Pictures/Wallpapers/minimaLinux.png"

fi

# ============================================================
# Noctalia State
# ============================================================

if [[ -d "$REPO_DIR/.local/state/noctalia" ]]; then
    mkdir -p "$ACTUAL_USER_HOME/.local/state"

    cp -a \
        "$REPO_DIR/.local/state/noctalia" \
        "$ACTUAL_USER_HOME/.local/state/"

fi

# ============================================================
# Restore Backup Configurations
# ============================================================

if [[ -d "$REPO_DIR/backup/.config" ]]; then
    echo "Restoring backup configurations..."

    if ! cp -a \
        "$REPO_DIR/backup/.config/." \
        "$CONFIG_DIR/"; then

        echo "${RED}ERROR: Failed to restore backup configurations.${ALL_OFF}" >&2
        exit 1
    fi

fi

# ============================================================
# Permissions
# ============================================================

SCRIPTS_PATH="$CONFIG_DIR/hypr/Scripts"

if [[ -d "$SCRIPTS_PATH" ]]; then
    echo "Setting execution permissions for Hyprland scripts..."

    if ! find "$SCRIPTS_PATH" -type f -exec chmod +x {} \;; then
        echo "${RED}Warning: Failed to set permissions on some Hyprland scripts.${ALL_OFF}"
    fi
fi

# ============================================================
# User Environment Defaults
# ============================================================

run_as_user() {
    runuser -u "$ACTUAL_USER" -- env \
        HOME="$ACTUAL_USER_HOME" \
        USER="$ACTUAL_USER" \
        LOGNAME="$ACTUAL_USER" \
        "$@"
}

echo "Updating user directories..."

if ! run_as_user xdg-user-dirs-update; then
    echo "${RED}Warning: Failed to update user directories.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default thunar.desktop inode/directory; then
    echo "${RED}Warning: Failed to set Thunar as default for directories.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default thunar.desktop application/x-gnome-saved-search; then
    echo "${RED}Warning: Failed to set Thunar as default for saved searches.${ALL_OFF}"
fi

for mime_type in     image/png     image/jpeg     image/gif     image/webp     image/svg+xml     image/tiff     image/bmp     image/avif     image/heif     image/jxl; do

    if ! run_as_user xdg-mime default imv.desktop "$mime_type"; then
        echo "${RED}Warning: Failed to set imv as default for $mime_type.${ALL_OFF}"
    fi
done

# ============================================================
# Thunar Bookmarks
# ============================================================

GTK_DIR="$CONFIG_DIR/gtk-3.0"
BOOKMARKS_FILE="$GTK_DIR/bookmarks"

mkdir -p "$GTK_DIR"

cat > "$BOOKMARKS_FILE" <<EOF
file://$ACTUAL_USER_HOME/Documents
file://$ACTUAL_USER_HOME/Downloads
file://$ACTUAL_USER_HOME/Pictures
file://$ACTUAL_USER_HOME/Music
file://$ACTUAL_USER_HOME/Videos
file://$ACTUAL_USER_HOME/.config/hypr
EOF

# ============================================================
# Final Ownership Fix
# ============================================================

if ! chown -R \
    "$ACTUAL_USER:$ACTUAL_USER_GROUP" \
    "$ACTUAL_USER_HOME/.config" \
    "$ACTUAL_USER_HOME/.local" \
    "$ACTUAL_USER_HOME/Pictures"; then

    echo "${RED}ERROR: Final user-space ownership fix failed.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 7. Final Hyprland / Greetd Sanity Checks
# ============================================================

echo ""
echo "--- Final Sanity Checks ---"

if [[ -f "/usr/share/wayland-sessions/hyprland.desktop" ]]; then
    echo "Hyprland Wayland session: OK"
else
    echo "${RED}Warning: Hyprland Wayland session file was not found.${ALL_OFF}"
fi

if command -v noctalia-greeter-session >/dev/null 2>&1; then
    echo "Noctalia Greeter session wrapper: OK"
else
    echo "${RED}Warning: noctalia-greeter-session was not found.${ALL_OFF}"
fi

if systemctl is-enabled greetd >/dev/null 2>&1; then
    echo "greetd service: enabled"
else
    echo "${RED}Warning: greetd.service is not enabled.${ALL_OFF}"
fi

if systemctl is-enabled accounts-daemon >/dev/null 2>&1; then
    echo "AccountsService: enabled"
else
    echo "AccountsService: not enabled"
fi

echo ""
echo "${GREEN}Installation Complete!${ALL_OFF}"

# ============================================================
# Reboot
# ============================================================

while true; do
    read -r -p "Would you like to reboot now? (y/n): " reboot_choice

    case "$reboot_choice" in
        y|Y|yes|YES)
            echo "Rebooting now..."
            systemctl reboot
            break
            ;;
        n|N|no|NO)
            echo "Please remember to reboot manually to apply all graphical alterations safely."
            exit 0
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done
