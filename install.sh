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
    echo "  1. Installs Homebrew packages from macos/Brewfile"
    echo "  2. Symlinks shell config (.zshrc, aliases, exports)"
    echo "  3. Installs Claude skills from claude/skills/"
    echo "  4. Applies macOS defaults from macos/defaults.sh"
    echo "  5. Checks for .env file"
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
# 1. Homebrew packages
# ---------------------------------------------------------------------------
echo -e "${CYAN}━━━ [1/5] Homebrew packages ━━━━━━━━━━━━━━━━━━━${NC}"
if command -v brew &>/dev/null; then
    info "Installing packages from Brewfile..."
    brew bundle --file="$DOTFILES/macos/Brewfile"
    success "Homebrew done"
else
    warn "Homebrew not found — skipping. Install it first: https://brew.sh"
fi

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
# 5. Environment file
# ---------------------------------------------------------------------------
echo ""
echo -e "${CYAN}━━━ [5/5] Environment ━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ ! -f "$HOME/.env" ] && [ ! -f "$DOTFILES/.env" ]; then
    warn ".env not found. Copy .env.example to .env and fill in your secrets."
else
    success ".env file found"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Setup complete! Restart terminal.      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
