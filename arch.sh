#!/usr/bin/env bash

set -euo pipefail

export LC_MESSAGES=C
export LANG=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# ============================================================
# 1. Privileges, Environment & Repository Checks
# ============================================================

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (or via sudo)." >&2
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    echo "ERROR: pacman was not found. This installer requires Arch Linux." >&2
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
    echo "ERROR: Could not determine a valid home directory for user '$ACTUAL_USER'." >&2
    exit 1
fi

if ! ACTUAL_USER_GROUP="$(id -gn "$ACTUAL_USER")"; then
    echo "ERROR: Could not determine primary group for user '$ACTUAL_USER'." >&2
    exit 1
fi

REPO_DIR="$SCRIPT_DIR"
CONFIG_DIR="$ACTUAL_USER_HOME/.config"

if [[ ! -d "$REPO_DIR/.config" || ! -d "$REPO_DIR/.config/hypr" ]]; then
    echo "ERROR: Script must be run from the repository root containing .config/hypr." >&2
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
    YELLOW="${BOLD}$(tput setaf 3)"
else
    ALL_OFF=""
    BOLD=""
    RED=""
    GREEN=""
    YELLOW=""
fi

# ============================================================
# 2. Confirmation
# ============================================================

echo "This script will install the Arch system packages, AUR packages,"
echo "system configuration, and custom dot-files from this repository."
echo ""
echo "No backup files will be created. Existing targeted configuration files"
echo "may be replaced by the configuration defined here."
echo ""

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
# 3. System Upgrade
# ============================================================

echo ""
echo "--- System Upgrade ---"
echo "Updating the Arch system before installing the environment..."

if ! pacman -Syu --noconfirm; then
    echo "${RED}ERROR: System upgrade failed.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 4. Official Package Installation
# ============================================================

# Archinstall already provides NetworkManager, BlueZ, PipeWire, power management,
# UFW, the kernel, linux-firmware, GRUB, zram, NTP, and the basic system. Do not reinstall
# those here. Packages below are the additional environment components.

OFFICIAL_PACKAGES=(
    dbus
    polkit
    accountsservice

    greetd
    noctalia
    uwsm
    hyprland
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk

    fish
    foot
    neovim
    fastfetch
    nwg-look
    xdg-user-dirs
    xdg-utils

    nautilus
    gvfs-mtp

    unrar
    unzip

    gum
    adw-gtk-theme
    imv
    evince
    upower

    gpu-screen-recorder
    qt6ct
    mpv

    wl-clip-persist
    starship
    curl
)

echo ""
echo "--- Official Arch Packages ---"
echo "Installing the required official packages..."

if ! pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"; then
    echo "${RED}ERROR: Official package installation failed.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 5. AUR Helper + AUR Packages
# ============================================================

run_as_user() {
    runuser -u "$ACTUAL_USER" -- env \
        HOME="$ACTUAL_USER_HOME" \
        USER="$ACTUAL_USER" \
        LOGNAME="$ACTUAL_USER" \
        PATH="/usr/local/sbin:/usr/local/bin:/usr/bin:/bin" \
        "$@"
}

install_yay() {
    echo ""
    echo "--- yay Setup ---"

    if command -v yay >/dev/null 2>&1; then
        echo "yay is already installed."
        return 0
    fi

    echo "Installing AUR build prerequisites..."
    if ! pacman -S --needed --noconfirm base-devel git go; then
        echo "${RED}ERROR: Failed to install yay build prerequisites.${ALL_OFF}" >&2
        return 1
    fi

    local build_dir
    local -a yay_packages

    build_dir="$(mktemp -d /tmp/yay-build.XXXXXX)"
    chown "$ACTUAL_USER:$ACTUAL_USER_GROUP" "$build_dir"

    echo "Building yay as user '$ACTUAL_USER'..."
    if ! run_as_user git clone --depth=1 https://aur.archlinux.org/yay.git "$build_dir/yay"; then
        rm -rf "$build_dir"
        echo "${RED}ERROR: Failed to clone yay.${ALL_OFF}" >&2
        return 1
    fi

    if ! run_as_user bash -c "cd \"$build_dir/yay\" && makepkg -f --noconfirm"; then
        rm -rf "$build_dir"
        echo "${RED}ERROR: Failed to build yay.${ALL_OFF}" >&2
        return 1
    fi

    mapfile -t yay_packages < <(find "$build_dir/yay" -maxdepth 1 -type f -name 'yay-[0-9]*.pkg.tar.zst' -print)

    if ((${#yay_packages[@]} == 0)); then
        rm -rf "$build_dir"
        echo "${RED}ERROR: yay package was not produced.${ALL_OFF}" >&2
        return 1
    fi

    if ! pacman -U --noconfirm "${yay_packages[@]}"; then
        rm -rf "$build_dir"
        echo "${RED}ERROR: Failed to install the built yay package.${ALL_OFF}" >&2
        return 1
    fi

    rm -rf "$build_dir"
    echo "yay installed successfully."
}

if ! install_yay; then
    exit 1
fi

AUR_PACKAGES=(
    noctalia-greeter
    brave-origin-bin
    localsend-bin
)

echo ""
echo "--- AUR Packages ---"
echo "Installing the small set of packages not provided by the official repositories..."

if ! run_as_user yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
    echo "${RED}ERROR: AUR package installation failed.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 6. Required Services & User Shell
# ============================================================

echo ""
echo "--- Services & User Shell ---"

FISH_SHELL="$(command -v fish)"
if ! grep -qxF "$FISH_SHELL" /etc/shells; then
    echo "$FISH_SHELL" >> /etc/shells
fi

if ! usermod -s "$FISH_SHELL" "$ACTUAL_USER"; then
    echo "${RED}ERROR: Failed to set fish as the default shell.${ALL_OFF}" >&2
    exit 1
fi

if systemctl enable accounts-daemon.service; then
    echo "AccountsService enabled."
else
    echo "${YELLOW}Warning: Failed to enable accounts-daemon.service.${ALL_OFF}"
fi


# ============================================================
# 8. UFW Firewall
# ============================================================

setup_ufw() {
    echo ""
    echo "--- UFW Rules ---"

    if ! ufw default deny incoming >/dev/null ||
       ! ufw default allow outgoing >/dev/null ||
       ! ufw allow 53317/tcp >/dev/null ||
       ! ufw allow 53317/udp >/dev/null ||
       ! ufw --force enable >/dev/null; then
        echo "${RED}ERROR: UFW rule configuration failed.${ALL_OFF}" >&2
        return 1
    fi

    echo "UFW configured: incoming denied, outgoing allowed, LocalSend 53317/tcp and 53317/udp allowed."
}

if ! setup_ufw; then
    exit 1
fi

# ============================================================
# 9. Noctalia Greeter + greetd
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

    if [[ ! -x "$setup_system_script" ]]; then
        echo "${RED}ERROR: Noctalia Greeter system setup script was not found at $setup_system_script.${ALL_OFF}" >&2
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

    echo "Writing greetd configuration..."
    cat > "$greetd_config_file" <<EOF_GREETD
[terminal]
vt = 1

[default_session]
command = "$session_bin"
user = "$greeter_user"
EOF_GREETD

    chmod 0644 "$greetd_config_file"

    echo "Running Noctalia Greeter system setup..."
    if ! "$setup_system_script" >/dev/null 2>&1; then
        echo "${RED}ERROR: Noctalia Greeter system setup failed.${ALL_OFF}" >&2
        return 1
    fi
}

if ! setup_noctalia_greeter; then
    echo "${RED}ERROR: Noctalia Greeter setup failed.${ALL_OFF}" >&2
    exit 1
fi

if ! systemctl enable greetd.service; then
    echo "${RED}ERROR: Failed to enable greetd.service.${ALL_OFF}" >&2
    exit 1
fi

if ! systemctl set-default graphical.target; then
    echo "${RED}ERROR: Failed to set graphical.target as default.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 10. User Configuration & File Deployment
# ============================================================

mkdir -p \
    "$CONFIG_DIR" \
    "$ACTUAL_USER_HOME/.local/bin"

deploy_configs() {
    echo ""
    echo "--- Configuration Deployment ---"

    if ! cp -a "$REPO_DIR/.config/." "$CONFIG_DIR/"; then
        echo "${RED}ERROR: Failed to copy configuration files.${ALL_OFF}" >&2
        return 1
    fi

    echo "Configuration files deployed successfully."
}

if ! deploy_configs; then
    exit 1
fi

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
            echo "${YELLOW}Warning: Failed to set permissions on some ~/.local/bin scripts.${ALL_OFF}"
        fi
    fi
fi

# ============================================================
# 11. JetBrains Mono Nerd Font (One Font File Only)
# ============================================================

install_jetbrains_mono_nerd_font() {
    echo ""
    echo "--- JetBrains Mono Nerd Font Setup ---"

    local font_version="v3.5.1"
    local font_file="JetBrainsMonoNerdFont-Medium.ttf"
    local font_dir="/usr/local/share/fonts/JetBrainsMonoNerdFont"
    local version_file="$font_dir/.version"
    local archive_sha256="04d5e8f903693f9dd13e16f867e994834e681eb3c72c0d337a770dcda09010cf"
    local archive_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${font_version}/JetBrainsMono.tar.xz"
    local tmp_dir
    local archive
    local source_font

    install -d -m 0755 "$font_dir"

    if [[ -f "$font_dir/$font_file" && -f "$version_file" && "$(<"$version_file")" == "$font_version" ]]; then
        echo "JetBrains Mono Nerd Font Medium ${font_version} is already installed."
        return 0
    fi

    tmp_dir="$(mktemp -d)"
    archive="$tmp_dir/JetBrainsMono.tar.xz"

    echo "Downloading JetBrains Mono Nerd Font ${font_version}..."
    if ! curl -fL --retry 3 --retry-delay 2 -o "$archive" "$archive_url"; then
        rm -rf "$tmp_dir"
        echo "${RED}ERROR: Failed to download JetBrains Mono Nerd Font.${ALL_OFF}" >&2
        return 1
    fi

    echo "Verifying font archive checksum..."
    if ! printf '%s  %s\n' "$archive_sha256" "$archive" | sha256sum -c - >/dev/null 2>&1; then
        rm -rf "$tmp_dir"
        echo "${RED}ERROR: JetBrains Mono Nerd Font checksum verification failed.${ALL_OFF}" >&2
        return 1
    fi

    if ! tar -xJf "$archive" -C "$tmp_dir"; then
        rm -rf "$tmp_dir"
        echo "${RED}ERROR: Failed to extract JetBrains Mono Nerd Font archive.${ALL_OFF}" >&2
        return 1
    fi

    source_font="$(find "$tmp_dir" -type f -name "$font_file" -print -quit)"
    if [[ -z "$source_font" || ! -f "$source_font" ]]; then
        rm -rf "$tmp_dir"
        echo "${RED}ERROR: $font_file was not found in the Nerd Fonts archive.${ALL_OFF}" >&2
        return 1
    fi

    # Keep this dedicated directory minimal: exactly the selected font file.
    find "$font_dir" -maxdepth 1 -type f -name 'JetBrainsMonoNerdFont*.ttf' -delete

    if ! install -m 0644 "$source_font" "$font_dir/$font_file"; then
        rm -rf "$tmp_dir"
        echo "${RED}ERROR: Failed to install $font_file.${ALL_OFF}" >&2
        return 1
    fi

    if ! printf '%s\n' "$font_version" > "$version_file"; then
        rm -rf "$tmp_dir"
        echo "${RED}ERROR: Failed to write font version marker.${ALL_OFF}" >&2
        return 1
    fi

    rm -rf "$tmp_dir"

    if ! fc-cache -f "$font_dir" >/dev/null 2>&1; then
        echo "${YELLOW}Warning: fc-cache reported an error; the font was installed but the cache could not be refreshed.${ALL_OFF}"
    fi

    echo "Installed exactly one JetBrains Mono Nerd Font file: $font_file"
}

if ! install_jetbrains_mono_nerd_font; then
    exit 1
fi

# ============================================================
# 12. User Environment Defaults
# ============================================================

set_mime_defaults() {
    local desktop="$1"
    local pattern="$2"
    local desktop_file="/usr/share/applications/$desktop"
    local mimes

    [[ -f "$desktop_file" ]] || return 1
    mimes="$(sed -n 's/^MimeType=//p' "$desktop_file" | tr ';' '\n' | grep -E "$pattern" || true)"
    [[ -n "$mimes" ]] || return 1

    # Intentional unquoted expansion: mimes is newline-separated MIME types.
    run_as_user xdg-mime default "$desktop" $mimes
}

echo ""
echo "--- Default Applications & User Directories ---"

if ! set_mime_defaults nvim.desktop '^(text/|application/x-shellscript$)'; then
    echo "${YELLOW}Warning: Failed to set Neovim as the default editor.${ALL_OFF}"
fi

if ! set_mime_defaults imv-dir.desktop '^image/'; then
    echo "${YELLOW}Warning: Failed to set imv as the default image viewer.${ALL_OFF}"
fi

if ! set_mime_defaults mpv.desktop '^(video/|audio/)'; then
    echo "${YELLOW}Warning: Failed to set mpv as the default audio/video player.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default org.gnome.Evince.desktop application/pdf; then
    echo "${YELLOW}Warning: Failed to set Evince as the default PDF viewer.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default brave-origin.desktop \
    text/html \
    x-scheme-handler/http \
    x-scheme-handler/https \
    x-scheme-handler/about \
    x-scheme-handler/unknown \
    x-scheme-handler/chromium; then
    echo "${YELLOW}Warning: Failed to set Brave Origin as the default browser.${ALL_OFF}"
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
    echo "${YELLOW}Warning: Failed to update user directories.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default org.gnome.Nautilus.desktop inode/directory; then
    echo "${YELLOW}Warning: Failed to set Nautilus as default for directories.${ALL_OFF}"
fi

if ! run_as_user xdg-mime default org.gnome.Nautilus.desktop application/x-gnome-saved-search; then
    echo "${YELLOW}Warning: Failed to set Nautilus as default for saved searches.${ALL_OFF}"
fi

# ============================================================
# 13. Nautilus Bookmarks
# ============================================================

GTK_DIR="$CONFIG_DIR/gtk-3.0"
BOOKMARKS_FILE="$GTK_DIR/bookmarks"

mkdir -p "$GTK_DIR"

cat > "$BOOKMARKS_FILE" <<EOF_BOOKMARKS
file://$ACTUAL_USER_HOME/Documents
file://$ACTUAL_USER_HOME/Downloads
file://$ACTUAL_USER_HOME/Pictures
file://$ACTUAL_USER_HOME/Music
file://$ACTUAL_USER_HOME/Videos
file://$ACTUAL_USER_HOME/.config/hypr
EOF_BOOKMARKS

# ============================================================
# 14. Final Ownership & Permissions
# ============================================================

echo ""
echo "--- Final User-Space Ownership ---"

if ! chown -R \
    "$ACTUAL_USER:$ACTUAL_USER_GROUP" \
    "$ACTUAL_USER_HOME/.config" \
    "$ACTUAL_USER_HOME/.local"; then
    echo "${RED}ERROR: Final user-space ownership fix failed.${ALL_OFF}" >&2
    exit 1
fi

# ============================================================
# 15. Final Sanity Checks
# ============================================================

echo ""
echo "--- Final Sanity Checks ---"

if [[ -f "/usr/share/wayland-sessions/hyprland.desktop" ]]; then
    echo "Hyprland Wayland session: OK"
else
    echo "${YELLOW}Warning: Hyprland Wayland session file was not found.${ALL_OFF}"
fi

if [[ -f "/usr/share/wayland-sessions/hyprland-uwsm.desktop" ]]; then
    echo "Hyprland UWSM Wayland session: OK"
else
    echo "${YELLOW}Warning: Hyprland UWSM session file was not found.${ALL_OFF}"
fi

if command -v noctalia-greeter-session >/dev/null 2>&1; then
    echo "Noctalia Greeter session wrapper: OK"
else
    echo "${YELLOW}Warning: noctalia-greeter-session was not found.${ALL_OFF}"
fi

if systemctl is-enabled greetd.service >/dev/null 2>&1; then
    echo "greetd service: enabled"
else
    echo "${YELLOW}Warning: greetd.service is not enabled.${ALL_OFF}"
fi

if systemctl is-enabled accounts-daemon.service >/dev/null 2>&1; then
    echo "AccountsService: enabled"
else
    echo "${YELLOW}Warning: accounts-daemon.service is not enabled.${ALL_OFF}"
fi

if ufw status | grep -q 'Status: active'; then
    echo "UFW: active"
else
    echo "${YELLOW}Warning: UFW is not active.${ALL_OFF}"
fi

if grep -qx 'WIRELESS_REGDOM="IN"' /etc/conf.d/wireless-regdom; then
    echo "Wireless regulatory domain config: IN"
else
    echo "${YELLOW}Warning: Wireless regulatory domain configuration is not set to IN.${ALL_OFF}"
fi

if [[ -f "/usr/local/share/fonts/JetBrainsMonoNerdFont/JetBrainsMonoNerdFont-Medium.ttf" ]]; then
    font_count="$(find /usr/local/share/fonts/JetBrainsMonoNerdFont -maxdepth 1 -type f -name '*.ttf' | wc -l)"
    if [[ "$font_count" == "1" ]]; then
        echo "JetBrains Mono Nerd Font: one TTF installed"
    else
        echo "${YELLOW}Warning: JetBrains Mono font directory contains $font_count TTF files.${ALL_OFF}"
    fi
else
    echo "${YELLOW}Warning: JetBrains Mono Nerd Font file was not found.${ALL_OFF}"
fi

for package in \
    hyprland noctalia uwsm greetd ufw \
    fish foot neovim fastfetch nwg-look \
    nautilus gvfs-mtp \
    imv evince upower gpu-screen-recorder qt6ct mpv \
    wl-clip-persist starship wireless-regdb; do
    if pacman -Q "$package" >/dev/null 2>&1; then
        echo "Package $package: installed"
    else
        echo "${YELLOW}Warning: Expected package $package is not installed.${ALL_OFF}"
    fi
done

for package in noctalia-greeter brave-origin-bin localsend-bin; do
    if pacman -Q "$package" >/dev/null 2>&1; then
        echo "AUR package $package: installed"
    else
        echo "${YELLOW}Warning: Expected AUR package $package is not installed.${ALL_OFF}"
    fi
done

echo ""
echo "${GREEN}Installation Complete.${ALL_OFF}"

# ============================================================
# 16. Reboot
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
            echo "Please reboot manually before testing the new graphical session."
            exit 0
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done
