#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"
SKILLS_DIR="$HOME/.claude/skills"

# Clone or update
if [ -d "$MARKETPLACE_DIR/.git" ]; then
    info "Updating claude-marketplace..."
    git -C "$MARKETPLACE_DIR" pull --rebase --quiet
    success "claude-marketplace up to date"
else
    info "Cloning claude-marketplace..."
    git clone --quiet "$MARKETPLACE_REPO" "$MARKETPLACE_DIR"
    success "claude-marketplace cloned"
fi

mkdir -p "$SKILLS_DIR"

# Symlink each SKILL.md → ~/.claude/skills/<skill-name>.md
info "Linking marketplace skills..."
while IFS= read -r skill_file; do
    skill_name="$(basename "$(dirname "$skill_file")")"
    symlink "$skill_file" "$SKILLS_DIR/${skill_name}.md"
done < <(find "$MARKETPLACE_DIR/plugins" -name "SKILL.md")

success "Marketplace skills linked"
