#!/usr/bin/env python3
import json
import sys
from pathlib import Path


REQUIRED_KEYS = {"id", "name", "region", "region_kor", "starting_location", "ability_bonus", "requires_kingdom"}


def load_json(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return data


def validate_bloodline_entry(entry, path, index, race_id):
    if not isinstance(entry, dict):
        print(f"ERROR: Bloodline entry at {path}:{index} for race '{race_id}' is not a dictionary.")
        return False
    missing = [k for k in REQUIRED_KEYS if k not in entry]
    if missing:
        print(
            f"ERROR: Bloodline entry for race '{race_id}' at index {index} missing keys: {', '.join(missing)}"
        )
        return False
    # name_en is optional but encouraged; if present it should be a string
    if "name_en" in entry and not isinstance(entry["name_en"], str):
        print(f"ERROR: 'name_en' for bloodline '{entry.get('id','unknown')}' in race '{race_id}' is not a string.")
        return False
    return True


def main():
    ok = True
    data_races = load_json(Path("data/races.json"))
    races = data_races.get("races", {})
    # Elf should have 7 bloodlines; Human should have 4
    elf_entry = races.get("elf", {})
    human_entry = races.get("human", {})

    elf_bloodlines = elf_entry.get("bloodline_options", [])
    human_bloodlines = human_entry.get("bloodline_options", [])

    if len(elf_bloodlines) != 7:
        print(f"ERROR: Expected 7 Elf bloodline_options, found {len(elf_bloodlines)}")
        ok = False
    if len(human_bloodlines) != 4:
        print(f"ERROR: Expected 4 Human bloodline_options, found {len(human_bloodlines)}")
        ok = False

    # Validate each bloodline entry structure
    for i, bl in enumerate(elf_bloodlines):
        if not isinstance(bl, dict):
            print(f"ERROR: Elf bloodline at index {i} is not a dictionary.")
            ok = False
            continue
        if not validate_bloodline_entry(bl, "data/races.json", i, "elf"):
            ok = False

    for i, bl in enumerate(human_bloodlines):
        if not isinstance(bl, dict):
            print(f"ERROR: Human bloodline at index {i} is not a dictionary.")
            ok = False
            continue
        if not validate_bloodline_entry(bl, "data/races.json", i, "human"):
            ok = False

    if ok:
        print("OK: Bloodline data passes validation (Elf=7, Human=4) and required fields present.")
        sys.exit(0)
    else:
        print("Validation failed. See above errors.")
        sys.exit(1)


if __name__ == "__main__":
    main()
