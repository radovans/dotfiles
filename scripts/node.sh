#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

NODE_VERSION="v22.14.0"
export NVM_DIR="$HOME/.nvm"

NVM_PREFIX="$(brew --prefix nvm 2>/dev/null || true)"
if [ -n "$NVM_PREFIX" ] && [ -s "$NVM_PREFIX/nvm.sh" ]; then
    # shellcheck source=/dev/null
    source "$NVM_PREFIX/nvm.sh"
    info "Installing Node $NODE_VERSION..."
    nvm install "$NODE_VERSION"
    nvm use "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    success "Node $(node --version) active, set as default"
else
    warn "nvm not found — skipping Node install"
fi
