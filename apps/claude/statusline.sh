#!/usr/bin/env bash
input=$(cat)

# ── Colors ────────────────────────────────────────────────────────────────────
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
GRAY=$'\033[90m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

SEP="${GRAY} │ ${RESET}"
DOT="${GRAY} · ${RESET}"

# ── Directory & Git ───────────────────────────────────────────────────────────
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
dir=$(basename "$cwd")

branch=$(cd "$cwd" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
dirty=$(cd "$cwd" && [ -n "$(git status --porcelain 2>/dev/null)" ] && echo '*' || echo '')

if [ -n "$branch" ]; then
    if [ -n "$dirty" ]; then
        git_part=" (${YELLOW}${branch}${dirty}${RESET})"
    else
        git_part=" (${GREEN}${branch}${RESET})"
    fi
fi

# ── Model, Version & Agent ────────────────────────────────────────────────────
model=$(echo "$input" | jq -r '.model.display_name // ""')
version=$(echo "$input" | jq -r '.version // ""')
agent=$(echo "$input" | jq -r '.agent.name // ""')

# ── Line 1: ◆ dir (branch) · model v1.2.3 · [agent] ─────────────────────────
printf '%s◆%s %s%s%s%s' "$CYAN" "$RESET" "$BOLD$CYAN" "$dir" "$RESET" "${git_part:-}"
[ -n "$model" ] && printf '%s%s' "$DOT" "${GRAY}${model}${RESET}"
[ -n "$version" ] && printf ' %s' "${GRAY}v${version}${RESET}"
[ -n "$agent" ] && printf '%s%s' "$DOT" "${CYAN}[${agent}]${RESET}"
printf '\n'

# ── Context bar ───────────────────────────────────────────────────────────────
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0 | floor')
filled=$(( pct * 10 / 100 ))
empty=$(( 10 - filled ))

bar=''
i=0; while [ $i -lt $filled ]; do bar+='█'; i=$((i+1)); done
i=0; while [ $i -lt $empty  ]; do bar+='░'; i=$((i+1)); done

if   [ "$pct" -ge 80 ]; then bar_colored="${RED}${bar}${RESET}"
elif [ "$pct" -ge 50 ]; then bar_colored="${YELLOW}${bar}${RESET}"
else                          bar_colored="${GREEN}${bar}${RESET}"
fi

# ── Tokens ────────────────────────────────────────────────────────────────────
total_tokens=$(echo "$input" | jq -r '
    (.context_window.total_input_tokens // 0) +
    (.context_window.total_output_tokens // 0)
')
if [ "$total_tokens" -ge 1000 ]; then
    tokens_fmt=$(echo "$total_tokens" | awk '{printf "%.1fk", $1/1000}')
else
    tokens_fmt="${total_tokens}"
fi

# ── Duration ──────────────────────────────────────────────────────────────────
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0 | floor')
duration_s=$(( duration_ms / 1000 ))
if   [ "$duration_s" -ge 3600 ]; then
    duration_fmt=$(printf '%dh %dm' $(( duration_s / 3600 )) $(( (duration_s % 3600) / 60 )))
elif [ "$duration_s" -ge 60 ]; then
    duration_fmt=$(printf '%dm %ds' $(( duration_s / 60 )) $(( duration_s % 60 )))
else
    duration_fmt="${duration_s}s"
fi

# ── Cost ──────────────────────────────────────────────────────────────────────
cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost=$(printf '$%.2f' "$cost_raw")

# ── Lines changed ─────────────────────────────────────────────────────────────
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# ── Line 2: ctx bar%  │  tok  │  time  │  cost  │  +/-  ──────────────────────
printf '%sctx%s %s %s%d%%%s' "$DIM" "$RESET" "$bar_colored" "$BOLD" "$pct" "$RESET"
printf '%s%stok%s %s'        "$SEP" "$DIM" "$RESET" "${GRAY}${tokens_fmt}${RESET}"
printf '%s%s'                "$SEP" "${GRAY}${duration_fmt}${RESET}"
printf '%s%s'                "$SEP" "${GRAY}${cost}${RESET}"
if [ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ]; then
    printf '%s%s+%d%s/%s-%d%s' "$SEP" "$GREEN" "$lines_added" "$RESET" "$RED" "$lines_removed" "$RESET"
fi
printf '\n'

# ── Usage limits (cached 5 min) ───────────────────────────────────────────────
CACHE_FILE="/tmp/claude_usage_cache.json"
CACHE_TTL=300

fetch_usage() {
    local creds token
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
    [ -z "$creds" ] && return
    token=$(echo "$creds" | jq -r '.claudeAiOauth.accessToken // ""')
    [ -z "$token" ] && return
    curl -sf "https://api.anthropic.com/api/oauth/usage" \
        -H "Authorization: Bearer $token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        -H "User-Agent: claude-code/2.0.32"
}

format_reset() {
    local iso="$1"
    local reset now diff iso_clean
    iso_clean=$(echo "$iso" | sed 's/\.[0-9]*//' | sed 's/+00:00$/Z/')
    reset=$(date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$iso_clean" +%s 2>/dev/null) || return
    now=$(date +%s)
    diff=$(( reset - now ))
    [ "$diff" -le 0 ] && echo "now" && return
    if   [ "$diff" -ge 86400 ]; then printf '%dd %dh' $(( diff / 86400 ))    $(( (diff % 86400) / 3600 ))
    elif [ "$diff" -ge 3600  ]; then printf '%dh %dm' $(( diff / 3600 ))     $(( (diff % 3600) / 60 ))
    else                             printf '%dm'     $(( diff / 60 ))
    fi
}

usage_bar() {
    local pct="$1" filled empty bar color
    filled=$(( pct * 10 / 100 ))
    empty=$(( 10 - filled ))
    bar=''; i=0; while [ $i -lt $filled ]; do bar+='█'; i=$((i+1)); done
            i=0; while [ $i -lt $empty  ]; do bar+='░'; i=$((i+1)); done
    if   [ "$pct" -ge 80 ]; then color="$RED"
    elif [ "$pct" -ge 50 ]; then color="$YELLOW"
    else                          color="$GREEN"
    fi
    printf '%s%s%s' "$color" "$bar" "$RESET"
}

usage_json=''
if [ -f "$CACHE_FILE" ]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
    [ "$cache_age" -lt "$CACHE_TTL" ] && usage_json=$(cat "$CACHE_FILE")
fi
if [ -z "$usage_json" ]; then
    usage_json=$(fetch_usage)
    [ -n "$usage_json" ] && echo "$usage_json" > "$CACHE_FILE"
fi

# ── Line 3: session bar%  ↺ reset  │  weekly bar%  ↺ reset ──────────────────
if [ -n "$usage_json" ]; then
    five_h_pct=$(echo  "$usage_json" | jq -r '.five_hour.utilization // 0 | floor')
    seven_d_pct=$(echo "$usage_json" | jq -r '.seven_day.utilization // 0 | floor')
    five_h_reset=$(echo  "$usage_json" | jq -r '.five_hour.resets_at // ""')
    seven_d_reset=$(echo "$usage_json" | jq -r '.seven_day.resets_at // ""')

    five_h_bar=$(usage_bar "$five_h_pct")
    seven_d_bar=$(usage_bar "$seven_d_pct")
    five_h_in=$(format_reset "$five_h_reset")
    seven_d_in=$(format_reset "$seven_d_reset")

    printf '%ssession%s %s %s%d%%%s' "$DIM" "$RESET" "$five_h_bar" "$BOLD" "$five_h_pct" "$RESET"
    [ -n "$five_h_in"  ] && printf ' %s↺ %s%s' "$GRAY" "$five_h_in" "$RESET"
    printf '%s%sweekly%s %s %s%d%%%s' "$SEP" "$DIM" "$RESET" "$seven_d_bar" "$BOLD" "$seven_d_pct" "$RESET"
    [ -n "$seven_d_in" ] && printf ' %s↺ %s%s' "$GRAY" "$seven_d_in" "$RESET"
    printf '\n'
fi
