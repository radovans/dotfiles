#!/usr/bin/env bash
# Bootstrap a new Mac from this dotfiles repo.
# Usage: ./install.sh [--help]

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"

source "$SCRIPTS/lib.sh"

show_help() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Dotfiles Bootstrap Installer         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./install.sh [OPTION]"
    echo ""
    echo -e "${CYAN}OPTIONS:${NC}"
    echo "  -h, --help    Show this help message"
    echo ""
    echo -e "${CYAN}WHAT IT DOES:${NC}"
    echo "  1. Xcode Command Line Tools"
    echo "  2. Oh My Zsh"
    echo "  3. Homebrew + packages from macos/Brewfile"
    echo "  4. Shell config symlinks (.zshrc, aliases, exports)"
    echo "  5. Git config + global gitignore"
    echo "  6. Claude skills"
    echo "  7. macOS defaults"
    echo "  8. Node via nvm"
    echo "  9. Directory structure (~/Developer/...)"
    echo " 10. Environment file check"
    echo ""
    echo -e "${CYAN}PREREQUISITES:${NC}"
    echo "  • macOS"
    echo "  • Internet connection"
    echo ""
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" ]]; then
    show_help
    exit 0
fi

STEPS=(
    "Xcode Command Line Tools:xcode.sh"
    "Oh My Zsh:ohmyzsh.sh"
    "Homebrew:homebrew.sh"
    "Shell config:shell.sh"
    "Git:git.sh"
    "Claude skills:claude.sh"
    "macOS defaults:macos.sh"
    "Node:node.sh"
    "Directory structure:dirs.sh"
    "Environment:env.sh"
)
TOTAL="${#STEPS[@]}"

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Dotfiles Bootstrap Installer         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

i=1
for entry in "${STEPS[@]}"; do
    label="${entry%%:*}"
    script="${entry##*:}"

    echo -e "${CYAN}━━━ [$i/$TOTAL] $label ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" \
        | cut -c1-54  # keep consistent width
    bash "$SCRIPTS/$script"
    echo ""
    i=$((i + 1))
done

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Setup complete! Restart terminal.      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
