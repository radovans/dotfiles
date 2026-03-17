#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if ! command -v claude &>/dev/null; then
    warn "claude CLI not found — skipping marketplace install"
    exit 0
fi

# Register marketplace (idempotent)
info "Registering Claude marketplace..."
claude plugin marketplace add "$MARKETPLACE_REPO" 2>/dev/null || true
success "Marketplace registered"

# Install all skills globally
info "Installing marketplace skills..."
claude plugin install domain-name-brainstormer@radovans-skills 2>/dev/null || true
claude plugin install remotion@radovans-skills 2>/dev/null || true
success "Marketplace skills installed"
