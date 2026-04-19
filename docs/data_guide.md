# 데이터 가이드 (Data Guide)

**최종 업데이트:** 2026-04-18
**용도:** JSON 데이터 파일 설명 및 사용 방법

---

## JSON 파일 목록

### 1. character_creation 관련

#### data/races.json (종족 데이터)
- **용도:** D&D 5e SRD 기반 종족 10종
- **종족:** 인간, 엘프, 드워프, 하플링, 오크, 트롤, 하프오크, 하프트롤, 노움, 다크엘프
- **필드:** name, name_en, ability_score_increases, traits, languages, darkvision, select_bloodline, bloodline_options

#### data/backgrounds.json (배경/혈통)
- **용도:** 종족별 혈통 선택
- **혈통:** 아이언블러드, 에테르 가디언, 솔라 워커, 미스트 세일러 (인간용)
- **필드:** name, ability_scores, starting_location

#### data/classes.json (직업)
- **용도:** 캐릭터職業 선택
- **직업:** 전사, 도적, 마법사, 사제, 레인저, 야만전사, 성기사, 음유시인

---

### 2. monster 관련

#### data/monsters.json (기본 몬스터)
- **용도:** 일반 몬스터 데이터
- **카테고리:** Beast, Humanoid, Undead
- **필드:** name, cr, hp, ac, attack, xp, abilities, actions, traits, drops

#### data/monsters_session.json (세션 몬스터)
- **용도:** 세션 변수(fog/orc/grid)에 따라 생성되는 특수 몬스터
- **예시:** fog_beast, noise_creature, demon_hunter, void_construct, abyssal_spawn

#### data/monsters_additional.json (추가 몬스터)
- **용도:** 특정 지역/시나리오 전용 몬스터
- **예시:** nova_ruins (노바 부유 도시), demon_army (마왕군)

---

### 3. resource/economy 관련

#### data/resources.json (자원 유형)
- **용도:** 경제 시스템의 자원 유형
- **자원:** food, mineral, magic_crystal, trade_goods, gold

#### data/settlements.json (정착지)
- **용도:** 게임 세계의 주요 도시/요새
- **정착지:** 실버하벤, 벤투라, 아이언클래드, 에버포지, 호리에테리아, 스노우펠, 미스트발, 다크포트
- **필드:** name, description, resource_output, resource_demand, trade_routes

#### data/political_factions.json (정치 세력)
- **용도:** 게임 세계의 정치 세력
- **세력:** 8개 세력 (왕국, 길드, 종교 등)
- **필드:** name, personality_template, environment_response

---

### 4. item/equipment 관련

#### data/items.json (아이템)
- **용도:** 무기, 방어구, 소모품, 마법 물건
- **카테고리:** weapon, armor, consumable, material
- **희귀도:** COMMON, UNCOMMON, RARE, EPIC, LEGENDARY

#### data/terrain.json (지형)
- **용도:** 맵 타일 타입 정의
- **타일:** floor, wall, door, water, cover, stairs

---

## 사용 코드 예시

### 캐릭터 생성에서 데이터 사용
```gdscript
# GameManager (Autoload)에서种族/배경 로드
var races = GameManager.get_races()
var backgrounds = GameManager.get_backgrounds()

# 종족 선택 시 능력치 보정 적용
var increases = races_data[race_id]["ability_score_increases"]
for stat in increases.keys():
    stats[stat] = 10 + increases[stat]
```

### 몬스터 스폰에서 데이터 사용
```gdscript
# MonsterSpawner (Autoload)에서 몬스터 로드
var spawn_list = MonsterSpawner.get_spawn_list(layer_idx, count)

# 세션 변수에 따른 몬스터 생성
if WorldSimulation.fog_density > 0.7:
    spawn_list.append("fog_beast")
```

### 전리품 생성에서 데이터 사용
```gdscript
# LootSystem (Autoload)에서 아이템 드롭
var loot = LootSystem.calculate_drop(monster_id, cr)
```

---

## 데이터 확장 가이드

### 새 종족 추가
```json
{
  "new_race": {
    "name": "새종족",
    "name_en": "New Race",
    "ability_score_increases": {
      "STR": 2,
      "DEX": 0,
      "CON": 1,
      "INT": 0,
      "WIS": 0,
      "CHA": 0
    },
    "select_bloodline": false,
    "size": "medium"
  }
}
```

### 새 몬스터 추가
```json
{
  "new_monster": {
    "name": "새몬스터",
    "cr": "0.5",
    "hp": 20,
    "ac": 14,
    "attack": "1d8+3",
    "xp": 100
  }
}
```