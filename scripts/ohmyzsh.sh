#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if [ -d "$HOME/.oh-my-zsh" ]; then
    info "Updating Oh My Zsh..."
    zsh -c 'omz update --unattended' && success "Oh My Zsh up to date" || warn "Oh My Zsh update failed"
else
    info "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/HEAD/tools/install.sh)"
    success "Oh My Zsh installed"
fi
