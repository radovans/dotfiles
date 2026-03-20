#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

MANAGED="$DOTFILES/apps/claude/managed.json"
MCP="$DOTFILES/apps/ai/mcp.json"
SETTINGS="$HOME/.claude/settings.json"
CLAUDE_JSON="$HOME/.claude.json"

info "Linking Claude statusline script..."
symlink "$DOTFILES/apps/claude/statusline.sh" "$HOME/.claude/statusline.sh"

info "Merging Claude managed settings (statusLine, permissions)..."
if [ ! -f "$SETTINGS" ]; then
    cp "$MANAGED" "$SETTINGS"
fi
merged=$(jq -s '(.[0] * .[1]) | del(.mcpServers)' "$SETTINGS" "$MANAGED")
echo "$merged" > "$SETTINGS"

info "Merging MCP servers into ~/.claude.json..."
mcp_servers=$(jq '.mcpServers' "$MCP")
jq --argjson servers "$mcp_servers" '.mcpServers = $servers' "$CLAUDE_JSON" > /tmp/claude.json.tmp \
    && mv /tmp/claude.json.tmp "$CLAUDE_JSON"

success "Claude settings updated"
