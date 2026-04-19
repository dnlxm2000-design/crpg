# 개발 계획 (Development Plan)

**최종 업데이트:** 2026-04-18

---

## 목표
- Godot 4 기반의 웹 익스포트 가능 뼈대
- 3층 던전 구조, 파티 관리 UI, 실시간 + 턴제 혼합 전투
- 코드를 모르는 사람도 스킬/몬스터 확장이 가능한 데이터驱动 설계

## 핵심 요소
- 데이터驱动 콘텐츠 파이프라인 (JSON)
- 확장성 있는 몬스터/스킬/아이템 포맷
- 이벤트 기반 던전 설계

## 뼈대 구성
- World/Layer1/Layer2/Layer3 씬
- DataLoader, CombatManager, Party

## MVP 로드맵: 3개월 동안 MVP 완성 및 콘텐츠 샘플 팩 1~2개

## 라이선스
- 구글 독스 기반 라이선스 문서 연결 및 SRD 콘텐츠 사용규칙

---

## 현재 진행 상황 (2026-04-18)

### 완료된 문서
- [x] docs/research.md - 기술 사양 (영문)
- [x] docs/research_full.md - 통합 연구 문서 (한국어, Bugfix 노트 포함)
- [x] docs/bloodline.md - 4대 혈통 상세
- [x] docs/scenario_A.md - 실버 텅 외교관 사건
- [x] docs/scenario_B.md - 증폭기 정지 + 지하 기계 사건
- [x] docs/scenario_C.md - 노바 부유 도시 잔해 사건
- [x] docs/world_map.md - 상세 지도 및 영토 설계
- [x] docs/project_structure.md - 프로젝트 구조
- [x] docs/data_guide.md - 데이터 가이드
- [x] data/bloodlines.json - 혈통 데이터
- [x] data/monsters_additional.json - 노바/마왕군 몬스터

### 완료된 기능 (2026-04-18 기준)
- [x] 캐릭터 생성 시스템 (종족 10개, 혈통 4개, 직군 8개, 포인트 구매)
- [x] 세션 변수 설정 (fog_density, grid_resonance, orc_disposition)
- [x] Tutorial 시나리오 (아이런스컬 습격)
- [x] 시나리오 선택 화면
- [x] WFC 맵 생성 시스템
- [x] A* 길찾기
- [x] 전투 시스템 (AP 기반 턴제)
- [x] 은폐/엄폐물 시스템
- [x] 3-layer 던전 관리
- [x] 몬스터 스폰 시스템 (세션 변수 연동)
- [x] 전리품 드롭 시스템
- [x] 세계 시뮬레이션 (자원, 정착지, 정치 세력)
- [x]突发事件 시스템

### TO-DO (미래 개발)
1. [ ] 스킬 시스템 (47 스킬)
2. [ ] 마법 시스템
3. [ ] 커버/플랭킹 시스템 개선
4. [ ] 파티 관리 UI
5. [ ] 저장/로드 시스템

### 최근 수정 사항 (2026-04-18)
- [x] character_creation.gd - Race 선택 시 능력치 적용 안 되던 문제 수정
- [x] character_creation.gd - bloodline bonus 로직 수정 (base_stats 재설정)
- [x] character_creation.gd - Race/Bloodline signal 연결 추가
- [x] scene_selector.tscn/gd - 한국어 번역 완료
- [x] ui_manager.gd - 한국어 번역 완료 (상태/미니맵/장비/로그/인벤토리/스킬)

---

## 게임 시작 사건

| 사건 | 제목 | 난이도 | 중심 스킬 |
|------|------|--------|----------|
| A | 실버 텅 외교관의 등장 | Easy | 외교, 대화 |
| B | 증폭기 정지 + 지하 기계 발견 | Medium | 기술, 잠행 |
| C | 노바 부유 도시 잔해 | Hard | 탐험, 전투 |
| D | Tutorial - 아이런스컬 습격 | Tutorial | 기본 조작 |

---

## 숨겨진 진실 (세계관)

1. 인간은 "살아있는 간수"로 설계됨
2. 성왕 퀘이사는 바알-카르와 계약했음
3. 제국의 번영은 1,000년 후의 빚
4. 루미나스의 마법은 봉인 갉아먹기 의식
5. 심연의 사도는 노예를 구원한 것이 아니라 제물로 사용
6. 안개를 먹는 기계가 마을 지하에 존재
7. 매일 밤 노예들이 제물로 바쳐짐
