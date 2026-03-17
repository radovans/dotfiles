# Load config if not already loaded (e.g. when sourced standalone)
if [ -z "${COMPUTER_NAME:-}" ]; then
    source "$(dirname "$(readlink "$HOME/.exports")")"/../config.sh
fi

# ── Homebrew ──────────────────────────────────────────────────────────────────
export PATH="/opt/homebrew/bin:$PATH"

# ── Java ──────────────────────────────────────────────────────────────────────
# To list available versions: /usr/libexec/java_home -V
# Change JAVA_VERSION in config.sh to switch versions
export JAVA_HOME=$(/usr/libexec/java_home -v "$JAVA_VERSION" 2>/dev/null)
export PATH="$JAVA_HOME/bin:$PATH"

# ── Antigravity ───────────────────────────────────────────────────────────────
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
