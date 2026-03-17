# ── Homebrew ──────────────────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:$PATH"

# ── Java ──────────────────────────────────────────────────────────────────────
# To list available versions: /usr/libexec/java_home -V
# export JAVA_HOME=$(/usr/libexec/java_home -v 17)
# export JAVA_HOME=$(/usr/libexec/java_home -v 21)
export JAVA_HOME=$(/usr/libexec/java_home -v 25)
export PATH="$JAVA_HOME/bin:$PATH"

# ── Antigravity ───────────────────────────────────────────────────────────────
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
