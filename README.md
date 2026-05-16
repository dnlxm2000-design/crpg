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
│   │   └── game_state.gd      # 전역 게임 상태
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
│   └── data/items/
└── graphify-out/              # 지식 그래프
```

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
4. **F5** 실행

## Tech Stack

- **Engine:** Godot 4 (GDScript)
- **Knowledge Graph:** graphify v0.7.13
- **Platform:** Windows 10+
