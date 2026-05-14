# CRPG_PROJECT — 작업 현황

## 마지막 작업: 2026-05-14

완료된 작업과 앞으로 할 일을 정리한다.

---

## ✅ 완료된 기능

### 1. Zone of Control (ZOC)
- **파일**: `source/features/turnbased/zoc_controller.gd`
- 인접 8타일 통제, 진입 시 AP+1, 이탈 시 Attack of Opportunity
- 유닛 속성: `zoc_range` (기본 1)
- 적 AI: ZOC 인식 측면 접근
- **테스트**: `test_zoc.gd` — 9개 통과

### 2. Hit/Miss 시스템 (CombatResolver)
- **파일**: `source/features/turnbased/combat_resolver.gd`
- 명중 = `clamp(accuracy - evasion + 거리패널티, 5%, 95%)`
- 치명타(Crit): 상위 5% 구간, 데미지 ×2
- 빗맞힘(Graze): 상위 5~10% 구간, 데미지 ÷2
- 거리 패널티: 최적 사거리 초과 시 타일당 -5%
- 유닛 속성: `crit_chance`, `crit_multiplier`
- **통합된 호출자**: player_controller (E공격), enemy_ai (근접/원거리), zoc_controller (AoO)
- **테스트**: `test_combat_resolver.gd` — 31개 통과

### 3. 전투 UI (Action Bar + Targeting)
- **파일**: `source/ui/hud/action_bar.gd` — 하단 중앙 [⚔Attack] [🎒Item] [⏳Wait]
  - AP 인식 버튼 상태
  - Attack → 인접 적 공격 (CombatResolver)
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
