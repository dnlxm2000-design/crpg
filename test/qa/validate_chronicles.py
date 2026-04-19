#!/usr/bin/env python3
import json
import sys
from pathlib import Path

REQUIRED_KEYS = [
    'id', 'title', 'title_en', 'era', 'date', 'region', 'region_kor',
    'description', 'description_en', 'significance', 'related_bloodlines', 'sources'
]


def main():
    path = Path('data/chronicles_silverhaven_samples.json')
    if not path.exists():
        print(f'ERROR: Chronicles sample file not found: {path}')
        sys.exit(2)
    data = json.loads(path.read_text(encoding='utf-8'))
    chronicles = data.get('chronicles', [])
    if len(chronicles) < 6:
        print(f'ERROR: Expected at least 6 chronicle entries, found {len(chronicles)}')
        sys.exit(1)
    ok = True
    for idx, item in enumerate(chronicles):
        if not isinstance(item, dict):
            print(f'ERROR: Chronicle at index {idx} is not an object')
            ok = False
            continue
        missing = [k for k in REQUIRED_KEYS if k not in item]
        if missing:
            print(f'ERROR: Chronicle {item.get("id","<unknown>")} missing keys: {", ".join(missing)}')
            ok = False
    if ok:
        print('OK: Chronicles sample structure validated')
        sys.exit(0)
    else:
        print('Chronicles validation failed')
        sys.exit(1)


if __name__ == '__main__':
    main()
