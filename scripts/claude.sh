#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

MANAGED="$DOTFILES/apps/claude/managed.json"
SETTINGS="$HOME/.claude/settings.json"

info "Merging Claude managed settings (statusLine, permissions)..."

if [ ! -f "$SETTINGS" ]; then
    cp "$MANAGED" "$SETTINGS"
else
    merged=$(jq -s '.[0] * .[1]' "$SETTINGS" "$MANAGED")
    echo "$merged" > "$SETTINGS"
fi

success "Claude settings updated"
