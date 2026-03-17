#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

info "Symlinking git config..."
symlink "$DOTFILES/git/.gitconfig"        "$HOME/.gitconfig"
symlink "$DOTFILES/git/.gitignore_global" "$HOME/.gitignore_global"
