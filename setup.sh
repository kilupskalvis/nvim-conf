#!/usr/bin/env bash
set -euo pipefail

# --- Pinned versions ---

NEOVIM_VERSION="v0.12.3"
NERD_FONT="JetBrainsMono"
NERD_FONT_VERSION="v3.4.0"

# --- Output helpers ---

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

STEP_CURRENT=0
STEP_TOTAL=0

info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}  ✓${NC} %s\n" "$1"; }
warn() { printf "${YELLOW}  ⚠${NC} %s\n" "$1"; }
error() {
  printf "${RED}  ✗${NC} %s\n" "$1"
  exit 1
}

step() {
  STEP_CURRENT=$((STEP_CURRENT + 1))
  echo ""
  printf "${BOLD}[%d/%d]${NC} ${BLUE}%s${NC}\n" "$STEP_CURRENT" "$STEP_TOTAL" "$1"
}

command_exists() { command -v "$1" &>/dev/null; }

# --- OS detection ---

detect_os() {
  case "$(uname -s)" in
  Darwin)
    OS="macos"
    PKG_MGR="brew"
    ;;
  Linux)
    if [[ -f /etc/os-release ]]; then
      . /etc/os-release
      case "$ID" in
      ubuntu | debian | pop | linuxmint | kali) PKG_MGR="apt" ;;
      fedora | rhel | centos | rocky | alma) PKG_MGR="dnf" ;;
      arch | manjaro | endeavouros) PKG_MGR="pacman" ;;
      *)
        case "${ID_LIKE:-}" in
        *debian*) PKG_MGR="apt" ;;
        *fedora* | *rhel*) PKG_MGR="dnf" ;;
        *arch*) PKG_MGR="pacman" ;;
        *) error "Unsupported Linux distribution: $ID" ;;
        esac
        ;;
      esac
      OS="linux"
    else
      error "Cannot detect Linux distribution (missing /etc/os-release)"
    fi
    ;;
  *)
    error "Unsupported operating system: $(uname -s)"
    ;;
  esac
}

# --- Package manager helpers ---

pkg_update() {
  case "$PKG_MGR" in
  apt) sudo apt-get update -qq ;;
  dnf) : ;;
  pacman) sudo pacman -Sy --noconfirm ;;
  brew) brew update --quiet ;;
  esac
}

pkg_install() {
  case "$PKG_MGR" in
  brew) brew install "$@" ;;
  apt) sudo apt-get install -y -qq "$@" ;;
  dnf) sudo dnf install -y -q "$@" ;;
  pacman) sudo pacman -S --noconfirm --needed "$@" ;;
  esac
}

# --- Installers ---

ensure_homebrew() {
  if [[ "$OS" != "macos" ]]; then return; fi
  if command_exists brew; then
    success "Homebrew already installed"
    return
  fi
  warn "Homebrew is not installed."
  read -rp "Install Homebrew? [y/N] " answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
  else
    error "Homebrew is required on macOS. Aborting."
  fi
}

ensure_system_deps() {
  local deps=("curl" "unzip" "tar" "git")
  for dep in "${deps[@]}"; do
    if command_exists "$dep"; then
      success "$dep"
    else
      info "Installing $dep..."
      pkg_install "$dep"
      success "$dep installed"
    fi
  done

  if command_exists cc || command_exists gcc; then
    success "C compiler"
  else
    info "Installing build tools..."
    case "$PKG_MGR" in
    brew) xcode-select --install 2>/dev/null || true ;;
    apt) pkg_install build-essential ;;
    dnf) pkg_install gcc ;;
    pacman) pkg_install base-devel ;;
    esac
    success "C compiler installed"
  fi
}

ensure_ripgrep() {
  if command_exists rg; then
    success "ripgrep $(rg --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    return
  fi
  info "Installing ripgrep..."
  pkg_install ripgrep
  success "ripgrep installed"
}

ensure_fd() {
  if command_exists fd || command_exists fdfind; then
    success "fd"
    return
  fi
  info "Installing fd..."
  case "$PKG_MGR" in
  brew | pacman) pkg_install fd ;;
  apt | dnf) pkg_install fd-find ;;
  esac
  success "fd installed"
}

ensure_neovim() {
  if command_exists nvim; then
    local version
    version=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    local minor
    minor=$(echo "$version" | cut -d. -f2)
    if ((minor >= 10)); then
      success "Neovim $version"
      return
    fi
    warn "Neovim $version found, but >= 0.10.0 is required — upgrading"
  fi
  info "Installing Neovim ${NEOVIM_VERSION}..."
  case "$OS" in
  macos)
    pkg_install neovim
    ;;
  linux)
    local arch
    case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) error "Unsupported architecture for Neovim: $(uname -m)" ;;
    esac
    local url="https://github.com/neovim/neovim/releases/download/${NEOVIM_VERSION}/nvim-linux-${arch}.tar.gz"
    local tmp
    tmp=$(mktemp -d)
    info "Downloading from GitHub releases..."
    curl -fsSL "$url" -o "$tmp/nvim.tar.gz"
    tar xzf "$tmp/nvim.tar.gz" -C "$tmp"
    mkdir -p ~/.local/bin
    rm -rf ~/.local/nvim
    mv "$tmp"/nvim-linux-"${arch}" ~/.local/nvim
    ln -sf ~/.local/nvim/bin/nvim ~/.local/bin/nvim
    export PATH="$HOME/.local/bin:$PATH"
    rm -rf "$tmp"
    ;;
  esac
  success "Neovim $(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
}

ensure_node() {
  if command_exists node && command_exists npm; then
    success "Node.js $(node --version)"
    return
  fi
  info "Installing Node.js..."
  case "$PKG_MGR" in
  brew) pkg_install node ;;
  apt) pkg_install nodejs npm ;;
  dnf) pkg_install nodejs npm ;;
  pacman) pkg_install nodejs npm ;;
  esac
  success "Node.js installed"
}

ensure_python() {
  if command_exists python3; then
    success "Python $(python3 --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    return
  fi
  info "Installing Python 3..."
  case "$PKG_MGR" in
  brew) pkg_install python3 ;;
  apt) pkg_install python3 python3-pip ;;
  dnf) pkg_install python3 python3-pip ;;
  pacman) pkg_install python python-pip ;;
  esac
  success "Python installed"
}

ensure_go() {
  if command_exists go; then
    success "Go $(go version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    return
  fi
  info "Installing Go..."
  case "$PKG_MGR" in
  brew) pkg_install go ;;
  apt) pkg_install golang ;;
  dnf) pkg_install golang ;;
  pacman) pkg_install go ;;
  esac
  success "Go installed"
}

ensure_rust() {
  if command_exists rustc && command_exists cargo; then
    success "Rust $(rustc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
    return
  fi
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "${CARGO_HOME:-$HOME/.cargo}/env"
  success "Rust $(rustc --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
}

ensure_npm_package() {
  local pkg="$1"
  if npm list -g "$pkg" &>/dev/null; then
    success "$pkg (npm)"
    return
  fi
  info "Installing $pkg globally via npm..."
  if [[ "$PKG_MGR" == "brew" ]]; then
    npm install -g "$pkg"
  else
    sudo npm install -g "$pkg"
  fi
  success "$pkg installed"
}

ensure_nerd_font() {
  local font_dir
  if [[ "$OS" == "macos" ]]; then
    font_dir="$HOME/Library/Fonts"
  else
    font_dir="$HOME/.local/share/fonts"
  fi

  if ls "$font_dir"/*"${NERD_FONT}"* &>/dev/null 2>&1; then
    success "${NERD_FONT} Nerd Font"
    return
  fi

  info "Installing ${NERD_FONT} Nerd Font ${NERD_FONT_VERSION}..."
  local url="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/${NERD_FONT}.tar.xz"
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$tmp/font.tar.xz"
  mkdir -p "$font_dir"
  tar xf "$tmp/font.tar.xz" -C "$font_dir"
  rm -rf "$tmp"

  if [[ "$OS" == "linux" ]] && command_exists fc-cache; then
    fc-cache -f "$font_dir"
  fi
  success "${NERD_FONT} Nerd Font installed"
  warn "Set your terminal font to '${NERD_FONT} Nerd Font' for icons to display"
}

# --- Smoke test ---

smoke_test() {
  local tools=("curl" "unzip" "tar" "git" "rg" "nvim" "node" "npm" "python3" "go" "rustc" "cargo")
  local failed=0

  for tool in "${tools[@]}"; do
    if command_exists "$tool"; then
      success "$tool"
    else
      warn "$tool NOT found"
      failed=1
    fi
  done

  if command_exists fd || command_exists fdfind; then
    success "fd"
  else
    warn "fd NOT found"
    failed=1
  fi

  if command_exists cc || command_exists gcc; then
    success "C compiler"
  else
    warn "C compiler NOT found"
    failed=1
  fi

  if ((failed)); then
    echo ""
    warn "Some tools are missing. Neovim may not work correctly."
  else
    echo ""
    success "All dependencies verified!"
  fi
}

sync_plugins() {
  if ! command_exists nvim; then
    warn "Neovim not found — skipping plugin sync"
    return
  fi
  info "Syncing plugins (this may take a moment)..."
  if nvim --headless "+Lazy! sync" +qa 2>/dev/null; then
    success "Plugins synced"
  else
    warn "Plugin sync had issues (this may resolve on next launch)"
  fi
}

# --- Main ---

main() {
  STEP_TOTAL=9

  echo ""
  printf "${BOLD}Neovim Config Setup${NC}\n"
  printf "${DIM}Installs all dependencies for this Neovim configuration${NC}\n"

  step "Detecting system"
  detect_os
  success "$OS ($PKG_MGR)"

  step "Setting up package manager"
  if [[ "$OS" == "macos" ]]; then
    ensure_homebrew
  fi
  info "Updating package index..."
  pkg_update
  success "Package manager ready"

  step "Installing system dependencies"
  ensure_system_deps

  step "Installing search tools"
  ensure_ripgrep
  ensure_fd

  step "Installing Neovim"
  ensure_neovim

  step "Installing language runtimes"
  ensure_node
  ensure_python
  ensure_go
  ensure_rust

  step "Installing formatters & linters"
  ensure_npm_package prettier
  ensure_npm_package eslint

  step "Installing Nerd Font"
  ensure_nerd_font

  step "Verifying installation"
  smoke_test
  sync_plugins

  echo ""
  printf "${BOLD}${GREEN}Setup complete!${NC}\n"
  echo ""
  printf "${DIM}Pinned versions:${NC}\n"
  printf "${DIM}  Neovim: %s | Font: %s %s${NC}\n" "$NEOVIM_VERSION" "$NERD_FONT" "$NERD_FONT_VERSION"
  echo ""

  if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    warn "Add ~/.local/bin to your PATH (add to ~/.bashrc or ~/.zshrc):"
    printf "  ${DIM}export PATH=\"\$HOME/.local/bin:\$PATH\"${NC}\n"
    echo ""
  fi
}

main "$@"
