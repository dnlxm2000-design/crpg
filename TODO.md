# CRPG_PROJECT — v0.1.0

Godot 4 하이브리드 실시간+턴제 CRPG 템플릿.
Knowledge-graph-driven development with [graphify](https://github.com/OhMyOpenCode/graphify).

---

## ✅ 완료된 기능 (v0.1.0)

### 코어 시스템
- [x] 게임 루프 + FSM (realtime ↔ turnbased 모드 전환)
- [x] 턴 매니저 (속도 기반 initiative, 라운드 관리)
- [x] Action Points (AP) 시스템
- [x] ZOC (Zone of Control) — 진입 AP+1, 이탈 AoO
- [x] CombatResolver — 명중/회피/치명타/빗맞힘/고도/후방공격
- [x] 캐릭터 스탯 (str/agi/int/con) + initiative
- [x] GameState.current_mode 연동

### 지형 시스템 (Isometric Terrain)
- [x] 63×126 타일 맵, FastNoiseLite 기반 높이맵
- [x] TileMapLayer 6단 스택 (z_index 깊이 정렬)
- [x] 지형 타입: GRASS, DIRT, PATH, STONE, MOSS, WATER
- [x] 절차적 타일셋 (8열 × 2행 아틀라스, 다이아몬드 텍스처)
- [x] 절벽면 자동 렌더링 (y+1 높이 차이 감지)
- [x] Polygon2D 큐브 (h≥2): 4각형 벽면 + 다이아몬드 윗면
- [x] 충돌: h=0(물) 및 h≥2(산) → `set_blocked()`
- [x] 단일 정보원: TerrainManager만 지형 생성, GridWorld는 읽기 전용

### 이동 시스템
- [x] **실시간**: 마우스 클릭 → A* 경로 탐색 → 연속 이동
- [x] **턴제**: 방향키로 한 타일씩 이동, AP 소모
- [x] WASD (화면 방향 → 그리드 대각선 매핑)
- [x] 충돌 체크: 목표 타일 `is_walkable()`
- [x] Shadow Sprite + idle bobbing

### 전투 시스템
- [x] Hit/Miss/Crit/Graze 판정
- [x] 고도 우세/열세 ±10% 명중률
- [x] 후방 공격 +15% 명중, ×1.5 데미지
- [x] Push 액션 (AP 2)
- [x] 적 AI (근접 + 원거리)
- [x] 전투 진입/종료 전환

### UI 시스템
- [x] HUD CanvasLayer (HP 바, AP 라벨, 모드 라벨, 턴 표시기)
- [x] Action Bar: [Attack] [Push] [Item] [Wait]
- [x] 타겟팅 (Tab 순환 + 우클릭 해제)
- [x] 이벤트 로그 (한국어)
- [x] 데미지 플로팅 넘버
- [x] 이동 범위 오버레이 (초록=이동가능, 빨강=불가, 주황=ZOC)
- [x] 미니맵 (독립 CanvasLayer, 우상단 배치, 좌표 표시)
- [x] 인벤토리/장비 패널 토글

### 인벤토리
- [x] 아이템 픽업 (E키 / 마우스 클릭)
- [x] 골드 수집
- [x] 시체 수색 (loot)

### 테스트
- [x] 7개 headless 테스트 스위트 (전부 통과)

---

## 🔜 다음 할 일

### 높은 우선순위
- [x] ~~플레이어 시작 위치 조정 — 길 교차점 (30,61)~~
- [ ] 산 경사면 시각화 — 사선 절단 + 평면 붙이기 (보류)
- [x] ~~전투 중 마우스 이동 안정화~~
- [ ] 6속성 기반 파생 스탯 계산식 반영 (STR→공격력, DEX→회피/선제권, CON→HP, INT→마법데미지, WIS→저항, CHA→가격)

### 전투 심화
- [ ] 스킬/마법 시스템 (근접 외 다양한 액션)
- [ ] 상태 이상 (독, 스턴, 버프/디버프)
- [ ] 원거리/사거리 시스템 개선

### AI / 콘텐츠
- [ ] 실시간 패트롤 AI
- [ ] 전리품 / 경험치 / 레벨업
- [ ] 추가 유적지 및 맵 구조물 (5×5 Hollow Cube)

### UI
- [ ] 명중률 프리뷰
- [ ] SpriteSheet 교체 (Blender AI)

---

## 🧪 테스트 스위트 (7/7 통과)

| 테스트 | 파일 | 통과 |
|---|---|---|
| CombatResolver | `test_combat_resolver.tscn` | 31/31 |
| ZOC | `test_zoc.tscn` | 9/9 |
| 모드 전환 | `test_combat_transition.tscn` | 9/9 |
| 승리/패배 | `test_combat_end.tscn` | 4/4 |
| 전투 인벤토리 | `test_combat_inventory.tscn` | 6/6 |
| 적 AI | `test_enemy_ai.tscn` | 7/7 |
| 장비 | `test_equipment.tscn` | 9/9 |

---

## 🏗 프로젝트 구조

```
main.tscn (Main: Node2D)
├── Terrain (Node2D)                    # 지형 렌더러 (z=0~6)
│   └── H0~H5 (TileMapLayer ×6)        # 높이 스택
├── GameLoop
│   ├── GridWorld (63×126 isometric)
│   ├── ModeStateMachine → realtime/turnbased
│   ├── TurnManager (initiative 정렬)
│   ├── ActionPoints
│   └── Timeline
├── RealTimeManager
├── MovementRangeOverlay (z=-5)         # 전투 그리드 오버레이
├── PathPreview (z=11)                  # 실시간 경로 미리보기
├── Minimap (CanvasLayer, layer=100)    # 독립 미니맵
└── HUD (CanvasLayer, layer=1)
    ├── ActionBar / Targeting
    ├── TurnOrderPanel / EventLog
    ├── InventoryPanel / EquipmentPanel
    └── TargetInfo

Autoloads: EventBus, GameState
```

---

## 📝 개발 체크리스트

### GDScript 문법
- [x] `var x := dict[key]` 타입 추론 금지 → `var x: int = dict[key]`
- [x] `for i: int in 3` 금지 → `for i in range(3)`
- [x] `String.split()` 결과 `:=` 추론 금지 → `var parts = key.split(",")`

### z-index / 렌더링
- [x] `z_as_relative = false` 설정 시 자식 Polygon2D가 z_index 상속 못 받음 → 기본 true 유지
- [x] Polygon2D winding 순서: 시계방향(clockwise)이 카메라 정면
- [x] 유닛은 y_sort에 위임 (z_index 직접 설정 금지)
- [x] 그리드 오버레이는 유닛 아래 (z=-5)
- [x] TileMapLayer position offset은 그리드 좌표계와 불일치 유발 → 제거

### 입력 처리
- [x] `_input()`과 `_process()`에서 동일 키 중복 처리 금지
- [x] 턴모드 키보드 입력: `_input()` → `_handle_turn_input()` 전담
- [x] 실시간모드 키보드 입력: `_process()` 전담
- [x] 아이소메트릭 WASD = 화면 방향(그리드 대각선)

### 지형 데이터
- [x] GridWorld `_generate_elevation()` 제거 (TerrainManager 단일 정보원)
- [x] 높이 0 = 물 = `set_blocked()` 처리
