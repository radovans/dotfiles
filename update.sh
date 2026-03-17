#!/usr/bin/env bash
# Pull latest dotfiles and re-apply — safe to run anytime.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

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

echo -e "${CYAN}━━━ Git config ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/git.sh"
echo ""

echo -e "${CYAN}━━━ Claude marketplace ━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
bash "$DOTFILES/scripts/marketplace.sh"
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
