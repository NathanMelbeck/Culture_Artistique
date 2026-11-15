"""Validate source links and the data needed by the native course renderer."""
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app"


def main():
    manifest = json.loads((APP / "content/courses/catalogue.json").read_text(encoding="utf-8"))
    media = json.loads((APP / "content/course_media.json").read_text(encoding="utf-8"))
    course_ids = set()
    chapter_count = question_count = 0
    used_media = set()
    for path in manifest["courses"]:
        course = json.loads((APP / path.removeprefix("res://")).read_text(encoding="utf-8"))
        assert course["id"] not in course_ids, "Duplicate course id"
        course_ids.add(course["id"])
        assert course["objectives"] and course["references"]
        used_media.add(course["cover_media"])
        chapter_ids = set()
        words = []
        for chapter in course["chapters"]:
            assert chapter["id"] not in chapter_ids, "Duplicate chapter id"
            chapter_ids.add(chapter["id"])
            assert chapter["source_pages"] and all(isinstance(n, int) and n > 0 for n in chapter["source_pages"])
            for block in chapter["blocks"]:
                assert block["type"] in {"paragraph", "heading", "image", "key_points", "callout"}
                if block["type"] == "image":
                    used_media.add(block["media"])
                else:
                    words.extend(re.sub(r"\[/?b\]", "", block.get("text", " ".join(block.get("items", [])))).split())
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
        assert (ROOT / item["source"]).is_file(), item["source"]
        assert item["caption"] and item["alt"] and item["source_page"] > 0
    for group in manifest["groups"]:
        assert set(group["periods"]).issubset(course_ids)
    assert used_media == set(media), "Unreferenced or missing illustrations"
    print(f'VALID: {len(course_ids)} courses / {chapter_count} chapters / {question_count} questions / {len(used_media)} existing illustrations')


if __name__ == "__main__":
    main()
