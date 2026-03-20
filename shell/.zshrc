# Resolve dotfiles location from this symlink's real path
export DOTFILES="$(dirname "$(dirname "$(readlink "$HOME/.zshrc")")")"

# Load central config
source "$DOTFILES/config.sh"

# ── Oh My Zsh ─────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="$ZSH_THEME"
HIST_STAMPS="dd/mm/yyyy"
ZSH_CUSTOM="$DOTFILES"

# Only include plugins that are bundled with Oh My Zsh
plugins=(git)

source "$ZSH/oh-my-zsh.sh"

# ── Locale ────────────────────────────────────────────────────────────────────
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# ── Aliases, exports & secrets ────────────────────────────────────────────────
[ -f "$HOME/.aliases" ] && source "$HOME/.aliases"
[ -f "$HOME/.exports" ] && source "$HOME/.exports"
[ -f "$HOME/.env" ] && source "$HOME/.env"

# ── Homebrew completions + zsh-completions ────────────────────────────────────
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