# CRPG_PROJECT

**Godot 4 CRPG** — 실시간 탐험과 턴제 전투를 오가는 듀얼 모드 게임 템플릿.
Knowledge-graph-driven development with [graphify](https://github.com/OhMyOpenCode/graphify).

## Architecture

### Dual-Mode Design

```
                 ┌─ RealityState ── RealTimeManager ── Real-time exploration
GameLoop ── FSM ─┤
                 └─ TurnbasedState ─ TurnManager ── Turn-based combat
                                         ├─ ActionPoints (AP system)
                                         └─ TimelineManager (ATB timeline)
```

- **실시간 모드** — 필드 탐험, 자유 이동, 실시간 상호작용 (`RealtimeState` / `RealTimeManager`)
- **턴제 모드** — 전투 진입 시 전환, 속도 기반 행동 순서 (`TurnbasedState` / `TurnManager`)
- GameLoop가 `enter_realtime()` / `enter_turn_mode()` 로 모드 전환을 오케스트레이션

### Movement System (Stoneshard-Inspired)

```
PlayerController ── input ──→ UnitMovement ── path ──→ GridWorld (A*)
    │                            │                        │
    ├─ Mouse click (realtime)    ├─ navigate_to()         ├─ AStar2D graph
    ├─ Arrow keys (both modes)   ├─ move_one_tile() [AP]  ├─ world_to_grid()
    └─ Space (turn-based skip)   └─ skip_turn()           └─ find_path_grid()
```

**듀얼 모드 이동:**
- **실시간 (모험 모드)** — 마우스 클릭으로 목적지 클릭 → A* 경로 탐색 → 연속 이동
  - 방향키도 실시간에서 한 칸씩 이동 가능 (Stoneshard 스타일)
  - 이동 속도: `move_speed` (기본 120px/s)
- **턴제 (전투 모드)** — 방향키/넘패드로 한 타일씩 이동, AP 소모
  - 이동 비용: `ap_cost_per_tile` (기본 1 AP)
  - Space = 턴 넘기기 (Stoneshard)
  - 이동 후 자동으로 다음 유닛 턴으로 전환

**Stoneshard와의 차용점:**
- 8방향 이동 (대각선 넘패드 1/3/7/9 지원)
- Adventure Mode = Click-to-move 연속 경로 이동
- Combat Mode = 한 번에 한 타일, AP 소모, 키보드 정밀 이동
- GridWorld가 타일 좌표계 + A* pathfinding 담당

### Core Components

| Component | File | Role |
|-----------|------|------|
| **StateMachine** | `source/core/state_machine/state_machine.gd` | Generic FSM — `change_state()` with `_process`/`_physics_process`/`_input` dispatch |
| **State** | `source/core/state_machine/state.gd` | Base state — `enter()`, `exit()`, `update()`, `physics_update()`, `handle_input()` |
| **ModeStateMachine** | `source/core/mode_state_machine.gd` | Active-mode FSM (realtime ↔ turnbased) |
| **GameLoop** | `source/core/game_loop.gd` | Top-level orchestrator — mode switching, pause, init |
| **EventBus** | `source/autoload/event_bus.gd` | **Autoload singleton** — 16 global signals for decoupled communication |
| **GameState** | `source/autoload/game_state.gd` | **Autoload singleton** — `GameMode` enum, settings persistence |

### Turn System

| Component | File | Role |
|-----------|------|------|
| **TurnManager** | `source/features/turnbased/turn_manager.gd` | Speed-based initiative queue, round/phases, `start_combat()` |
| **ActionPoints** | `source/features/turnbased/action_points.gd` | AP component — `max_ap`, `reset_for_turn()`, `spend()`, `can_afford()` |
| **TimelineManager** | `source/features/turnbased/timeline/timeline_manager.gd` | ATB-style timeline — speed-haste accumulation → turn threshold |

### Shared Components

| Component | File | Role |
|-----------|------|------|
| **Unit** | `source/features/shared/unit.gd` | Unit base class — `CharacterBody2D`, HP/AP/speed/attack/defense exports, `take_damage()`, `die()` |
| **GridWorld** | `source/features/shared/grid_world.gd` | A\* tile grid — `world_to_grid()`, `find_path_grid()`, `is_walkable()`, 8-dir movement |
| **UnitMovement** | `source/features/shared/unit_movement.gd` | Dual-mode movement — `navigate_to()` (realtime), `move_one_tile()` (turn-based, AP) |
| **PlayerController** | `source/features/shared/player_controller.gd` | Input handler — mouse click (realtime), arrow keys, Space skip (turn-based) |
| **HUD** | `source/ui/hud/hud.gd` | CanvasLayer HUD — HP bars, turn indicator, mode label |

### Grid Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `GridWorld.CELL_SIZE` | `32` | 한 타일의 픽셀 크기 (32×32) |
| `GridWorld.grid_width` | `64` | 그리드 가로 타일 개수 |
| `GridWorld.grid_height` | `64` | 그리드 세로 타일 개수 |

좌표 변환:
- `world_to_grid(pos)` → `floori(pos.x / 32, pos.y / 32)`
- `grid_to_world(pos)` → `vec2(pos.x × 32 + 16, pos.y × 32 + 16)` (타일 중앙)
- 1 AP = 1 타일 이동 = 32px

## Project Structure

```
CRPG_PROJECT/
├── project.godot              # Godot 4 project config
├── AGENTS.md                  # AI agent assistant instructions (graphify integration)
├── README.md                  # This file
├── pyproject.toml             # Python project config
├── .gitignore
├── assets/                    # Assets (images, audio, etc.)
├── data/                      # Game data (JSON, configs)
├── source/
│   ├── main.gd                # Entry point
│   ├── main.tscn              # Main scene (scene tree)
│   ├── autoload/
│   │   ├── event_bus.gd       # Global event bus (19 signals)
│   │   └── game_state.gd      # Global game state + settings
│   ├── core/
│   │   ├── game_loop.gd       # Mode orchestrator
│   │   ├── mode_state_machine.gd
│   │   ├── state_machine/
│   │   │   ├── state.gd
│   │   │   └── state_machine.gd
│   │   └── states/
│   │       ├── realtime_state.gd
│   │       └── turnbased_state.gd
│   ├── features/
│   │   ├── realtime/
│   │   │   └── realtime_manager.gd  # Player spawn + real-time mode mgmt
│   │   ├── shared/
│   │   │   ├── unit.gd              # Unit base class (CharacterBody2D)
│   │   │   ├── grid_world.gd        # A* tile grid (NEW)
│   │   │   ├── unit_movement.gd     # Dual-mode movement (NEW)
│   │   │   └── player_controller.gd # Input handler (NEW)
│   │   └── turnbased/
│   │       ├── action_points.gd
│   │       ├── turn_manager.gd
│   │       └── timeline/
│   │           └── timeline_manager.gd
│   ├── ui/
│   │   └── hud/
│   │       └── hud.gd
│   └── utils/
│       └── helpers.gd
├── graphify-out/              # Knowledge graph output
│   ├── GRAPH_REPORT.md        # Graph report (177 nodes, 163 edges, 19 communities)
│   ├── graph.json
│   └── graph.html
└── crpg_project/              # Python package (graphify integration)
```

## graphify — Knowledge Graph Integration

This project uses **graphify** (v0.7.13) to build a knowledge graph of the entire codebase, including GDScript files.

### How It Works

```
graphify update .
  ├── detect        → discover .gd, .py, .tsx, etc. files
  ├── extract       → AST-based parsing with GDScript extractor (regex)
  ├── build graph   → nodes + edges + communities (Leiden clustering)
  ├── analyze       → god nodes, surprising connections
  └── report        → GRAPH_REPORT.md, graph.json, graph.html
```

### Usage

```bash
# Update knowledge graph after code changes (AST-only, no API cost)
graphify update .

# Or via AI assistant slash command in OpenCode / Claude Code
/graphify
```

### GDScript Extract Support

GDScript is fully supported via a custom regex-based extractor injected into graphify:

| Feature | Graph Node Kind | Example |
|---------|----------------|---------|
| `class_name` | `class` | `State`, `TurnManager` |
| `extends` | edge `→` | `State → Node` |
| `func` | `function` | `enter()`, `take_damage()` |
| `signal` | `signal` | `turn_started`, `unit_damaged` |
| `@export var` | `export_var` | `max_hp (export)`, `speed (export)` |
| `@onready var` | `onready_var` | `health_bar` |
| `var` / `const` | `variable` | `current_hp`, `MAX_PLAYERS` |
| `enum` | `enum` | `enum GameMode` |

### Current Graph Stats

| Metric | Value |
|--------|-------|
| Files | 20 (16 .gd + 4 .py) |
| Nodes | **177** |
| Edges | **163** |
| Communities | **19** |
| Extraction | 100% EXTRACTED (no LLM inference) |

## Getting Started

**Prerequisites:** Godot 4 engine ([download](https://godotengine.org/download/windows/))

1. Download & install Godot 4
2. Open `project.godot` in Godot
3. **Register Autoloads** (mandatory):
   - `source/autoload/event_bus.gd` → singleton name `EventBus`
   - `source/autoload/game_state.gd` → singleton name `GameState`
4. **Create `main.tscn`** with the following scene tree:
   ```
   Main (Node) — script: source/main.gd
   ├── GameLoop (Node) — script: source/core/game_loop.gd
   │   ├── ModeStateMachine (Node) — script: source/core/mode_state_machine.gd
   │   │   ├── realtime (Node) — script: source/core/states/realtime_state.gd
   │   │   └── turnbased (Node) — script: source/core/states/turnbased_state.gd
   │   ├── TurnManager (Node) — script: source/features/turnbased/turn_manager.gd
   │   ├── ActionPoints (Node) — script: source/features/turnbased/action_points.gd
   │   └── Timeline (Node) — script: source/features/turnbased/timeline/timeline_manager.gd
   ├── RealTimeManager (Node) — script: source/features/realtime/realtime_manager.gd
   ├── HUD (CanvasLayer) — script: source/ui/hud/hud.gd
   │   ├── HealthBar (ProgressBar, %HealthBar)
   │   ├── ModeLabel (Label, %ModeLabel)
   │   ├── ActionPointsLabel (Label, %ActionPointsLabel)
   │   └── TurnIndicator (Label, %TurnIndicator)
   └── (other children as needed)
   ```
5. Press **F5** to run

> **graphify note:** GDScript extractor is injected into graphify's `extract.py` (site-packages). It will persist across graphify version upgrades as a scripted post-install step. The regex-based parser covers all standard GDScript constructs; for edge cases (nested multi-line strings, unusual block comments), results may vary.

## Tech Stack

- **Engine:** Godot 4 (GDScript)
- **Knowledge Graph:** graphify v0.7.13
- **Language:** GDScript + Python
- **Platform:** Windows 10+
- **Python:** 3.14+
