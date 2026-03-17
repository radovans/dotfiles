#!/usr/bin/env bash
# Bootstrap a new Mac from this dotfiles repo.
# Usage: ./install.sh [--help]

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*"; }

show_help() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Dotfiles Bootstrap Installer         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./install.sh [OPTION]"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo "  -h, --help    Show this help message"
    echo ""
    echo -e "${CYAN}WHAT IT DOES:${NC}"
    echo "  1. Installs Homebrew (if missing), then packages from macos/Brewfile"
    echo "  2. Symlinks shell config (.zshrc, aliases, exports)"
    echo "  3. Installs Claude skills from claude/skills/"
    echo "  4. Applies macOS defaults from macos/defaults.sh"
    echo "  5. Installs Node via nvm"
    echo "  6. Checks for .env file"
    echo ""
    echo -e "${CYAN}PREREQUISITES:${NC}"
    echo "  • macOS"
    echo "  • Homebrew installed (https://brew.sh) for package installation"
    echo ""
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
    show_help
    exit 0
fi

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Dotfiles Bootstrap Installer         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# ---------------------------------------------------------------------------
# 1. Homebrew
# ---------------------------------------------------------------------------
echo -e "${CYAN}━━━ [1/5] Homebrew ━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for the rest of this script (Apple Silicon path)
    if [ -x "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
    success "Homebrew installed"
else
    info "Homebrew already installed, updating..."
    brew update --quiet
    success "Homebrew up to date"
fi

info "Installing packages from Brewfile..."
brew bundle --file="$DOTFILES/macos/Brewfile"
success "Homebrew packages done"

# ---------------------------------------------------------------------------
# 2. Shell config
# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}━━━ [2/5] Shell config ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
info "Symlinking shell config..."

symlink() {
    local src="$1" dst="$2"
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        warn "Backing up existing $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    success "Linked $dst"
}

symlink "$DOTFILES/shell/.zshrc"     "$HOME/.zshrc"
symlink "$DOTFILES/shell/aliases.sh" "$HOME/.aliases"
symlink "$DOTFILES/shell/exports.sh" "$HOME/.exports"

# ---------------------------------------------------------------------------
# 3. Claude skills
# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}━━━ [3/5] Claude skills ━━━━━━━━━━━━━━━━━━━━━━━${NC}"
info "Installing Claude skills..."
CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"

for skill in "$DOTFILES/claude/skills/"*.md; do
    [ -e "$skill" ] || continue
    symlink "$skill" "$CLAUDE_SKILLS_DIR/$(basename "$skill")"
done
success "Claude skills done"

# ---------------------------------------------------------------------------
# 4. macOS defaults
# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}━━━ [4/5] macOS defaults ━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ -f "$DOTFILES/macos/defaults.sh" ]; then
    info "Applying macOS defaults..."
    bash "$DOTFILES/macos/defaults.sh"
    success "macOS defaults applied"
else
    warn "macos/defaults.sh not found — skipping"
fi

# ---------------------------------------------------------------------------
# 5. Node via nvm
# ---------------------------------------------------------------------------
NODE_VERSION="v22.14.0"
echo ""
echo -e "${CYAN}━━━ [5/6] Node via nvm ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
export NVM_DIR="$HOME/.nvm"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    # shellcheck source=/dev/null
    source "$(brew --prefix nvm)/nvm.sh"
    info "Installing Node $NODE_VERSION..."
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    success "Node $(node --version) active, set as default"
else
    warn "nvm not found — skipping Node install"
fi

# ---------------------------------------------------------------------------
# 6. Environment file
# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}━━━ [6/6] Environment ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ ! -f "$HOME/.env" ] && [ ! -f "$DOTFILES/.env" ]; then
    warn ".env not found. Copy .env.example to .env and fill in your secrets."
else
    success ".env file found"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Setup complete! Restart terminal.      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
