#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

info "Symlinking shell config..."
symlink "$DOTFILES/shell/.zshrc"     "$HOME/.zshrc"
symlink "$DOTFILES/shell/aliases.sh" "$HOME/.aliases"
symlink "$DOTFILES/shell/exports.sh" "$HOME/.exports"
