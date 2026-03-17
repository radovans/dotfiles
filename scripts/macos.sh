#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if [ -f "$DOTFILES/macos/defaults.sh" ]; then
    info "Applying macOS defaults..."
    bash "$DOTFILES/macos/defaults.sh"
    success "macOS defaults applied"
else
    warn "macos/defaults.sh not found — skipping"
fi
