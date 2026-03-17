#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

CLAUDE_SKILLS_DIR="$HOME/.claude/skills"
mkdir -p "$CLAUDE_SKILLS_DIR"

info "Installing Claude skills..."
for skill in "$DOTFILES/claude/skills/"*.md; do
    [ -e "$skill" ] || continue
    symlink "$skill" "$CLAUDE_SKILLS_DIR/$(basename "$skill")"
done
success "Claude skills done"
