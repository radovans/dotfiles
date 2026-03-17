#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

# Find the latest IntelliJ IDEA config directory
IDEA_CONFIG=$(ls -dt "$HOME/Library/Application Support/JetBrains/IntelliJIdea"* 2>/dev/null | head -1)

if [ -z "$IDEA_CONFIG" ]; then
    warn "IntelliJ IDEA config directory not found — skipping"
    exit 0
fi

info "Linking IntelliJ IDEA settings to $IDEA_CONFIG..."

symlink "$DOTFILES/apps/idea/fileTemplates" "$IDEA_CONFIG/fileTemplates"
symlink "$DOTFILES/apps/idea/templates"     "$IDEA_CONFIG/templates"

success "IntelliJ IDEA settings linked"
