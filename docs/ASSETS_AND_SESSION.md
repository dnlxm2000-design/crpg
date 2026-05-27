# CRPG_PROJECT — 자산 현황 & 세션 기록

> 최종 갱신: 2026-05-27

---

## 1. 이 세션 커밋 로그

```

a9ad605 — fix: update_facing_direction 3D 모델 회전 추가
c4dc921 — feat: GLB 애니메이션 — Idle/Walk 자동 전환
9e8f5a2 — fix: 카메라 오빗 (Input.is_mouse_button_pressed)
e419d4c — feat: 우클릭 오빗 카메라 — 360도 회전 + 줌
4429a07 — fix: GLB → GLTFDocument 런타임 로딩
6d260fb — feat: KayKit 캐릭터 모델 (플레이어 전용)
3d06a6d — fix: watermill 위치 + 강 폭 축소
04165c9 — fix: 연못/타워B/물레방앗간 위치 조정
3899edd — fix: 강 경로 마을 우회
0818e50 — fix: 숲/나무/건물 강 중앙 침범 방지
e5d88ad — refactor: Curve3D 강 경로 + 가변 폭
dabf85d — fix: map_decorator type inference
722808b — feat: 호수+강+숲 — 야생의 숨결
ce21483 — fix: building model paths + alchemy RECIPES
a6d6174 — chore: Godot 4 .uid files
d53ab32 — KayKit Medieval Hexagon Pack + MapDecorator
```

---

## 2. KayKit 자산 인벤토리

### 2.1 캐릭터 모델 (Adventurers Pack)

| 파일 | 크기 | 게임 내 용도 | 상태 |
|------|------|-------------|------|
| `Barbarian.glb` | 3.4MB | `fighter` 클래스 플레이어 | ✅ 사용 중 |
| `Knight.glb` | 3.5MB | `paladin` 클래스 플레이어 | ✅ 사용 중 |
| `Mage.glb` | 3.4MB | `mage` 클래스 플레이어 | ✅ 사용 중 |
| `Rogue.glb` | 3.4MB | `rogue` 클래스 플레이어 | ✅ 사용 중 |
| `Rogue_Hooded.glb` | 3.4MB | (미매핑 — 확장용) | ⏸️ 대기 |

모델당 애니메이션 70개 포함 — Idle, Walking_A~C, Running_A~B, 전투모션(1H/2H/활/마법), 회피, 피격, 죽음, 점프, 상호작용 등.

#### 직업별 모델 매핑 (`realtime_manager.gd`)

| class_id | GLB | 특징 |
|----------|-----|------|
| `fighter` | Barbarian | 양손도끼 + 원형방패 + 모자 + 망토 |
| `paladin` | Knight | 장검 + 배지방패 + 갑옷 |
| `mage` | Mage | 로브 + 스태프 + 마법서 |
| `rogue` | Rogue | 단검 + 후드 |

### 2.2 무기/소품 (Adventurers Pack)

```
도검류: sword_1handed, sword_2handed, dagger
도끼류: axe_1handed, axe_2handed
원거리: bow, crossbow_1handed, crossbow_2handed, arrow, quiver
방패류: shield_badge, shield_round, shield_spikes, shield_square
마법: staff, wand, spellbook_closed, spellbook_open
기타: mug, smokebomb
```

→ 현재 게임 내 미사용. 향후 무기 장착 시스템에서 `handslot_l/r` BoneAttachment에 부착 가능.

### 2.3 건물 (Medieval Hexagon Pack)

현재 맵에 배치된 14개:

| 건물 | 개수 |
|------|------|
| Townhall | 1 |
| Tavern | 1 |
| Church | 1 |
| Blacksmith | 1 |
| Tower A | 1 |
| Tower B | 1 |
| Watchtower | 1 |
| Wall Straight | 2 |
| Wall Gate | 1 |
| Watermill | 1 |
| Well | 1 |
| Home A | 1 |
| Home B | 1 |

2가지 색상 변형(blue/green) 존재. 18개 건물 유형 × 2~3색상 = 총 40개 이상의 건물 GLTF 보유.

### 2.4 지형 장식 (Medieval Hexagon Pack)

```
언덕: hill_single_A~C, hills_A~C (±trees variants)
산: mountain_A~C (±grass, ±trees variants)
바위: rock_single_A~E
나무: tree_single_A~B, trees_A~B (large/medium/small/cut)
수생: waterlily_A~B, waterplant_A~C
소품: barrel, crate, sack, tent, flag, fence, ladder, wheelbarrow, target 등
```

→ `map_decorator.gd`에서 숲 생성 및 장식 산포에 사용 중.

### 2.5 텍스처

| 파일 | 용도 |
|------|------|
| `hexagons_medieval.png` | 지형 타일 텍스처 (옥타크린 16방향) |
| `barbarian_texture.png` | Barbarian 캐릭터 |
| `knight_texture.png` | Knight 캐릭터 |
| `mage_texture.png` | Mage 캐릭터 |
| `rogue_texture.png` | Rogue 캐릭터 |

---

## 3. 게임플레이 시스템 현황

### 조작

| 동작 | 입력 | 구현 파일 |
|------|------|----------|
| 이동 (실시간) | 마우스 좌클릭 | `player_controller.gd` |
| 이동 (WASD) | W/A/S/D | `player_controller.gd` |
| 카메라 회전 | 우클릭 드래그 | `camera_follow.gd` |
| 카메라 줌 | 마우스 휠 | `camera_follow.gd` |
| 인벤토리 | I 키 | `inventory_panel.gd` |
| 장비/스탯 | E 키 | `equipment_panel.gd` |
| 액션바 (턴제) | 1~4 키 | `action_bar.gd` |

### 이동 시스템

- 실시간: A* 경로 탐색 → `move_and_slide` 방식 연속 이동
- 턴제: 방향키 → 한 타일씩 이동 (AP 소모)
- ZOC: 진입 AP+1, 이탈 Attack of Opportunity
- Bobbing: 이동 중 Y축 미세 상하 운동
- 애니메이션: 이동 시 Walking_A (loop), 정지 시 Idle (loop)
- 방향 전환: 이동 방향으로 CharacterModel + DirectionIndicator 회전

### 전투 시스템

- 실시간 ↔ 턴제 전환 (GameLoop FSM)
- 명중/회피/치명타/빗맞힘 판정
- 고도/후방/엄폐 보정
- ATB 타임라인 (속도 기반)
- 스킬/AP 시스템

### 월드

- 그리드 기반 A* (63×126 타일)
- 지형: PLAINS / FOREST / MOUNTAIN / WATER / MARSH
- 호수, 강(Curve3D 가변폭 2~4타일), 숲 절차적 생성
- 카메라: 오소그래픽, 플레이어 추적, 우클릭 360° 오빗

---

## 4. 라이선스

### KayKit Adventurers Character Pack v1.0
### KayKit Medieval Hexagon Pack v1.0

- **라이선스**: [CC0 (Creative Commons Zero)](http://creativecommons.org/publicdomain/zero/1.0/)
- **제작자**: Kay Lousberg ([www.kaylousberg.com](https://www.kaylousberg.com))
- **개인 프로젝트**: ✅ 무료
- **상업 프로젝트**: ✅ 무료 (로열티 없음)
- **수정/리믹스**: ✅ 무료
- **크레딧**: 선택사항 (의무 아님, `Kay Lousberg, www.kaylousberg.com` 권장)

→ 게임을 스팀/스토어에 출시해도 추가 비용이나 라이선스 표시 의무 없음.

---

## 5. 프로젝트 전체 구조

```
source/
│
├── main.tscn                      ─── 루트 씬
├── main.gd                        ─── 진입점 (플레이어 생성, HUD, 맵)
│
├── autoload/                      ─── 전역 싱글톤
│   ├── event_bus.gd               ─── 신호 버스
│   ├── game_state.gd              ─── 게임 모드/설정 상태
│   └── localization.gd            ─── 다국어 UI
│
├── core/                          ─── FSM + 게임 루프
│   ├── game_loop.gd               ─── 모드 오케스트레이터
│   ├── mode_state_machine.gd
│   ├── state_machine/
│   │   ├── state.gd               ─── State 베이스
│   │   └── state_machine.gd       ─── 제네릭 FSM
│   └── states/
│       ├── realtime_state.gd
│       └── turnbased_state.gd
│
├── data/                          ─── 데이터 정의
│   ├── classes/ (class_data.gd, class_definition.gd)
│   ├── crafting/ (alchemy_data.gd)
│   ├── enemies/ (enemy_data.gd)
│   ├── items/ (item.gd, item_data.gd, item_types.gd + resources/*.tres)
│   ├── skills/ (skill_data.gd, skill_types.gd)
│   ├── status_effects/ (status_effect_data.gd)
│   ├── terrain_data.gd
│   ├── terrain_data.tres
│   └── terrain_type_definition.gd
│
├── features/                      ─── 핵심 게임플레이
│   ├── realtime/
│   │   ├── realtime_manager.gd    ─── 실시간 모드 관리자
│   │   └── map_item.gd
│   ├── shared/
│   │   ├── unit.gd                ─── 유닛 베이스 (CharacterBody3D)
│   │   ├── unit_movement.gd       ─── 이동 컴포넌트
│   │   ├── player_controller.gd   ─── 입력 처리
│   │   ├── grid_world.gd          ─── A* 그리드
│   │   ├── enemy_ai.gd            ─── 적 AI
│   │   ├── corpse.gd              ─── 시체
│   │   ├── effects/
│   │   │   ├── camera_follow.gd   ─── 3인칭 오빗 카메라
│   │   │   ├── map_decorator.gd   ─── 건물/숲/강/호수 배치
│   │   │   ├── Terrain.gd         ─── 지형 생성
│   │   │   ├── terrain.gdshader
│   │   │   ├── water.gdshader
│   │   │   ├── path_preview.gd
│   │   │   ├── projectile.gd
│   │   │   └── movement_range_overlay.gd
│   │   └── inventory/ (inventory.gd)
│   └── turnbased/
│       ├── turn_manager.gd        ─── 턴 큐
│       ├── action_points.gd       ─── AP 시스템
│       ├── combat_resolver.gd     ─── 전투 판정
│       ├── zoc_controller.gd      ─── ZOC + AoO
│       └── timeline/ (timeline_manager.gd)
│
├── ui/                            ─── HUD / 오버레이
│   ├── hud/ (hud.gd, inventory_panel.gd, equipment_panel.gd,
│   │         action_bar.gd, targeting.gd, event_log.gd,
│   │         turn_order_panel.gd, minimap_panel.gd)
│   └── screens/ (defeat_panel.gd)
│
└── utils/ (helpers.gd)
```

### main.tscn 런타임 노드 트리

```
Main (Node3D) — main.gd
├── Terrain (MeshInstance3D)
├── GridWorld (Node)
├── GameLoop (Node) — game_loop.gd
│   ├── ModeStateMachine (Node)
│   ├── TurnManager (Node)
│   ├── ActionPoints (Node)
│   └── Timeline (Node)
├── MapDecorator (Node)
├── RealTimeManager (Node)
├── RealtimeState (Node)
├── TurnbasedState (Node)
├── HUD (CanvasLayer) — hud.gd
├── MinimapPanel (CanvasLayer)
├── PlayerUnit (CharacterBody3D/Unit)       ← 동적 생성
│   ├── CollisionShape3D
│   ├── UnitMovement (unit_movement.gd)
│   ├── Inventory (inventory.gd)
│   ├── ShadowMesh
│   ├── DirectionIndicator
│   └── CharacterModel (Node3D)              ← GLB 로드
│       ├── Rig/ → Skeleton3D + MeshInstances
│       └── AnimationPlayer                  ← Idle / Walk 전환
├── Camera3D (Orthogonal) — camera_follow.gd ← 동적 생성
├── PathPreview (Node)
└── MapItems (Node)
```
