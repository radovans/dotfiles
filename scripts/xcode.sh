#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if xcode-select -p &>/dev/null; then
    success "Xcode Command Line Tools already installed"
else
    info "Installing Xcode Command Line Tools..."
    info "A dialog will appear — click Install and wait for it to finish."
    xcode-select --install 2>/dev/null || true
    # Wait up to 30 minutes for installation to complete
    local waited=0
    until xcode-select -p &>/dev/null; do
        sleep 10
        waited=$((waited + 10))
        if [ "$waited" -ge 1800 ]; then
            error "Timed out waiting for Xcode CLT — re-run install.sh after installing manually."
            exit 1
        fi
    done
    success "Xcode Command Line Tools installed"
fi
