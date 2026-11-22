"""Validate the offline chronological catalogue and its links to existing courses."""
from pathlib import Path
import json
import re
import hashlib
from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'app'

def main():
    data = json.loads((APP / 'content/games/chronology.json').read_text(encoding='utf-8'))
    assert data['version'] == 1
    periods = {p['id']: p for p in data['periods']}
    assert len(periods) == len(data['periods'])
    assert len({p['order'] for p in periods.values()}) == len(periods)
    courses = {id: json.loads((APP / f'content/courses/{id}.json').read_text(encoding='utf-8')) for id in periods}
    sheets = {sheet['id']: sheet for sheet in json.loads((APP / 'content/revision_sheets.json').read_text(encoding='utf-8'))['sheets']}
    for p in periods.values():
        assert p['start'] < p['end'] and p['start'] != 0 and p['end'] != 0
        assert p['scope'] and p['start_note'] and p['end_note'] and p['bounds_source']
        provenance = p['bounds_source']
        sheet = sheets[provenance['sheet_id']]
        assert provenance['sheet_id'] == p['id']
        pdf = ROOT / sheet['source_file']
        assert hashlib.sha256(pdf.read_bytes()).hexdigest() == sheet['source_sha256']
        text = PdfReader(pdf).pages[provenance['page'] - 1].extract_text()
        normalize = lambda value: re.sub(r'\s+', '', value)
        heading = normalize(provenance['heading'])
        assert heading in normalize(text), f"{p['id']}: revision heading changed"
        found = re.search(r'\|(-?\d+)à(-?\d+)', heading)
        assert found and [int(value) for value in found.groups()] == [p['start'], p['end']], f"{p['id']}: game bounds must match revision heading"
        for boundary in ['start', 'end']:
            choices = p[boundary + '_choices']
            assert len(choices) == 5 and len(set(choices)) == 5 and p[boundary] in choices
            assert all(type(year) is int and year != 0 for year in choices)
    for group in data['groups']:
        assert group['title'] and set(group['periods']) <= periods.keys()
    assert len({e['id'] for e in data['events']}) == len(data['events'])
    for event in data['events']:
        assert event['title'] and event['explanation'] and event['source']['title']
        assert not re.search(r'\d|av\. J|ap\. J', event['title']), 'Card fronts must not display dates'
        assert event['source']['url'].startswith('https://')
        assert type(event['year']) is int and event['year'] != 0
        assert event['rarity'] in {'common', 'rare', 'epic', 'legendary'}, event['id']
        if event.get('approximate'):
            lower, upper = event['accepted_from'], event['accepted_to']
            assert type(lower) is int and type(upper) is int
            assert lower != 0 and upper != 0 and lower <= event['year'] <= event.get('year_end', event['year']) <= upper
        assert event['periods'] and set(event['periods']) <= periods.keys()
        end = event.get('year_end', event['year'])
        assert event['year'] <= end and end != 0
        course = courses[event['course_id']]
        assert event['chapter'] in {chapter['id'] for chapter in course['chapters']}, event['id']
    playable = set()
    for id, period in periods.items():
        matching = [event for event in data['events'] if id in event['periods'] and period['start'] <= event['year'] <= event.get('year_end', event['year']) <= period['end']]
        playable.update(event['id'] for event in matching)
    print(f"VALID: {len(periods)} periods matching revision PDFs / {len(data['events'])} sourced events / {len(playable)} playable within style bounds / 5 choices per boundary")

if __name__ == '__main__':
    main()
