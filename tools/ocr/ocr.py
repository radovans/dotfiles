#!/usr/bin/env python3
"""
OCR Pipeline: PDF -> Tesseract (local hint) + GPT Vision -> JSON output
"""

import os
import sys
import json
import base64
import shutil
import argparse
import datetime
import tempfile
import subprocess
from pathlib import Path

import requests
import pytesseract
import cv2
import numpy as np
from pdf2image import convert_from_path


# ─────────────────────────────────────────────
# Config & env
# ─────────────────────────────────────────────

def load_env(env_path: Path) -> dict:
    env = {}
    if not env_path.exists():
        raise FileNotFoundError(f".env not found at {env_path}")
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        value = value.strip().strip('"').strip("'")
        env[key.strip()] = value
    return env


def load_config(script_dir: Path) -> dict:
    config_path = script_dir / "config.json"
    with open(config_path) as f:
        cfg = json.load(f)

    repo_root = script_dir.parent.parent
    env = load_env(repo_root / ".env")
    cfg["openai_api_key"] = env.get("OPENAI_API_KEY", "")

    inbox_override = env.get("OCR_INBOX_DIR", "")
    if inbox_override:
        cfg["inbox_dir"] = Path(inbox_override).resolve()
    else:
        raise ValueError("OCR_INBOX_DIR not set in .env — please set the path to your inbox folder")

    cfg["processed_dir"] = cfg["inbox_dir"] / "processed"

    for key in ["ocr_prompt", "metadata_prompt"]:
        if isinstance(cfg.get(key), list):
            cfg[key] = "\n".join(cfg[key])

    required = ["openai_api_key", "model", "tesseract_langs", "dpi",
                "min_text_length", "ocr_prompt", "metadata_prompt"]
    for key in required:
        if not cfg.get(key):
            raise ValueError(f"Missing required config key: {key}")
    if cfg["openai_api_key"].startswith("sk-YOUR"):
        raise ValueError("Please set OPENAI_API_KEY in .env")

    return cfg


# ─────────────────────────────────────────────
# PDF text extraction
# ─────────────────────────────────────────────

def extract_embedded_text(pdf_path: Path) -> list[dict]:
    try:
        result = subprocess.run(
            ["pdftotext", "-layout", str(pdf_path), "-"],
            capture_output=True, text=True, timeout=30
        )
        if result.returncode != 0:
            return []
        pages = result.stdout.split("\f")
        return [{"page": i + 1, "text": p.strip()} for i, p in enumerate(pages) if p.strip()]
    except Exception as e:
        print(f"  [warn] pdftotext failed: {e}")
        return []


def is_meaningful(text: str, min_length: int) -> bool:
    return len(text.strip()) >= min_length


# ─────────────────────────────────────────────
# Tesseract
# ─────────────────────────────────────────────

def preprocess_for_tesseract(pil_image) -> np.ndarray:
    img = np.array(pil_image)
    gray = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    binary = cv2.adaptiveThreshold(
        gray, 255,
        cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv2.THRESH_BINARY,
        blockSize=31,
        C=10
    )
    return cv2.fastNlMeansDenoising(binary, h=10)


def run_tesseract(img: np.ndarray, langs: str) -> str:
    try:
        return pytesseract.image_to_string(img, lang=langs, config="--oem 3 --psm 6").strip()
    except Exception as e:
        print(f"  [warn] Tesseract failed: {e}")
        return ""


# ─────────────────────────────────────────────
# OpenAI
# ─────────────────────────────────────────────

def pil_to_base64(pil_image) -> str:
    import io
    buf = io.BytesIO()
    pil_image.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")


def call_openai_vision(api_key: str, model: str, prompt: str, image_b64: str) -> str:
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json={
            "model": model,
            "messages": [{
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {
                        "url": f"data:image/png;base64,{image_b64}",
                        "detail": "high"
                    }}
                ]
            }],
            "max_tokens": 4096
        },
        timeout=120
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"].strip()


def call_openai_text(api_key: str, model: str, prompt: str) -> str:
    response = requests.post(
        "https://api.openai.com/v1/chat/completions",
        headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
        json={
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 1024
        },
        timeout=60
    )
    response.raise_for_status()
    return response.json()["choices"][0]["message"]["content"].strip()


def extract_metadata(api_key: str, model: str, prompt_template: str, full_text: str) -> dict:
    prompt = prompt_template.replace("{document_text}", full_text[:6000])
    raw = call_openai_text(api_key, model, prompt).strip()
    if raw.startswith("```"):
        raw = "\n".join(raw.split("\n")[1:])
    if raw.endswith("```"):
        raw = raw[:-3].strip()
    try:
        return json.loads(raw)
    except json.JSONDecodeError:
        print(f"  [warn] Could not parse metadata JSON:\n{raw}")
        return {"description": None, "short_summary": None, "document_date": None}


# ─────────────────────────────────────────────
# Core pipeline
# ─────────────────────────────────────────────

def process_pdf(pdf_path: Path, cfg: dict) -> dict:
    print(f"\n{'='*60}")
    print(f"Processing: {pdf_path.name}")
    print(f"{'='*60}")

    api_key   = cfg["openai_api_key"]
    model     = cfg["model"]
    dpi       = cfg["dpi"]
    langs     = cfg["tesseract_langs"]
    min_len   = cfg["min_text_length"]

    pages_data = []
    embedded_pages = extract_embedded_text(pdf_path)

    with tempfile.TemporaryDirectory() as tmpdir:
        all_images = convert_from_path(str(pdf_path), dpi=dpi, output_folder=tmpdir)
        total_pages = len(all_images)
        print(f"  Total pages: {total_pages}")

        for page_num in range(1, total_pages + 1):
            print(f"\n  ── Page {page_num}/{total_pages} ──")
            pil_image = all_images[page_num - 1]

            embedded = next((p for p in embedded_pages if p["page"] == page_num), None)
            if embedded and is_meaningful(embedded["text"], min_len):
                print(f"    Using embedded text ({len(embedded['text'])} chars)")
                pages_data.append({"page": page_num, "text": embedded["text"]})
                continue

            print("    Running Tesseract...")
            preprocessed = preprocess_for_tesseract(pil_image)
            tesseract_text = run_tesseract(preprocessed, langs)
            print(f"    Tesseract got {len(tesseract_text)} chars")

            print(f"    Calling {model} Vision API...")
            image_b64 = pil_to_base64(pil_image)
            ocr_prompt = cfg["ocr_prompt"].replace(
                "{tesseract_text}", tesseract_text or "(no text detected)"
            )
            try:
                final_text = call_openai_vision(api_key, model, ocr_prompt, image_b64)
                print(f"    Got {len(final_text)} chars from Vision API")
            except requests.HTTPError as e:
                print(f"    [error] Vision API failed: {e}")
                final_text = tesseract_text

            pages_data.append({"page": page_num, "text": final_text})

    # Extract metadata via OpenAI text API
    print("\n  Extracting metadata...")
    full_text = "\n\n--- Page Break ---\n\n".join(p["text"] for p in pages_data if p["text"])
    try:
        meta = extract_metadata(api_key, model, cfg["metadata_prompt"], full_text)
    except Exception as e:
        print(f"  [error] Metadata extraction failed: {e}")
        meta = {"description": None, "short_summary": None, "document_date": None}

    return {
        "original_filename": pdf_path.name,
        "pages": total_pages,
        "ocr_date": datetime.date.today().isoformat(),
        "document_date": meta.get("document_date"),
        "description": meta.get("description"),
        "short_summary": meta.get("short_summary"),
        "pages_data": pages_data
    }


# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="OCR pipeline: PDF → Tesseract + GPT Vision → JSON"
    )
    parser.add_argument("files", nargs="*", help="Specific PDF(s) to process")
    args = parser.parse_args()

    script_dir = Path(__file__).parent
    cfg = load_config(script_dir)

    inbox_dir     = cfg["inbox_dir"]
    processed_dir = cfg["processed_dir"]
    processed_dir.mkdir(parents=True, exist_ok=True)

    if args.files:
        pdf_files = [Path(f) for f in args.files]
    else:
        pdf_files = sorted(inbox_dir.glob("*.pdf"))

    if not pdf_files:
        print(f"No PDF files found in {inbox_dir}")
        sys.exit(1)

    print(f"Found {len(pdf_files)} PDF(s) to process")

    results = []
    for pdf_path in pdf_files:
        if not pdf_path.exists():
            print(f"[skip] File not found: {pdf_path}")
            continue

        processed_pdf = processed_dir / pdf_path.name
        if processed_pdf.exists():
            print(f"[skip] Already processed: {pdf_path.name}")
            results.append({"file": pdf_path.name, "status": "skipped"})
            continue

        try:
            output = process_pdf(pdf_path, cfg)

            # Save JSON next to the processed PDF
            json_path = processed_dir / (pdf_path.stem + ".json")
            json_path.write_text(json.dumps(output, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"  JSON → processed/{json_path.name}")

            # Move original PDF to processed/
            shutil.move(str(pdf_path), str(processed_pdf))
            print(f"  PDF  → processed/{processed_pdf.name}")

            results.append({"file": pdf_path.name, "status": "ok",
                            "description": output.get("description")})
        except Exception as e:
            print(f"[error] Failed to process {pdf_path.name}: {e}")
            results.append({"file": pdf_path.name, "status": "error", "error": str(e)})

    # Summary
    print(f"\n{'='*60}\nSUMMARY\n{'='*60}")
    icons = {"ok": "✓", "skipped": "↷", "error": "✗"}
    for r in results:
        print(f"  {icons.get(r['status'], '?')} {r['file']}")
        if r.get("description"):
            print(f"      {r['description']}")

    # Write run summary
    summary_path = processed_dir / "run_summary.json"
    summary_path.write_text(
        json.dumps({
            "timestamp": datetime.datetime.now().isoformat(),
            "files": results
        }, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )
    print(f"\nDone. Output → {processed_dir}")


if __name__ == "__main__":
    main()
