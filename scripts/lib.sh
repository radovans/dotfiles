#!/usr/bin/env bash
# Shared colors and helper functions — source this, don't run it directly.

# Load central config (DOTFILES must be set before sourcing lib.sh)
source "$DOTFILES/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*"; }

symlink() {
    local src="$1" dst="$2"
    if [ ! -e "$src" ]; then
        warn "Skipping $dst — source not found: $src"
        return 0
    fi
    if [ -L "$dst" ]; then
        # Remove existing symlink so ln -sf doesn't create inside the target
        rm "$dst"
    elif [ -e "$dst" ]; then
        warn "Backing up existing $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    success "Linked $dst"
}
