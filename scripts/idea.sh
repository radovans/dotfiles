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

# ── Plugins ───────────────────────────────────────────────────────────────────
IDEA_BIN="$HOME/Applications/IntelliJ IDEA Ultimate.app/Contents/MacOS/idea"

if [ ! -x "$IDEA_BIN" ]; then
    warn "IntelliJ IDEA binary not found — skipping plugin installation"
    exit 0
fi

plugins=(
    "org.sonarlint.idea"                  # SonarQube for IDE
    "izhangzhihao.rainbow.brackets"       # Rainbow Brackets
    "PlantUML integration"                # PlantUML
    "com.github.copilot"                  # GitHub Copilot
    "com.anthropic.code.plugin"           # Claude Code
    "com.mallowigi.idea"                  # Atom Material Icons
)

info "Installing IntelliJ IDEA plugins..."
for plugin in "${plugins[@]}"; do
    info "Installing plugin: $plugin"
    "$IDEA_BIN" installPlugins "$plugin" 2>/dev/null && success "Installed $plugin" || warn "Failed to install $plugin"
done
