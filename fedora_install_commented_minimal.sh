
#!/bin/bash

export LC_MESSAGES=C
export LANG=C

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

append_unique_package() {
    local -n package_list="$1"
    local package="$2"
    local existing_package

    for existing_package in "${package_list[@]}"; do
        if [ "$existing_package" = "$package" ]; then
            return 0
        fi
    done

    package_list+=("$package")
}

# Ensure running as root before collecting interactive input.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
fi

if ! command -v dnf >/dev/null 2>&1; then
    echo "ERROR: dnf was not found. This installer is intended for Fedora."
    exit 1
fi

# --- Pre-flight confirmation ---
echo "This script will install custom dot-files for Hyprland. Use at your own risk."
while true; do
    read -r -p "Would you like to proceed? (y/n): " proceed
    case "$proceed" in
        y|Y|yes|YES)
            echo "Great! Proceeding with installation..."
            break
            ;;
        n|N|no|NO)
            echo "Fair enough, Have a nice day."
            exit 0
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done

INSTALL_NVIDIA_OPTIONAL=0
while true; do
    echo ""
    read -r -p "Are you using an Nvidia GPU? (y/n): " nvidia_choice
    case "$nvidia_choice" in
        y|Y|yes|YES)
            INSTALL_NVIDIA_OPTIONAL=1
            echo "Nvidia-specific Hyprland options will be enabled."
            break
            ;;
        n|N|no|NO)
            INSTALL_NVIDIA_OPTIONAL=0
            echo "Skipping Nvidia-specific Hyprland options."
            break
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done

# --- Default install mode ---
INSTALL_DEFAULT=0
while true; do
    echo ""
    read -r -p "Would you like to use the default install? (y/n): " default_choice
    case "$default_choice" in
        y|Y|yes|YES)
            INSTALL_DEFAULT=1
            echo "Default install settings will be applied automatically."
            break
            ;;
        n|N|no|NO)
            INSTALL_DEFAULT=0
            echo "Using custom install settings."
            break
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done

echo "Enabling COPR repository: lionheartp/Hyprland..."
if ! dnf -y copr enable lionheartp/Hyprland; then
    echo "ERROR: Failed to enable COPR repository lionheartp/Hyprland."
    exit 1
fi

echo "Enabling COPR repository: leloubil/wl-clip-persist..."
if ! dnf -y copr enable leloubil/wl-clip-persist; then
    echo "ERROR: Failed to enable COPR repository leloubil/wl-clip-persist."
    exit 1
fi

echo "Enabling COPR repository: tofik/nwg-shell..."
if ! dnf -y copr enable tofik/nwg-shell; then
    echo "ERROR: Failed to enable COPR repository tofik/nwg-shell."
    exit 1
fi

echo "Installing RPM Fusion repositories..."
if ! dnf -y install \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"; then
    echo "ERROR: Failed to install RPM Fusion repositories."
    exit 1
fi

# DISABLED: echo "Installing Flatpak..."
# DISABLED: if ! dnf -y install flatpak; then
    # DISABLED: echo "ERROR: Failed to install Flatpak."
    # DISABLED: exit 1
# DISABLED: fi
# DISABLED: 
# DISABLED: echo "Adding Flathub flatpak remote..."
# DISABLED: if ! flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo; then
    # DISABLED: echo "ERROR: Failed to add Flathub remote."
    # DISABLED: exit 1
# DISABLED: fi
# DISABLED: 
# Add more Flatpaks here when you want them installed with the optional prompt.
# DISABLED: FLATPAK_OPTIONAL_PACKAGES=(
    # DISABLED: com.obsproject.Studio
    # DISABLED: com.teamspeak.TeamSpeak
    # DISABLED: com.vysp3r.ProtonPlus
    # DISABLED: org.gtk.Gtk3theme.adw-gtk3-dark
    # DISABLED: org.signal.Signal
    # DISABLED: org.upscayl.Upscayl
    # DISABLED: io.missioncenter.MissionCenter
# DISABLED: )
# DISABLED: 
# DISABLED: INSTALL_FLATPAK_OPTIONAL_PACKAGES=0
# DISABLED: if [ "$INSTALL_DEFAULT" -eq 1 ]; then
    # DISABLED: INSTALL_FLATPAK_OPTIONAL_PACKAGES=1
    # DISABLED: echo ""
    # DISABLED: echo "Optional Flatpak packages:"
    # DISABLED: for flatpak_package in "${FLATPAK_OPTIONAL_PACKAGES[@]}"; do
        # DISABLED: echo "  - $flatpak_package"
    # DISABLED: done
    # DISABLED: echo "Default install: optional Flatpak packages enabled."
# DISABLED: else
    # DISABLED: while true; do
        # DISABLED: echo ""
        # DISABLED: echo "Optional Flatpak packages:"
        # DISABLED: for flatpak_package in "${FLATPAK_OPTIONAL_PACKAGES[@]}"; do
            # DISABLED: echo "  - $flatpak_package"
        # DISABLED: done
        # DISABLED: read -r -p "Do you want to install optional Flatpak packages? (y/n): " flatpak_choice
        # DISABLED: case "$flatpak_choice" in
            # DISABLED: y|Y|yes|YES)
                # DISABLED: INSTALL_FLATPAK_OPTIONAL_PACKAGES=1
                # DISABLED: echo "Optional Flatpak packages will be installed."
                # DISABLED: break
                # DISABLED: ;;
            # DISABLED: n|N|no|NO)
                # DISABLED: INSTALL_FLATPAK_OPTIONAL_PACKAGES=0
                # DISABLED: echo "Skipping optional Flatpak packages."
                # DISABLED: break
                # DISABLED: ;;
            # DISABLED: *)
                # DISABLED: echo "Please answer 'y' or 'n'."
                # DISABLED: ;;
        # DISABLED: esac
    # DISABLED: done
# DISABLED: fi
# DISABLED: 
# --- Browser selection ---
BROWSER_CHOICE="none"
if [ "$INSTALL_DEFAULT" -eq 1 ]; then
    BROWSER_CHOICE="brave"
    echo ""
    echo "Browser setup option:"
    echo "  0. Skip browser installation"
    echo "  1. Firefox"
    echo "  2. Brave"
    echo "  3. Vivaldi"
    echo "Default install: Brave will be installed."
else
    while true; do
        echo ""
        echo "Browser setup option:"
        echo "  0. Skip browser installation"
        echo "  1. Firefox"
        echo "  2. Brave"
        echo "  3. Vivaldi"
        read -r -p "Choose browser option (0-3): " browser_choice
        case "$browser_choice" in
            0|"")
                BROWSER_CHOICE="none"
                echo "Skipping browser installation."
                break
                ;;
            1)
                BROWSER_CHOICE="firefox"
                echo "Firefox will be installed."
                break
                ;;
            2)
                BROWSER_CHOICE="brave"
                echo "Brave will be installed."
                break
                ;;
            3)
                BROWSER_CHOICE="vivaldi"
                echo "Vivaldi will be installed."
                break
                ;;
            *)
                echo "Please enter 0, 1, 2 or 3."
                ;;
        esac
    done
fi

echo "Installing Noctalia Hyprland meta package..."
if ! dnf in noctalia-hyprland-meta -y; then
    echo "ERROR: Failed to install noctalia-hyprland-meta."
    exit 1
fi

# --- Configuration ---
# echilon, tonekneeo, xnyte
# Get the actual user running the script (not root)
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    ACTUAL_USER="$SUDO_USER"
else
    ACTUAL_USER=$(logname 2>/dev/null)
fi

if [ -z "$ACTUAL_USER" ] || [ "$ACTUAL_USER" = "root" ]; then
    echo "ERROR: Could not determine a non-root target user. Run this script with sudo from your normal user account."
    exit 1
fi

ACTUAL_USER_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
if [ -z "$ACTUAL_USER_HOME" ] || [ ! -d "$ACTUAL_USER_HOME" ]; then
    echo "ERROR: Could not determine home directory for user '$ACTUAL_USER'."
    exit 1
fi

ensure_user_home_permissions() {
    sudo -u "$ACTUAL_USER" mkdir -p \
        "$ACTUAL_USER_HOME/.config" \
        "$ACTUAL_USER_HOME/.config/fish" \
        "$ACTUAL_USER_HOME/.local" \
        "$ACTUAL_USER_HOME/.local/share" \
        "$ACTUAL_USER_HOME/.local/share/fish" \
        "$ACTUAL_USER_HOME/.local/state"

    chown -R "$ACTUAL_USER:$ACTUAL_USER" \
        "$ACTUAL_USER_HOME/.config" \
        "$ACTUAL_USER_HOME/.local"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_USER_HOME"
}

verify_and_fix_user_home_permissions() {
    local dir
    local bad_paths=()

    for dir in \
        "$ACTUAL_USER_HOME/.config" \
        "$ACTUAL_USER_HOME/.config/fish" \
        "$ACTUAL_USER_HOME/.local" \
        "$ACTUAL_USER_HOME/.local/share" \
        "$ACTUAL_USER_HOME/.local/share/fish" \
        "$ACTUAL_USER_HOME/.local/state"; do
        if [ -e "$dir" ] && [ "$(stat -c '%U' "$dir" 2>/dev/null || echo root)" != "$ACTUAL_USER" ]; then
            bad_paths+=("$dir")
        fi
    done

    if [ ${#bad_paths[@]} -gt 0 ]; then
        echo "Fixing ownership of user config/state directories: ${bad_paths[*]}"
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "${bad_paths[@]}"
    fi
}

ensure_user_home_permissions
verify_and_fix_user_home_permissions

REPO_DIR="$SCRIPT_DIR"
CONFIG_DIR="$ACTUAL_USER_HOME/.config"

# Validate repo directory
if [ ! -d "$REPO_DIR/.config" ]; then
    echo "ERROR: Script must be run from the repository root directory."
    exit 1
fi

if [ ! -d "$REPO_DIR/.config/hypr" ]; then
    echo "ERROR: Could not find the Hyprland config directory inside your repository at '$REPO_DIR/.config/hypr'."
    exit 1
fi

# --- Gaming package selection ---
INSTALL_GAMING_PACKAGES=0
if [ "$INSTALL_DEFAULT" -eq 1 ]; then
    INSTALL_GAMING_PACKAGES=1
    echo "Default install: gaming packages will be installed."
else
    while true; do
        echo ""
        read -r -p "Do you want to install gaming packages (steam, mangohud, wine, winetricks)? (y/n): " gaming_choice
        case "$gaming_choice" in
            y|Y|yes|YES)
                INSTALL_GAMING_PACKAGES=1
                echo "Gaming packages will be installed."
                break
                ;;
            n|N|no|NO)
                INSTALL_GAMING_PACKAGES=0
                echo "Skipping gaming package installation."
                break
                ;;
            *)
                echo "Please answer 'y' or 'n'."
                ;;
        esac
    done
fi

# --- Bluetooth package selection ---
INSTALL_BLUETOOTH_PACKAGES=0
if [ "$INSTALL_DEFAULT" -eq 1 ]; then
    INSTALL_BLUETOOTH_PACKAGES=1
    echo "Default install: Bluetooth packages will be installed and service will be enabled."
else
    while true; do
        echo ""
        read -r -p "Do you want to install Bluetooth packages and enable the Bluetooth service? (y/n): " bluetooth_choice
        case "$bluetooth_choice" in
            y|Y|yes|YES)
                INSTALL_BLUETOOTH_PACKAGES=1
                echo "Bluetooth packages will be installed and service will be enabled."
                break
                ;;
            n|N|no|NO)
                INSTALL_BLUETOOTH_PACKAGES=0
                echo "Skipping Bluetooth package installation and service."
                break
                ;;
            *)
                echo "Please answer 'y' or 'n'."
                ;;
        esac
    done
fi

# --- Audio mode selection ---
AUDIO_MODE="easyeffects"
if [ "$INSTALL_DEFAULT" -eq 1 ]; then
    echo ""
    echo "Audio setup option:"
    echo "  0. Skip EasyEffects and Dolby setup"
    echo "  1. EasyEffects (default)"
    echo "  2. Dolby Atmos support"
    echo "Default install: EasyEffects will be used."
else
    while true; do
        echo ""
        echo "Audio setup option:"
        echo "  0. Skip EasyEffects and Dolby setup"
        echo "  1. EasyEffects (default)"
        echo "  2. Dolby Atmos support"
        read -r -p "Choose audio option (0-2): " audio_choice
        case "$audio_choice" in
            0)
                AUDIO_MODE="none"
                echo "Skipping EasyEffects and Dolby setup."
                break
                ;;
            1|"")
                AUDIO_MODE="easyeffects"
                echo "Using EasyEffects setup."
                break
                ;;
            2)
                AUDIO_MODE="dolby"
                echo "Dolby Atmos profile will be applied after installation."
                break
                ;;
            *)
                echo "Please enter 0, 1 or 2."
                ;;
        esac
    done
fi

# Define the list of core packages to install using dnf.
# Some packages are provided by COPR or third-party repositories.
PACKAGES=(
    # Core Components
    dbus                     # D-Bus for greetd / greeter session plumbing
    polkit                   # Polkit service used by the desktop and greeter
    accountsservice          # AccountsService for greeter avatars
    greetd                   # Login manager daemon for Noctalia Greeter
    noctalia-greeter-git         # Noctalia login greeter for greetd
    hyprland                 # Ensure compositor package/session is present
    xdg-desktop-portal-hyprland # Hyprland portal backend
    xorg-x11-server-Xwayland # Xwayland support for Wayland sessions
    mesa-dri-drivers         # OpenGL drivers (important on minimal installs/VMs)
    mesa-vulkan-drivers      # Vulkan drivers used by wlroots stack
    # DISABLED: xfce-polkit               # PolicyKit authentication agent
    # DISABLED: gnome-keyring             # Credential storage   
    # DISABLED: pavucontrol               # PulseAudio/PipeWire volume control
    playerctl                 # Media player controller
    # DISABLED: wlsunset                  # Nightlight for quickshell
    fish                      # Shell
    fastfetch                 # System Info Display
    # DISABLED: grim                      # Screenshot utility for wayland
    # DISABLED: slurp                     # Screenshot selector for region
    # DISABLED: hyprshot                  # Screenshot selector region - this is a standalone app
    # DISABLED: gedit                     # Gnome Advanced Text Editor
    nwg-look                  # Look and feel configuration
    # DISABLED: nwg-displays              # Configure Monitors 
    # DISABLED: kitty-shell-integration   # Kitty terminal shell integration
    # DISABLED: kitty-terminfo            # Terminfo for Kitty
    xdg-desktop-portal-gtk    # GTK implementation of xdg-desktop-portal
    xdg-user-dirs             # Manage user directories
    thunar                    # File Manager  
    thunar-media-tags-plugin  # Media tags plugin for Thunar
    # DISABLED: thunar-shares-plugin      # Shares plugin for Thunar
    # DISABLED: thunar-vcs-plugin         # VCS integration plugin for Thunar
    thunar-volman             # Volume management plugin for Thunar
    thunar-archive-plugin     # Archive plugin for Thunar
    # DISABLED: grub2-tools               # GRUB tooling
    # DISABLED: gcolor3                   # Color picker
    # DISABLED: gnome-calculator          # Math n stuff...
    tumbler                   # Thumbnailer
    power-profiles-daemon     # Power profile management
    # DISABLED: file-roller               # Archive manager
    unrar                     # RAR archive support
    unzip                     # ZIP archive support
    p7zip                     # 7z archive support
    # DISABLED: p7zip-plugins             # Additional 7z formats
    cava                      # Audio visualizer
    # DISABLED: gnome-disk-utility        # Disk Management
    libopenraw                # Lib for Tumbler
    libgsf                    # Lib for Tumbler
    poppler-glib              # Lib for Tumbler
    ffmpegthumbnailer         # Lib for Tumbler 
    freetype                  # Lib for Tumbler
    libgepub                  # Lib for Tumbler
    gvfs                      # Needed for Thunar to see drives
    # DISABLED: gvfs-afc                  # Apple Device Support
    gvfs-mtp                  # Android/MTP Device Support
    # DISABLED: gvfs-smb                  # SMB Support 
    # DISABLED: ntfs-3g                   # NTFS filesystem support
    dosfstools                # DOS filesystem utilities
    exfatprogs                # exFAT filesystem support
    # DISABLED: clang                     # Build package
    # DISABLED: cmake                     # Cross-platform build system
    # DISABLED: golang                    # Go programming language compiler
    # DISABLED: rust                      # Rust programming language compiler
    # DISABLED: pkgconf                   # Package config system
    # DISABLED: meson                     # Modern build system
    # DISABLED: ninja-build               # Small build system focused on speed
    matugen                   # Color Generation
    adw-gtk-theme             # Libadwaita theme
    loupe                     # Image viewer
    # DISABLED: cpupower                  # CPU frequency scaling utilities
    upower                    # Power management service
    gpu-screen-recorder       # Screen Recorder
    qt6-qtbase                # Qt6 base libraries and tools
    qt6ct                     # Qt Settings
    yaru-icon-theme           # Yaru Icons
    # DISABLED: humanity-icon-theme       # Humanity Icons
    # DISABLED: google-noto-emoji-fonts   # Emoji font
    # DISABLED: dejavu-sans-fonts         # Fonts
    gst-plugins-good          # Gstreamer Plugins 
    gst-plugins-ugly          # Gstreamer Plugins
    gst-libav                 # Gstreamer Plugins
    # DISABLED: qt6-qtwebsockets          # Websocket
    # DISABLED: os-prober                 # Os prober for Grub
    adw-gtk3-theme            # GTk Theme
    # DISABLED: gnome-software            # Software Store
    # DISABLED: plasma-pa                 # Audio Management
    mpv                       # Video Player
    # DISABLED: rocm-opencl               # ROCm OpenCL platform
    # DISABLED: rocm-hip                  # ROCm HIP platform
    wl-clip-persist           # Clipboard persistence
    # DISABLED: nwg-displays              # Display configuration tool
    # DISABLED: lm_sensors                # Hardware monitoring
    # DISABLED: nethogs                   # Network monitoring
    ImageMagick               # Image manipulation tools
)

# Audio stack is selected at runtime.
if [ "$AUDIO_MODE" = "easyeffects" ]; then
    PACKAGES+=(
        easyeffects               # Audio Effects
        calf                      # Easyeffects Plugins
    )
fi

# --- Color Functions ---
disable_colors() {
    unset ALL_OFF BOLD BLUE GREEN RED YELLOW CYAN MAGENTA
}

enable_colors() {
    if tput setaf 0 &>/dev/null; then
        ALL_OFF="$(tput sgr0)"
        BOLD="$(tput bold)"
        RED="${BOLD}$(tput setaf 1)"
        GREEN="${BOLD}$(tput setaf 2)"
        YELLOW="${BOLD}$(tput setaf 3)"
        BLUE="${BOLD}$(tput setaf 4)"
        MAGENTA="${BOLD}$(tput setaf 5)"
        CYAN="${BOLD}$(tput setaf 6)"
    else
        ALL_OFF="\e[0m"
        BOLD="\e[1m"
        RED="${BOLD}\e[31m"
        GREEN="${BOLD}\e[32m"
        YELLOW="${BOLD}\e[33m"
        BLUE="${BOLD}\e[34m"
        MAGENTA="${BOLD}\e[35m"
        CYAN="${BOLD}\e[36m"
    fi
    readonly ALL_OFF BOLD BLUE GREEN RED YELLOW CYAN MAGENTA
}

if [[ -t 2 ]]; then
    enable_colors
else
    disable_colors
fi

# --- Main Installation Functions ---

install_dnf_packages() {
    local installable_packages=()
    local unavailable_packages=()
    local pkg

    for pkg in "$@"; do
        if rpm -q "$pkg" >/dev/null 2>&1 || dnf -q list --available "$pkg" >/dev/null 2>&1; then
            installable_packages+=("$pkg")
        else
            unavailable_packages+=("$pkg")
        fi
    done

    if [ ${#unavailable_packages[@]} -gt 0 ]; then
        echo "Skipping unavailable packages: ${unavailable_packages[*]}"
    fi

    if [ ${#installable_packages[@]} -eq 0 ]; then
        echo "ERROR: No installable packages were found in the provided package list."
        return 1
    fi

    dnf install -y "${installable_packages[@]}"
}

install_gaming_packages() {
    if [ "$INSTALL_GAMING_PACKAGES" -ne 1 ]; then
        return 0
    fi

    echo -e "\n--- Gaming Packages Installation ---"
    echo "Installing gaming packages..."
    if ! dnf in steam mangohud wine winetricks -y; then
        echo "Warning: Some gaming packages failed to install."
    fi
}

install_bluetooth_packages() {
    if [ "$INSTALL_BLUETOOTH_PACKAGES" -ne 1 ]; then
        return 0
    fi

    echo -e "\n--- Bluetooth Installation ---"
    echo "Installing Bluetooth packages..."
    if ! install_dnf_packages bluez blueman; then
        echo "Warning: Some Bluetooth packages failed to install."
    fi

    echo "Enabling Bluetooth service..."
    systemctl enable bluetooth

    if [ $? -ne 0 ]; then
        echo "Warning: Failed to enable Bluetooth service."
    fi
}

# DISABLED: ensure_flatpak_available() {
    # DISABLED: if command -v flatpak >/dev/null 2>&1; then
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: echo "ERROR: Flatpak is not installed yet. Skipping Flatpak-based installs."
    # DISABLED: return 1
# DISABLED: }

enable_accounts_daemon() {
    echo -e "\n--- AccountsService Setup ---"
    echo "Enabling accounts-daemon service..."
    if systemctl enable accounts-daemon; then
        echo "accounts-daemon service enabled."
    else
        echo "Warning: Failed to enable accounts-daemon.service."
    fi
}

setup_noctalia_greeter() {
    echo -e "\n--- Noctalia Greeter Setup ---"

    local greetd_config_file="/etc/greetd/config.toml"
    local greeter_user="greeter"
    local session_bin="/usr/bin/noctalia-greeter-session"

    if command -v noctalia-greeter-session >/dev/null 2>&1; then
        session_bin=$(command -v noctalia-greeter-session)
    fi

    if ! id -u "$greeter_user" >/dev/null 2>&1; then
        echo "Creating greeter user '$greeter_user'..."
        useradd -r -s /usr/bin/nologin -d /var/lib/noctalia-greeter "$greeter_user"
    fi

    echo "Preparing greeter state directory..."
    mkdir -p /var/lib/noctalia-greeter
    chown -R "$greeter_user:$greeter_user" /var/lib/noctalia-greeter

    if [ -f "$greetd_config_file" ]; then
        cp -a "$greetd_config_file" "$greetd_config_file.bak.$(date +%s)"
    fi

    echo "Writing greetd configuration to $greetd_config_file..."
    mkdir -p /etc/greetd
    cat > "$greetd_config_file" <<EOF
[terminal]
vt = 1

[default_session]
command = "$session_bin"
user = "$greeter_user"
EOF

    if [ -x /usr/share/noctalia-greeter/setup_greetd_pam.sh ]; then
        echo "Configuring greetd PAM integration for Noctalia Greeter..."
        if ! bash /usr/share/noctalia-greeter/setup_greetd_pam.sh; then
            echo "Warning: greetd PAM setup failed."
        fi
    else
        echo "Warning: /usr/share/noctalia-greeter/setup_greetd_pam.sh was not found."
    fi
}

enable_greetd_service() {
    echo -e "\n--- Display Manager Setup ---"
    echo "Enabling greetd service..."
    if systemctl enable greetd; then
        echo "greetd service enabled."
    else
        echo "Warning: Failed to enable greetd.service."
    fi

    echo "Setting default boot target to graphical.target..."
    if systemctl set-default graphical.target; then
        echo "Default target set to graphical.target."
    else
        echo "Warning: Failed to set default target to graphical.target."
    fi

    local current_target
    current_target=$(systemctl get-default 2>/dev/null || true)
    if [ -n "$current_target" ]; then
        echo "Current default target: $current_target"
    fi
}

# Deploy configuration files from repo/.config to ~/.config
deploy_configs() {
    echo "Deploying configuration files..."
    
    CONFIG_SOURCE_ROOT="$REPO_DIR/.config"
    
    if [ ! -d "$CONFIG_SOURCE_ROOT" ]; then
        echo "FATAL ERROR: Could not find the '.config' directory inside your repository at '$REPO_DIR'."
        return
    fi

    # Ensure target .config directory exists
    sudo -u "$ACTUAL_USER" mkdir -p "$CONFIG_DIR"

    # Back up any existing configs that would be overwritten
    BACKUP_TIMESTAMP=$(date +%s)
    echo "Backing up existing configuration files..."

    for item in "$CONFIG_SOURCE_ROOT"/*; do
        name=$(basename "$item")
        target="$CONFIG_DIR/$name"
        if [ "$name" = "hypr" ]; then
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            echo "  -> Backing up: $name to $name.bak.$BACKUP_TIMESTAMP"
            mv "$target" "$CONFIG_DIR/$name.bak.$BACKUP_TIMESTAMP"
        fi
    done

    if [ -e "$CONFIG_DIR/hypr" ] || [ -L "$CONFIG_DIR/hypr" ]; then
        echo "  -> Backing up: hypr to hypr.bak.$BACKUP_TIMESTAMP"
        mv "$CONFIG_DIR/hypr" "$CONFIG_DIR/hypr.bak.$BACKUP_TIMESTAMP"
    fi

    # Copy all configuration files from repo/.config to ~/.config
    echo "Copying configuration files from $CONFIG_SOURCE_ROOT to $CONFIG_DIR..."
    cp -rf "$CONFIG_SOURCE_ROOT"/* "$CONFIG_DIR"/
    
    if [ $? -eq 0 ]; then
        echo "Configuration files copied successfully!"
        
        # Fix ownership since we're running as root

# DISABLED: install_flatpak_optional_packages() {
    # DISABLED: if [ "$INSTALL_FLATPAK_OPTIONAL_PACKAGES" -ne 1 ]; then
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: if ! ensure_flatpak_available; then
        # DISABLED: return 1
    # DISABLED: fi
# DISABLED: 
    # DISABLED: echo -e "\n--- Optional Flatpak Packages Installation ---"
    # DISABLED: echo "Installing optional Flatpak packages..."
# DISABLED: 
    # DISABLED: local flatpak_package
    # DISABLED: local failed_packages=()
# DISABLED: 
    # DISABLED: for flatpak_package in "${FLATPAK_OPTIONAL_PACKAGES[@]}"; do
        # DISABLED: echo "Installing $flatpak_package..."
        # DISABLED: if ! flatpak install -y flathub "$flatpak_package"; then
            # DISABLED: echo "Warning: Failed to install $flatpak_package."
            # DISABLED: failed_packages+=("$flatpak_package")
        # DISABLED: fi
    # DISABLED: done
# DISABLED: 
    # DISABLED: if [ ${#failed_packages[@]} -gt 0 ]; then
        # DISABLED: echo "Warning: Some optional Flatpak packages failed to install: ${failed_packages[*]}"
    # DISABLED: fi
# DISABLED: }

install_browser_choice() {
    if [ "$BROWSER_CHOICE" = "none" ]; then
        return 0
    fi

    echo -e "\n--- Browser Installation ---"

    case "$BROWSER_CHOICE" in
        firefox)
            echo "Installing Firefox via dnf..."
            if ! dnf in firefox -y; then
                echo "Warning: Firefox installation failed."
            fi
            ;;
        brave)
            echo "Installing Brave via the official Fedora installer..."
            if ! curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh; then
                echo "Warning: Brave installation failed."
            fi
            ;;
        vivaldi)
            if ! ensure_flatpak_available; then
                return 1
            fi
            echo "Installing Vivaldi via Flatpak..."
            if ! flatpak install -y flathub com.vivaldi.Vivaldi; then
                echo "Warning: Vivaldi installation failed."
            fi
            ;;
        *)
            echo "Warning: Unknown browser choice '$BROWSER_CHOICE'. Skipping browser installation."
            ;;
    esac
}

# DISABLED: install_satty_flatpak() {
    # DISABLED: echo -e "\n--- Satty Flatpak Installation ---"
# DISABLED: 
    # DISABLED: if ! ensure_flatpak_available; then
        # DISABLED: return 1
    # DISABLED: fi
# DISABLED: 
    # DISABLED: if ! command -v curl >/dev/null 2>&1; then
        # DISABLED: echo "Warning: curl is not installed. Skipping Satty Flatpak install."
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: local release_api="https://api.github.com/repos/Satty-org/Satty/releases/latest"
    # DISABLED: local release_json
    # DISABLED: local asset_name
    # DISABLED: local download_url
    # DISABLED: local tmp_dir
    # DISABLED: local bundle_path
# DISABLED: 
    # DISABLED: echo "Fetching latest Satty release metadata..."
    # DISABLED: if ! release_json=$(curl -fsSL "$release_api"); then
        # DISABLED: echo "Warning: Failed to fetch Satty release metadata. Skipping Satty install."
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: asset_name=$(printf '%s\n' "$release_json" | sed -n 's/.*"name": "\(satty-v[^"]*\.flatpak\)".*/\1/p' | head -n 1)
    # DISABLED: download_url=$(printf '%s\n' "$release_json" | sed -n 's/.*"browser_download_url": "\(https:[^"]*satty-v[^"]*\.flatpak\)".*/\1/p' | head -n 1)
# DISABLED: 
    # DISABLED: if [ -z "$asset_name" ] || [ -z "$download_url" ]; then
        # DISABLED: echo "Warning: Could not find a Satty Flatpak asset in the latest release."
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: tmp_dir=$(mktemp -d)
    # DISABLED: bundle_path="$tmp_dir/$asset_name"
# DISABLED: 
    # DISABLED: echo "Downloading $asset_name..."
    # DISABLED: if ! curl -fL "$download_url" -o "$bundle_path"; then
        # DISABLED: echo "Warning: Failed to download Satty Flatpak bundle."
        # DISABLED: rm -rf "$tmp_dir"
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: echo "Installing Satty Flatpak bundle..."
    # DISABLED: if flatpak install -y --system "$bundle_path"; then
        # DISABLED: echo "Satty Flatpak installed successfully."
    # DISABLED: else
        # DISABLED: echo "Warning: Satty Flatpak installation failed."
    # DISABLED: fi
# DISABLED: 
    # DISABLED: rm -rf "$tmp_dir"
# DISABLED: }

install_starship() {
    echo -e "\n--- Starship Installation ---"
    echo "Installing Starship prompt..."

    if curl -sS https://starship.rs/install.sh | sh -s -- -y; then
        echo "Starship installed successfully."
    else
        echo "Warning: Starship installation failed."
    fi
}
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"

    else
        echo "ERROR: Failed to copy configuration files."
    fi
}

install_wallpaper() {
    local wallpaper_source="$REPO_DIR/minimaLinux.png"
    local wallpapers_dir="$ACTUAL_USER_HOME/Pictures/Wallpapers"

    echo "Installing wallpaper..."

    if [ ! -f "$wallpaper_source" ]; then
        echo "Warning: Wallpaper '$wallpaper_source' not found."
        return 0
    fi

    sudo -u "$ACTUAL_USER" mkdir -p "$wallpapers_dir"
    cp -f "$wallpaper_source" "$wallpapers_dir/"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$wallpapers_dir/minimaLinux.png"
    echo "Wallpaper installed at $wallpapers_dir/minimaLinux.png."
}

install_noctalia_state() {
    local state_source="$REPO_DIR/.local/state/noctalia"
    local state_dir="$ACTUAL_USER_HOME/.local/state"
    local noctalia_state_dir="$state_dir/noctalia"

    echo "Installing Noctalia state files..."

    if [ ! -d "$state_source" ]; then
        echo "Warning: Noctalia state directory '$state_source' not found."
        return 0
    fi

    sudo -u "$ACTUAL_USER" mkdir -p "$state_dir"
    cp -rf "$state_source" "$state_dir/"
    chown -R "$ACTUAL_USER:$ACTUAL_USER" "$ACTUAL_USER_HOME/.local"
    echo "Noctalia state files installed at $noctalia_state_dir."
}

update_hypr_startup_config() {
    local startup_file="$ACTUAL_USER_HOME/.config/hypr/startup.lua"
    # DISABLED: local polkit_match='polkit-gnome-authentication-agent-1'
# DISABLED: 
    # DISABLED: if [ ! -f "$startup_file" ]; then
        # DISABLED: echo "Warning: Hyprland startup file '$startup_file' not found."
        # DISABLED: return 0
    # DISABLED: fi
# DISABLED: 
    # DISABLED: if grep -qF "$polkit_match" "$startup_file"; then
        # DISABLED: echo "Updating Hyprland startup command in $startup_file..."
        # DISABLED: sed -i '/polkit-gnome-authentication-agent-1/c\    "sleep 1 \&\& \/usr\/libexec\/xfce-polkit",' "$startup_file"
        # DISABLED: if grep -qF '"sleep 1 && /usr/libexec/xfce-polkit",' "$startup_file"; then
            # DISABLED: echo "Hyprland xfce-polkit startup command updated successfully."
        # DISABLED: else
            # DISABLED: echo "Warning: Failed to update polkit startup command in '$startup_file'."
        # DISABLED: fi
    # DISABLED: else
        # DISABLED: echo "Warning: Expected polkit startup line not found in '$startup_file'."
    # DISABLED: fi

    if [ "$INSTALL_NVIDIA_OPTIONAL" -eq 1 ]; then
        if grep -qF 'local enable_nvidia_optional = false' "$startup_file"; then
            echo "Enabling Nvidia-specific Hyprland options in $startup_file..."
            sed -i 's|^local enable_nvidia_optional = false$|local enable_nvidia_optional = true|' "$startup_file"
        else
            echo "Warning: Expected Nvidia toggle line not found in '$startup_file'."
        fi
    fi
}

# Set executable permissions for scripts
set_permissions() {
    SCRIPTS_PATH="$ACTUAL_USER_HOME/.config/hypr/Scripts"
    
    if [ -d "$SCRIPTS_PATH" ]; then
        echo "Setting execution permissions for scripts..."
        find "$SCRIPTS_PATH" -type f -exec chmod +x {} \;
    else
        echo "Warning: Hyprland scripts directory '$SCRIPTS_PATH' not found."
    fi
}

# Set default file manager to Thunar
set_default_file_manager() {
    echo ""
    echo "Setting Thunar as default file manager..."
    # Ensure the user config directory exists so xdg-mime writes to the correct path.
    sudo -u "$ACTUAL_USER" mkdir -p "$ACTUAL_USER_HOME/.config"
    sudo -u "$ACTUAL_USER" xdg-mime default thunar.desktop inode/directory application/x-gnome-saved-search
    echo "Default file manager set to Thunar."
}

# Create GTK bookmarks for Thunar
create_thunar_bookmarks() {
    echo ""
    echo "Creating Thunar bookmarks..."

    local gtk_dir="$ACTUAL_USER_HOME/.config/gtk-3.0"
    local bookmarks_file="$gtk_dir/bookmarks"

    sudo -u "$ACTUAL_USER" mkdir -p "$gtk_dir"

    sudo -u "$ACTUAL_USER" tee "$bookmarks_file" >/dev/null <<EOF
file://$ACTUAL_USER_HOME/Documents
file://$ACTUAL_USER_HOME/Downloads
file://$ACTUAL_USER_HOME/Pictures
file://$ACTUAL_USER_HOME/Music
file://$ACTUAL_USER_HOME/Videos
file://$ACTUAL_USER_HOME/.config/hypr
EOF

    echo "Thunar bookmarks created at $bookmarks_file."
}

# Copy backup config files if available
copy_backup_configs() {
    echo -e "\n--- Optional: Copy Backup Configs ---"
    
    local config_source="$REPO_DIR/backup/.config"
    
    if [[ ! -d "$config_source" ]]; then
        echo "No backup folder found at $REPO_DIR/backup/.config"
        echo "Skipping backup config restoration."
        return 0
    fi
    
    echo "Found backup configs at: $config_source"
    echo "Restoring config files from backup automatically..."
    cp -rf "$config_source"/* "$CONFIG_DIR"/
    
    if [ $? -eq 0 ]; then
        echo "Config files copied successfully!"
        
        # Fix ownership since we're running as root
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$CONFIG_DIR"

        # If running under Hyprland, reload it to apply config changes
        if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
            echo "Detected Hyprland environment. Reloading Hyprland to apply new configs..."
            hyprctl reload 2>/dev/null || echo "Note: Could not reload Hyprland. You may need to restart it manually."
            sleep 2
        fi
    else
        echo "ERROR: Failed to copy backup config files."
    fi
}

# Apply optional Dolby PipeWire profile
apply_dolby_pipewire_profile() {
    if [ "$AUDIO_MODE" != "dolby" ]; then
        return 0
    fi

    local pipewire_source="$REPO_DIR/pipewire"
    local pipewire_target="$CONFIG_DIR/pipewire"

    echo -e "\n--- Applying Dolby PipeWire Profile ---"

    if [ ! -d "$pipewire_source" ]; then
        echo "Warning: Dolby profile selected, but no '$pipewire_source' folder was found."
        return 0
    fi

    echo "Copying Dolby PipeWire config to $pipewire_target..."
    sudo -u "$ACTUAL_USER" mkdir -p "$pipewire_target"
    cp -rf "$pipewire_source"/* "$pipewire_target"/

    if [ $? -eq 0 ]; then
        chown -R "$ACTUAL_USER:$ACTUAL_USER" "$pipewire_target"
        echo "Dolby PipeWire profile applied successfully."
    else
        echo "Warning: Failed to apply Dolby PipeWire profile."
    fi
}

post_install_hyprland_checks() {
    local session_file="/usr/share/wayland-sessions/hyprland.desktop"

    echo -e "\n--- Hyprland Session Sanity Check ---"

    if [ ! -f "$session_file" ]; then
        echo "Warning: $session_file was not found."
        echo "greetd will not be able to launch Hyprland if no Wayland session is installed."
        echo "Try: dnf install -y hyprland"
    else
        echo "Found Hyprland session file: $session_file"
    fi

    if systemctl list-unit-files | grep -q '^greetd\.service'; then
        echo "Detected greetd on this system."
        if ! systemctl is-enabled greetd >/dev/null 2>&1; then
            echo "Note: greetd.service is not enabled."
            echo "Enable it with: systemctl enable greetd"
        fi
    fi
}

# --- Main Installation Flow ---

echo "Starting Hyprland Dotfiles Installation..."

# 2. Install Core Packages
echo "Installing required core packages via dnf..."
echo "installing core packages in 3..."
echo "2..."
echo "1!"
echo "Please Wait..."
if ! install_dnf_packages "${PACKAGES[@]}"; then
    echo "ERROR: Failed to install core packages. Aborting installation."
    exit 1
fi

# 2.5 Optional gaming packages (interactive)
install_gaming_packages

# 2.7 Optional Bluetooth support
install_bluetooth_packages

# 2.8 AccountsService for login avatars
enable_accounts_daemon

# 2.9 Configure Noctalia Greeter + greetd display manager
setup_noctalia_greeter
enable_greetd_service

# 4. Update user directories
echo "Updating user directories..."
sudo -u "$ACTUAL_USER" xdg-user-dirs-update

if [ $? -ne 0 ]; then
    echo "Warning: Failed to update user directories."
fi

echo "Base package installation complete!"
echo "--------------------------------------------------------"
echo "Proceeding with post-install configuration..."
echo "--------------------------------------------------------"

# Refresh and upgrade system packages before post-install package setup
echo "Updating system packages before installing Noctalia..."
dnf upgrade -y

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to update system packages. Aborting installation."
    exit 1
fi

# Set default file manager to Thunar
set_default_file_manager

# Deploy Configurations
deploy_configs

# Install wallpaper
install_wallpaper

# Install Noctalia state files
install_noctalia_state

# Copy backup config files if available
copy_backup_configs

# Update Hyprland startup command for Fedora
update_hypr_startup_config

# Create Thunar bookmarks
create_thunar_bookmarks

# Set Script Permissions
set_permissions

# Apply optional Dolby PipeWire profile
apply_dolby_pipewire_profile

# Optional Flatpak packages (run after all other package/setup operations)
# DISABLED: install_flatpak_optional_packages

# Browser installation stays separate from the core and optional package groups
install_browser_choice
# DISABLED: 
# Satty Flatpak installation from latest GitHub release
# DISABLED: install_satty_flatpak

# Install Starship shell prompt
install_starship

# Validate session essentials that otherwise cause greetd/Hyprland login issues
post_install_hyprland_checks

# Ensure Thunar remains the default file manager right before reboot
sudo -u "$ACTUAL_USER" xdg-mime default thunar.desktop inode/directory
sudo -u "$ACTUAL_USER" xdg-mime default thunar.desktop application/x-gnome-saved-search

# Reboot confirmation
echo ""
echo "Installation complete! Time to reboot."
while true; do
    read -r -p "Would you like to reboot now? (y/n): " reboot_choice
    case "$reboot_choice" in
        y|Y|yes|YES)
            echo "Rebooting now..."
            sudo reboot now
            break
            ;;
        n|N|no|NO)
            echo ""
            echo "Installation complete! Time to reboot."
            ;;
        *)
            echo "Please answer 'y' or 'n'."
            ;;
    esac
done

