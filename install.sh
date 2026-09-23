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
    echo "ERROR: dnf was not found. This installer requires Fedora." >&2
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
    ALL_OFF=""
    BOLD=""
    RED=""
    GREEN=""
fi

# ============================================================
# 2. Interactive Prompts
# ============================================================

echo "This script will install the system packages and custom dot-files from this repository."
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

if ! dnf copr --help >/dev/null 2>&1; then
    echo "Installing DNF5 COPR support..."
    if ! dnf install -y dnf5-plugins; then
        echo "${RED}ERROR: Failed to install DNF5 COPR support.${ALL_OFF}" >&2
        exit 1
    fi
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

if [[ ! -f /etc/yum.repos.d/brave-browser.repo ]]; then
    echo "Adding Brave Origin repository..."
    if ! dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo >/dev/null 2>&1; then
        echo "${RED}ERROR: Failed to add Brave Origin repository.${ALL_OFF}" >&2
        exit 1
    fi
fi

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
    uwsm
    hyprland-uwsm
    bluez
    ufw

    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xorg-x11-server-Xwayland

    mesa-dri-drivers
    mesa-vulkan-drivers
    intel-media-driver

    pipewire
    pipewire-pulseaudio
    pipewire-alsa
    wireplumber
    cava

    fish
    foot
    neovim
    fastfetch
    nwg-look
    xdg-user-dirs
    xdg-utils

    nautilus

    power-profiles-daemon

    unrar
    unzip
    tar

    ffmpegthumbnailer

    gvfs-mtp

    dosfstools
    exfatprogs


    gum
    adw-gtk3-theme
    imv
    evince

    upower
    gpu-screen-recorder

    qt6ct
    mpv
    brave-origin

    wl-clip-persist
    ImageMagick
    starship

    curl
)

# ============================================================
# 4. Core Package Installation
# ============================================================

echo ""
echo "Installing required core packages via dnf..."
echo "Please wait..."

if ! dnf --setopt=install_weak_deps=False install -y "${PACKAGES[@]}"; then
    echo "${RED}ERROR: Core package installation failed.${ALL_OFF}" >&2
    exit 1
fi

FISH_SHELL="$(command -v fish)"
if ! grep -qxF "$FISH_SHELL" /etc/shells; then
    echo "$FISH_SHELL" >> /etc/shells
fi
if ! usermod -s "$FISH_SHELL" "$ACTUAL_USER"; then
    echo "${RED}ERROR: Failed to set fish as the default shell.${ALL_OFF}" >&2
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

setup_ufw() {
    echo ""
    echo "--- UFW Firewall Setup ---"

    if systemctl cat firewalld.service >/dev/null 2>&1; then
        if systemctl is-active --quiet firewalld.service || systemctl is-enabled --quiet firewalld.service; then
            if ! systemctl disable --now firewalld.service; then
                echo "${RED}ERROR: Failed to disable firewalld.service.${ALL_OFF}" >&2
                return 1
            fi
        fi
    fi

    ufw default deny incoming >/dev/null &&
    ufw default allow outgoing >/dev/null &&
    ufw allow 53317/tcp >/dev/null &&
    ufw allow 53317/udp >/dev/null &&
    ufw --force enable >/dev/null || {
        echo "${RED}ERROR: UFW setup failed.${ALL_OFF}" >&2
        return 1
    }

    echo "UFW enabled: incoming denied, outgoing allowed, LocalSend 53317/tcp and 53317/udp allowed."
}

if ! setup_ufw; then
    exit 1
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

    if [[ -f "$greetd_config_file" ]] && cmp -s "$greetd_config_file" <(
        printf '%s\n' \
            '[terminal]' \
            'vt = 1' \
            '' \
            '[default_session]' \
            "command = \"$session_bin\"" \
            "user = \"$greeter_user\""
    ); then
        echo "greetd configuration is already up to date."
    else
        echo "Writing greetd configuration..."

        cat > "$greetd_config_file" <<EOF
[terminal]
vt = 1

[default_session]
command = "$session_bin"
user = "$greeter_user"
EOF
    fi

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
    "$ACTUAL_USER_HOME/.local/bin"

deploy_configs() {
    echo ""
    echo "--- Configuration Deployment ---"
    echo "Copying configuration files..."

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
# .local Deployment & Script Permissions
# ============================================================

echo "Deploying user-local files..."

if [[ -d "$REPO_DIR/.local" ]]; then
    if ! cp -a "$REPO_DIR/.local/." "$ACTUAL_USER_HOME/.local/"; then
        echo "${RED}ERROR: Failed to deploy .local files.${ALL_OFF}" >&2
        exit 1
    fi

    SCRIPTS_PATH="$ACTUAL_USER_HOME/.local/bin"

    if [[ -d "$SCRIPTS_PATH" ]]; then
        echo "Setting execution permissions on ~/.local/bin scripts..."

        if ! find "$SCRIPTS_PATH" -maxdepth 1 -type f -exec chmod +x {} +; then
            echo "${RED}Warning: Failed to set permissions on some ~/.local/bin scripts.${ALL_OFF}"
        fi
    fi
fi

install_jetbrains_mono_nerd_font() {
    echo ""
    echo "--- JetBrains Mono Nerd Font Setup ---"

    local font_version="v3.5.1"
    local font_dir="/usr/local/share/fonts/JetBrainsMonoNerdFont"
    local version_file="$font_dir/.version"
    local tmp_dir
    local archive

    if [[ -f "$version_file" && "$(<"$version_file")" == "$font_version" ]]; then
        echo "JetBrains Mono Nerd Font ${font_version} is already installed."
        return 0
    fi

    tmp_dir="$(mktemp -d)"
    archive="$tmp_dir/JetBrainsMono.tar.xz"

    if ! curl -fL --retry 3 --retry-delay 2 \
        -o "$archive" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.5.1/JetBrainsMono.tar.xz" \
        || ! tar -xJf "$archive" -C "$tmp_dir" \
        || ! install -d -m 0755 "$font_dir" \
        || ! find "$tmp_dir" -type f -name 'JetBrainsMonoNerdFont-*.ttf' \
            -exec install -m 0644 {} "$font_dir/" \; \
        || ! fc-cache -f "$font_dir" >/dev/null 2>&1 \
        || ! printf '%s\n' "$font_version" > "$version_file"; then

        rm -rf "$tmp_dir"
        echo "${RED}ERROR: JetBrains Mono Nerd Font setup failed.${ALL_OFF}" >&2
        return 1
    fi

    rm -rf "$tmp_dir"
    echo "JetBrains Mono Nerd Font installed system-wide."
}

if ! install_jetbrains_mono_nerd_font; then
    exit 1
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

set_mime_defaults() {
    local desktop="$1"
    local pattern="$2"
    local desktop_file="/usr/share/applications/$desktop"
    local mimes

    [[ -f "$desktop_file" ]] || return 1
    mimes="$(sed -n 's/^MimeType=//p' "$desktop_file" | tr ';' '\n' | grep -E "$pattern" || true)"
    [[ -n "$mimes" ]] || return 1
    run_as_user xdg-mime default "$desktop" $mimes
}

echo "Updating user directories and application defaults..."

if ! set_mime_defaults nvim.desktop '^(text/|application/x-shellscript$)'; then
    echo "${RED}Warning: Failed to set Neovim as the default editor.${ALL_OFF}"
fi

if ! set_mime_defaults imv-dir.desktop '^image/'; then
    echo "${RED}Warning: Failed to set imv-dir as the default image viewer.${ALL_OFF}"
fi

if ! set_mime_defaults mpv.desktop '^(video/|audio/)'; then
    echo "${RED}Warning: Failed to set mpv as the default audio/video player.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default org.gnome.Evince.desktop application/pdf; then
    echo "${RED}Warning: Failed to set Evince as the default PDF viewer.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default brave-origin.desktop \
    text/html x-scheme-handler/http x-scheme-handler/https \
    x-scheme-handler/about x-scheme-handler/unknown x-scheme-handler/chromium; then
    echo "${RED}Warning: Failed to set Brave Origin as the default browser.${ALL_OFF}"
fi

XFCE_HELPERS="$CONFIG_DIR/xfce4/helpers.rc"
mkdir -p "$(dirname "$XFCE_HELPERS")"
touch "$XFCE_HELPERS"
sed -i \
    -e '/^TerminalEmulator=/d' \
    -e '/^WebBrowser=/d' \
    "$XFCE_HELPERS"
printf '%s\n' \
    'TerminalEmulator=foot' \
    'WebBrowser=brave-origin' >> "$XFCE_HELPERS"

if ! run_as_user xdg-user-dirs-update; then
    echo "${RED}Warning: Failed to update user directories.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default org.gnome.Nautilus.desktop inode/directory; then
    echo "${RED}Warning: Failed to set Nautilus as default for directories.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default org.gnome.Nautilus.desktop application/x-gnome-saved-search; then
    echo "${RED}Warning: Failed to set Nautilus as default for saved searches.${ALL_OFF}"
fi

# ============================================================
# Nautilus Bookmarks
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
    "$ACTUAL_USER_HOME/.local"; then

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
