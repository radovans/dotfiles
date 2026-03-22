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

# ── Line 2: SESSION bar% ↺ reset │ WEEKLY bar% ↺ reset ───────────────────────
if [ -n "$usage_json" ]; then
    five_h_pct=$(echo  "$usage_json" | jq -r '.five_hour.utilization // 0 | floor')
    seven_d_pct=$(echo "$usage_json" | jq -r '.seven_day.utilization // 0 | floor')
    five_h_reset=$(echo  "$usage_json" | jq -r '.five_hour.resets_at // ""')
    seven_d_reset=$(echo "$usage_json" | jq -r '.seven_day.resets_at // ""')

    five_h_bar=$(usage_bar "$five_h_pct")
    seven_d_bar=$(usage_bar "$seven_d_pct")
    five_h_in=$(format_reset "$five_h_reset")
    seven_d_in=$(format_reset "$seven_d_reset")

    printf '%sSESSION%s %s %s%3d%%%s' "$DIM" "$RESET" "$five_h_bar" "$BOLD" "$five_h_pct" "$RESET"
    [ -n "$five_h_in"  ] && printf ' %s↺ %s%s' "$GRAY" "$five_h_in" "$RESET"
    printf '%s%sWEEKLY%s %s %s%3d%%%s' "$SEP" "$DIM" "$RESET" "$seven_d_bar" "$BOLD" "$seven_d_pct" "$RESET"
    [ -n "$seven_d_in" ] && printf ' %s↺ %s%s' "$GRAY" "$seven_d_in" "$RESET"
    printf '\n'
fi

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

# ── Session data ──────────────────────────────────────────────────────────────
total_tokens=$(echo "$input" | jq -r '
    (.context_window.total_input_tokens // 0) +
    (.context_window.total_output_tokens // 0)
')

duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0 | floor')
duration_s=$(( duration_ms / 1000 ))
if   [ "$duration_s" -ge 3600 ]; then
    duration_fmt=$(printf '%dh %dm' $(( duration_s / 3600 )) $(( (duration_s % 3600) / 60 )))
elif [ "$duration_s" -ge 60 ]; then
    duration_fmt=$(printf '%dm %ds' $(( duration_s / 60 )) $(( duration_s % 60 )))
else
    duration_fmt="${duration_s}s"
fi

cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# ── Formatting helpers ────────────────────────────────────────────────────────
fmt_tok() {
    local t="$1"
    if   [ "$t" -ge 1000000 ]; then awk -v v="$t" 'BEGIN{printf "%.1fM",v/1000000}'
    elif [ "$t" -ge 1000    ]; then awk -v v="$t" 'BEGIN{printf "%.1fk",v/1000}'
    else printf '%d' "$t"
    fi
}
fmt_cost() { printf '$%.2f' "$1"; }

# ── Line 3: CONTEXT bar% │ TIME duration │ +/- ───────────────────────────────
printf '%sCONTEXT%s %s %s%3d%%%s' "$DIM" "$RESET" "$bar_colored" "$BOLD" "$pct" "$RESET"
printf '%s%sTIME%s %s' "$SEP" "$DIM" "$RESET" "${GRAY}${duration_fmt}${RESET}"
if [ "$lines_added" -gt 0 ] || [ "$lines_removed" -gt 0 ]; then
    printf '%s%s+%d%s/%s-%d%s' "$SEP" "$GREEN" "$lines_added" "$RESET" "$RED" "$lines_removed" "$RESET"
fi
printf '\n'

# ── Local usage tracking ──────────────────────────────────────────────────────
# Accumulates tokens/cost per session into day/week/month rolling totals.
# Deduplicates mid-session refreshes using duration_ms as a session fingerprint:
# if duration reset → new session started → use full current values as delta.
TRACK_FILE="$HOME/.claude/usage_track.json"
NOW_DATE=$(date +%Y-%m-%d)
NOW_WEEK=$(date +%G-W%V)
NOW_MONTH=$(date +%Y-%m)

track='{}'
[ -f "$TRACK_FILE" ] && track=$(cat "$TRACK_FILE")

last_dur=$(echo "$track" | jq -r '.last_duration_ms // 0')
last_tok=$(echo "$track" | jq -r '.last_tokens // 0')
last_cst=$(echo "$track" | jq -r '.last_cost // 0')

# Compute delta for this refresh
if [ "$duration_ms" -lt "$last_dur" ] 2>/dev/null || [ "$last_dur" -eq 0 ]; then
    # New session
    dtok=$total_tokens
    dcst=$cost_raw
else
    # Continuing session
    dtok=$(( total_tokens - last_tok ))
    [ "$dtok" -lt 0 ] && dtok=0
    dcst=$(awk -v a="$cost_raw" -v b="$last_cst" 'BEGIN{d=a-b; printf "%.6f",(d<0)?0:d}')
fi

# Accumulate daily
daily_lbl=$(echo "$track" | jq -r '.daily.label // ""')
if [ "$daily_lbl" = "$NOW_DATE" ]; then
    daily_tok=$(( $(echo "$track" | jq -r '.daily.tokens // 0') + dtok ))
    daily_cst=$(awk -v a="$(echo "$track" | jq -r '.daily.cost // 0')" -v b="$dcst" \
                'BEGIN{printf "%.6f",a+b}')
else
    daily_tok=$dtok
    daily_cst=$(awk -v b="$dcst" 'BEGIN{printf "%.6f",b}')
fi

# Accumulate weekly
weekly_lbl=$(echo "$track" | jq -r '.weekly.label // ""')
if [ "$weekly_lbl" = "$NOW_WEEK" ]; then
    weekly_tok=$(( $(echo "$track" | jq -r '.weekly.tokens // 0') + dtok ))
    weekly_cst=$(awk -v a="$(echo "$track" | jq -r '.weekly.cost // 0')" -v b="$dcst" \
                 'BEGIN{printf "%.6f",a+b}')
else
    weekly_tok=$dtok
    weekly_cst=$(awk -v b="$dcst" 'BEGIN{printf "%.6f",b}')
fi

# Accumulate monthly
monthly_lbl=$(echo "$track" | jq -r '.monthly.label // ""')
if [ "$monthly_lbl" = "$NOW_MONTH" ]; then
    monthly_tok=$(( $(echo "$track" | jq -r '.monthly.tokens // 0') + dtok ))
    monthly_cst=$(awk -v a="$(echo "$track" | jq -r '.monthly.cost // 0')" -v b="$dcst" \
                  'BEGIN{printf "%.6f",a+b}')
else
    monthly_tok=$dtok
    monthly_cst=$(awk -v b="$dcst" 'BEGIN{printf "%.6f",b}')
fi

# Persist only when something changed
if [ "$dtok" -gt 0 ]; then
    jq -n \
      --argjson ldm "$duration_ms" --argjson lt "$total_tokens" --argjson lc "$cost_raw" \
      --arg dl "$NOW_DATE"  --argjson dt "$daily_tok"   --argjson dc "$daily_cst" \
      --arg wl "$NOW_WEEK"  --argjson wt "$weekly_tok"  --argjson wc "$weekly_cst" \
      --arg ml "$NOW_MONTH" --argjson mt "$monthly_tok" --argjson mc "$monthly_cst" \
      '{
        last_duration_ms: $ldm, last_tokens: $lt, last_cost: $lc,
        daily:   {label: $dl, tokens: $dt, cost: $dc},
        weekly:  {label: $wl, tokens: $wt, cost: $wc},
        monthly: {label: $ml, tokens: $mt, cost: $mc}
      }' > "$TRACK_FILE" 2>/dev/null || true
fi

# ── Line 4: TOKENS  SESSION │ DAY │ WEEK │ MONTH ─────────────────────────────
printf '%s%-7s%s' "$DIM" "TOKENS" "$RESET"
printf '%s%sSESSION%s %s' "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_tok $total_tokens)${RESET}"
printf '%s%sDAY%s %s'     "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_tok $daily_tok)${RESET}"
printf '%s%sWEEK%s %s'    "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_tok $weekly_tok)${RESET}"
printf '%s%sMONTH%s %s'   "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_tok $monthly_tok)${RESET}"
printf '\n'

# ── Line 5: COST    SESSION │ DAY │ WEEK │ MONTH ─────────────────────────────
printf '%s%-7s%s' "$DIM" "COST" "$RESET"
printf '%s%sSESSION%s %s' "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_cost $cost_raw)${RESET}"
printf '%s%sDAY%s %s'     "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_cost $daily_cst)${RESET}"
printf '%s%sWEEK%s %s'    "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_cost $weekly_cst)${RESET}"
printf '%s%sMONTH%s %s'   "$SEP" "$DIM" "$RESET" "${GRAY}$(fmt_cost $monthly_cst)${RESET}"
printf '\n'
