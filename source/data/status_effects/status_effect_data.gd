# status_effect_data.gd — 상태이상/버프/디버프 정의.
# 폭탄, 스킬, 아이템 사용 시 참조.
class_name StatusEffectData
extends RefCounted

## 상태이상 타입
enum Type {
	BUFF = 0,    # 버프 (긍정)
	DEBUFF = 1,  # 디버프 (부정)
	NEUTRAL = 2, # 중립 (고정/지형 등)
}

## 지속 시간 단위
enum DurationUnit {
	TURN = 0,    # 턴 기준
	ACTION = 1,  # 행동 기준
	INSTANT = 2, # 즉시
}

## 효과 정의: {id: {name, type, duration, description, ...}}
const EFFECTS: Dictionary = {
	# ── 원소 피해 (ELEMENTAL) ──
	"burning": {
		name = "화상(Burning)",
		type = Type.DEBUFF,
		duration = 3,
		unit = DurationUnit.TURN,
		description = "턴당 화염 5",
	},
	"acid": {
		name = "산성(Acid)",
		type = Type.DEBUFF,
		duration = 3,
		unit = DurationUnit.TURN,
		description = "방어구 -3",
	},
	"radiant": {
		name = "신성(Radiant)",
		type = Type.DEBUFF,
		duration = 1,
		unit = DurationUnit.TURN,
		description = "언데드에게 2배 피해",
	},

	# ── 상태 디버프 (CONDITION DEBUFF) ──
	"flat_footed": {
		name = "방심(Flat-footed)",
		type = Type.DEBBUFF,
		duration = 1,
		unit = DurationUnit.TURN,
		description = "회피 불가, 후방 공격 판정",
	},
	"slowed": {
		name = "이동 감속(Slowed)",
		type = Type.DEBUFF,
		duration = 2,
		unit = DurationUnit.TURN,
		description = "이동속도 -50%",
	},
	"deafened": {
		name = "청각 상실(Deafened)",
		type = Type.DEBUFF,
		duration = 2,
		unit = DurationUnit.TURN,
		description = "음성/주문 실패 확률 +30%",
	},
	"rooted": {
		name = "속박(Rooted)",
		type = Type.DEBUFF,
		duration = 3,
		unit = DurationUnit.TURN,
		description = "이동 불가",
	},
	"confused": {
		name = "혼란(Confused)",
		type = Type.DEBUFF,
		duration = 1,
		unit = DurationUnit.TURN,
		description = "아군/적 구분 불가, 무작위 행동",
	},

	# ── 버프 (BUFF) ──
	"haste": {
		name = "가속(Haste)",
		type = Type.BUFF,
		duration = 3,
		unit = DurationUnit.TURN,
		description = "이동속도 +50%, 행동 +1",
	},
	"fortify": {
		name = "강화(Fortify)",
		type = Type.BUFF,
		duration = 3,
		unit = DurationUnit.TURN,
		description = "방어력 +5",
	},
	"regen": {
		name = "재생(Regeneration)",
		type = Type.BUFF,
		duration = 5,
		unit = DurationUnit.TURN,
		description = "턴당 HP +5",
	},
}
