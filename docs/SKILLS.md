# CRPG_PROJECT — 스킬 데이터 (65개)

> 최종 갱신: 2026-05-27
> 출처: `source/data/skills/skill_data.gd`, `skill_types.gd`

---

## 유형 구분

| Type | Value | 분류 |
|------|-------|------|
| WEAPON | 0 | 무기 스킬 — 명중/데미지/회피 직접 영향 |
| SUPPORT | 1 | 보조 스킬 — 데미지% 증가, 속성 부스트 |
| MAGIC | 2 | 마법 스킬 — 마법 데미지, 마나 회복 |
| UTILITY | 3 | 유틸 스킬 — 탐지/제작/환경 |

---

## 🗡️ WEAPON — 무기 스킬 (7개)

| skill_id | 한글명 | 명중(GM) | 데미지(GM) | 회피 | 상승 스탯 |
|----------|--------|---------|-----------|------|----------|
| `swordsmanship` | 검술 | +50% | +30% | - | STR |
| `spear` | 창술 | +50% | +35% | - | STR |
| `fencing` | 펜싱 | +60% | +20% | +10% | DEX |
| `mace_fighting` | 둔기 | +40% | +40% | - | STR |
| `archery` | 궁술 | +50% | +30% | - | DEX |
| `wrestling` | 격투 | +30% | +10% | +20% | - |
| `throwing` | 투척술 | +45% | +25% | - | DEX |

---

## 🛡️ SUPPORT — 보조 스킬 (10개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `tactics` | 전술 | 물리 데미지 +50% (STR계수) |
| `anatomy` | 해부학 | 치명타 +20% (INT계수) |
| `healing` | 치료 | 회복량 증가 |
| `prayer` | 기도 | 신성 버프 데미지 +15%, 회피 +10% |
| `resisting_spells` | 마법저항 | 마법 회피 +30% |
| `parrying` | 패링 | 방패/무기 막기 확률 |
| `arms_lore` | 장비 지식 | 무기/방어구 이해도 |
| `focus` | 집중 | 마나 회복/집중력 |
| `bushido` | 무사도 | 양손무기 +30%, 회피 +15% (STR/WIS계수) |
| `ninjitsu` | 인술 | 암습 +20%, 회피 +25% (DEX계수) |

---

## 🔮 MAGIC — 마법 스킬 (7개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `magery` | 마법학 | 마법 데미지 (INT계수 0.2) |
| `meditation` | 명상 | 마나 회복 속도 |
| `eval_int` | 지능측정 | 마법 데미지 +40% (INT계수) |
| `divinity` | 신성학 | 신성 마법 +35% |
| `nature_magic` | 자연술 | 자연 마법 |
| `necromancy` | 사령술 | 흡혈/어둠 마법 +40% |
| `mysticism` | 주술 | 단체 공격 마법 +35% |

---

## 🔧 UTILITY — 유틸 스킬 (41개)

### 도적 계열 (7개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `hiding` | 은신 | 회피 +30% |
| `stealth` | 은신 이동 | 회피 +35% |
| `detecting_hidden` | 은신 탐색 | INT/WIS 기반 탐지 |
| `stealing` | 훔치기 | DEX 계열 |
| `snooping` | 훔쳐보기 | INT/DEX 계열 |
| `remove_trap` | 함정 제거 | 함정 해체 전문 |
| `poisoning` | 독 바르기 | 무기 독 코팅 |

### 음유 계열 (5개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `musicianship` | 악기연주 | CHA/WIS 계열 |
| `dancing` | 춤추기 | 회피 +25% (DEX/CHA계수) |
| `provocation` | 도발 | CHA계수 |
| `peacemaking` | 평온 | 회피 +15% (CHA계수) |
| `discordance` | 불협화음 | 대상 약화 +25% (CHA계수) |

### 야생 계열 (5개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `tracking` | 추적술 | DEX/WIS 계열 |
| `animal_taming` | 동물 조련 | WIS/CHA 계열 |
| `animal_lore` | 동물 지식 | INT/WIS 계열 |
| `herding` | 몰이 | WIS/CHA 계열 |
| `veterinary` | 수의학 | 동물 치료 (CON/WIS계수) |

### 연금술 계열 (6개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `alchemy` | 연금술 | 포션/폭탄 제조 |
| `herbalism` | 약초학 | 약초 채집/가공 |
| `poison_crafting` | 독포션 제조 | INT계수 |
| `herbal_remedy` | 회복포션 제조 | WIS/INT계수 |
| `enhancement_elixir` | 강화포션 제조 | INT/WIS계수 |
| `bomb_disposal` | 폭탄 제거/제조 | 폭탄 관련 전문 |

### 제작 계열 (7개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `blacksmithy` | 대장기술 | 금속 무기/갑옷 제작 |
| `bowcraft` | 활 제작 | 활/화살/석궁 제작 |
| `carpentry` | 목공술 | 목재 무기/가구 제작 |
| `tailoring` | 재봉술 | 가죽/천 갑옷 제작 |
| `cooking` | 요리 | 음식 버프 제작 |
| `mining` | 채광 | 광석 채취 |
| `lumberjacking` | 벌목 | 도끼 데미지 +25%, 목재 채취 |

### 조사/기타 (6개)

| skill_id | 한글명 | 효과 |
|----------|--------|------|
| `forensic_eval` | 법의학 | INT 계열 |
| `taste_id` | 맛보기 | 포션 식별 |
| `item_id` | 아이템 감정 | 아이템 성능 파악 |
| `spirit_speak` | 영매술 | 영혼과 대화 (WIS/INT계수) |
| `camping` | 야영 | 야외에서 체력/마나 회복 |
| `fishing` | 낚시 | DEX/WIS 계열 |
| `begging` | 구걸 | CHA 계열 |

---

## 💥 스킬 콤보 (4개)

| 콤보 ID | 요구 스킬 | 효과 | 확률 | 타입 |
|---------|----------|------|------|------|
| `stun_punch` | anatomy + wrestling | 4초 마비 | 15% | active |
| `disarm` | arms_lore + wrestling | 무기 낙하 | 10% | active |
| `emergency_heal` | anatomy + healing | 힐링량 50% 증가 | - | passive |
| `power_strike` | lumberjacking + swordsmanship | 도끼 25% 추가데미지 | - | passive |

---

## 🏫 스킬 티어 시스템

스킬 레벨은 10단위 버킷(bucket)으로 묶이며, 각 버킷마다 티어 명칭이 붙음:

| 레벨 | 버킷 | 티어 |
|------|------|------|
| 0.0 | 0 | 언트레인드(Untrained) |
| 1~9 | 0 | 언트레인드 |
| 10~19 | 1 | 초보(Novice) |
| 20~29 | 2 | 견습(Apprentice) |
| 30~39 | 3 | 숙련(Journeyman) |
| 40~49 | 4 | 전문(Expert) |
| 50~59 | 5 | 베테랑(Veteran) |
| 60~69 | 6 | 달인(Adept) |
| 70~79 | 7 | 마스터(Master) |
| 80~89 | 8 | 그랜드마스터(Grandmaster) |
| 90~99 | 9 | 전설(Legendary) |
| 100+ | 10+ | 초월(Transcendent) |

---

## 직업별 시작 스킬

| 직업 | 스킬 (시작 레벨) |
|------|-----------------|
| Fighter | swordsmanship(50), tactics(50), anatomy(30) |
| Mage | magery(50), eval_int(50), meditation(30), fencing(25) |
| Ranger | archery(50), tracking(40), herding(30), swordsmanship(25) |
| Rogue | fencing(50), hiding(40), anatomy(30) |
| Barbarian | mace_fighting(50), tactics(40), anatomy(30) |
| Paladin | mace_fighting(50), divinity(50), prayer(30) |
| Bard | musicianship(50), provocation(40), dancing(30), fencing(25) |
| Monk | wrestling(50), meditation(40), anatomy(30) |
| Cleric | divinity(50), healing(50), prayer(30), mace_fighting(25) |
| Druid | nature_magic(50), healing(50), animal_lore(30), mace_fighting(25) |
| Tamer | animal_taming(50), animal_lore(50), veterinary(30), spear(25) |
| Alchemist | alchemy(50), herbalism(50), anatomy(30), fencing(25) |
| Blacksmith | blacksmithy(50), mining(50), arms_lore(30), mace_fighting(25) |
| Samurai | bushido(50), swordsmanship(50), parrying(30) |
| Assassin (해금) | fencing(50), hiding(40), poisoning(30) |
| Knight (해금) | swordsmanship(50), parrying(50), tactics(30) |
| Warlock (해금) | magery(50), spirit_speak(40), eval_int(30) |
