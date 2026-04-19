#!/usr/bin/env python3
import json
import sys
from pathlib import Path

DATA_PATH = Path("C:/crpg_prototype/data/races.json")

def load_json(path: Path):
    with path.open("r", encoding="utf-8") as f:
        text = f.read()
        try:
            # Some files may have BOM; strip BOM if present
            if text.startswith("\ufeff"):
                text = text.encode('utf-8').decode('utf-8-sig')
        except Exception:
            pass
        return json.loads(text)

def ensure_keys(obj, keys):
    missing = [k for k in keys if k not in obj]
    return missing

def main():
    data = load_json(DATA_PATH)
    if not isinstance(data, dict):
        print("ERROR: data is not a dict at top level")
        sys.exit(2)
    races = data.get("races") if isinstance(data.get("races"), dict) else None
    if races is None:
        print("ERROR: 'races' section not found in data/races.json")
        sys.exit(3)

    # Elf bloodlines
    elf = races.get("elf")
    if not elf:
        print("WARN: No 'elf' section found in races.json")
    else:
        bl = elf.get("bloodline_options", [])
        print(f"Elf bloodline_options count: {len(bl)}")
        required_keys = ["id", "name", "name_en", "region", "region_kor", "starting_location", "ability_bonus", "requires_kingdom"]
        for i, item in enumerate(bl):
            if not isinstance(item, dict):
                print(f"  Bloodline #{i} is not a dict: {type(item)}")
                continue
            missing = ensure_keys(item, required_keys)
            if missing:
                print(f"  Bloodline #{i} missing keys: {missing}")

    # Human bloodlines (structure check)
    human = races.get("human")
    if human:
        h_bl = human.get("bloodline_options", []) if isinstance(human.get("bloodline_options"), list) else []
        print(f"Human bloodline_options count: {len(h_bl)}")
        for i, item in enumerate(h_bl):
            if isinstance(item, dict):
                missing = ensure_keys(item, ["id", "name", "name_en", "region", "region_kor", "starting_location", "ability_bonus", "requires_kingdom"])
                if missing:
                    print(f"  Human bloodline #{i} missing keys: {missing}")
            else:
                print(f"  Human bloodline #{i} not an object: {type(item)}")
    else:
        print("WARN: No human section found in data/races.json")

    print("DONE")

if __name__ == '__main__':
    main()
