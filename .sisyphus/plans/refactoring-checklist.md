# Refactoring Checklist — CRPG_PROJECT

> 매 리팩토링 세션 시작 전 이 파일을 읽고, 각 항목 완료 후 `[x]`로 마킹한다.

## 1. 파일 구조 감사
- [ ] `source/` 아래 모든 `.gd` 파일이 Feature Index 기준 올바른 위치인가?
- [ ] `source/features/` 도메인별 분리 (realtime/shared/turnbased) 유지되고 있는가?
- [ ] `source/data/` 시스템별 분리 (items/skills/classes/enemies/crafting) 유지?
- [ ] 분류되지 않은 파일이 루트에 방치되어 있지는 않은가?
- [ ] `source/shaders/` 가 비어있는 것은 의도된 것인가?

## 2. 데드 코드 탐지
- [ ] 선언만 있고 호출되지 않은 함수?
- [ ] 초기화만 하고 읽히지 않은 변수?
- [ ] 주석처리된 코드 블록 (TODO/FIXME 노트와 별개)?
- [ ] 미사용 `@export var` (인스펙터용이 아니라 실제 코드에서 참조하는가)?
- [ ] 사용되지 않는 `const`/`enum` 정의?

## 3. 타입 안전성
- [ ] `get("property")` 동적 접근이 `@export var` 또는 정적 변수로 대체 가능한가?
- [ ] `set("property", val)` 동적 할당 대체 가능한가?
- [ ] `has_method()` 대신 `is` 연산자나 시그널 사용 가능한가?
- [ ] `Node` 타입 대신 구체적 `class_name` 타입 선언이 가능한가?

## 4. EventBus 일관성
- [ ] 두 시스템이 서로를 직접 `get_node()` 로 참조하고 있는가? → EventBus로 대체
- [ ] 불필요하게 케이블링된 신호가 있는가? (A→B→C 체인)?
- [ ] EventBus에 빠진 시그널이 필요한가?

## 5. FSM 상태 검증
- [ ] 모든 State 서브클래스가 `enter(prev_state)` 구현했는가?
- [ ] 모든 State 서브클래스가 `exit()` 구현했는가?
- [ ] `update(delta)` 에 방치된 빈 pass가 의도된 것인가?
- [ ] State 전환 순서가 예상과 일치하는가? (realtime → turnbased, 그 역)

## 6. Scene 트리 일관성
- [ ] `main.tscn`의 노드 구조와 `get_node()` 경로가 일치하는가?
- [ ] 상대 경로 (`../../TurnManager`) vs 절대 경로 (`/root/Main/...`) 혼용이 의도된 것인가?
- [ ] Autoload 이름이 실제 `project.godot` Autoload 목록과 일치하는가?

## 7. 명명 규칙
- [ ] 모든 재사용 컴포넌트에 `class_name` 이 선언되었는가?
- [ ] 파일명과 `class_name` 이 일치하는가? (snake_case 파일명, PascalCase class_name 변환?)
- [ ] `class_name` 없는 파일이 의도적(예: singleton autoload)인가?

## 8. graphify graph 갱신
- [ ] `graphify update .` 실행
- [ ] `graphify-out/GRAPH_REPORT.md` 읽고 god nodes 확인
- [ ] 커뮤니티 구조가 actual 시스템 분리와 일치하는가?
- [ ] 빠진 .gd 파일이 graph에 없는가?

## 9. 에러 핸들링 감사
- [ ] 빈 `catch` 블록 (`OS.get_unix_time()` 등 exception-safe 래퍼)?
- [ ] 적절한 `push_error()` / `push_warning()` 사용 (침묵하는 실패 없음)
- [ ] assertion으로 불변조건 보호되고 있는가? (`assert(grid != null)`)

## 10. LSP 진단
- [ ] 변경된 모든 파일: `lsp_diagnostics` error/warning 0
- [ ] 변경되지 않은 파일에 ripple error 발생하지 않음
- [ ] `@warning_ignore` 가 정당한 이유로 사용되었는가?
