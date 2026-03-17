#!/usr/bin/env bash
# Bootstrap a new Mac from this dotfiles repo.
# Usage: ./install.sh [--help] [--step <name>] [--list]

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS="$DOTFILES/scripts"

source "$SCRIPTS/lib.sh"

STEPS=(
    "Xcode Command Line Tools:xcode.sh"
    "Oh My Zsh:ohmyzsh.sh"
    "Homebrew:homebrew.sh"
    "App Store apps:mas.sh"
    "Shell config:shell.sh"
    "Git:git.sh"
    "Claude marketplace:marketplace.sh"
    "IntelliJ IDEA:idea.sh"
    "macOS defaults:macos.sh"
    "Node:node.sh"
    "Directory structure:dirs.sh"
    "Environment:env.sh"
)
TOTAL="${#STEPS[@]}"

show_help() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Dotfiles Bootstrap Installer         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./install.sh                  Run all steps"
    echo "  ./install.sh --step <name>    Run a single step"
    echo "  ./install.sh --list           List all available steps"
    echo "  ./install.sh --help           Show this help message"
    echo ""
    echo -e "${CYAN}EXAMPLES:${NC}"
    echo "  ./install.sh --step homebrew"
    echo "  ./install.sh --step node"
    echo ""
}

show_list() {
    echo -e "${CYAN}Available steps:${NC}"
    local i=1
    for entry in "${STEPS[@]}"; do
        local script="${entry##*:}"
        local name="${script%.sh}"
        printf "  %-4s %s\n" "$i)" "$name"
        i=$((i + 1))
    done
}

run_step() {
    local label="$1" script="$2" i="$3" total="$4"
    echo -e "${CYAN}━━━ [$i/$total] $label ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" \
        | cut -c1-54
    bash "$SCRIPTS/$script"
    echo ""
}

# Handle flags
case "${1:-}" in
    -h|--help|help)
        show_help; exit 0 ;;
    --list)
        show_list; exit 0 ;;
    --step)
        STEP="${2:-}"
        if [ -z "$STEP" ]; then
            error "No step name provided. Run --list to see available steps."
            exit 1
        fi
        for entry in "${STEPS[@]}"; do
            script="${entry##*:}"
            name="${script%.sh}"
            label="${entry%%:*}"
            if [ "$name" = "$STEP" ]; then
                echo -e "${BLUE}Running step: $label${NC}"
                echo ""
                run_step "$label" "$script" "-" "-"
                exit 0
            fi
        done
        error "Unknown step '$STEP'. Run --list to see available steps."
        exit 1 ;;
esac

# Run all steps
echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Dotfiles Bootstrap Installer         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

i=1
for entry in "${STEPS[@]}"; do
    label="${entry%%:*}"
    script="${entry##*:}"
    run_step "$label" "$script" "$i" "$TOTAL"
    i=$((i + 1))
done

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       Setup complete! Restart terminal.      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
