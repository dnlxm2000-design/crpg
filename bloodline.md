Bloodline Modeling (Elves and Humans)

Overview
- This document defines the data model and planning for Bloodlines in the CRPG project.
- Bloodlines are region-based, extendable entities that sit alongside Kingdom/Clan options.
- Elf Bloodlines are extended to 7; Human Bloodlines are prepared to be structured to align with the Elf data model (4 items currently for humans).

Data Model (JSON schema-like)
- bloodline_options: Array of bloodline objects with fields:
  - id: string
  - name: string (Korean name)
  - name_en: string (English name)
  - description: string
  - region: string (internal region_id, e.g. Northlands)
  - region_kor: string (Korean region name)
  - starting_location: string
  - ability_bonus: object (e.g. {"STR": 1, "DEX": 1})
  - requires_kingdom: bool

Elf Bloodlines (7, examples include region-based entries)
- elf_bloodline_silver_guard
  - region: Northlands; region_kor: 노스랜드; starting_location: SilverWatch; name_en: Silver Guardian Bloodline
- elf_bloodline_forest_guard
  - region: ForestReach; region_kor: 숲지대; starting_location: ForestGrove; name_en: Forest Guardian Bloodline
- elf_bloodline_moonweaver
  - region: CoastalCliffs; region_kor: 해안 절벽; starting_location: MoonriseCliff; name_en: Moonweaver Bloodline
- elf_bloodline_river_guard
  - region: RiverDelta; region_kor: 강 삼각주; starting_location: RiverWatch; name_en: River Guard Bloodline
- elf_bloodline_mountain_guard
  - region: MountainPass; region_kor: 산맥 고개; starting_location: PeakWatch; name_en: Mountain Guardian Bloodline
- elf_bloodline_dawnpatron
  - region: MountainPass; region_kor: 산맥 고개; starting_location: DawnPeak; name_en: Dawn Patron Bloodline
- elf_bloodline_skyweaver
  - region: Northlands; region_kor: 노스랜드; starting_location: Skyspire; name_en: Skyweaver Bloodline

Human Bloodlines (4, to be aligned with Elf pattern)
- human_bloodline_dawn
- human_bloodline_sky
- human_bloodline_sun
- human_bloodline_moon
(4 items to finalize with exact region/starting_location/ability_bonus)

Region Mappings (Korean/English)
- Northlands -> 노스랜드
- ForestReach -> 숲지대
- RiverDelta -> 강 삼각주
- CoastalCliffs -> 해안 절벽
- MountainPass -> 산맥 고개

Notes
- Bloodlines can be extended to additional regions in the future (multi-region support).
- Starting locations should be region-based defaults with the possibility of per-bloodline overrides.
- UI must display name_en alongside the Korean name, in the Bloodline selector when available.

Next steps (when you lift the Plan mode):
- Integrate these bloodlines into data/races.json and adjacent docs.
- Update character_creation.gd to load and display name_en/region_kor.
- Create PR with changes and a compact QA checklist.
