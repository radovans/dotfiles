# ── Navigation ────────────────────────────────────────────────────────────────
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

alias l="ls"
alias ll="ls -al"
alias o="open ."
alias home="cd ~"

alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"

# ── Directories ───────────────────────────────────────────────────────────────
alias dotfiles="cd $DOTFILES"
alias library="cd $HOME/Library"
alias dev="cd $HOME/Developer"

# ── Git ───────────────────────────────────────────────────────────────────────
alias gst="git status"
alias gpl="git pull"
alias gcp="git cherry-pick -x"

# ── Apps ──────────────────────────────────────────────────────────────────────
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'

# ── Shortcuts ─────────────────────────────────────────────────────────────────
# Recursively delete .DS_Store files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"
# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'
