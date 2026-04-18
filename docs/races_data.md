## Orc (오크) - 종족 데이터 개요

- 기본 능력치 증가: STR +2, CON +1, INT -2, DEX/WIS/CHA 0
- Kingdom/Clan: 5개 clan_options 유지
- Bloodline: 지역 기반 Bloodline 확장 계획(향후 확장 가능)
- 시작 위치: Bloodline region별 starting_location 반영

지역(한국어 표기) 매핑
- Northlands: 노스랜드
- ForestReach: 숲지대
- RiverDelta: 강 삼각주
- CoastalCliffs: 해안 절벽
- MountainPass: 산맥 고개

혈통 옵션 (Bloodlines) - 지역 기반 확장 샘플
- Northlands (노스랜드) — 아이언 혈맥 (Iron Bloodline, name_en: Iron Bloodline)
  - region: Northlands
  - region_kor: 노스랜드
  - starting_location: IronKeep
  - ability_bonus: {"STR": 1, "CON": 1}
  - description: 강철 심장과 전쟁의 의지
  - name_en: Iron Bloodline
- ForestReach (숲지대) — 피의 그림자 혈맥 (Bloodshadow Bloodline, name_en: Bloodshadow Bloodline)
  - region: ForestReach
  - region_kor: 숲지대
  - starting_location: ShadowGrove
  - ability_bonus: {"DEX": 1, "CHA": 1}
  - description: 암흑의 은밀함
  - name_en: Bloodshadow Bloodline
- RiverDelta (강 삼각주) — 강의 혈맥 (River Bloodline, name_en: River Bloodline)
  - region: RiverDelta
  - region_kor: 강 삼각주
  - starting_location: RiverGate
  - ability_bonus: {"STR": 1, "DEX": 1}
  - description: 강의 흐름을 지배하는 자
  - name_en: River Bloodline
- CoastalCliffs (해안 절벽) — 해안의 혈맥 (Coastal Bloodline, name_en: Coastal Bloodline)
  - region: CoastalCliffs
  - region_kor: 해안 절벽
  - starting_location: CoastWatch
  - ability_bonus: {"CON": 1, "CHA": 1}
  - description: 해안의 상인과 모험가
  - name_en: Coastal Bloodline
- MountainPass (산맥 고개) — 산맥의 혈맥 (Mountain Bloodline, name_en: Mountain Bloodline)
- River Guard Bloodline (RiverDelta) — region: RiverDelta, region_kor: 강 삼각주, starting_location: RiverWatch, ability_bonus: {DEX:1, WIS:1}, description: 강의 흐름을 수호하는 혈맥
- Mountain Guardian Bloodline (MountainPass) — region: MountainPass, region_kor: 산맥 고개, starting_location: PeakWatch, ability_bonus: {STR:1, WIS:1}, description: 산맥의 경계 수호자
  - region: MountainPass
  - region_kor: 산맥 고개
  - starting_location: PeakFort
  - ability_bonus: {"STR": 1, "WIS": 1}
  - description: 산맥의 용자
  - name_en: Mountain Bloodline

배열 스펙 및 확장성
- bloodline_options은 Orc의 data/races.json에 확장 가능
- region, region_kor, starting_location, ability_bonus, requires_kingdom 등의 필드를 포함한다

참고
- 혈통은 독립적 지역 기반 모델로 확장되며, 시작 위치는 지역별로 유연하게 설정한다.
