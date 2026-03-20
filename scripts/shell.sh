#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

info "Symlinking shell config..."
symlink "$DOTFILES/shell/.zshrc"     "$HOME/.zshrc"
symlink "$DOTFILES/shell/aliases.sh" "$HOME/.aliases"
symlink "$DOTFILES/shell/exports.sh" "$HOME/.exports"

if [ ! -f "$DOTFILES/.env" ]; then
    warn ".env not found — copy .env.example to .env and fill in your values"
else
    symlink "$DOTFILES/.env" "$HOME/.env"
fi
