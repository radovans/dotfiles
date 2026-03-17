#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if ! command -v mas &>/dev/null; then
    warn "mas not installed — skipping App Store apps (install via: brew install mas)"
    exit 0
fi

if ! mas account &>/dev/null; then
    warn "Not signed into App Store — skipping (sign in via App Store app first)"
    exit 0
fi

info "Installing App Store apps..."

mas_install() {
    local id="$1" name="$2"
    if mas list | grep -q "^$id"; then
        success "$name already installed"
    else
        info "Installing $name..."
        mas install "$id"
        success "$name installed"
    fi
}

mas_install 937984704  "Amphetamine"
mas_install 497799835  "Xcode"
mas_install 1451685025 "WireGuard"
