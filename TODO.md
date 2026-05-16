# CRPG_PROJECT — 작업 현황

## 마지막 작업: 2026-05-16

완료된 작업과 앞으로 할 일을 정리한다.

---

## 🔧 오늘 수정 (2026-05-16)

### WASD 그리드 이동 수정
| 문제 | 원인 | 수정 |
|---|---|---|
| 방향키로 이동 시 격자 불일치 | GridWorld와 TerrainManager가 **다른 noise seed**로 지형 생성 → `blocked`와 `elevation` 불일치 | `grid_world.gd`에서 `_generate_elevation()` 제거 → TerrainManager가 단일 정보원 |
| WASD 이동 시 빈번한 차단 | corner blocking 체크: 대각선 이동 시 인접 2타일 모두 통과 가능해야 함 | `unit_movement.gd`에서 corner blocking 제거 → 목표 타일만 체크 |
| TileMapLayer 위치 어긋남 | `tile_offset_axis = HORIZONTAL`이 DIAMOND_DOWN 레이아웃과 충돌 | `tile_offset_axis` 설정 제거 |
| GDScript 타입 추론 에러 | `var h := dict[key]` 패턴 | 명시적 타입 선언 `var h: int = dict[key]` |

### 체크리스트 업데이트
- [x] 지형 데이터: GridWorld와 TerrainManager noise 충돌 주의
- [x] 이동: corner blocking은 직선 이동에서만 유효 (WASD는 대각선格子)
- [x] TileMapLayout: DIAMOND_DOWN + HORIZONTAL offset_axis 호환 안 됨
- [x] GDScript: `:=` 타입 추론은 리터럴/명시적 타입에서만 안전

---

---

## 🛠 개발 체크리스트 (문제 재발 방지)

### GDScript 문법
- [x] `var x := dict[key]` 타입 추론 금지 → `var x: int = dict[key]` (명시적 타입)
- [x] `for i: int in 3` 금지 → `for i in range(3)`
- [x] `String.split()` 결과 `:=` 추론 금지 → `var parts = key.split(",")`
- [ ] 외부 클래스 참조(`TerrainData` 등)는 `preload` 말고 `class_name` 의존

### z-index / 렌더링
- [x] `z_as_relative = false` 설정 시 자식 Polygon2D가 z_index 상속 못 받음 → 기본 true 유지
- [x] Polygon2D winding 순서: 시계방향(clockwise)이 카메라 정면
- [x] 새 유닛/오브젝트 추가 시 `z_index = 100` 필수 (지형 z=1..6 위로)
- [x] TileMapLayer position offset은 그리드 좌표계와 불일치 유발 → 제거
- [x] TileMapLayout: DIAMOND_DOWN + HORIZONTAL offset_axis 호환 안 됨 → 제거

### 입력 처리
- [x] `_input()`과 `_process()`에서 동일 키 중복 처리 금지 → 한쪽에서만
- [x] 턴모드 키보드 입력: `_input()` → `_handle_turn_input()` 전담
- [x] 실시간모드 키보드 입력: `_process()` 전담
- [x] 아이소메트릭 WASD = 화면 방향(그리드 대각선), Q/R/Z/V 제거

### 지형 데이터
- [x] `hm` Dictionary 순회 시 `_moss` 키(bool 값) 필터링 → **그리드 직접 순회로 변경**
- [x] 높이 0 = 물 = `set_blocked()` 처리 필요
- [x] GridWorld `_generate_elevation()` 제거 (TerrainManager 단일 정보원)
- [ ] 큐브 생성 시 이웃 높이로 경사면/직벽 결정 (현재 직벽)

---

## ✅ 완료된 기능

### 0. 코어 시스템
- 게임 루프 + FSM (realtime ↔ turnbased)
- 턴 매니저 (속도 → Agility 기반 initiative)
- Action Points 시스템
- ZOC (Zone of Control) — 진입 AP+1, 이탈 AoO
- CombatResolver — 명중/회피/치명타/빗맞힘/고도/후방공격
- 캐릭터 스탯 (str/agi/int/con) + initiative
- GameState.current_mode 버그 수정

### 4. 지형 시스템 (Isometric Terrain)
- **63×126 타일** 맵, FastNoiseLite 기반 높이맵
- **TileMapLayer** 6단 스택 (z_index로 깊이 정렬)
- 지형 타입: GRASS, DIRT, PATH, STONE, MOSS
- 절차적 타일셋 (8열 × 2행 아틀라스, 다이아몬드 텍스처)
- 절벽면 자동 렌더링 (y+1 높이 차이 감지)
- 십자형 길 (수동 레이아웃)
- **Polygon2D 큐브** (h≥2): 4각형 벽면 + 다이아몬드 윗면
- **충돌**: h=0(물) 및 h≥2(산) → `set_blocked()`
- **단일 정보원**: TerrainManager만 지형 생성, GridWorld는 elevation 읽기 전용

### 2. 유적지 (Ruins)
- **5×5 Hollow Cube** at (50,20)
- 벽 높이 1~3 랜덤 (무너진 효과)
- Stone Top / Stone Side L+R (3톤 그림자)
- 이끼 (8% 녹색 픽셀 혼합)
- 입구 + 내부 바닥 + 그림자 데칼

### 3. 캐릭터 3D 박스
- 3-Polygon2D 육면체 (top + left side + right side)
- 지형 타일과 동일한 3단 스택 방식
- flip_h → 좌우 옆면 색상 반전
- 이동 시 Bobbing 효과

### 4. 실시간 이동
- **WASD**: 화면 방향 → 格子 대각선 (W=(-1,-1), S=(1,1), A=(-1,1), D=(1,-1))
- **충돌 체크**: 목표 타일만 `is_walkable()` (corner blocking 제거)
- 마우스 클릭 경로 이동 (A*) 병행
- Shadow Sprite + idle bob
- 턴모드: `_input()` 전담, 실시간모드: `_process()` 전담

### 5. 전투 시스템
- Hit/Miss/Crit/Graze (CombatResolver)
- 고도 우세/열세 ±10%
- 후방 공격 +15% 명중, ×1.5 데미지
- Push 액션 버튼 (AP 2)
- ZOC + Attack of Opportunity
- 적 AI (근접 + 원거리)

### 6. 전투 UI
- Action Bar: [Attack] [Push] [Item] [Wait]
- 타겟팅 (Tab 순환 + 우클릭 해제)
- HP bar / AP / 턴 표시 / 데미지 플로팅
- 이벤트 로그 (한국어)

### 7. 인풋 시스템
- **WASD 전용**: 화면 방향 이동 (Q/R/Z/V 대각선 제거)
- 전투 마우스 클릭 (이동 + 공격)
- GameState.current_mode 연동

### 8. VS Code / Godot 통합
- Godot Tools 확장, 디버그 설정
- 7개 headless 테스트 스위트

---

## 🔜 다음 할 일

### 높은 우선순위
- [x] **WASD 그리드 이동 수정** — 지형 데이터 불일치 + corner blocking 제거 (2026-05-16)
- [ ] **플레이어 시작 위치 조정** — 길 교차점 (30,61)
- [ ] **산 경사면 시각화** — 사선 절단 + 평면 붙이기 (보류)

### 전투 심화
- [ ] 스킬/마법 시스템 (근접 외 다양한 액션)
- [ ] 상태 이상 (독, 스턴, 버프/디버프)
- [ ] 원거리/사거리 시스템 개선

### AI / 콘텐츠
- [ ] 실시간 패트롤 AI
- [ ] 전리품 / 경험치 / 레벨업
- [ ] 추가 유적지 및 맵 구조물

### UI
- [ ] 이동 가능 범위 하이라이트 (턴제)
- [ ] 명중률 프리뷰
- [ ] SpriteSheet 교체 (Blender AI)

---

## 🧪 테스트 스위트 (7/7 통과)
모든 테스트는 headless Godot 4.6.2로 실행:

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
├── Terrain (Node2D)                    # 지형 렌더러
│   ├── H0~H5 (TileMapLayer ×6)        # 높이 스택
├── GameLoop
│   ├── GridWorld (63×126 isometric)
│   ├── ModeStateMachine → realtime/turnbased
│   ├── TurnManager (initiative 정렬)
│   └── ...
├── RealTimeManager
└── HUD (CanvasLayer)
    ├── ActionBar / Targeting
    ├── TurnOrderPanel / EventLog
    └── InventoryPanel / EquipmentPanel

Autoloads: EventBus, GameState

New systems:
├── source/features/turnbased/combat_resolver.gd
├── source/features/turnbased/zoc_controller.gd
└── source/features/shared/effects/terrain_manager.gd
```

## 🛠 빌드/실행
- **Run**: `F5` (VS Code) 또는 Godot 에디터로 `source/main.tscn` 실행
- **Headless 테스트**: 각 `.tscn`을 Godot `--headless` 플래그로 실행
- **모든 테스트**: VS Code `Run All Headless Tests` 태스크
  - Item → 인벤토리 토글
  - Wait → AP 클리어 + 턴 종료
- **파일**: `source/ui/hud/targeting.gd` — Tab 순환 + 적 하이라이트 + HP 표시
  - Tab: 다음 적, Shift+Tab: 이전 적
  - 빨강 반투명 타일 하이라이트
  - 타겟 이름/HP 정보 레이블
  - 전투 시작 시 자동 첫 타겟, 사망 시 자동 전환

### 4. 기존 시스템 (이전 세션)
- 게임 루프 + FSM (realtime ↔ turnbased)
- 턴 매니저 (속도 기반 턴 순서, 라운드)
- Action Points 시스템
- 유닛/이동/인벤토리/장비
- 적 AI (근접 + 원거리)
- HUD (HP/AP/모드/골드/턴표시/데미지/이벤트로그)
- defeat_panel
- VS Code 통합 (Godot Tools, 디버그 설정)
- 7개 headless 테스트 스위트

---

## 🔜 다음 할 일 (우선순위 순)

### 1. 전투 시스템 심화
- [ ] **스킬/마법 시스템** — 근접 공격 외 다양한 액션 (돌진, 방어, 힐 등)
- [ ] **원거리/사거리 시스템** — 활, 마법 등 거리 기반 전투 (기본 골격 있음)
- [ ] **범위 공격 (AOE)** — 광역 스킬
- [ ] **상태 이상** — 독, 스턴, 버프/디버프

### 2. 적 AI 개선
- [ ] **실시간 패트롤** — 탐험 모드에서 적 순찰 행동
- [ ] **전술 AI** — ZOC 인식 회피, 포위, 후퇴

### 3. 전투 보상
- [ ] **전리품 시스템** — 적 처치 후 드롭
- [ ] **경험치/레벨업**

### 4. 캐릭터 시스템
- [ ] **스탯** — 힘/민첩/지능 등 RPG 스탯
- [ ] **클래스/종족** — 캐릭터 빌드
- [ ] **레벨업** — 경험치 → 레벨 → 스탯 성장

### 5. UI/UX 개선
- [ ] **Hit chance 표시** — 공격 전 명중률 프리뷰
- [ ] **이동 가능 범위 하이라이트**
- [ ] **데미지 텍스트 개선** (Crit/Miss/Graze 색상 구분)

---

## 🧪 테스트 스위트 (7/7 통과)
모든 테스트는 headless Godot 4.6.2로 실행:

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

## 🏗 프로젝트 구조 (요약)

```
main.tscn
├── GameLoop (game_loop.gd)
│   ├── GridWorld (grid_world.gd)
│   ├── ModeStateMachine → realtime / turnbased (State)
│   ├── TurnManager (turn_manager.gd)
│   ├── ActionPoints (action_points.gd)
│   └── Timeline (timeline_manager.gd)
├── RealTimeManager (realtime_manager.gd)
└── HUD (CanvasLayer)
    ├── ActionBar (action_bar.gd)          ← NEW
    ├── Targeting (targeting.gd)           ← NEW
    ├── TurnOrderPanel (turn_order_panel.gd)
    ├── InventoryPanel / EquipmentPanel
    └── EventLog / CombatAnnounce

Autoloads: EventBus, GameState

New systems:
├── source/features/turnbased/zoc_controller.gd        ← NEW
├── source/features/turnbased/combat_resolver.gd        ← NEW
```

---

## 🛠 빌드/실행
- **Run**: `F5` (VS Code) 또는 Godot 에디터로 `main.tscn` 실행
- **Headless 테스트**: 각 `.tscn`을 Godot `--headless` 플래그로 실행
- **모든 테스트 한 번에**: VS Code `Run All Headless Tests` 태스크
