#!/usr/bin/env bash
# Modern CLI tools installer
# Kepano: one script, logged output, no interactivity

set -euo pipefail

# Logging setup - all output timestamped to file and stdout
LOG_FILE="${HOME}/.local/log/dotfiles-install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $msg" | tee -a "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_ok() { log " OK " "$@"; }
log_skip() { log "SKIP" "$@"; }
log_err() { log "ERR " "$@"; }

# Detect platform
detect_platform() {
    case "$OSTYPE" in
        darwin*) echo "macos" ;;
        linux*) echo "linux" ;;
        *) log_err "Unsupported OS: $OSTYPE"; exit 1 ;;
    esac
}

# Check if command exists
has() { command -v "$1" &>/dev/null; }

has_noto_serif() {
    if has fc-list; then
        fc-list 2>/dev/null | grep -qi "Noto Serif"
        return $?
    fi
    return 1
}

# Detect package manager
detect_pkg_manager() {
    if has pacman; then echo "pacman"
    elif has apt; then echo "apt"
    elif has dnf; then echo "dnf"
    elif has brew; then echo "brew"
    else log_err "No supported package manager found"; exit 1
    fi
}

# Install package via system package manager
pkg_install() {
    local pkg="$1"
    local cmd="${2:-$1}"

    if has "$cmd"; then
        log_skip "$pkg (already installed)"
        return 0
    fi

    log_info "Installing $pkg..."
    case "$PKG_MGR" in
        pacman) sudo pacman -S --noconfirm "$pkg" ;;
        apt) sudo apt-get install -y "$pkg" ;;
        dnf) sudo dnf install -y "$pkg" ;;
        brew) brew install "$pkg" ;;
    esac
    log_ok "$pkg installed"
}

# Install from GitHub release binary
github_install() {
    local repo="$1"
    local binary="$2"
    local tarball_pattern="$3"

    if has "$binary"; then
        log_skip "$binary (already installed)"
        return 0
    fi

    log_info "Installing $binary from $repo..."
    local version
    version=$(curl -sL "https://api.github.com/repos/$repo/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    if [[ -z "$version" ]]; then
        log_err "Could not detect latest release for $repo"
        return 1
    fi
    local url="https://github.com/$repo/releases/download/$version/$tarball_pattern"
    url="${url//\{version\}/$version}"
    url="${url//\{version_num\}/${version#v}}"

    local tmp_dir
    tmp_dir=$(mktemp -d)
    curl -sL "$url" -o "$tmp_dir/archive.tar.gz"
    tar xzf "$tmp_dir/archive.tar.gz" -C "$tmp_dir"

    # Find and install binary
    local bin_path
    bin_path=$(find "$tmp_dir" -name "$binary" -type f | head -1)
    if [[ -n "$bin_path" ]]; then
        sudo install -m 755 "$bin_path" /usr/local/bin/
        log_ok "$binary installed"
    else
        log_err "Binary $binary not found in release"
        return 1
    fi
    rm -rf "$tmp_dir"
}

# Install via install script
script_install() {
    local name="$1"
    local cmd="$2"
    local url="$3"
    local args="${4:-}"
    local -a arg_array=()

    if has "$cmd"; then
        log_skip "$name (already installed)"
        return 0
    fi

    log_info "Installing $name..."
    if [[ -n "$args" ]]; then
        read -r -a arg_array <<<"$args"
        curl -sS "$url" | bash -s -- "${arg_array[@]}"
    else
        curl -sS "$url" | bash
    fi
    log_ok "$name installed"
}

# Cargo install
cargo_install() {
    local pkg="$1"
    local cmd="${2:-$1}"

    if has "$cmd"; then
        log_skip "$pkg (already installed)"
        return 0
    fi

    if ! has cargo; then
        log_info "Installing Rust toolchain first..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
    fi

    log_info "Installing $pkg via cargo..."
    cargo install "$pkg"
    log_ok "$pkg installed"
}

install_noto_serif() {
    if has_noto_serif; then
        log_skip "Noto Serif font (already installed)"
        return 0
    fi

    log_info "Installing Noto Serif font..."
    case "$PLATFORM:$PKG_MGR" in
        macos:brew|linux:brew)
            brew tap homebrew/cask-fonts >/dev/null 2>&1 || true
            brew install --cask font-noto-serif
            ;;
        linux:apt)
            sudo apt-get install -y fonts-noto-core
            ;;
        linux:pacman)
            sudo pacman -S --noconfirm noto-fonts
            ;;
        linux:dnf)
            sudo dnf install -y google-noto-serif-fonts
            ;;
        *)
            log_skip "No supported Noto Serif installer for $PLATFORM/$PKG_MGR"
            return 0
            ;;
    esac
    log_ok "Noto Serif font installed"
}

# Main installation
main() {
    log_info "Starting modern CLI tools installation"
    log_info "Log file: $LOG_FILE"

    PLATFORM=$(detect_platform)
    PKG_MGR=$(detect_pkg_manager)
    log_info "Platform: $PLATFORM, Package manager: $PKG_MGR"

    echo ""
    log_info "=== Core CLI Tools ==="

    # Essentials (cross-platform via pkg manager)
    pkg_install "ripgrep" "rg"
    pkg_install "fzf" "fzf"
    pkg_install "btop" "btop"
    pkg_install "tmux" "tmux"

    # bat (different names on some systems)
    if ! has bat && ! has batcat; then
        pkg_install "bat" "bat" || pkg_install "bat" "batcat"
    else
        log_skip "bat (already installed)"
    fi

    # eza (ls replacement)
    pkg_install "eza" "eza"

    echo ""
    log_info "=== Git Tools ==="

    # lazygit
    if [[ "$PKG_MGR" == "pacman" || "$PKG_MGR" == "brew" ]]; then
        pkg_install "lazygit" "lazygit"
    else
        github_install "jesseduffield/lazygit" "lazygit" "lazygit_{version_num}_Linux_x86_64.tar.gz"
    fi

    # delta (git pager)
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_install "git-delta" "delta"
    elif [[ "$PKG_MGR" == "brew" ]]; then
        pkg_install "git-delta" "delta"
    else
        github_install "dandavison/delta" "delta" "delta-{version_num}-x86_64-unknown-linux-gnu.tar.gz"
    fi

    echo ""
    log_info "=== Docker Tools ==="

    # lazydocker
    if [[ "$PKG_MGR" == "pacman" || "$PKG_MGR" == "brew" ]]; then
        pkg_install "lazydocker" "lazydocker"
    else
        github_install "jesseduffield/lazydocker" "lazydocker" "lazydocker_{version_num}_Linux_x86_64.tar.gz"
    fi

    echo ""
    log_info "=== Navigation & Search ==="

    # zoxide (smarter cd)
    script_install "zoxide" "zoxide" "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"

    # navi (cheatsheets)
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_install "navi" "navi"
    elif [[ "$PKG_MGR" == "brew" ]]; then
        pkg_install "navi" "navi"
    else
        cargo_install "navi"
    fi

    echo ""
    log_info "=== Terminal UI Tools ==="

    # zellij (terminal multiplexer)
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_install "zellij" "zellij"
    elif [[ "$PKG_MGR" == "brew" ]]; then
        pkg_install "zellij" "zellij"
    else
        cargo_install "zellij"
    fi

    # dust (disk usage)
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_install "dust" "dust"
    elif [[ "$PKG_MGR" == "brew" ]]; then
        pkg_install "dust" "dust"
    else
        cargo_install "du-dust" "dust"
    fi

    # glow (markdown viewer)
    if [[ "$PKG_MGR" == "pacman" ]]; then
        pkg_install "glow" "glow"
    elif [[ "$PKG_MGR" == "brew" ]]; then
        pkg_install "glow" "glow"
    else
        github_install "charmbracelet/glow" "glow" "glow_{version_num}_Linux_x86_64.tar.gz"
    fi

    echo ""
    log_info "=== API & HTTP Tools ==="

    # posting (API client TUI)
    if ! has posting; then
        if has pipx; then
            log_info "Installing posting via pipx..."
            pipx install posting
            log_ok "posting installed"
        elif has pip; then
            log_info "Installing posting via pip..."
            pip install --user posting
            log_ok "posting installed"
        else
            log_err "posting requires pipx or pip"
        fi
    else
        log_skip "posting (already installed)"
    fi

    echo ""
    log_info "=== Shell & Prompt ==="

    # starship prompt
    script_install "starship" "starship" "https://starship.rs/install.sh" "-y"

    # fastfetch (system info)
    pkg_install "fastfetch" "fastfetch"

    # tldr (simplified man pages)
    pkg_install "tldr" "tldr"

    echo ""
    log_info "=== Fonts ==="
    install_noto_serif

    echo ""
    log_info "=== Installation Complete ==="
    log_info "Log saved to: $LOG_FILE"

    echo ""
    echo "Next steps:"
    echo "  1. Stow configs: cd ~/.dotfiles && stow fastfetch lazydocker zsh git"
    echo "  2. Reload shell: exec zsh"
    echo "  3. Update tldr:  tldr --update"
}

main "$@"
