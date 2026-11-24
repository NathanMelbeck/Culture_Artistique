"""Validate source links and the data needed by the native course renderer."""
from pathlib import Path
import json
import re
import hashlib
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"
ALLOWED_FURNITURE_VISUAL_TYPES = {"original", "period_representation", "faithful_reproduction"}


def validate_furniture_visual(item, period_id, allowed_types):
    """Require editorial evidence for fidelity and period, not a stylistic resemblance."""
    status = item.get("historical_status")
    assert status in allowed_types, "Furniture must be original, a period representation or a documented faithful reproduction"
    assert period_id in item.get("subject_periods", []), "Furniture is not documented for the taught period"
    assert item.get("source", "").startswith("https://"), "An identified public source is required for furniture"
    if status == "faithful_reproduction":
        assert item.get("model_url", "").startswith("https://"), "Identify the original model of a reproduction"
        assert item.get("fidelity_url", "").startswith("https://"), "Document the fidelity of a reproduction"
        assert item.get("fidelity_note", "").strip(), "Describe the reproduction and its documented limits"


def main():
    manifest = json.loads((APP / "content/courses/catalogue.json").read_text(encoding="utf-8"))
    media = json.loads((APP / "content/course_media.json").read_text(encoding="utf-8"))
    furniture_policy = manifest["editorial_requirements"]["furniture_section"]
    allowed_types = set(furniture_policy["allowed_visual_types"])
    assert allowed_types and allowed_types <= ALLOWED_FURNITURE_VISUAL_TYPES, "Reinterpretations cannot be authorized by the catalogue"
    course_ids = set()
    chapter_count = question_count = 0
    used_media = set()
    column_count = 0
    for path in manifest["courses"]:
        course = json.loads((APP / path.removeprefix("res://")).read_text(encoding="utf-8"))
        assert course["id"] not in course_ids, "Duplicate course id"
        course_ids.add(course["id"])
        assert course["objectives"] and course["references"]
        furniture_sections = [chapter for chapter in course["chapters"] if chapter.get("section") == furniture_policy["id"]]
        assert len(furniture_sections) == 1, f'{course["id"]}: one Le Mobilier section is required'
        furniture_section = furniture_sections[0]
        assert furniture_section["title"] == furniture_policy["title"]
        examples = [block for block in furniture_section["blocks"] if block["type"] == "furniture_example"]
        assert len(examples) >= furniture_policy["minimum_examples"], f'{course["id"]}: insufficient illustrated furniture examples'
        assert len({example["id"] for example in examples}) == len(examples)
        for example in examples:
            assert example["title"] and example["description"] and example["status_label"]
            assert len(example["characteristics"]) >= furniture_policy["minimum_characteristics"]
            assert all(item.strip() for item in example["characteristics"])
            reference = example["reference"]
            assert reference["title"] and reference["text"] and reference["url"].startswith("https://")
            assert media[example["media"]]["source"] == reference["url"], "Example and image provenance must agree"
            validate_furniture_visual(media[example["media"]], course["period_id"], allowed_types)
        gallery = course["chapters"][course["chapters"].index(furniture_section) + 1]
        assert gallery["id"] == "catalogue" and len(gallery["blocks"]) >= 4
        gallery_media = [block["media"] for block in gallery["blocks"] if block["type"] == "catalogue_item"]
        assert len(set(gallery_media)) == len(gallery["blocks"]), "Each catalogue item needs its own illustration"
        used_media.add(course["cover_media"])
        chapter_ids = set()
        words = []
        column_examples = []
        for chapter in course["chapters"]:
            assert chapter["id"] not in chapter_ids, "Duplicate chapter id"
            chapter_ids.add(chapter["id"])
            if "source_pages" in chapter:
                assert chapter["source_pages"] and all(isinstance(n, int) and n > 0 for n in chapter["source_pages"])
            for block in chapter["blocks"]:
                assert block["type"] in {"paragraph", "heading", "image", "key_points", "callout", "source", "furniture_example", "column_example", "annotated_image", "catalogue_item"}
                if block["type"] == "source":
                    assert block["title"] and block["text"] and block["url"].startswith("https://")
                if block["type"] in {"catalogue_item", "image", "furniture_example", "column_example", "annotated_image"}:
                    used_media.add(block["media"])
                    item = media[block["media"]]
                    if "historical_status" in item:
                        validate_furniture_visual(item, course["period_id"], allowed_types)
                    if "region" in block:
                        x, y, width, height = block["region"]
                        assert 0 <= x < 1 and 0 <= y < 1 and width > 0 and height > 0
                        assert x + width <= 1 and y + height <= 1, "Crop outside source image"
                    for marker in block.get("markers", []):
                        assert marker["label"].strip() and marker["definition"].strip()
                        for point in [marker["point"], marker.get("label_point", marker["point"])]:
                            assert len(point) == 2 and all(0 <= value <= 1 for value in point), "Pointer outside displayed image"
                    assert "support" not in block.get("caption", "").lower()
                if block["type"] == "catalogue_item":
                    assert all(block.get(k) for k in ["title", "date", "origin", "observation"])
                    assert item["source"].startswith("https://")
                    validate_furniture_visual(item, course["period_id"], allowed_types)
                if block["type"] == "column_example":
                    assert block["title"] and block["description"] and len(block["cues"]) >= 3
                    assert all(cue.strip() for cue in block["cues"])
                    assert block["display_height"] >= 350
                    column_examples.append(block["id"])
                    words.extend((block["description"] + " " + " ".join(block["cues"])).split())
                if block["type"] == "furniture_example":
                    words.extend((block["description"] + " " + " ".join(block["characteristics"]) + " " + block["reference"]["text"]).split())
                elif block["type"] != "image":
                    words.extend(re.sub(r"\[/?b\]", "", block.get("text", " ".join(block.get("items", [])))).split())
                for marker in block.get("markers", []):
                    words.extend((marker["label"] + " " + marker["definition"]).split())
        expected_columns = manifest["editorial_requirements"]["column_sections"][course["period_id"]]
        assert len(column_examples) == len(set(column_examples)), "Duplicate column type"
        assert set(column_examples) == set(expected_columns), f'{course["id"]}: each column type needs its own illustrated example'
        column_count += len(column_examples)
        for question in course["quiz"]:
            assert question["chapter"] in chapter_ids
            assert len(question["choices"]) >= 2
            assert 0 <= question["correct"] < len(question["choices"])
            assert len(set(question["choices"])) == len(question["choices"])
            assert question["explanation"].strip()
            if "media" in question:
                used_media.add(question["media"])
        chapter_count += len(chapter_ids)
        question_count += len(course["quiz"])
        print(f'{course["id"]}: {len(chapter_ids)} chapters, {len(words)} words, {len(course["quiz"])} questions')
    for key in used_media:
        item = media[key]
        assert (APP / item["path"].removeprefix("res://")).stat().st_size > 0
        if item["source"].startswith("https://"):
            assert (ROOT / item["metadata_file"]).is_file()
            assert item["display_credit"]
            original = json.loads((ROOT / item["metadata_file"]).read_text(encoding="utf-8-sig"))
            if item.get("provider") == "wikimedia":
                assert item["visual_role"] == "reference_diagram", "Modern reference drawing must be identified"
                assert original["descriptionurl"] == item["source"] and original["url"] == item["download_url"]
                assert item["rights"] == original["extmetadata"]["LicenseShortName"]["value"]
                assert item["rights"] in {"Public domain", "CC BY-SA 4.0"}
                assert item["license_url"].startswith("https://creativecommons.org/")
                if item["rights"] == "CC BY-SA 4.0":
                    assert item["license_url"] == original["extmetadata"]["LicenseUrl"]["value"]
                    assert "JLVwiki" in item["display_credit"] and "même licence" in item["display_credit"]
            elif item.get("provider") == "cleveland":
                assert original["share_license_status"] == item["rights"] == "CC0"
                assert original["url"] == item["source"] and original["image_web"] == item["download_url"]
            else:
                assert item["rights"].startswith("CC0")
                assert original["isPublicDomain"] and original["objectURL"] == item["source"]
                assert item["download_url"] in [original["primaryImage"], *original["additionalImages"]]
            assert hashlib.sha256((APP / item["path"].removeprefix("res://")).read_bytes()).hexdigest() == item["source_image_sha256"]
        else:
            assert (ROOT / item["source"]).is_file(), item["source"]
            assert item["source_page"] > 0
        assert item["caption"] and item["alt"]
        assert "support" not in item["caption"].lower()
        assert "support" not in item.get("display_credit", "").lower()
        if item["path"].endswith(".svg"):
            drawing = ET.parse(APP / item["path"].removeprefix("res://"))
            for element in drawing.iter():
                assert element.tag.rsplit("}", 1)[-1] not in {"script", "foreignObject"}
                for attribute, value in element.attrib.items():
                    if attribute.rsplit("}", 1)[-1] in {"href", "src"}:
                        assert value.startswith(("#", "data:image/")), "SVG must not fetch external content"
    for group in manifest["groups"]:
        assert set(group["periods"]).issubset(course_ids)
    assert used_media == set(media), "Unreferenced or missing illustrations"
    print(f'VALID: {len(course_ids)} courses / {chapter_count} chapters / {question_count} questions / {len(used_media)} existing illustrations / {column_count} individually illustrated column types')


if __name__ == "__main__":
    main()
