#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if [ ! -d "$HOME/.cursor" ]; then
    warn "Cursor config directory not found — skipping"
    exit 0
fi

info "Linking Cursor MCP servers..."
symlink "$DOTFILES/apps/ai/mcp.json" "$HOME/.cursor/mcp.json"

success "Cursor settings linked"
