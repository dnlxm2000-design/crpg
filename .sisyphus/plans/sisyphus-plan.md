# .sisyphus/plans/crpg-project-state.md

## Current Goal
Godot 4 CRPG 듀얼 모드 게임 템플릿 + graphify GDScript 지식 그래프 통합 완료.

## Completed

### graphify GDScript Integration
- [x] graphify codebase 분석 완료 (7-stage pipeline, _DISPATCH 패턴, detect/watch/extract 구조)
- [x] `graphifyy` v0.7.13 pip 설치 완료
- [x] `graphify install --platform opencode --platform claude` 스킬 등록
- [x] `extract_gdscript()` 함수 작성 — regex 기반 GDScript 파서 (class_name, extends, func, signal, @export var, @onready var, var/const, enum, inner class 지원)
- [x] `_DISPATCH`에 `".gd": extract_gdscript` 엔트리 추가 → graphify가 .gd 파일 인식
- [x] `detect.py` `CODE_EXTENSIONS`에 `.gd` 추가 → graphify가 .gd 파일 검색
- [x] `graphify update .` 실행 검증: **9→177 nodes, 5→163 edges, 4→19 communities** (16개 .gd 파일 전부 파싱)

### CRPG_PROJECT 구조
- [x] `project.godot` — Godot 4 설정 (1280x720, forward_plus, canvas_items stretch)
- [x] `source/core/state_machine/state.gd` + `state_machine.gd` — Generic FSM
- [x] `source/core/game_loop.gd` — Mode orchestrator (realtime ↔ turnbased)
- [x] `source/core/states/realtime_state.gd` + `turnbased_state.gd`
- [x] `source/autoload/event_bus.gd` — 16 global signals (Autoload singleton)
- [x] `source/autoload/game_state.gd` — GameMode enum, settings (Autoload singleton)
- [x] `source/features/turnbased/turn_manager.gd` — Speed-based initiative
- [x] `source/features/turnbased/action_points.gd` — AP system
- [x] `source/features/turnbased/timeline/timeline_manager.gd` — ATB timeline
- [x] `source/features/realtime/realtime_manager.gd`
- [x] `source/features/shared/unit.gd` — Unit base (CharacterBody2D)
- [x] `source/ui/hud/hud.gd` — CanvasLayer HUD
- [x] `source/utils/helpers.gd`
- [x] `source/main.gd` — Entry point
- [x] `.gitignore`, `AGENTS.md`, `pyproject.toml`, `README.md`

## Blocked / External
- Godot 4 엔진 미설치 — 사용자가 godotengine.org 에서 다운로드 필요
- tree-sitter-gdscript PyPI 패키지 없음 → regex 기반 우회

## Critical Context
- graphify GDScript extractor는 site-packages에 직접 주입됨 (graphifyy 업그레이드 시 덮어쓰기 주의)
- GDScript extractor 함수: `C:\Users\user6\AppData\Local\Python\pythoncore-3.14-64\Lib\site-packages\graphify\extract.py` — line 5511
- 프로젝트 루트: `C:\Users\user6\projects\CRPG_PROJECT`
- Python 3.14.4, Windows PowerShell 환경
- graphify update 시 LLM API 키 불필요 (AST-only, 무료)

## Next Steps
1. Godot 4 설치 → `project.godot` 열기
2. Autoload 등록: EventBus, GameState
3. `main.tscn` 생성, `main.gd` 연결
4. 게임 기능 구현 (전투, AI, 스킬, 인벤토리 등)
