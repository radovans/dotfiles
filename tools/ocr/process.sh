#!/usr/bin/env bash
# OCR Pipeline runner
# Usage: ./run.sh [--help] [file.pdf ...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"
CONFIG="$SCRIPT_DIR/config.json"
VENV="$SCRIPT_DIR/venv"
OCR_PY="$SCRIPT_DIR/ocr.py"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*"; }

show_help() {
    echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              OCR Pipeline                    ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}USAGE:${NC}"
    echo "  ./process.sh                  Process all PDFs in inbox"
    echo "  ./process.sh file.pdf ...     Process specific file(s)"
    echo "  ./process.sh --help           Show this help message"
    echo ""
    echo -e "${CYAN}PIPELINE:${NC}"
    echo "  1. Skip files already in \$OCR_INBOX_DIR/processed/"
    echo "  2. Extract embedded text or run Tesseract + GPT Vision OCR"
    echo "  3. Extract metadata (description, summary, date) via GPT"
    echo "  4. Save JSON to processed/ and move original PDF there"
    echo ""
    echo -e "${CYAN}CONFIGURATION:${NC}"
    echo "  .env (repo root)   OPENAI_API_KEY and OCR_INBOX_DIR"
    echo "  config.json        Model, DPI, language, prompts"
    echo ""
    echo -e "${CYAN}FIRST-TIME SETUP:${NC}"
    echo "  cp ../../.env.example ../../.env  # fill in OPENAI_API_KEY and OCR_INBOX_DIR"
    echo "  Venv and dependencies are created automatically on first run."
    echo ""
}

load_env() {
    [ -f "$ENV_FILE" ] || return 0
    while IFS='=' read -r key value; do
        key="${key// /}"
        [[ "$key" =~ ^# ]] && continue
        [[ -z "$key" ]] && continue
        value="${value%\"}" ; value="${value#\"}"
        value="${value%\'}" ; value="${value#\'}"
        export "$key=$value"
    done < "$ENV_FILE"
}

check_prereqs() {
    echo -e "${CYAN}━━━ Prerequisites ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    local ok=true

    if [ ! -f "$ENV_FILE" ]; then
        error ".env not found at repo root — copy .env.example and fill in values"
        ok=false
    else
        success ".env"
        if [[ "${OPENAI_API_KEY:-}" == sk-YOUR* ]] || [ -z "${OPENAI_API_KEY:-}" ]; then
            error "OPENAI_API_KEY not set in .env"
            ok=false
        else
            success "OpenAI API key"
        fi
        if [ -z "${OCR_INBOX_DIR:-}" ]; then
            error "OCR_INBOX_DIR not set in .env"
            ok=false
        else
            success "OCR_INBOX_DIR → $OCR_INBOX_DIR"
        fi
    fi

    if [ ! -f "$CONFIG" ]; then
        error "config.json not found"
        ok=false
    else
        success "config.json"
    fi

    if [ ! -d "$VENV" ]; then
        info "Virtual environment not found — creating..."
        python3 -m venv "$VENV"
        # shellcheck disable=SC1091
        source "$VENV/bin/activate"
        pip install --quiet pdf2image pytesseract opencv-python numpy requests
        deactivate 2>/dev/null || true
        success "Virtual environment created and dependencies installed"
    else
        success "Virtual environment"
    fi

    if ! command -v tesseract &>/dev/null; then
        error "Tesseract not installed  →  brew install tesseract tesseract-lang"
        ok=false
    else
        success "Tesseract ($(tesseract --version 2>&1 | head -1))"
    fi

    if ! command -v pdftotext &>/dev/null; then
        error "Poppler not installed  →  brew install poppler"
        ok=false
    else
        success "Poppler"
    fi

    if [ "$ok" = false ]; then
        echo ""
        error "Prerequisites not met — exiting"
        exit 1
    fi
    echo ""
}

count_total() {
    local inbox_dir="$1"; shift
    if [ "$#" -gt 0 ]; then
        echo "$#"
    else
        find "$inbox_dir" -maxdepth 1 -name "*.pdf" 2>/dev/null | wc -l | tr -d ' '
    fi
}

count_new() {
    local inbox_dir="$1"
    local processed_dir="$inbox_dir/processed"
    shift
    local n=0
    if [ "$#" -gt 0 ]; then
        for f in "$@"; do
            local name; name="$(basename "$f")"
            [ ! -f "$processed_dir/$name" ] && n=$((n + 1))
        done
    else
        for f in "$inbox_dir"/*.pdf; do
            [ -f "$f" ] || continue
            local name; name="$(basename "$f")"
            [ ! -f "$processed_dir/$name" ] && n=$((n + 1))
        done
    fi
    echo $n
}

show_summary() {
    local summary_file="$1"
    [ -f "$summary_file" ] || return

    echo -e "${CYAN}━━━ Results ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    while IFS='|' read -r status count; do
        case $status in
            ok)      success "Processed:  $count" ;;
            skipped) info    "Skipped:    $count (already done)" ;;
            error)   error   "Failed:     $count" ;;
        esac
    done < <(python3 - <<PYEOF
import json
d = json.load(open("$summary_file"))
from collections import Counter
counts = Counter(f["status"] for f in d["files"])
for status, count in counts.items():
    print(f"{status}|{count}")
PYEOF
)
    echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
case "${1:-}" in
    -h|--help|help) show_help; exit 0 ;;
esac

echo -e "${BLUE}╔══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              OCR Pipeline                    ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════╝${NC}"
echo ""

load_env
check_prereqs

INBOX_DIR="${OCR_INBOX_DIR}"
PROCESSED_DIR="$INBOX_DIR/processed"
SUMMARY_FILE="$PROCESSED_DIR/run_summary.json"

mkdir -p "$INBOX_DIR" "$PROCESSED_DIR"

echo -e "${CYAN}━━━ Input ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
total=$(count_total "$INBOX_DIR" "$@")
new_count=$(count_new "$INBOX_DIR" "$@")
already=$((total - new_count))

info "Found:      $total PDF(s)"
[ "$already" -gt 0 ] && info "Skipped:    $already (already processed)"
info "To process: $new_count"
echo ""

if [ "$new_count" -eq 0 ]; then
    success "Nothing new to process."
    exit 0
fi

read -r -p "  Proceed? [Y/n] " confirm || true
[[ "${confirm:-}" =~ ^[Nn] ]] && { info "Aborted."; exit 0; }
echo ""

echo -e "${CYAN}━━━ Running OCR pipeline ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
# shellcheck disable=SC1091
source "$VENV/bin/activate"
echo ""

if [ "$#" -gt 0 ]; then
    python3 "$OCR_PY" "$@" || true
else
    python3 "$OCR_PY" || true
fi

echo ""
deactivate 2>/dev/null || true

show_summary "$SUMMARY_FILE"

echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                   Done.                      ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
