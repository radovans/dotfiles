#!/usr/bin/env bash
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$DOTFILES/scripts/lib.sh"

if [ ! -f "$HOME/.env" ] && [ ! -f "$DOTFILES/.env" ]; then
    warn ".env not found. Copy .env.example to .env and fill in your secrets."
else
    success ".env file found"
fi
