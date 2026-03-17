# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="robbyrussell"

# History timestamp format
HIST_STAMPS="dd/mm/yyyy"

# Use dotfiles dir as ZSH_CUSTOM so plugins/themes inside it are picked up
export DOTFILES="$HOME/Developer/personal/repo/dotfiles"
ZSH_CUSTOM="$DOTFILES"

# Plugins
plugins=(
    git
    zsh-completions
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ── Locale ────────────────────────────────────────────────────────────────────
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ── Aliases & exports ─────────────────────────────────────────────────────────
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"
[ -f "$HOME/.exports" ] && source "$HOME/.exports"

# ── Homebrew completions ──────────────────────────────────────────────────────
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
    autoload -Uz compinit
    compinit
fi

# ── Plugins (Homebrew-managed) ────────────────────────────────────────────────
[ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && \
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
[ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && \
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── nvm ───────────────────────────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix nvm)/nvm.sh" ] && source "$(brew --prefix nvm)/nvm.sh"
[ -s "$(brew --prefix nvm)/etc/bash_completion.d/nvm" ] && source "$(brew --prefix nvm)/etc/bash_completion.d/nvm"
