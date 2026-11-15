"""Prepare offline revision pages for Godot from the original PDFs.

Development only: Python + pypdf + Pillow and Poppler's pdftoppm.
The distributed application only needs the generated WebP pages and JSON.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import unicodedata

from PIL import Image, ImageDraw, ImageFont
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / "fiche_revision"
OUTPUT = ROOT / "app/assets/revision_sheets"
CATALOGUE = ROOT / "app/content/revision_sheets.json"
LONG_EDGE = 3000
# Explicit editorial order; original file names are preserved in the manifest.
SHEETS = [
    ("egypte", "Égypte antique", "Antiquité", "Egypte.pdf", ["égyptien", "egyptien"]),
    ("grece", "Grèce antique", "Antiquité", "Grece.pdf", ["grec", "grecque"]),
    ("rome", "Rome antique", "Antiquité", "Rome.pdf", ["romain", "romaine"]),
    ("roman", "Style roman", "Moyen Âge", "Style Roman.pdf", ["art roman"]),
    ("gothique", "Style gothique", "Moyen Âge", "Style Gothique.pdf", ["gothique"]),
    ("renaissance", "Renaissance", "Renaissance", "Style Renaissance.pdf", []),
    ("louis-xiii", "Louis XIII", "XVIIᵉ siècle", "Style Louis 13.pdf", ["louis 13"]),
    ("louis-xiv", "Louis XIV", "XVIIᵉ siècle", "Style Louis 14.pdf", ["louis 14"]),
    ("regence", "Régence", "XVIIIᵉ siècle", "Fiche Régence.pdf", []),
    ("louis-xv", "Louis XV", "XVIIIᵉ siècle", "Fiche Louis 15.pdf", ["louis 15"]),
    ("louis-xvi", "Louis XVI", "XVIIIᵉ siècle", "Fiche Louis 16.pdf", ["louis 16"]),
    ("directoire", "Directoire", "Révolution et XIXᵉ siècle", "Fiche Louis Directoire.pdf", []),
    ("empire", "Empire", "Révolution et XIXᵉ siècle", "Fiche Louis Empire.pdf", ["napoleon 1"]),
    ("restauration", "Restauration et Louis-Philippe", "Révolution et XIXᵉ siècle", "Fiche Louis phillipe _ restauration.pdf", ["louis philippe", "louis phillipe"]),
    ("napoleon-iii", "Napoléon III", "Révolution et XIXᵉ siècle", "Fiche Napoleon 3.pdf", ["napoleon 3", "second empire"]),
    ("art-nouveau", "Art nouveau", "Autour de 1900", "Fiche Art Nouveau.pdf", []),
    ("art-deco", "Art déco", "Autour de 1900", "Fiche Art Deco.pdf", []),
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdftoppm", default=shutil.which("pdftoppm"))
    args = parser.parse_args()
    if not args.pdftoppm:
        parser.error("pdftoppm is required at import time (Poppler).")
    files = {unicodedata.normalize("NFC", p.name): p for p in SOURCES.glob("*.pdf")}
    known_files = {unicodedata.normalize("NFC", row[3]) for row in SHEETS}
    if set(files) != known_files:
        raise ValueError(f"Review catalogue mapping. Missing: {known_files-set(files)}; unmapped: {set(files)-known_files}")
    temporary = ROOT / ".tmp/revision-import"
    temporary.mkdir(parents=True, exist_ok=True)
    records = []
    covers = []
    for sheet_id, title, group, filename, aliases in SHEETS:
        source = files[unicodedata.normalize("NFC", filename)]
        reader = PdfReader(source)
        target = OUTPUT / sheet_id
        target.mkdir(parents=True, exist_ok=True)
        prefix = temporary / sheet_id
        subprocess.run([
            args.pdftoppm, "-r", "220", "-scale-to", str(LONG_EDGE), "-png", str(source), str(prefix)
        ], check=True, capture_output=True)
        rendered = sorted(temporary.glob(sheet_id + "-*.png"), key=lambda p: int(p.stem.rsplit("-", 1)[1]))
        if len(rendered) != len(reader.pages):
            raise ValueError(f"Incomplete rendering: {filename}")
        pages = []
        for number, png in enumerate(rendered, start=1):
            destination = target / f"page-{number:02}.webp"
            with Image.open(png) as original:
                image = original.convert("RGB")
                image.save(destination, "WEBP", quality=95, method=4)
                pages.append({"path": "res://" + destination.relative_to(ROOT / "app").as_posix(), "width": image.width, "height": image.height})
                if number == 1:
                    thumbnail = image.copy()
                    thumbnail.thumbnail((440, 315))
                    covers.append((title, thumbnail))
            png.unlink()  # Only the temporary file just rendered, never the source PDF.
        records.append({
            "id": sheet_id, "title": title, "group": group, "aliases": aliases,
            "source_file": source.relative_to(ROOT).as_posix(),
            "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "credit": "Document fourni par Nathan ; crédits d'origine conservés dans les pages.",
            "pages": pages,
        })
        print(f"{sheet_id}: {len(pages)} pages ready", flush=True)
    CATALOGUE.parent.mkdir(parents=True, exist_ok=True)
    CATALOGUE.write_text(json.dumps({"version": 1, "render_long_edge": LONG_EDGE, "sheets": records}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    proof = ROOT / "docs/validation/revision"
    proof.mkdir(parents=True, exist_ok=True)
    contact = Image.new("RGB", (1500, 6 * 360), "#f8f6ef")
    draw = ImageDraw.Draw(contact)
    font = ImageFont.truetype(str(ROOT / "app/assets/fonts/Manrope.ttf"), 20)
    for index, (title, cover) in enumerate(covers):
        x, y = (index % 3) * 500, (index // 3) * 360
        contact.paste(cover, (x + (500 - cover.width)//2, y))
        draw.text((x + 20, y + 320), title, fill="#243d37", font=font)
    contact.save(proof / "contact-sheet.jpg", quality=92)
    print(f"Imported {len(records)} sheets / {sum(len(r['pages']) for r in records)} pages.")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
