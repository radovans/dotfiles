#!/usr/bin/env bash
# Central configuration for dotfiles.
# Edit this file — scripts pick up values from here automatically.

# ── Machine ───────────────────────────────────────────────────────────────────
COMPUTER_NAME="radovan-mac"

# ── Shell ─────────────────────────────────────────────────────────────────────
ZSH_THEME="robbyrussell"

# ── Java ──────────────────────────────────────────────────────────────────────
# Run /usr/libexec/java_home -V to list installed versions
JAVA_VERSION="25"

# ── Node ──────────────────────────────────────────────────────────────────────
NODE_VERSION="v22.14.0"

# ── Claude marketplace ────────────────────────────────────────────────────────
MARKETPLACE_REPO="https://github.com/radovans/claude-marketplace.git"
MARKETPLACE_DIR="$HOME/Developer/personal/repo/claude-marketplace"
