# CRPG Prototype - 프로젝트 구조 (Project Structure)

**최종 업데이트:** 2026-04-18
**버전:** 1.0.0

---

## 프로젝트 디렉토리 구조

```
crpg_prototype/
├── project.godot                 # 프로젝트 설정 (Godot 4.x, Autoload 정의)
├── scenes/                       # 게임 씬 (SCN 파일)
│   ├── main.tscn               # 메인 게임 씬
│   ├── enemy.tscn              # 적 엔티티 씬
│   ├── character_creation.tscn # 캐릭터 생성 화면
│   ├── session_setup.tscn     # 세션 설정 화면
│   ├── scene_selector.tscn     # 시나리오 선택 화면
│   └── tutorial_scenario.tscn  # 튜토리얼 시나리오
├── scripts/                      # GDScript 코드
│   ├── autoload/               # Autoload (Singleton) - 프로젝트 전역에서 접근 가능
│   │   └── game_manager.gd     # 전역 게임 매니저 (플래그, 데이터 관리)
│   ├── entities/                # 게임 엔티티 ( CharacterBody3D )
│   │   ├── player.gd           # 플레이어 캐릭터
│   │   └── enemy.gd           # 적 캐릭터
│   ├── systems/                 # 게임 시스템 (주요 로직)
│   │   ├── main_controller.gd  # 메인 컨트롤러 (맵 생성, 플레이어 관리)
│   │   ├── ui_manager.gd       # UI 관리 (미니맵, 로그 등)
│   │   ├── combat_manager.gd   # 전투 시스템 (BattleSystem Autoload)
│   │   ├── pathfinding.gd      # A* 길찾기 알고리즘
│   │   ├── wfc_system.gd       # WFC (Wave Function Collapse) 맵 생성
│   │   ├── cover_system.gd     # 은폐/엄폐물 시스템
│   │   ├── level_manager.gd    # 던전 레벨 관리 (3-layer)
│   │   ├── story_manager.gd   # 시나리오 관리 (StoryManager Autoload)
│   │   ├── tutorial_scenario.gd # 튜토리얼 시나리오
│   │   ├── scene_selector.gd   # 씬 선택 화면
│   │   ├── tile_data.gd       # 타일 데이터
│   │   ├── character_creation.gd # 캐릭터 생성 시스템
│   │   ├── session_setup.gd   # 세션 변수 설정
│   │   ├── world_simulation.gd # 세계 시뮬레이션 (WorldSimulation Autoload)
│   │   ├── monster_spawner.gd # 몬스터 스폰 시스템 (MonsterSpawner Autoload)
│   │   ├── loot_system.gd     # 전리품 시스템 (LootSystem Autoload)
│   │   └── emergent_events.gd #突发事件 생성 시스템
│   └── data/                   # 데이터 로더
│       ├── content.gd         # 콘텐츠 로더
│       └── terrain_data.gd    # 지형 데이터
├── data/                       # JSON 데이터 파일
│   ├── races.json             # 종족 데이터 (D&D 5e SRD)
│   ├── backgrounds.json        # 배경/혈통 데이터
│   ├── monsters.json           # 몬스터 데이터
│   ├── monsters_session.json   # 세션 기반 몬스터
│   ├── monsters_additional.json # 추가 몬스터
│   ├── items.json             # 아이템 데이터
│   ├── classes.json           #职业 데이터
│   ├── resources.json          # 자원 유형
│   ├── settlements.json        # 정착지 데이터
│   ├── political_factions.json # 정치 세력
│   ├── flags.json             # 게임 플래그
│   ├── terrain.json            # 지형 설정
│   └── bloodlines.json        # 혈통 데이터
└── docs/                       # 기술 문서
    ├── research.md             # 기술 사양 (영문)
    ├── research_full.md        # 통합 연구 문서 (한국어)
    ├── project_structure.md    # 프로젝트 구조 (본 문서)
    ├── data_guide.md           # 데이터 가이드
    ├── plan.md                 # 개발 계획
    ├── world_map.md            # 세계 지도
    ├── scenario_A.md           # 시나리오 A
    ├── scenario_B.md           # 시나리오 B
    ├── scenario_C.md           # 시나리오 C
    └── bloodline.md            # 혈통 가이드
```

---

## Autoload (Singleton) 시스템

project.godot에 정의된 Autoload 노드들:

| Autoload 이름 | 스크립트 | 용도 |
|--------------|----------|------|
| GameManager | game_manager.gd | 플래그, race/background 데이터 관리 |
| GameContent | content.gd | 콘텐츠 로더 |
| StoryManager | story_manager.gd | 시나리오 관리 |
| LevelManager | level_manager.gd | 던전 레벨 관리 |
| BattleSystem | combat_manager.gd | 전투 시스템 (AP, 턴제) |
| WorldSimulation | world_simulation.gd | 물리 변수 레이어 (fog, grid, orc) |
| MonsterSpawner | monster_spawner.gd | 몬스터 스폰 (세션 변수 연동) |
| LootSystem | loot_system.gd | 전리품 드롭 |

---

## 모델 합성 (WFC) 맵 생성 시스템

### wfc_system.gd

**알고리즘:** Wave Function Collapse (Model Synthesis)
**용도:** 3-layer 던전 맵 자동 생성

#### 타일 유형 (Tile Types)
| 타입 | 값 | 확률 |
|------|-----|------|
| WALL | 0 | 15% |
| FLOOR | 1 | 75% |
| DOOR | 2 | 2% |
| WATER | 3 | - |
| COVER | 4 | 8% |
| STAIRS_UP | 6 | - |
| STAIRS_DOWN | 7 | - |

#### 인접 규칙 (Adjacency Rules)
```
WALL  → WALL, FLOOR, DOOR
FLOOR → WALL, FLOOR, DOOR, COVER
DOOR  → FLOOR, WALL
COVER → FLOOR, WALL, COVER
```

#### 생성 알고리즘
1. 모든 셀을 가능한 상태로 초기화 (entropy 계산)
2. 가장 낮은 entropy의 셀 선택
3. 확률 기반으로 타일 결정 (가중치 적용)
4. 인접 규칙으로 가능한 상태 축소 (propagation)
5. 전체 셀collapse 될 때까지 반복
6. 실패 시 fallback 생성 ( simplesRandom)
- WALL ↔ WALL, FLOOR, DOOR
- FLOOR ↔ WALL, FLOOR, DOOR, COVER
- DOOR ↔ FLOOR, WALL
- COVER ↔ FLOOR, WALL, COVER

### main_controller.gd 연동
- WFC 시스템으로 맵 생성
- 타일 유형별 다른 mesh/collision 생성