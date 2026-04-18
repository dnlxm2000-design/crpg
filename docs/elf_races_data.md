## Elf 혈통 확장 요약 (Races Data)

- Elf 혈통 옵션은 region 기반 Bloodline 확장을 통해 확장 중이며, 현재 3개 혈통이 추가되어 총 6개(또는 7~8개까지 확장 가능)까지 확장 여지가 남아 있습니다.
- 지역 표기: Northlands(노스랜드), ForestReach(숲지대), RiverDelta(강 삼각주), CoastalCliffs(해안 절벽), MountainPass(산맥 고개)

혈통 옵션 (Bloodlines) - 확장 예시
- elf_bloodline_silver_guard
  - region: Northlands
  - region_kor: 노스랜드
  - starting_location: SilverWatch
  - ability_bonus: {"WIS": 2}
  - name_en: Silver Guardian Bloodline
  - description: 은빛의 방어를 중시하는 수호자
  - requires_kingdom: true
- elf_bloodline_forest_guard
  - region: ForestReach
  - region_kor: 숲지대
  - starting_location: ForestGrove
  - ability_bonus: {"DEX": 1, "WIS": 1}
  - name_en: Forest Guardian Bloodline
  - description: 숲의 생태를 수호하는 자
  - requires_kingdom: false
- elf_bloodline_moonweaver
  - region: CoastalCliffs
  - region_kor: 해안 절벽
  - starting_location: MoonriseCliff
  - ability_bonus: {"INT": 1, "CHA": 1}
  - name_en: Moonweaver Bloodline
  - description: 달빛과 은은한 마력의 조합
  - requires_kingdom: false

추가 확장 포인트
- 향후 다지역 확장 가능성을 유지하되, 초기 3개 혈통에서 시작하고, 지역 확장을 통해 확장해 나가는 방식이 적합합니다.
- name_en이 존재하는 혈통은 UI에서 영어 이름과 함께 노출되도록 표기 로직을 유지합니다.
