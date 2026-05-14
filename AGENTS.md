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

## Requirements for New Code
1. **graphify-friendly**: Every new `.gd` file should have meaningful `class_name`, `extends`, `func`, `signal`, `@export var` so graphify captures them
2. **EventBus signals**: Use `EventBus` for cross-component communication, never direct references between distant systems
3. **State pattern**: Game mode logic goes in State subclasses, not in GameLoop directly
4. **File structure**: One class per file, filename matches class_name (lowercase)
