# 실버하벤 CRPG - 통합 연구 문서 (전체 백업)

**버전:** 1.3.0  
**최종 업데이트:** 2026-04-18  
**라이선스:** Google Docs 관리 / D&D 5e SRD 기반

---

## 제1장: 게임 개요

### 1.1 프로젝트 개요

| 항목 | 내용 |
|------|------|
| **게임 제목** | 실버하벤: 그리드와 심연의 서사시 |
| **플랫폼** | Godot 4.x + 웹 (WASM) |
| **장르** | CRPG (Computer Role-Playing Game) |
| **전투 시스템** | 실시간 + ATB/턴제 혼합 + Pause |
| **세계관** | 자체 설정 "실버하벤 (Silverhaven)" |
| **라이선스** | D&D 5e SRD + 자체 설정 |

### 1.2 개발 목표

- 3개월 내 MVP 완성
- 코드를 모르는 사람도 스킬/몬스터 확장이 가능한 데이터 주도 설계
- JSON 기반 콘텐츠 파이프라인

---

## 제2장: 세계관 - 실버하벤

### 2.1 연대기 개요

실버하벤은 1,000년의 역사를 가진 세계로, 신화의 시대부터 현재까지 4분기로 구분됩니다.

### 2.2 신화의 시대

**태초의 상태:**
- 세상은 형태 없는 **보이드 노이즈(Void Noise)**와 악신 **바알-카르**의 공포 아래 있었습니다.
- 선과 악(바알-카르)의 충돌로 신들이 탄생하고, 종족들의 영혼이 만들어졌습니다.

**삼중 방어선 구축:**
| 방어선 | 위치 | 역할 | 현재 상태 |
|--------|------|------|----------|
| 빙벽 | 북부 (에델바이스) | 악신 봉인 물리 장벽 | 균열 발생, 마왕군 침투 중 |
| 태고의 숲 | 미스트랄 | 정화 필터 + 마계 격리 | 세계수 시들어감, 탁기 침투 |
| 에테르 그리드 | 대륙 전역 | 질서/마력 순환 체계 | 파괴됨, 실버하벤만 부분 가동 |

**⚠️ 숨겨진 진실:** 인간은 지혜를 받은 존재가 아니라, 봉인이 풀리지 않게 감시하도록 설계된 **'살아있는 간수'**에 불과함.

### 2.3 제1분기: 여명과 철혈 (0~250년)

**성왕 퀘이사:** 분열된 부족을 통합하고 8대 왕국을 분봉하며 단일 제국을 선포.

**원죄의 시작:** 오크와 트롤을 유배지로 추방. 남은 아인종을 '건설 노예'로 부려 그리드와 8대 왕궁을 완공.

**⚠️ 숨겨진 진실:** 퀘이사가 신에게 받았다는 힘은 사실 바알-카르와의 계약이었으며, 제국의 번영은 안개의 시대를 저당 잡힌 대가임.

### 2.4 제2분기:황금과 오만 (251~500년)

**마도공학 레네상스:** 부유 도시와 마도 전차 탄생. Gold가 대륙의 유일한 신이 됨.

**종족의 균열:** 엘프는 '보존과 보전'을 이유로 은둔. 폐쇄 드워프들은 지하 관문을 닫음.

**⚠️ 숨겨진 진실:** 아카데미 '루미나스'에서 가르친 고위 마법은 사실 그리드에 과부하를 걸어 악신의 봉인을 갉아먹는 의식이었음.

### 2.5 제3분기: 균열과 부패 (501~750년)

**뒤틀린 과학:** 자원 고갈로 인간 대상 생체 연금술 성행. 8대 왕국 간의 Gold 쟁탈전 격화.

**노예 해방전쟁:** '심연의 사도'들과 손잡은 노예들의 게릴라전 발발. 안개 왕국 미스트랄이 피로 물듦.

**⚠️ 숨겨진 진실:** 해방군은 구원받은 것이 아니라, 그들의 원한을 '노이즈(악신의 숨결)'로 바꾸기 위한 사도들의 제물이 됨.

### 2.6 제4분기: 대붕괴와 현재 (751~1,000년)

**대붕괴(751년):** 그리드 폭발과 함께 안개가 세상을 덮음. 제국 멸망.

**실버하벤(현재):** 안개 왕국 미스트랄 서쪽 끝 요새에 집결한 생존자들. 스크랩 마도공학과 Gold 한 닐에 매달리는 처절한 사투.

**⚠️ 현재의 위기:** 유배지에서 돌아온 오크 5대 부족의 최후통첩. "원죄의 ���가를 치르거나, 안개 속에서 죽거나."

### 2.7 삼중 방어선 파괴의 인과관계

1. 제3분기 (501~750년)
   └─ 심연의 사도들이 루미나스에서 가르치는 마법이 
      그리드 과부하를 유발하는 것이 발견
   └─ 봉인 갉아먹기 시작

2. 제3분기 말~4분기 초
   └─ 노예 해방전쟁 + 사도들의 노이즈 증폭 실험
   └─ 그리드 중추에 "독" 주입

3. 751년 (대붕괴)
   └─ 그리드 폭발 → 삼중 방어선 전체 약화
   └─ 바알-카르의 숨결(노이즈) 대량 방출 → 안개 형성

4. 현재 (1,000년)
   └─ 안개가 대륙을 뒤덮음
   └─ 마왕 크로노스 강림 가능 → 빙벽 균열 확대

---

## 제3장: 종족 시스템

### 3.1 종족 목록

| 번호 | 종족 | 덤프 가능 |特이 사항 |
|------|------|----------|-----------|
| 1 | 인간 | ✅ | 4대 혈통 선택 |
| 2 | 엘프 | ❌ | CON-1, 3대 혈통 |
| 3 | 드워프 | ❌ | 마법-1, 3대 왕국 |
| 4 | 하플링 | ❌ | DEX+2, 3역할+3혈통 |
| 5 | 오크 | ❌ | STR+2, INT-2, 5대 부족 |
| 6 | 트롤 | ❌ | REGEN+1HP/turn, 4대 부족 |
| 7 | 하프오크 | ❌ | 배경 시스템 |
| 8 | 하프트롤 | ❌ | 배경 시스템 |
| 9 | 노움 | ❌ | 2계열 |
| 10 | 다크엘프 | ❌ | 120ft 암시야, 2갈래 |

### 3.2 INT 시스템

| INT 범위 | 말 가능 | NPC 적대감 |
|----------|---------|-----------|
| < 5 | 불가 | - |
| 5~7 | 어눌함 | +30% |
| 8~10 | 기본 | +10% |
| 11+ | 유창 | 0% |

---

## 제4장: 4대 혈통 상세

### 4.1 아이언브러드 (Iron-bloods)

**배경:** 북부 빙벽 수호의 Bloodline. 제국 초기 오크 유배에 가장 앞장섰던 종족입니다.

**역사적 의미:** 성왕 퀘이사와 함께 삼중 방어선 중 '빙벽'의 수호자 역할을 담당했습니다.

**능력치:**
```
STR: +2 | DEX: -1 | CON: +1 | INT: +0 | WIS: +0 | CHA: -1
```

**고유 특성:**
| 특성명 | 효과 | 사용 횟수 |
|--------|------|----------|
| **추위 저항** | Cold 데미지 50% 감소 | دائم |
| **단단한 피부** | 마법 외피 (피해 3 감소) | 1/day |
| **돌진** | Charge 거리가 5ft 증가 | - |

**권장 클래스:** ★★★★★ Fighter, Barbarian | ★★★★☆ Paladin
**권장 스킬:** 검술, 둔기전투, 전술, 해부학, 생존
**피해야 할 스킬:** 마법사용, 은신, 소매치기

**시뮬레이션:**
- 오크 **아이언스컬**의 주요 적대 대상
- 아이언가드 출신은 "형제"로 인식
- "강한 것이 곧 정의"라는 확고한 신념

**시작 배경:**
"아이언가드 군단에서 복무 중이던 중, 갑작스러운 소집으로 
실버하벤 성벽 수비에 투입됨. 습격 당시 하층 지구를 순찰 중이었음."
→ Tutorial 시작 위치: 하층 지구

**시작 장비:** 징발 한손 도끼 + 징발 흉갑 (AC+3) + 아이언가드 문장

---

### 4.2 에테르 가디언 (Ether-Guardians)

**배경:** 마력 감응도가 비정상적으로 높은 Bloodline. 과거 루미나스의 주축입니다.

**역사적 의미:** 삼중 방어선 중 '에테르 그리드'의 관리와 감시를 담당했습니다.

**능력치:**
```
STR: -1 | DEX: +0 | CON: +0 | INT: +2 | WIS: +1 | CHA: +0
```

**고유 특성:**
| 특성명 | 효과 | 사용 횟수 |
|--------|------|----------|
| **에테르 시야** | 암흑 + 30ft, 마법 오라 감지 | دائم |
| **마법 감응 +5%** | 마법 성공률 +5% | - |
| **지식 탐색** | 역사/마법 관련 INT 체크 +2 | - |

**권장 클래스:** ★★★★★ Wizard, Warlock | ★★★★☆ Bard, Sorcerer
**권장 스킬:** 마법사용, 명상, 주문저항, 연금술, 사역술
**피해야 할 스킬:** 궁술, 벌목, 투척

**시뮬레이션:**
- 심연의 사도의 주요 표적 (마력 흡수)
- 노�� 망령과 대화 가능성 최고
- "제국의 진정한 지배층"이라는 자존심

**시작 배경:**
"루미나스 출신으로 실버하벤의 에테르 증폭기 연구자.
Tutorial 시에는 수리반으로 투입될予定이었으나, 
아이언가드 부대 지시를 받음."
→ Tutorial 시작 위치: 증폭기실 근처

**시작 장비:** 연금단검 (마법대미지 1d4) + 마도 로브 (AC+1, 마법저항 5%) + 에테리아 성물

---

### 4.3 솔라 워커 (Solar Walkers)

**배경:** 사막의 태양 아래 길들여진 Bloodline. 멸망 직전의 피난민입니다.

**역사적 의미:** 삼중 방어선 중 '태고의 숲' 외곽을 순찰하며, 사막과 숲의 경계를 감시했습니다.

**능력치:**
```
STR: +1 | DEX: +1 | CON: +0 | INT: -1 | WIS: +0 | CHA: +0
```

**고유 특성:**
| 특성명 | 효과 | 사용 횟수 |
|--------|------|----------|
| **더위 저항** | Fire/Cold 데미지 50% 감소 | دائم |
| **동체 시력** | 은신 적 감지 +5, 후방 공격 +1d4 | - |
| **명중의 축복** | 원거리 공격 첫 히트 시 +2 대미지 | - |

**권장 클래스:** ★★★★★ Ranger, Rogue | ★★★★☆ Fighter
**권장 스킬:** 궁술, 투척, 추적, 생존, 동물학
**피해야 할 스킬:** 사역술, 집중, 명상

**시뮬레이션:**
- 오크의 노예로 전락한 역사가 많음
- 아이언브러드와 마찰 ("고문하던 놈들이야")
- 본 워커 부족과 공통점: "버려진 땅의 생존자"

**시작 배경:**
"솔라리스 왕국의 피난민. 실버하벤에서 고용된 용병.
Tutorial 시 수복파 보조금으로 참여."
→ Tutorial 시작 위치: 서성벽 외벽

**시작 장비:** 복합궁 (위력 低) + 경량 가죽 갑옷 + 태양 표식 목걸이

---

### 4.4 미스트 세일러 (Mist Sailors)

**배경:** 안개와 바다의 Bloodline. 실버하벤의 정보網을 장악하고 있습니다.

**역사적 의미:** 삼중 방어선 중 '안개'와 바다의 경계를 감시하며,密輸入과 침투자를 탐지하는 역할을 담당했습니다.

**능력치:**
```
STR: -1 | DEX: +2 | CON: +0 | INT: +0 | WIS: +1 | CHA: +1
```

**고유 특성:**
| 특성명 | 효과 | 사용 횟수 |
|--------|------|----------|
| **안개 탐지** | 시야 감소 구간에서 DEX 체크 +3 | - |
| **행운의 아류** | 1일 1회 d20 리롤 가능 | 1/day |
| **밀수 천재** | 계약밴드 관련 스킬 +2 | - |

**권장 클래스:** ★★★★★ Rogue, Bard | ★★★★☆ Ranger
**권장 스킬:** 은신, 소매치기, 함정해제, 엿보기, 도발
**피해야 할 스킬:** 전술, 둔기전투, 해부학

**시뮬레이션:**
- 실버하벤 암시장의 실질적 장악자
- "돈이면 다 된다" 현실주의자
- 심연의 사도와 밀접한 거래 관계
- 하플링과天然 동맹

**시작 배경:**
"자유의 항구 출신 밀수상. 실버하벤에서 추궁을 피해 숨어살다가
Tutorial 시 강제 징집됨. 정보 제공 거래로 참전."
→ Tutorial 시작 위치: 하층 지구 뒷골목

**시작 장비:** 단검 x2 + 습식 망토 + 안개 방울 (은신 +10)

---

### 4.5 혈통별 최적/비추천 조합

**최적 조합 ★★★★★**
| 혈통 | 최적 클래스 | 핵심 스탯 | 예상 AC |
|------|------------|----------|--------|
| 아이언브러드 | Fighter | STR 20 | 18~20 |
| 에테르 가디언 | Wizard | INT 20 | 마법 대미지 12d6+ |
| 솔라 워커 | Ranger | DEX 18 | 원거리 명중 +9 |
| 미스트 세일러 | Rogue | DEX 18 | Sneak Attack 6d6 |

**비추천 조합 ★★☆☆☆**
| 혈통 | 비추천 이유 |
|------|-----------|
| 아이언브러드 + Wizard | 마법 시전 불가 |
| 에테르 가디언 + Monk | AC 低 |
| 솔라 워커 + Paladin | CHA 0 → 오라 효과 감소 |
| 미스트 세일러 + Fighter | 방어 중심 ��레�� 어려움 |

---

## 제5장: 스킬 시스템

### 5.1 스킬 카테고리 (총 47개 + 유니크)

| 카테고리 | 수 | 스킬 목록 |
|----------|----|----------|
| **전투** | 8 | 검술, 펜싱, 둔기전투, 궁술, 투척, 검술방어, 전술, 해부학 |
| **마법** | 6 | 마법사용, 사역술, 신비주의, 샤머니즘, 명상, 주문저항 |
| **정신** | 4 | 기공, 집중, 화신, 지술 |
| **제작** | 7 | 연금술, 대장기술, 목공술, 재봉술, 도구제작, 필사술, 마법부여 |
| **채집** | 2 | 벌목, 채광 |
| **탐색** | 2 | 추적, 아이템식별 |
| **생존** | 4 | 치유, 수의학, 동물학, 가축몰이 |
| **잠입** | 7 | 숨기, 은신, 독바르기, 엿보기, 소매치기, 함정해제, 구걸 |
| **특수** | 7 | 무사도, 기사도, 인술, 음악연주, 도발, 불협화음, 진정 |

(중간 생략 - 전체는 data/ 파일 참조)

---

## 제10장: 시각 시스템

### 10.1 시야 범위

| 상태 | 시야 범위 |
|------|----------|
| 일반 | 60ft |
| 암시야 (Darkvision) | 60ft 암흑 시각 |
| 확장 시야 | 120ft (다크엘프) |

### 10.2 안개/노이즈 효과

- 시야 범위 30ft로 감소
- 은신 체크 +5 보너스
- 원거리 공격 disadvantage

---

## 제11장: 게임 시작 사건 시스템

### 11.1 사건 선택 구조

| 사건 | 제목 | 난이도 | 중심 스킬 |
|------|------|--------|----------|
| A | 실버 텅 외교관의 등장 | Easy | 외교, 대화 |
| B | 증폭기 정지 + 지하 기계 발견 | Medium | 기술,潜行 |
| C | 노바 부유 도시 잔해 | Hard | 탐험, 전투 |
| D | Tutorial - 아이런스컬 습격 | Tutorial | 기본 조작 |

---

## 제15장: 숨겨진 진실

### 15.1 공개된 숨겨진 진실

1. **인간은 "살아있는 간수"로 설계됨**
   - 바알-카르를 감시하기 위해 영혼에 "질서 조각"을 이식

2. **성왕 퀘이사는 바알-카르와 계약했음**
   - 제국의 번영은 1,000년 후의 빚

3. **루미나스의 마법은 봉인 갉아먹기 의식**
   - 그리드에 과부하를 걸어 악신의 봉인을 약화시킴

4. **심연의 사도는 노예를 구원한 것이 아니라 제물로 사용**
   - 노예들의 원한을 노이즈로 증폭

5. **안개를 먹는 기계가 마을 지하에 존재**
   - 매일 밤 노예들이 제물로 바쳐짐

6. **8대 왕국이 맺었다는 '비밀 조약'의 진짜 내용**
   - 유배지 영구 소유 vs 오크의 본래 영토 인정

7. **심연의 사도의 정체**
   - 과거 노예 출신으로, 자신의族人을 이용

### 15.2 게임 내 활용

- 퀘스트 보상: **진실 조각 (Truth Fragment)**
- 특정 수확량 달성 시 숨겨진 진실 공개
- 플레이어 선택에 따라 진실의 해석이 달라짐

---

## 부록: 핵심 데이터 요약

### 혈통 능력치

| 혈통 | STR | DEX | CON | INT | WIS | CHA |
|------|-----|-----|-----|-----|-----|-----|
| 아이언브러드 | +2 | -1 | +1 | +0 | +0 | -1 |
| 에테르 가디언 | -1 | +0 | +0 | +2 | +1 | +0 |
| 솔라 워커 | +1 | +1 | +0 | -1 | +0 | +0 |
| 미스트 세일러 | -1 | +2 | +0 | +0 | +1 | +1 |

### 주요 몬스터 CR

| 몬스터 | CR | HP | AC |
|--------|-----|-----|-----|
| 부유 거머리 | 1/8 | 7 | 11 |
| 폭주 고철 골렘 | 3 | 52 | 15 |
| 흑마도 정화기 | 5 | 68 | 13 |
| 노바의 망령 | 6 | 85 | 12 |
| 안개 사도 | 7 | 95 | 14 |
| 빙벽 균열자 | 8 | 110 | 16 |
| 마왕 크로노스 부관 | 10 | 180 | 18 |

### 전투 공식

```
Attack Roll = d20 + Ability Modifier + Proficiency Bonus
Damage = Weapon Dice + Ability Modifier
AC = 10 + 방어구 + DEX + 방패
Initiative = d20 + DEX Modifier
```

---

## 제16장: 미해결 사항 (Plan Mode)

### 16.1 종족/혈통/부족 선택 시스템

| 항목 | 선택지 | 출처 | 상태 |
|------|--------|-----|------|
| 종족 목록 | 10개 (인간, 엘프, 드워프, 하플링, 오크, 트롤, 하프오크, 하프트롤, 노움, 다크엘프) | research_full.md | ✅ 확정 |
| 종족 능력치 | D&D 5e SRD 표준 | D&D 5e SRD | ✅ 확정 |
| 인간 bloodline | 4대 (아이언브러드, 에테르 가디언, 솔라 워커, 미스트 세일러) | bloodlines.json | ✅ 확정 |
| 오크 부족 | 5대 (아이언스컬, 블러드 문, 본 워커, 스카이 팽, 실버 텅) | world_map.md | ✅ 확정 |
| 트롤 부족 | 10대 (은빛침묵, 피의 숨결, 이끼 뿌리, 강철 뼈, 환영의 달, 재가루, 바다 파도, 영혼 사냥꾼, 모래 바람, 서리 이빨) | research_full.md | ✅ 확정 |
| 하플링 | 안개의 자치령 + 3배경 (정보상/밀수상/항구 노동자) | research_full.md | ✅ 확정 |
| 다크엘프 | 2갈래 (노이즈 오염 지역/심연의 사도) | research_full.md | ✅ 확정 |

### 16.2 종족별 선택 흐름

| 종족 | 1단계 | 2단계 | 3단계 |
|------|-------|-------|-------|
| 인간 | bloodline 선택 | 왕국 선택 | - |
| 드워프 | 왕국 선택 | 배경 선택 | - |
| 엘프 | 왕국 선택 | 배경 선택 | - |
| 하플링 | 왕국 선택 | 배경 선택 | - |
| 오크 | 부족 선택 | 배경 선택 | - |
| 트롤 | 부족 선택 (10개) | - | - |
| 하프오크 | 배경 선택 | 왕국 선택 | - |
| 하프트롤 | 배경 선택 | - | - |
| 노움 | bloodline/왕국 선택 | 배경 선택 | - |
| 다크엘프 | 배경 선택 | - | - |

### 16.2 캐릭터 생성 화면

| 항목 | 선택지 | 출처 | 상태 |
|------|--------|-----|------|
| Stat 시스템 | Point Buy (27 포인트) | D&D 5e SRD | ✅ 확정 |
| Class | 8개 (fighter, rogue, wizard, cleric, ranger, barbarian, paladin, bard) | classes.json | ✅ 확정 |
| Background | 기존 bloodlines.json 활용 | bloodlines.json | ✅ 확정 |
| 시작 위치 | Bloodline/부족/왕국에 따라 자동 배정 | research_full.md | ✅ 확정 |
| 초기 장비 | 없음 | 사용자 결정 | ✅ 확정 |

### 16.3 시뮬레이션 관련 (예정)

| 시스템 | 핵심 변수 | 설정 방식 |
|--------|----------|----------|
| 자원 흐름 | food, mineral, magic_crystal | 사용자 선택 |
| 정치 세력 AI | personality_template | 사용자 선택 |
| 사건 발생 | 환경 변수 | 사용자 선택 |
| 세션 변수 | 안개 밀도, 그리드 공명도, 오크 성향 | 사용자 선택 |

### 16.4 구현 순서

| 순서 | 작업 | 파일 | 데이터 의존성 |
|------|------|------|---------------|
| 1 | races.json 작성 | data/races.json | D&D 5e SRD |
| 2 | backgrounds.json 작성 | data/backgrounds.json | bloodlines.json |
| 3 | character_creation.tscn 생성 | scenes/character_creation.tscn | - |
| 4 | character_creation.gd 작성 | scripts/systems/character_creation.gd | races.json, backgrounds.json |

---

### 16.5 종족별 능력치 (D&D 5e SRD)

| 종족 | 능력치 증가 | 특수력 | 비고 |
|------|-------------|---------|------|
| 인간 | +1 전체 | - | bloodline 선택 가능 |
| 엘프 | +2 DEX | Darkvision 60ft, Fey Ancestry | - |
| 드워프 | +2 CON, +1 WIS | Darkvision 60ft, Dwarven Resilience | - |
| 하플링 | +2 DEX, +1 CHA | Lucky, Brave | - |
| 오크 | +2 STR, -2 INT | Aggressive, Menacing | 5대 부족 선택 |
| 드래곤천 | +2 STR, +1 CHA | Breath Weapon, Draconic Resistance | - |
| 노움 | +2 INT, +1 DEX | Darkvision 60ft, Gnome Cunning | - |
| 하프오크 | +2 STR, +1 CON | Relentless Endurance, Aggressive | - |
| 하프트롤 | +2 STR, +1 CON | Regeneration | - |
| 타이플링 | +2 CHA, +1 INT | Hellish Resistance, Infernal Legacy | - |
| 다크엘프 | +2 DEX, +1 CHA | Superior Darkvision 120ft, Fey Ancestry | - |

---

## 제17장: 몬스터 시스템 (D&D 5e SRD + 세션 변수)

### 17.1 기존 몬스터 (monsters.json)

| Category | 몬스터 | CR | HP | AC |
|----------|--------|-----|-----|-----|
| **beast** | 거미 | 1 | 26 | 14 |
| **beast** | 동굴곰 | 2 | 42 | 15 |
| **beast** | 바실리스크 | 3 | 52 | 15 |
| **humanoid** | 고블린 | 1/4 | 7 | 13 |
| **humanoid** | 오크 | 1/2 | 15 | 13 |
| **humanoid** | 다크엘프 | 1 | 13 | 15 |
| **undead** | 해골 | 1/4 | 13 | 12 |
| **aberration** | 마음 잡아吞者 | 7 | 75 | 15 |

### 17.2 새로 추가한 몬스터 (monsters.json)

| Category | 몬스터 | CR | HP | AC |
|----------|--------|-----|-----|-----|
| **beast** | 토끼 | 0 | 3 | 12 |
| **beast** | 사슴 | 0 | 12 | 13 |
| **beast** | 늑대 | 1/4 | 11 | 13 |
| **beast** | 다이어울프 | 1 | 19 | 14 |
| **beast** | 멧돼지 | 1/4 | 11 | 12 |
| **beast** | 곰 | 1/2 | 19 | 12 |
| **beast** | 호랑이 | 2 | 37 | 13 |
| **beast** | 그리즐리 | 2 | 42 | 15 |
| **humanoid** | 코볼드 | 1/8 | 5 | 12 |
| **humanoid** | 버그베어 | 1 | 27 | 16 |
| **undead** | 좀비 | 1/4 | 22 | 8 |
| **undead** | 굴 | 1/4 | 22 | 12 |

### 17.3 세션 변수 몬스터 (monsters_session.json)

| 몬스터 | 조건 | CR | HP | AC |
|--------|------|-----|-----|-----|
| 안개 악마 | fog_density ≥ 0.7 | 2 | 32 | 13 |
| 노이즈 生物 | fog_density ≥ 0.5 | 2 | 28 | 12 |
| 데몬 사냥꾼 | orc_disposition ≥ 4 | 3 | 45 | 14 |
| 공허 구성물 | grid_resonance ≥ 0.7 | 3 | 55 | 16 |
| 심연의 알 | grid_resonance ≥ 0.5 | 2 | 30 | 13 |

### 17.4 몬스터 스폰 공식

```
actual_spawn_count = base_count × fog_mod × orc_mod × grid_mod

fog_mod = 1.0 + (fog_density × 0.3)  [fog ≥ 0.7]
orc_mod = 1.0 + ((orc_disposition - 3) × 0.2)  [orc ≥ 4]
grid_mod = 1.0 + (grid_resonance × 0.3)  [grid ≥ 0.7]
```

### 17.5 드롭 시스템

| DRROP | 공식 |
|------|------|
| Gold | CR 기반 (1d4 ~ 12d10) |
| 아이템 | 50% 확률, CR + 세션 변수 영향 |
| XP | CR 기반 (10 ~ 6200) |

### 17.6 레이어별 몬스터 Pool

| Layer | основні | вторинні |
|-------|--------|----------|
| Surface | - | 토끼, 사슴 |
| LAYER1 | 고블린, 해골, 코볼드 | 쥐, 거미, 좀비 |
| LAYER2 | 오크, 다크엘프, 버그베어 | 늑대, 멧돼지, 굴 |
| LAYER3 | 마음 잡아자, 심연의 사도 | 데몬, 공허, 심연의 알 |

---

## 제18장: 아이템 드롭 시스템

### 18.1 드롭 테이블

| 확률 등급 | 기본확률 | 안개 보너스 | 그리드 보너스 |
|-----------|----------|------------|--------------|
| COMMON | 50% | +15% | +10% |
| UNCOMMON | 25% | +10% | +8% |
| RARE | 10% | +5% | +5% |
| EPIC | 5% | +3% | +3% |
| LEGENDARY | 2% | +1% | +1% |

### 18.2 드롭 아이템 (템플릿)

| 등급 | 아이템 |
|------|--------|
| COMMON | 치유 물약, 횃불, 로프 |
| UNCOMMON | 강력 치유 물약, 해독제, 성수 |
| RARE | 화염구 scroll, 보호 망토, 반지 갑옷 |
| EPIC | 힘의 지杖, 판금 갑옷 |
| LEGENDARY | 유물 |

---

## 제19장: Tutorial 시나리오 구현

### 19.1 Tutorial 흐름

```
session_setup.tscn (세션 변수 선택)
    ↓
character_creation.tscn (캐릭터 생성)
    ↓
main.tscn (메인 게임)
    ↓
scene_selector.tscn (시나리오 선택)
    ↓
tutorial_scenario.gd 실행
```

### 19.2 Tutorial 단계

| 단계 | 설명 | 모드 |
|------|------|------|
| INTRO | 설명 | 실시간 |
| MOVE_TUTORIAL | 마우스 이동 | 실시간 |
| ATTACK_TUTORIAL | SPACE 공격 | 실시간 |
| COVER_TUTORIAL | 커버 시스템 | 실시간 |
| COMBAT_START | 적 2마리 전투 | 턴제 (AP) |
| VICTORY | 완료 | - |

### 19.3 세션 변수 연동 (tutorial_scenario.gd)

| 세션 변수 | 영향 |
|---------|------|
| fog_density ≥ 0.7 | 적 1마리 추가 + HP 스케일링 |
| orc_disposition ≥ 4 | 적 1마리 추가 |
| fog ≥ 0.5 + orc ≥ 3 | 적 1마리 추가 |
| grid_resonance | HP 스케일링 |

### 19.4 Tutorial 적 ([[ 아이런스컬 ]])

| 属性 | 值 |
|------|-----|
| HP | 15 (세션 변수로 증가) |
| CR | 1 |
| XP | 100 |
| 공격 | 단검 (1d6+2) |

---

## 제20장: 개발 Bugfix 노트

### 20.1 2026-04-18

#### Bug: OptionButton (Race/Class) 텍스트가 화면에 표시되지 않음

**증상:**
- TSCN에서 미리 정의된 OptionButton 아이템(item_count=10/8)이 화면에 표시되지 않음
- Bloodline dropdown은 정상显示 (코드에서 add_item()으로 추가됨)
- Debug 출력: item_count는 정상(10/8), selected 텍스트도 정상

**원인:**
- Godot 4.x에서 TSCN에 정의된 OptionButton 아이템은 정적 정의로 처리됨
- 기본 테마 색상이 배경색과 충돌하거나 렌더링 문제가 발생
- 코드에서 `add_item()`으로 동적으로 추가하면 테마가 다시 적용되어 정상 显示

**해결 방법:**
```gdscript
# character_creation.gd - _populate_race_options()에서
func _populate_race_options():
    var option = race_nodes["option"]
    if not option:
        return
    
    option.clear()  # TSCN 정의된 아이템 제거
    var race_names = ["인간", "엘프", "드워프", "하플링", "오크", "트롤", "하프오크", "하프트롤", "노움", "다크엘프"]
    for i in range(race_names.size()):
        option.add_item(race_names[i], i)  # 코드에서 다시 추가
    
    option.select(0)
    _on_race_selected(0)

# _populate_class_options()도 동일한 방식으로 수정
```

**관련 파일:**
- `scripts/systems/character_creation.gd`
- `scenes/character_creation.tscn`

**결과:** Race/Class dropdown이 정상 작동 확인

---

#### Bug: JSON 파싱 실패 (한국어 문자)

**증상:**
- `game_manager.gd:53`, `monster_spawner.gd:49`에서 JSON 파싱 오류
- 오류 메시지: "Parse JSON failed. Error at line 43: Unexpected character"

**원인:**
- `races.json`, `monsters.json` 파일에 한국어 특수문자가 포함됨
- UTF-8 BOM이 파일에 있으나 Godot JSON 파서가 특정 문자 처리 실패

**해결 방법:**
```gdscript
# game_manager.gd - load_races()에서 하드코딩 기본값 추가
func load_races():
    var file = FileAccess.open("res://data/races.json", FileAccess.READ)
    if file:
        var text = file.get_as_text()
        file.close()
        var json = JSON.parse_string(text)
        if json and json is Dictionary:
            races_data = json.get("races", {})
    
    if races_data.is_empty():
        races_data = _get_default_races()  # 하드코딩 기본값 사용

func _get_default_races() -> Dictionary:
    return {
        "human": {"name": "인간", "name_en": "Human", ...},
        "elf": {"name": "엘프", "name_en": "Elf", ...},
        # ... 나머지 종족
    }
```

**결과:** JSON 파싱 실패 시 하드코딩 데이터 사용, 게임 정상 작동

---

#### Bug: session_setup.gd 노드 찾기 실패

**증상:**
- `session_setup.gd:29`에서 "PanelContainer/VBox/SessionNameInput" 노드 못 찾음

**원인:**
- session_setup.tscn의 노드 구조가 PanelContainer/VBox가 아닌 직접 배치
- `get_node()`는 정확한 경로만 찾음

**해결 방법:**
```gdscript
# session_setup.gd - get_node() 대신 find_child() 사용
func _get_nodes():
    name_input = find_child("SessionNameInput", true, true)
    fog_slider = find_child("FogSlider", true, true)
    # ... 나머지 노드도 동일하게 수정
```

**결과:** 노드 정상 찾기 확인

---

#### Bug: Autoload 노드 중복 생성

**증상:**
- session_setup.gd에서 WorldSimulation, MonsterSpawner 노드를 새로 생성하지만, 이미 Autoload로 로드됨

**원인:**
- project.godot에 Autoload로 등록된 노드와 session_setup.gd에서 생성하는 노드 충돌

**해결 방법:**
```gdscript
# session_setup.gd - _create_simulation_nodes() 제거, _configure_simulation() 수정
func _create_simulation_nodes():
    # Autoload nodes already exist - no need to create new ones
    pass

func _configure_simulation():
    var ws = get_node("/root/WorldSimulation")
    if ws and ws.has_method("initialize_new_session"):
        ws.initialize_new_session(fog_density, grid_resonance, orc_disposition)
    # ... 나머지 Autoload 노드들도 동일하게 수정
```

**결과:** Autoload 충돌 해결

---

#### Bug: world_simulation.gd 정수 나누기

**증상:**
- `world_simulation.gd:86`에서 "Integer division. Decimal part will be discarded."

**해결 방법:**
```gdscript
# 수정 전
var idx = int(day_count / 90) % 4

# 수정 후
var idx = int(day_count / 90.0) % 4
```

---

#### Bug: wfc_system.gd Parse Error

**증상:**
- "Parse error" - _init 함수 문제

**해결 방법:**
```gdscript
# 수정 전
func _init(w: int = 20, h: int = 20):
    width = w
    height = h

# 수정 후 - _ready() 사용
func _ready():
    pass

func set_size(w: int, h: int):
    width = w
    height = h
```

---

#### Bug: character_creation.gd Race 선택 시 능력치 미적용

**증상:**
- Race를 선택해도 능력치 보정이 적용되지 않음
- Bloodline 선택 시 능력치 적용은 되지만 Race 보수는 적용 안됨

**원인:**
- races_data.keys()가 alphabetical order로 정렬되어 race_names 배열과 불일치
- `_on_race_selected` signal이 연결되지 않음
- `_apply_bloodline_bonus()`에서 `_apply_race_bonus()` 호출 시 base_stats가 다시 덮어씌워짐

**해결 방법:**
```gdscript
# race_keys 배열 추가 (race_names과 1:1 매핑)
var race_names = ["인간", "엘프", "드워프", ...]
var race_keys = ["human", "elf", "dwarf", ...]

func _on_race_selected(index):
    var race_id = race_keys[index] if index < race_keys.size() else "human"
    current_race = race_id
    # ...

# signal 연결
func _setup_options():
    _populate_race_options()
    _populate_class_options()
    
    if race_nodes.has("option") and race_nodes["option"]:
        race_nodes["option"].item_selected.connect(_on_race_selected)
    # ...

# bloodline bonus 수정
func _apply_bloodline_bonus():
    # bloodline 능력치 먼저 계산
    var new_base = {}
    for stat in base_stats.keys():
        new_base[stat] = 10 + increases.get(stat, 0)
    
    # race bonus 적용 후 bloodline 다시 적용
    _apply_race_bonus(races_data.get(current_race, {}))
    
    for stat in base_stats.keys():
        base_stats[stat] = new_base[stat]
        stats[stat] = new_base[stat]
```

**결과:** Race/Bloodline 선택 시 능력치 정상 적용

---

#### Bug: ui_manager.gd 영어 라벨

**증상:**
- 메인 게임 화면 UI가 영어로 표시됨

**해결 방법:**
```gdscript
# 번역 적용
t.text = "=== 상태 ==="       # STATUS → 상태
t.text = "=== 미니맵 ==="     # MINIMAP → 미니맵
t.text = "=== 장비 ==="      # EQUIPMENT → 장비
t.text = "=== 게임 로그 ==="  # GAME LOG → 게임 로그
skills_button.text = "스킬"   # Skills → 스킬
inv_btn.text = "인벤토리"     # Inventory → 인벤토리
t.text = "인벤토리"          # INVENTORY → 인벤토리
t.text = "스킬"              # Skills → 스킬
```

**결과:** 메인 게임 UI 한국어 표시 확인

---

## 제18장: 종족별 생존 및 분파 전략

### 18.1 드워프: 태도의 분열

| 분파 | 이름 | 위치 | 특징 | 추가 능력치 |
|------|------|------|------|-------------|
| 폐쇄 왕국 | 그라니트 가드 | 빙벽 깊숙한 곳 | 고립주의, 지하 관문 봉쇄 | CON +1, STR +1 |
| 협력 왕국 | 엠버 포지 | 실버하벤 인근 | 실용주의, 에테르 증폭기 수리 | INT +1, WIS +1 |
| 야생 부족 | 스카이 해머 | 산맥 정상 | 룬 마법, 트롤과 교류/게릴라전 | DEX +1, CHA +1 |

### 18.2 엘프: 보존의 성역 (8개 분파)

| 분파 | 핵심 가치 | 특징 | 추가 능력치 |
|------|----------|------|-------------|
| **은빛 잎 왕국 (에테리아)** | 절대적 보전과 정치 | 강력한 결계 안에서 시간이 멈춘 듯한 삶을 살며 멸종 위기종을 보호, 외부 전쟁에 냉소적 | WIS +2 |
| **노이즈 워커** | 오염의 기록과 억제 | 보이드 노이즈에 오염된 지역에서 기계화된 신체로 저항, 악신의 봉인 감시 | CON +1, INT +1 |
| **루미나스 유민** | 잊혀진 마법 지식의 회수 | 과거 루미나스 아카데미 출신, 마법 스크롤 회수, 자신들이 만든 마법이 봉인을 갉아먹었다는 죄책감 | INT +2 |
| **미스트랄 추격대** | 실용적 생존과 안개 정화 | 실버하벤 인근 숲에서 활동, 기계 부품 구하거나 물자 보급 협력 | DEX +1, WIS +1 |
| **그리드 아키텍트** | 에테르 질서의 재건 | 파괴된 에테르 그리드 수리, 마을 지하 기계/증폭기 관리 | INT +1, DEX +1 |
| **붉은 이슬 부족** | 원한의 승화 | 노예 해방전쟁 때 제물로 바쳐진 엘프들의 후손, 영혼과 대화, 동족 영혼 해방 장례 의식 | WIS +1, CHA +1 |
| **수정 혈맥 부족** | 자원의 보존 | 드워프와 협력하여 지하 마력 수정 보호, 생체 연금술 연구 | STR +1, INT +1 |
| **안개 세일러** | 단절된 대륙의 연결 | 안개와 바다 경계에서 유목, 미스트 세일러와 밀거래, 특수 에테르 항법 | DEX +2 |

> **참고:** 미스트랄은 하플링의 안개의 자치령과 관련 있으나, 엘프 분파인 "미스트랄 추격대"와는 별도 존재

### 18.3 하플링: 안개의 주인

<!-- duplicate block removed -->

### 18.3 하플링: 안개의 주인

| 분파 | 이름 | 위치 | 특징 | 추가 능력치 |
|------|------|------|------|-------------|
| 안개의 자치령 | - | 안개 속 | 물자 수송/정보망 | DEX +1, CHA +1 |

### 18.4 오크 부족

| 부족 | 위치 | 특징 | 추가 능력치 |
|------|------|------|-------------|
| 아이언스컬 | - | - | STR +2 |
| 블러드 문 | - | - | CON +1, CHA +1 |
| 본 워커 | - | - | INT +1 |
| 스카이 팽 | 동서 산악 | 와이번/절벽늑대 | DEX +2 |
| 실버 텅 | - | - | CHA +1 |

### 18.5 트롤 부족 (10대)

| 부족 | 중심 구루 | 특징 | 추가 능력치 |
|------|-----------|------|-------------|
| 은빛침묵 부족 | 나함 | 정신 감응, 환영/정신 지배, 역사 기록자 | WIS +2 |
| 피의 숨결 부족 | 보르카 | 혈액 마법, 재생 능력 극대화 | CON +2 |
| 이끼 뿌리 부족 | 오룸 | 식물과 공생, 덩굴 포획 | CON +1, WIS +1 |
| 강철 뼈 부족 | 크로그 | 기계공학, 중갑/병기 설계 | STR +1, INT +1 |
| 환영의 달 부족 | 여울 | 밤 활동, 별점점, 투명화 은신 | DEX +2 |
| 재가루 부족 | 이그니스 | 불 숭배, 화염 마법 | INT +1, CHA +1 |
| 바다 파도 부족 | 심해 | 파도 조종, 해수수 조종 | CON +1, CHA +1 |
| 영혼 사냥꾼 부족 | 라즈 | 영혼 소환, 영혼석 제작 | WIS +2 |
| 모래 바람 부족 | 자말 | 모래 조종, 신기루 창조 | DEX +2 |
| 서리 이빨 부족 | 울프릭 | 냉기 마법, 얼음 피부 | CON +2 |
---

| 부족 | 중심 구루 | 특징 | 추가 능력치 |
|------|-----------|------|-------------|
| 은빛침묵 부족 | 나함 | 정신 감응, 환영/정신 지배, 역사 기록자 | WIS +2 |
| 피의 숨결 부족 | 보르카 | 혈액 마법, 재생 능력 극대화 | CON +2 |
| 이끼 뿌리 부족 | 오룸 | 식물과 공생, 덩굴 포획 | CON +1, WIS +1 |
| 강철 뼈 부족 | 크로그 | 기계공학, 중갑/병기 설계 | STR +1, INT +1 |
| 환영의 달 부족 | 여울 | 밤 활동, 별점점, 투명화 은신 | DEX +2 |
| 재가루 부족 | 이그니스 | 불 숭배, 화염 마법 | INT +1, CHA +1 |
| 바다 파도 부족 | 심해 | 파도 조종, 해수수 조종 | CON +1, CHA +1 |
| 영혼 사냥꾼 부족 | 라즈 | 영혼 소환, 영혼석 제작 | WIS +2 |
| 모래 바람 부족 | 자말 | 모래 조종, 신기루 창조 | DEX +2 |
| 서리 이빨 부족 | 울프릭 | 냉기 마법, 얼음 피부 | CON +2 |

### 18.6 하프오크 선택 흐름

```
하프오크 선택 → 배경 선택 (노예/부랑아/고아/용병) → 특정 배경 시 왕국 선택
```

### 18.7 하프트롤 선택 흐름

```
하프트롤 선택 → 배경 선택 (노예/부랑아/고아/용병) → (하프오크와 유사)
```

### 18.8 노움 선택 흐름

```
노움: bloodline/왕국 선택 → 배경 선택 (연금술사/일루져니스트)
```

### 18.9 다크엘프 선택 흐름

```
다크엘프: 배경 선택 (노이즈 오염 지역/심연의 사도)
```

---

**문서 끝 (전체 백업)**
- 
- Korean-English bilingual note:
- The Orc Bloodline Expansion Plan is provided in both languages below for clarity.

## 4. Orc Bloodline Expansion Plan / 오크 혈통 확장 계획

- 목표: Orc의 기본 5개 부족(clan_options)은 유지합니다. Bloodline은 지역(region) 기반의 독립 모델로 확장하되, 필요 시 다지역 확장도 가능하도록 설계합니다. Bloodline의 시작 위치(starting_location) 및 region 정보를 지역별로 저장하고 활용합니다. 지역 명칭은 한국어 표기로 기록하되, 다국어 지원 시 영어 원문 매핑도 가능하도록 구조화합니다.
- Region naming (Korean): 노스랜드(Northlands), 숲지대(ForestReach), 강 삼각주(RiverDelta), 해안 절벽(CoastalCliffs), 산맥 고개(MountainPass)
- Data model (Orc Bloodline): bloodline_options added under data/races.json, with fields id, name, description, region, region_kor, starting_location, ability_bonus, requires_kingdom
- Example bloodline item: { "id": "orc_bloodline_iron", "name": "아이언 혈맥", "description": "강철 심장과 전쟁의 의지", "region": "Northlands", "region_kor": "노스랜드", "starting_location": "IronKeep", "ability_bonus": {"STR": 1, "CON": 1}, "requires_kingdom": true }
- Data migration: add bloodline_options to Orc, seed 3-5 early, ensure backward compatibility
- UI: Bloodline 영역은 region-based Bloodlines로 표시, Orc 선택 시 ClanOptions는 유지, Bloodline은 region-based로 표시
- Start positions: bloodline.region + bloodline.starting_location
- Testing: Orc selection shows 5 clans; Bloodline region appears; Bloodline selection updates starting_location; regression checks for existing flows

## 4. Orc Bloodline Expansion Plan / 오크 혈통 확장 계획 (English)

- Goal: Keep Orc clans at 5 options; introduce Bloodline as a region-based, independent model with optional multi-region expansion
- Region naming: Northlands, ForestReach, RiverDelta, CoastalCliffs, MountainPass (Korean equivalents noted above)
- Data model: add bloodline_options under data/races.json for orc; fields: id, name, description, region, region_kor, starting_location, ability_bonus, requires_kingdom
- Example bloodline item: { "id": "orc_bloodline_iron", "name": "Iron Bloodline", "description": "Iron heart and will to war", "region": "Northlands", "region_kor": "노스랜드", "starting_location": "IronKeep", "ability_bonus": {"STR": 1, "CON": 1}, "requires_kingdom": true }
- Migration plan: extend Orc bloodline_options, seed 3-5 samples, merge into runtime loading
- UI: Bloodline area shows region-based Bloodlines; Orc clans remain 5; Bloodline expansion is independent
- Start positions: Bloodline region + starting_location used to compute starting location
- Testing: confirm 5 clans display, new Bloodlines load, starting_location reflects Bloodline region, regression checks
