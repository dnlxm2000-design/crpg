Silverhaven Chronicles (MVP)

Overview
- Chronicles model: core events and their regional/bloodline context to connect lore with data model.
- Fields (core MVP): id, title, title_en, era, date, region, region_kor, description, description_en, significance, related_bloodlines, sources
- Relationship: Chronicles reference bloodlines and regions; UI uses region and bloodline mappings to link events.
- Multilingual: title_en, description_en, region_kor present; plan to extend to more fields if needed.

JSON Sample (data/chronicles_silverhaven_samples.json)
[ 
  {
    "id": "silverhaven_foundation",
    "title": "실버하벤의 설립",
    "title_en": "Founding of Silverhaven",
    "era": "Foundation",
    "date": "1000",
    "region": "Silverhaven",
    "region_kor": "실버하벤",
    "description": "실버하벤의 설립과 초기 공동체의 형성.",
    "description_en": "Foundation of Silverhaven and the formation of its early community.",
    "significance": "지역의 자립 및 은하드의 중심 축으로 성장",
    "related_bloodlines": ["elf_bloodline_silver_guard", "mist_sailors"],
    "sources": ["docs/research_full.md", "docs/chronicles.md"]
  },
  {
    "id": "silverhaven_gird_expansion",
    "title": "에테르 그리드 확장",
    "title_en": "Expansion of the Ether Grid",
    "era": "Expansion Era",
    "date": "1020",
    "region": "Silverhaven",
    "region_kor": "실버하벤",
    "description": "에테르 그리드의 재가동으로 지역 간 교류 증가.",
    "description_en": "Reactivation of the Ether Grid increases inter-regional exchange.",
    "significance": "무역 및 마력 연계 성장 촉진",
    "related_bloodlines": ["ether_guardians"],
    "sources": ["docs/research_full.md"]
  },
  {
    "id": "silverhaven_trade_treaty",
    "title": "실버하벤 무역 협정",
    "title_en": "Silverhaven Trade Treaty",
    "era": "Expansion Era",
    "date": "1012",
    "region": "Silverhaven",
    "region_kor": "실버하벤",
    "description": "실버하벤과 인접 지역 간 무역 규범 합의 체결.",
    "description_en": "Trade norms agreement between Silverhaven and neighboring regions.",
    "significance": "경제 협력 강화, 자원 흐름 안정",
    "related_bloodlines": ["mist_sailors", "elf_bloodline_forest_guard"],
    "sources": ["docs/research_full.md", "docs/world_building.md"]
  },
  {
    "id": "silverhaven_defense_upgrade",
    "title": "빙벽 방어선 강화",
    "title_en": "Icewall Defense Upgrade",
    "era": "Foundation",
    "date": "1018",
    "region": "Silverhaven",
    "region_kor": "실버하벤",
    "description": "빙벽 방어선 개선으로 외부 침략에 대한 저항력 강화.",
    "description_en": "Upgrade of the Icewall defense line to strengthen resistance to external threats.",
    "significance": "방어력 강화, 안정성과 장기 생존력 증가",
    "related_bloodlines": ["elf_bloodline_silver_guard","ironbloods"],
    "sources": ["docs/research_full.md"]
  },
  {
    "id": "mist_sailors_pirate_trade",
    "title": "미스트 세일러의 해적 연계와 무역",
    "title_en": "Mist Sailors: Piracy and Trade Links",
    "era": "Expansion Era",
    "date": "1016",
    "region": "Silverhaven",
    "region_kor": "실버하벤",
    "description": "해적 네트워크와의 협력으로 물류 순환 다변화.",
    "description_en": "Collaboration with pirate networks diversifies logistics cycles.",
    "significance": "노동과 자원 흐름 다변화",
    "related_bloodlines": ["mist_sailors"],
    "sources": ["docs/chronicles.md"]
  }
]
