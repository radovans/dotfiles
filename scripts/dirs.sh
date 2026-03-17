#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

info "Creating directory structure..."

BASE="$HOME/Developer"

mkdir -p \
    "$BASE/work/programs" \
    "$BASE/work/profiles" \
    "$BASE/work/projects" \
    "$BASE/work/repo" \
    "$BASE/personal/repo" \
    "$BASE/personal/repo/sandbox"

success "Directory structure created"
