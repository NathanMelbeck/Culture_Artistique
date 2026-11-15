"""Re-extract PDF illustrations using the editorial media manifest.

Museum photographs and their metadata remain untouched. The manifest is the
single source of truth for captions, provenance and extraction coordinates.
"""
from pathlib import Path
import csv, hashlib, json, logging, sys
from pypdf import PdfReader
ROOT = Path(__file__).resolve().parents[1]

def main():
    logging.getLogger("pypdf").setLevel(logging.ERROR)
    manifest = ROOT / "app/content/course_media.json"
    media = json.loads(manifest.read_text(encoding="utf-8"))
    readers = {}
    for key, item in media.items():
        if item["source"].startswith("https://"):
            continue
        source = ROOT / item["source"]
        if source not in readers:
            readers[source] = PdfReader(source)
        image = readers[source].pages[item["source_page"] - 1].images[item["source_image_index"]]
        bitmap = image.image.convert("RGB")
        item["original_size"] = list(bitmap.size)
        item["source_image_sha256"] = hashlib.sha256(image.data).hexdigest()
        bitmap.thumbnail((2200, 2200))
        output = ROOT / "app" / item["path"].removeprefix("res://")
        output.parent.mkdir(parents=True, exist_ok=True)
        bitmap.save(output, "WEBP", quality=95, method=4)
        print(key, flush=True)
    manifest.write_text(json.dumps(media, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    with (ROOT / "docs/course-asset-register.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(["asset_id", "file_path", "source", "pdf_page", "image_index", "credit", "rights", "modifications"])
        for key, item in media.items():
            writer.writerow([key, item["path"], item["source"], item.get("source_page", ""), item.get("source_image_index", ""), item["credit"], item["rights"], item["modifications"]])
    print(f"{len(media)} illustrations registered.")

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    main()
