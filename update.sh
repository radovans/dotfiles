#!/usr/bin/env bash
# Pull latest dotfiles and re-apply — safe to run anytime.
# Usage: ./update.sh [--help]
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES/scripts/lib.sh"

show_help() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           Dotfiles Updater                   ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./update.sh [OPTION]"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo "  -h, --help    Show this help message"
    echo ""
    echo -e "${CYAN}WHAT IT DOES:${NC}"
    echo "  1. Pulls latest changes from git"
    echo "  2. Re-applies shell config symlinks"
    echo "  3. Updates Oh My Zsh"
    echo "  4. Re-applies git config symlinks"
    echo "  5. Updates Claude marketplace skills"
    echo "  6. Re-applies Claude settings symlink"
    echo "  7. Re-applies Cursor settings symlinks"
    echo "  8. Re-applies IntelliJ IDEA settings"
    echo "  9. Runs brew bundle + upgrade + cleanup"
    echo ""
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
    show_help
    exit 0
fi

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Dotfiles Updater                   ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

# Pull latest changes
info "Pulling latest dotfiles..."
git -C "$DOTFILES" pull --rebase
success "Dotfiles up to date"
echo ""

# Re-apply symlinks
echo -e "${CYAN}━━━ Shell config ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/shell.sh"
echo ""

echo -e "${CYAN}━━━ Oh My Zsh ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/ohmyzsh.sh"
echo ""

echo -e "${CYAN}━━━ Git config ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/git.sh"
echo ""

echo -e "${CYAN}━━━ Claude marketplace ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/marketplace.sh"
echo ""

echo -e "${CYAN}━━━ Claude settings ━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/claude.sh"
echo ""

echo -e "${CYAN}━━━ Cursor ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/cursor.sh"
echo ""

echo -e "${CYAN}━━━ IntelliJ IDEA ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/idea.sh"
echo ""

# Update Homebrew packages
echo -e "${CYAN}━━━ Homebrew ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
info "Updating Homebrew..."
brew update --quiet
brew bundle --file="$DOTFILES/macos/Brewfile"
brew upgrade
brew cleanup
success "Homebrew up to date"
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Update complete! Reload your shell.    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
