#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_user() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run script as root! Run as regular user."
        exit 1
    fi
}

check_yay() {
    if ! command -v yay &> /dev/null; then
        print_info "yay not installed. Installing..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        if [ $? -eq 0 ]; then
            print_success "yay installed successfully"
        else
            print_error "Failed to install yay"
            exit 1
        fi
    fi
}

check_dependencies() {
    local deps=("git" "curl" "wget" "makepkg")
    local missing=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        print_info "Installing missing dependencies: ${missing[*]}"
        sudo pacman -S --needed --noconfirm "${missing[@]}"
    fi
}

create_temp_dir() {
    TEMP_DIR=$(mktemp -d)
    if [ ! -d "$TEMP_DIR" ]; then
        print_error "Failed to create temp directory"
        exit 1
    fi
    print_info "Temp directory: $TEMP_DIR"
}

download_config() {
    print_info "Downloading configs from GitHub..."

    GITHUB_URL="https://github.com/Koz0chka/.config.git"

    if git clone --depth 1 "$GITHUB_URL" "$TEMP_DIR/config" 2>/dev/null; then
        print_success "Configs downloaded successfully"
    else
        print_error "Failed to download configs"
        exit 1
    fi
}

install_official_packages() {
    print_info "Installing packages from official repositories..."

    OFFICIAL_PACKAGES=(
        hyprland hyprcursor hyprlang hyprutils
        kitty waybar grim slurp swww
        xdg-desktop-portal-hyprland wayland wayland-protocols
        fastfetch rofi yazi code
    )

    sudo pacman -S --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"
}

install_aur_packages() {
    print_info "Installing packages from AUR..."

    AUR_PACKAGES=(
        hyprland-qt-support hyprland-qtutils
        hyprgraphics hyprsunset hyprwayland-scanner
        kitty-shell-integration kitty-terminfo
        nwg-bar waypaper grimblast-git librewolf v2rayn
    )

    for pkg in "${AUR_PACKAGES[@]}"; do
        print_info "Installing $pkg from AUR..."
        yay -S --noconfirm --needed "$pkg"
    done
}

copy_config() {
    print_info "Copying configs to ~/.config..."

    CONFIG_SRC="$TEMP_DIR/config"
    CONFIG_DEST="$HOME/.config"

    if [ ! -d "$CONFIG_SRC" ]; then
        print_error "Config source not found"
        exit 1
    fi

    if [ -d "$CONFIG_DEST" ]; then
        BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
        print_info "Creating backup of existing .config in $BACKUP_DIR"
        cp -r "$CONFIG_DEST" "$BACKUP_DIR"
    fi

    mkdir -p "$CONFIG_DEST"

    rsync -a --progress "$CONFIG_SRC"/ "$CONFIG_DEST"/

    print_success "Configs copied successfully"
}

activate_exec_script() {
    print_info "Activating exec.conf script..."

    EXEC_SCRIPT="$HOME/.config/hypr/config/exec.conf"

    if [ -f "$EXEC_SCRIPT" ]; then
        if bash -n "$EXEC_SCRIPT"; then
            if [ ! -x "$EXEC_SCRIPT" ]; then
                chmod +x "$EXEC_SCRIPT"
            fi

            print_info "Starting exec.conf..."
            bash "$EXEC_SCRIPT" &
            print_success "exec.conf script started"
        else
            print_warning "exec.conf contains syntax errors"
        fi
    else
        print_warning "exec.conf not found: $EXEC_SCRIPT"
    fi
}

install_hyprland_deps() {
    print_info "Checking additional Hyprland dependencies..."

    HYPRLAND_DEPS=(
        polkit-kde-agent
        qt5-wayland
        qt6-wayland
        xdg-utils
        wl-clipboard
        networkmanager
        bluez
        bluez-utils
    )

    sudo pacman -S --needed --noconfirm "${HYPRLAND_DEPS[@]}"
}

setup_services() {
    print_info "Setting up services..."

    if pacman -Q bluez &> /dev/null; then
        sudo systemctl enable --now bluetooth.service
    fi
}

cleanup() {
    print_info "Cleaning temp files..."

    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
        print_success "Temp files removed"
    fi
}

verify_installation() {
    print_info "Verifying package installation..."

    ALL_PACKAGES=(
        hyprcursor hyprgraphics hyprland hyprland-qt-support hyprland-qtutils
        hyprlang hyprsunset hyprutils hyprwayland-scanner fastfetch
        kitty kitty-shell-integration kitty-terminfo nwg-bar waybar
        waypaper grim grimblast-git slurp swww xdg-desktop-portal-hyprland
        wayland wayland-protocols snixembed
    )

    local missing=()
    for pkg in "${ALL_PACKAGES[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null && ! yay -Q "$pkg" &> /dev/null; then
            missing+=("$pkg")
        fi
    done

    if [ ${#missing[@]} -ne 0 ]; then
        print_warning "Following packages not installed:"
        printf '%s\n' "${missing[@]}"
        print_info "You can install them manually later"
    else
        print_success "All packages installed successfully!"
    fi
}

main() {
    print_info "=== Hyprland config installation for Arch Linux ==="

    check_user
    check_dependencies
    check_yay
    create_temp_dir
    download_config
    install_official_packages
    install_aur_packages
    install_hyprland_deps
    copy_config
    setup_services
    activate_exec_script
    verify_installation
    cleanup

    print_success "=== Installation completed successfully! ==="
    echo ""
    print_info "Recommended actions:"
    print_info "1. Reboot system: sudo reboot"
    print_info "2. Or restart Hyprland: Hyprland"
    print_info "3. Check settings in ~/.config/"
    echo ""
    print_warning "Remember to check config files"
}

trap 'print_error "Script interrupted"; cleanup; exit 1' INT TERM
trap cleanup EXIT

main "$@"
