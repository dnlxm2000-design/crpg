# CRPG_PROJECT — AI Agent Assistant Guide

## Project Overview
Godot 4 hybrid real-time + turn-based CRPG template. Knowledge-graph-driven development.

## graphify Integration

graphify is installed. Type `/graphify` in your AI coding assistant — it reads files, builds a knowledge graph, and gives back structure.

- **graphify** (`~/.claude/skills/graphify/SKILL.md`) — any input to knowledge graph. Trigger: `/graphify`
- When the user types `/graphify`, invoke the Skill tool with `skill: "graphify"` before doing anything else.
- The knowledge graph lives at `graphify-out/`. Before answering architecture or codebase questions, read `graphify-out/GRAPH_REPORT.md` for god nodes and community structure.
- After modifying code files, run `graphify update .` to keep the graph current (AST-only, no API cost).

## Architecture

```
main.tscn (root: main.gd)
  ├── GameLoop (game_loop.gd) — mode orchestrator
  │   ├── ModeStateMachine (mode_state_machine.gd) — extends StateMachine
  │   │   ├── realtime (realtime_state.gd) — extends State
  │   │   └── turnbased (turnbased_state.gd) — extends State
  │   ├── TurnManager (turn_manager.gd)
  │   ├── ActionPoints (action_points.gd)
  │   └── Timeline (timeline_manager.gd)
  ├── RealTimeManager (realtime_manager.gd)
  ├── HUD (hud.gd) — CanvasLayer
  └── (other children as needed)

Autoloads:
  - EventBus (source/autoload/event_bus.gd)
  - GameState (source/autoload/game_state.gd)
```

### Dual-Mode Flow
- `GameLoop.enter_realtime()` → switches to RealtimeState → emits `game_mode_changed("realtime")`
- `GameLoop.enter_turn_mode()` → switches to TurnbasedState → emits `game_mode_changed("turnbased")`

## GDScript Code Conventions
- Use `class_name` for all reusable components
- `@export var` for inspector-exposed fields; `@onready var` for scene references
- Signals for decoupled communication via EventBus
- Extend `State` class for FSM states
- Use `Unit` as base class for all entities (player, enemies, NPCs)
- Feature folders under `source/features/` by domain (realtime/, turnbased/)

## Feature Index — 기능 수정 시 봐야 할 파일

시스템별로 관련 파일을 그룹화. 특정 기능을 수정할 때 이 목록을 기준으로 파일을 읽으면 검색 낭비가 없다.

### 진입점 / 코어
| 파일 | 역할 |
|------|------|
| `source/main.tscn` | 루트 씬 — 트리 구조 결정 |
| `source/main.gd` | 진입점 — 플레이어 스폰, HUD/오버레이 생성 |
| `source/core/game_loop.gd` | 리얼타임↔턴 모드 오케스트레이터 |
| `source/core/states/realtime_state.gd` | 리얼타임 상태 (FSM) |
| `source/core/states/turnbased_state.gd` | 턴제 상태 (FSM) |
| `source/core/mode_state_machine.gd` | ModeStateMachine (StateMachine 확장) |
| `source/core/state_machine/state_machine.gd` | 제네릭 FSM 베이스 |
| `source/core/state_machine/state.gd` | State 베이스 클래스 |

### 오토로드 (전역 싱글톤)
| 파일 | 역할 |
|------|------|
| `source/autoload/event_bus.gd` | 전역 신호 버스 — 모든 시스템 간 디커플드 통신 |
| `source/autoload/game_state.gd` | 게임 모드/설정/파티 관리 |
| `source/autoload/localization.gd` | UI 문자열 관리 (한글/영문) |

### 유닛 시스템
| 파일 | 역할 |
|------|------|
| `source/features/shared/unit.gd` | 유닛 베이스 — HP/AP/스탯/장비/시체 |
| `source/features/shared/enemy_ai.gd` | 적 AI — IDLE/PATROL/CHASE/COMBAT/DEAD |
| `source/features/shared/corpse.gd` | 시체 — 루팅 가능 오브젝트 |

### 이동 시스템
| 파일 | 역할 |
|------|------|
| `source/features/shared/grid_world.gd` | A* 그리드 — pathfinding, occupancy, elevation |
| `source/features/shared/unit_movement.gd` | 이동 컴포넌트 — 실시간 navaigate_to() / 턴제 move_one_tile() |
| `source/features/shared/player_controller.gd` | 플레이어 입력 — 마우스클릭/WASD/액션바/인벤토리 |

### 전투 시스템
| 파일 | 역할 |
|------|------|
| `source/features/turnbased/turn_manager.gd` | 턴 큐 — 전투원 등록, 속도 기반 정렬, 라운드 관리 |
| `source/features/turnbased/action_points.gd` | AP 컴포넌트 — spend()/can_afford() |
| `source/features/turnbased/combat_resolver.gd` | 전투 판정 엔진 — 명중/회피/치명타/빗맞힘/고도/후방/엄폐 |
| `source/features/turnbased/zoc_controller.gd` | ZOC — 진입 AP+1, 이탈 Attack of Opportunity |
| `source/features/turnbased/timeline/timeline_manager.gd` | ATB 타임라인 — 속도 기반 행동 대기열 |

### 리얼타임 시스템
| 파일 | 역할 |
|------|------|
| `source/features/realtime/realtime_manager.gd` | 리얼타임 모드 관리자 — 플레이어 스폰, 유닛 등록 |
| `source/features/realtime/map_item.gd` | 맵 위 아이템 (드랍/배치) |

### 데이터 / 정의
| 파일 | 역할 |
|------|------|
| `source/data/items/item.gd` | 아이템 리소스 클래스 |
| `source/data/items/item_data.gd` | 아이템 데이터 카탈로그 |
| `source/data/items/item_types.gd` | 아이템 타입 정의 (Equipment, Consumable, Weapon...) |
| `source/data/items/resources/*.tres` | 개별 아이템 리소스 |
| `source/data/skills/skill_data.gd` | 스킬 데이터 |
| `source/data/skills/skill_types.gd` | 스킬 타입 정의 |
| `source/data/classes/class_data.gd` | 직업 데이터 (fighter, rogue, mage...) |
| `source/data/classes/class_definition.gd` | ClassDefinition 리소스 |
| `source/data/enemies/enemy_data.gd` | 적 데이터 — 스탯/드랍/스킬 |
| `source/data/crafting/alchemy_data.gd` | 연금술 데이터 |

### 지형 / 비주얼 이펙트
| 파일 | 역할 |
|------|------|
| `source/features/shared/effects/terrain_manager.gd` | 지형 생성 — 노이즈→메시→워터, BotW 스타일 |
| `source/features/shared/effects/terrain.gdshader` | 지형 셰이더 — 높이 기반 컬러링 + UV 타입 오버라이드 |
| `source/data/terrain_data.gd` | 지형 데이터 — 타입별 속성 |
| `source/data/terrain_type_definition.gd` | TerrainTypeDefinition 리소스 |
| `source/features/shared/effects/camera_follow.gd` | 3인칭 카메라 추적 |
| `source/features/shared/effects/path_preview.gd` | 실시간 경로 미리보기 (하얀 선) |
| `source/features/shared/effects/movement_range_overlay.gd` | 턴제 이동 범위 하이라이트 |
| `source/features/shared/effects/projectile.gd` | 발사체 (스피어 오브젝트 → 타겟) |

### 인벤토리 / 아이템
| 파일 | 역할 |
|------|------|
| `source/features/shared/inventory/inventory.gd` | 인벤토리 컴포넌트 — add/remove/use/stack/equip |

### UI / HUD
| 파일 | 역할 |
|------|------|
| `source/ui/hud/hud.gd` | 메인 HUD — 체력바/AP/모드/데미지 표시 |
| `source/ui/hud/inventory_panel.gd` | 인벤토리 패널 (I키) |
| `source/ui/hud/equipment_panel.gd` | 장비/스탯 패널 (E키) — 11개 슬롯 + 파생스탯 |
| `source/ui/hud/action_bar.gd` | 전투 액션 바 — Attack/Push/Item/Wait |
| `source/ui/hud/targeting.gd` | 타겟팅 시스템 — 적 순환 선택 + 하이라이트 |
| `source/ui/hud/event_log.gd` | 이벤트 로그 패널 |
| `source/ui/hud/turn_order_panel.gd` | 턴 순서 패널 (상단 중앙) |
| `source/ui/hud/minimap_panel.gd` | 미니맵 — CanvasLayer 우상단 |
| `source/ui/screens/defeat_panel.gd` | 패배 화면 (DEFEAT + Restart) |

### 유틸리티
| 파일 | 역할 |
|------|------|
| `source/utils/helpers.gd` | 공용 헬퍼 함수 |

---

## 주기적 AI 리팩토링 (필수)

코드베이스가 커질수록 버그 발생률이 기하급수적으로 늘어나는 것을 방지하기 위해, AI가 직접 전체 코드 구조를 정리하는 리팩토링을 주기적으로 수행한다.

### 규칙
- **최소 2주에 1회**, 가능하면 **1주에 1회** 리팩토링 실행
- 리팩토링 시점: 새 기능 구현 완료 후, 또는 유저 요청 시
- 리팩토링 전 반드시 `.sisyphus/plans/refactoring-checklist.md` 를 읽고 순서대로 수행
- graphify graph 업데이트는 리팩토링의 일부로 포함 (`graphify update .`)
- 모든 변경사항은 `git commit` 전에 검증 완료해야 함

### 수행 항목
1. **파일 구조 감사** — Feature Index 기준으로 틀린 위치, 미분류 파일 확인
2. **데드 코드 탐지** — 미사용 변수, 미호출 함수, 주석처리된 코드 제거
3. **타입 안전성** — `get()`/`set()` 동적 접근 → 정적 시그널/메서드로 대체 가능한지
4. **EventBus 일관성** — 시스템 간 직접 참조가 있는지 (EventBus로 대체 가능한지)
5. **FSM 상태 검증** — State 서브클래스들이 `enter()/exit()/update()` 올바르게 구현했는지
6. **Scene 트리 일관성** — `main.tscn`의 노드 구조가 실제 코드의 `get_node()` 경로와 일치하는지
7. **명명 규칙** — AGENTS.md 컨벤션 위반 (class_name 누락, 파일명≠클래스명 등)
8. **graphify graph 갱신** — `graphify update .` 실행 후 GRAPH_REPORT.md 확인
9. **에러 핸들링 감사** — 빈 catch 블록, push_error/push_warning 적절한 사용 확인
10. **LSP 진단** — 변경된 모든 파일 `lsp_diagnostics` clean 확인

## Requirements for New Code
1. **graphify-friendly**: Every new `.gd` file should have meaningful `class_name`, `extends`, `func`, `signal`, `@export var` so graphify captures them
2. **EventBus signals**: Use `EventBus` for cross-component communication, never direct references between distant systems
3. **State pattern**: Game mode logic goes in State subclasses, not in GameLoop directly
4. **File structure**: One class per file, filename matches class_name (lowercase)
