# CRPG_PROJECT v0.1.0

**Godot 4 CRPG** — 실시간 탐험과 턴제 전투를 오가는 듀얼 모드 게임 템플릿.
Knowledge-graph-driven development with [graphify](https://github.com/OhMyOpenCode/graphify).

## Architecture

### Dual-Mode Design

```
                 ┌─ RealtimeState ── RealTimeManager ── 실시간 탐험
GameLoop ── FSM ─┤
                 └─ TurnbasedState ─ TurnManager ── 턴제 전투
                                         ├─ ActionPoints (AP 시스템)
                                         └─ TimelineManager (ATB 타임라인)
```

- **실시간 모드** — 필드 탐험, 자유 이동, 실시간 상호작용
- **턴제 모드** — 전투 진입 시 전환, 속도 기반 행동 순서
- GameLoop가 `enter_realtime()` / `enter_turn_mode()`로 모드 전환 오케스트레이션

### Movement System (Stoneshard-Inspired)

```
PlayerController ── input ──→ UnitMovement ── path ──→ GridWorld (A*)
    │                            │                        │
    ├─ Mouse click (realtime)    ├─ navigate_to()         ├─ AStar2D graph
    ├─ WASD (both modes)         ├─ move_one_tile() [AP]  ├─ world_to_grid()
    └─ Space (turn-based skip)   └─ skip_turn()           └─ find_path_grid()
```

**듀얼 모드 이동:**
- **실시간** — 마우스 클릭으로 목적지 지정 → A* 경로 탐색 → 연속 이동
- **턴제** — 방향키로 한 타일씩 이동, AP 소모
- **WASD** — 화면 방향 → 그리드 대각선 매핑 (W=(-1,-1), S=(1,1), A=(-1,1), D=(1,-1))

### Core Components

| Component | File | Role |
|-----------|------|------|
| **StateMachine** | `source/core/state_machine/state_machine.gd` | Generic FSM |
| **GameLoop** | `source/core/game_loop.gd` | 모드 전환 오케스트레이터 |
| **EventBus** | `source/autoload/event_bus.gd` | **Autoload** — 전역 신호 |
| **GameState** | `source/autoload/game_state.gd` | **Autoload** — 모드/설정 상태 |
| **Localization** | `source/autoload/localization.gd` | **Autoload** — 다국어 UI |

### Turn System

| Component | File | Role |
|-----------|------|------|
| **TurnManager** | `source/features/turnbased/turn_manager.gd` | 속도 기반 initiative 큐 |
| **ActionPoints** | `source/features/turnbased/action_points.gd` | AP 관리 — `max_ap`, `spend()`, `can_afford()` |
| **TimelineManager** | `source/features/turnbased/timeline/timeline_manager.gd` | ATB 스타일 타임라인 |

### Shared Components

| Component | File | Role |
|-----------|------|------|
| **Unit** | `source/features/shared/unit.gd` | 유닛 베이스 — HP/AP/속도/공격/방어 |
| **GridWorld** | `source/features/shared/grid_world.gd` | A* 타일 그리드 — `world_to_grid()`, `find_path_grid()` |
| **UnitMovement** | `source/features/shared/unit_movement.gd` | 듀얼 모드 이동 — `navigate_to()`, `move_one_tile()` |
| **PlayerController** | `source/features/shared/player_controller.gd` | 입력 처리 — 마우스, WASD, Space |
| **CombatResolver** | `source/features/turnbased/combat_resolver.gd` | 명중/회피/치명타/빗맞힘 판정 |
| **ZocController** | `source/features/turnbased/zoc_controller.gd` | Zone of Control — 진입 AP+1, 이탈 AoO |

### Grid Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `GridWorld.TILE_WIDTH_ISO` | `64` | 아이소메트릭 타일 너비 |
| `GridWorld.TILE_HEIGHT_ISO` | `32` | 아이소메트릭 타일 높이 |
| `GridWorld.grid_width` | `63` | 그리드 가로 타일 수 |
| `GridWorld.grid_height` | `126` | 그리드 세로 타일 수 |

## Project Structure

```
CRPG_PROJECT/
├── project.godot              # Godot 4 프로젝트 설정
├── AGENTS.md                  # AI 에이전트 가이드
├── README.md                  # 이 파일
├── TODO.md                    # 작업 현황
├── assets/                    # 에셋 (이미지, 오디오)
├── data/                      # 게임 데이터 (아이템 등)
├── source/
│   ├── main.gd                # 진입점
│   ├── main.tscn              # 메인 씬
│   ├── autoload/
│   │   ├── event_bus.gd       # 전역 이벤트 버스
│   │   ├── game_state.gd      # 전역 게임 상태
│   │   └── localization.gd    # 다국어 UI
│   ├── core/
│   │   ├── game_loop.gd       # 모드 오케스트레이터
│   │   ├── mode_state_machine.gd
│   │   ├── state_machine/
│   │   └── states/
│   ├── features/
│   │   ├── realtime/
│   │   ├── shared/
│   │   │   ├── unit.gd
│   │   │   ├── grid_world.gd
│   │   │   ├── unit_movement.gd
│   │   │   ├── player_controller.gd
│   │   │   └── effects/
│   │   │       ├── terrain_manager.gd
│   │   │       ├── movement_range_overlay.gd
│   │   │       └── path_preview.gd
│   │   └── turnbased/
│   │       ├── action_points.gd
│   │       ├── turn_manager.gd
│   │       ├── combat_resolver.gd
│   │       ├── zoc_controller.gd
│   │       └── timeline/
│   ├── ui/
│   │   └── hud/
│   │       ├── hud.gd
│   │       ├── action_bar.gd
│   │       ├── targeting.gd
│   │       ├── event_log.gd
│   │       ├── turn_order_panel.gd
│   │       ├── minimap_panel.gd
│   │       ├── inventory_panel.gd
│   │       └── equipment_panel.gd
│   └── data/
│       ├── items/
│       ├── skills/skill_data.gd
│       └── classes/class_data.gd
└── graphify-out/              # 지식 그래프
```

## Systems

### RPG Stats (D&D 6-Attribute)

| 속성 | 영향 |
|---|---|
| STR (힘) | 근접 데미지, 운반량 |
| DEX (민첩) | 선제권, 회피, 원거리 |
| CON (건강) | HP, 저항 |
| INT (지능) | 마법 데미지, 지식 |
| WIS (지혜) | 지각, 의지력, 마법저항 |
| CHA (매력) | 교섭, 상점 가격 |

### Race System (6종)

| 종족 | STR | DEX | CON | INT | WIS | CHA |
|---|---|---|---|---|---|---|
| Human | +1 | +1 | +1 | +1 | +1 | +1 |
| Dwarf | +2 | -1 | +3 | 0 | +1 | -1 |
| Elf | -1 | +2 | -1 | +2 | +1 | +1 |
| Halfling | -2 | +3 | 0 | 0 | +2 | +1 |
| HalfElf | 0 | +1 | 0 | +1 | 0 | +2 |
| HalfOrc | +3 | 0 | +2 | -1 | -1 | 0 |

### Class System (15직업)

| 직업 | 핵심 스탯 | 시작 스킬 |
|---|---|---|
| 전사(Fighter) | STR+3 CON+2 | 검술 50, 전술 50, 해부학 30 |
| 마법사(Mage) | INT+3 WIS+2 | 마법학 50, 지능측정 50, 명상 30 |
| 레인저(Ranger) | DEX+3 WIS+2 | 궁술 50, 추적술 40, 몰이 30 |
| 로그(Rogue) | DEX+3 CHA+2 | 펜싱 50, 은신 40, 해부학 30 |
| 성기사(Paladin) | STR+2 CON+3 | 둔기 50, 신성학 50, 기도 30 |
| 음유시인(Bard) | WIS+2 CHA+2 | 악기연주 50, 도발 40, 춤추기 30 |
| 무도가(Monk) | STR+2 DEX+2 | 격투 50, 명상 40, 해부학 30 |
| 사제(Cleric) | INT+2 WIS+2 | 신성학 50, 치료 50, 기도 30 |
| 조련사(Tamer) | WIS+3 CHA+1 | 동물조련 50, 동물지식 50, 수의학 30 |
| 드루이드(Druid) | WIS+3 INT+1 | 자연술 50, 치료 50, 동물지식 30 |
| 연금술사(Alchemist) | INT+3 WIS+2 | 연금술 50, 약초학 50, 해부학 30 |
| 대장장이(Blacksmith) | STR+3 CON+2 | 대장기술 50, 채광 50, 장비지식 30 |
| 사무라이(Samurai) | STR+2 DEX+2 | 무사도 50, 검술 50, 방패막기 30 |
| 닌자(Ninja) | DEX+3 WIS+1 | 인술 50, 은신이동 50, 독바르기 30 |
| 강령술사(Necromancer) | INT+3 WIS+2 | 사령술 50, 주술 50, 심령술 30 |

### Skill System (57스킬 — UO Full Set)

| 분류 | 개수 | 대표 스킬 |
|---|---|---|
| 🔪 무기 | 7 | 검술, 창술, 펜싱, 둔기, 궁술, 격투, 투척술 |
| 🛡 보조 | 8 | 전술, 해부학, 치료, 기도, 마법저항, 방패막기, 독바르기, 장비지식 |
| ✨ 마법 | 7 | 마법학, 명상, 지능측정, 신성학, 자연술, 사령술, 주술 |
| 🎯 유틸 | 26 | 은신, 추적술, 악기연주, 춤추기, 도발, 평온, 불협화음, 은신탐색, 은신이동, 훔치기, 훔쳐보기, 법의학, 동물조련, 동물지식, 몰이, 수의학, 약초학, 연금술, 함정제거, 집중, 야영, 낚시, 구걸, 맛보기, 아이템감정, 심령술 |
| 🔨 제작 | 7 | 대장기술, 활/화살제작, 목공술, 재봉, 요리, 채광, 벌목 |
| 🥷 특수 | 2 | 무사도, 인술 |

### Skill Leveling (UO-Style)

- **레벨 범위**: 0.0 ~ 100.0 (GM = Grand Master)
- **타이틀**: 견습생 → 초보 → 수습 → 기술자 → 숙련자 → 장인 → 전문가 → 상급자 → 달인 → 거장(GM)
- **XP 시스템**: 사용 기반 XP, 레벨별 체감 (저레벨 ↑↑, 고레벨 ↓↓)
- **총합 제한**: 720.0 (향후 구현 예정)

### Cover System (3단계)

| 레벨 | AC/DEX 보너스 | 설명 |
|---|---|---|
| 절반 엄폐 (Half) | +2 | 장애물 일부 |
| 3/4 엄폐 (Three-Quarter) | +5 | 장애물 대부분 |
| 완전 엄폐 (Total) | 직접 공격 불가 | 완전 가림 |

## graphify — Knowledge Graph Integration

```bash
# 코드 변경 후 지식 그래프 업데이트
graphify update .

# AI 어시스턴트에서
/graphify
```

## Getting Started

**필요:** Godot 4 ([다운로드](https://godotengine.org/download/windows/))

1. Godot 4 설치
2. `project.godot` 열기
3. **Autoload 등록** (필수):
   - `source/autoload/event_bus.gd` → `EventBus`
   - `source/autoload/game_state.gd` → `GameState`
   - `source/autoload/localization.gd` → `Localization`
4. **F5** 실행

## Tech Stack

- **Engine:** Godot 4 (GDScript)
- **Knowledge Graph:** graphify v0.7.13
- **Platform:** Windows 10+

## License

MIT
