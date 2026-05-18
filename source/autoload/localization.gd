# localization.gd — UI 문자열 중앙 관리 (한글(English) 형식).
# autoload: Localization
# 사용법: Localization.t("key") 또는 Localization.t("key", [args])

extends Node

## UI 문자열 사전. 키는 snake_case, 값은 한글(English) 형식.
const UI_STRINGS: Dictionary = {
	# ── 장비 패널 ──
	"panel_title": "캐릭터 스테이터스",
	"section_equipment": "장비(Equipment)",
	"section_inventory": "보관함(Inventory)",
	"slot_head": "머리(Head)",
	"slot_necklace": "목걸이(Necklace)",
	"slot_right_hand": "오른손(Right Hand)",
	"slot_left_hand": "왼손(Left Hand)",
	"slot_body": "몸통(Body)",
	"slot_belt": "허리(Belt)",
	"slot_cloak": "망토(Cloak)",
	"slot_ring_1": "반지 1(Ring 1)",
	"slot_ring_2": "반지 2(Ring 2)",
	"slot_gloves": "장갑(Gloves)",
	"slot_boots": "신발(Boots)",
	"btn_equip": "장착(Equip)",
	"btn_unequip": "해제(Unequip)",
	"btn_use": "사용(Use)",
	"btn_no_ammo": "탄약 부족(No Ammo)",
	"empty_slot": "(비어있음)",
	"empty_inventory": "(보관함 없음)",
	"unknown_item": "(알 수 없음)",

	# ── HUD ──
	"hp_label": "체력(HP): %d / %d",
	"ap_label": "행동(AP): %d / %d",
	"gold_label": "골드(Gold): %d",
	"mode_realtime": "실시간(Realtime)",
	"mode_turnbased": "턴제(Turn-based)",
	"round_label": "라운드(Round) %d",
	"turn_label": "%s의 턴",
	"miss_text": "빗나감(MISS)",
	"enemy_default": "적(Enemy)",
	"unknown_default": "알 수 없음(Unknown)",
	"dist_label": "거리: %d",

	# ── 액션 바 ──
	"btn_attack": "공격(Attack)",
	"btn_push": "밀치기(Push)",
	"btn_item": "아이템(Item)",
	"btn_wait": "대기(Wait)",

	# ── 타겟팅 ──
	"target_hp": "체력(HP): %d/%d",

	# ── 파생 스탯 ──
	"stat_hp": "체력(HP)",
	"stat_atk": "공격(ATK)",
	"stat_def": "방어(DEF)",
	"stat_acc": "명중(ACC)",
	"stat_eva": "회피(EVA)",
	"stat_init": "선제(INIT)",
	"stat_magic": "마법(Magic)",
	"stat_resist": "저항(Resist)",
	"stat_price": "가격(Price)",

	# ── 이벤트 로그 ──
	"log_title": "로그",
}


## 문자열 조회. args가 있으면 % 포맷팅 적용.
## 키가 없으면 키 자체를 반환 (디버깅 용이).
static func t(key: String, args = []) -> String:
	var s: String = UI_STRINGS.get(key, key)
	if args is Array and not args.is_empty():
		return s % args
	return s
