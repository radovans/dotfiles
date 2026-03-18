# OCR Tool

Processes PDF files using a two-pass OCR pipeline: local Tesseract for a first-pass hint, then OpenAI Vision for accurate extraction. Outputs structured JSON with full text and metadata.

## Pipeline

1. Extract embedded text from PDF (fast, no API call needed)
2. If no embedded text → run Tesseract locally for a rough pass
3. Send page image + Tesseract hint to OpenAI Vision for clean extraction
4. Extract metadata (description, summary, date) via GPT
5. Save JSON output and move original PDF to `processed/`

## Output format

Each PDF produces a `.json` file alongside the processed PDF:

```json
{
  "original_filename": "scan.pdf",
  "pages": 2,
  "ocr_date": "2026-03-18",
  "document_date": "2022-09-19",
  "description": "Invoice from Acme Corp",
  "short_summary": "Invoice no. 2022-047 issued by Acme Corp on 19 September 2022...",
  "pages_data": [
    { "page": 1, "text": "..." },
    { "page": 2, "text": "..." }
  ]
}
```

## Setup

**1. Configure `.env`** at the repo root:

```bash
OPENAI_API_KEY=sk-...
OCR_INBOX_DIR=/path/to/your/inbox
```

The inbox folder is outside the repo. Processed files are moved to `$OCR_INBOX_DIR/processed/`.

**2. Install system dependencies** (once, via Homebrew):

```bash
brew install tesseract tesseract-lang poppler
```

## Usage

```bash
./process.sh                        # process all PDFs in inbox
./process.sh /path/to/file.pdf      # process a specific file
./process.sh --help                 # show help
```

The venv and Python dependencies are created automatically on first run.

## Configuration

`config.json` — adjust without touching code:

| Key | Description |
|-----|-------------|
| `model` | OpenAI model (default: `gpt-4o-mini`) |
| `tesseract_langs` | Language codes for Tesseract (default: `slk+ces+eng`) |
| `dpi` | Render resolution for PDF pages (default: `300`) |
| `min_text_length` | Minimum chars to consider embedded text usable (default: `50`) |
| `ocr_prompt` | Prompt sent to Vision API with the page image |
| `metadata_prompt` | Prompt used to extract description, summary, date |
