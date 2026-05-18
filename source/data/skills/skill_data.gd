# skill_data.gd — 13개 스킬 정의 (상수 방식, .tres 불필요).
# CombatResolver, Unit, equipment_panel에서 참조.
class_name SkillData
extends RefCounted

## 스킬 정의: {id: {name, type, accuracy_per_100, damage_per_100, evasion_per_100, str, dex, con, int, wis}}
const SKILLS: Dictionary = {
	# ── 무기 스킬 (WEAPON) ──
	"swordsmanship": {
		name = "검술(Swordsmanship)",
		type = 0,  # WEAPON
		accuracy = 0.5,    # GM 시 +50 명중
		damage = 0.3,      # GM 시 +30% 데미지
		evasion = 0.0,
		str = 0.1, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0,
	},
	"spear": {
		name = "창술(Spear)",
		type = 0,
		accuracy = 0.5,
		damage = 0.35,     # 창술은 약간 높은 데미지
		evasion = 0.0,
		str = 0.1, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0,
	},
	"fencing": {
		name = "펜싱(Fencing)",
		type = 0,
		accuracy = 0.6,    # 가장 높은 명중
		damage = 0.2,
		evasion = 0.1,     # 회피 보너스
		str = 0.0, dex = 0.1, con = 0.0, int = 0.0, wis = 0.0,
	},
	"mace_fighting": {
		name = "둔기(Mace Fighting)",
		type = 0,
		accuracy = 0.4,
		damage = 0.4,      # 높은 데미지
		evasion = 0.0,
		str = 0.1, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0,
	},
	"archery": {
		name = "궁술(Archery)",
		type = 0,
		accuracy = 0.5,
		damage = 0.3,
		evasion = 0.0,
		str = 0.0, dex = 0.1, con = 0.0, int = 0.0, wis = 0.0,
	},
	"wrestling": {
		name = "격투(Wrestling)",
		type = 0,
		accuracy = 0.3,
		damage = 0.1,
		evasion = 0.2,     # 높은 회피
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0,
	},

	# ── 보조 스킬 (SUPPORT) ──
	"tactics": {
		name = "전술(Tactics)",
		type = 1,  # SUPPORT
		accuracy = 0.0,
		damage = 0.5,      # 물리 데미지 증가
		evasion = 0.0,
		str = 0.05, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0,
	},
	"anatomy": {
		name = "해부학(Anatomy)",
		type = 1,
		accuracy = 0.0,
		damage = 0.2,      # 치명타 관련
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.05, wis = 0.0,
	},
	"healing": {
		name = "치료(Healing)",
		type = 1,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.05, int = 0.0, wis = 0.05,
	},
	"prayer": {
		name = "기도(Prayer)",
		type = 1,
		accuracy = 0.0,
		damage = 0.15,     # 신성 버프 데미지 증가
		evasion = 0.1,     # 기도 시 회피 보너스
		str = 0.0, dex = 0.0, con = 0.1, int = 0.0, wis = 0.1,
	},
	"resisting_spells": {
		name = "마법저항(Resisting Spells)",
		type = 1,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.3,     # 마법 회피
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.05,
	},

	# ── 마법 스킬 (MAGIC) ──
	"magery": {
		name = "마법학(Magery)",
		type = 2,  # MAGIC
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.2, wis = 0.0,
	},
	"meditation": {
		name = "명상(Meditation)",
		type = 2,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.1,
	},
	"eval_int": {
		name = "지능측정(Evaluating Intelligence)",
		type = 2,
		accuracy = 0.0,
		damage = 0.4,      # 마법 데미지 증가
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.15, wis = 0.0,
	},
	"divinity": {
		name = "신성학(Divinity)",
		type = 2,
		accuracy = 0.0,
		damage = 0.35,     # 신성 마법 데미지 증가
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.1, wis = 0.15,
	},

	# ── 유틸 스킬 (UTILITY) ──
	"hiding": {
		name = "은신(Hiding)",
		type = 3,  # UTILITY
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.3,     # 은신 시 회피
		str = 0.0, dex = 0.2, con = 0.0, int = 0.0, wis = 0.0,
	},
	"tracking": {
		name = "추적술(Tracking)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.1, con = 0.0, int = 0.0, wis = 0.1,
	},
	"musicianship": {
		name = "악기연주(Musicianship)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.05, cha = 0.15,
	},
	"dancing": {
		name = "춤추기(Dancing)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.25,    # 춤 동작 시 회피 보너스
		str = 0.0, dex = 0.15, con = 0.0, int = 0.0, wis = 0.0, cha = 0.1,
	},
	"provocation": {
		name = "도발(Provocation)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0, cha = 0.2,
	},
	"peacemaking": {
		name = "평온(Peacemaking)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.15,    # 평온 시 회피 보너스
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.05, cha = 0.1,
	},
	"discordance": {
		name = "불협화음(Discordance)",
		type = 3,
		accuracy = 0.0,
		damage = 0.25,     # 대상 약화 → 간접 데미지 증가
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.0, cha = 0.2,
	},
	"detecting_hidden": {
		name = "은신 탐색(Detecting Hidden)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.1, wis = 0.15, cha = 0.0,
	},
	"stealth": {
		name = "은신 이동(Stealth)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.35,    # 은신 이동 시 높은 회피
		str = 0.0, dex = 0.2, con = 0.0, int = 0.0, wis = 0.0, cha = 0.0,
	},
	"stealing": {
		name = "훔치기(Stealing)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.25, con = 0.0, int = 0.0, wis = 0.0, cha = 0.0,
	},
	"snooping": {
		name = "훔쳐보기(Snooping)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.1, con = 0.0, int = 0.1, wis = 0.05, cha = 0.0,
	},
	"forensic_eval": {
		name = "법의학(Forensic Evaluation)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.2, wis = 0.05, cha = 0.0,
	},
	"animal_taming": {
		name = "동물 조련(Animal Taming)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.1, cha = 0.15,
	},
	"animal_lore": {
		name = "동물 지식(Animal Lore)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.15, wis = 0.1, cha = 0.0,
	},
	"herding": {
		name = "몰이(Herding)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.0, int = 0.0, wis = 0.15, cha = 0.1,
	},
	"veterinary": {
		name = "수의학(Veterinary)",
		type = 3,
		accuracy = 0.0,
		damage = 0.0,
		evasion = 0.0,
		str = 0.0, dex = 0.0, con = 0.1, int = 0.0, wis = 0.15, cha = 0.0,
	},
}


## 스킬 콤보 정의: [요구 스킬 배열] → {name, effect, chance/passive}
const SKILL_COMBOS: Dictionary = {
	"stun_punch": {
		skills = ["anatomy", "wrestling"],
		name = "스턴펀치(Stun Punch)",
		effect = "4초 마비",
		chance = 0.15,
		passive = false,
	},
	"disarm": {
		skills = ["arms_lore", "wrestling"],
		name = "디스암(Disarm)",
		effect = "적 무기 낙하",
		chance = 0.10,
		passive = false,
	},
	"emergency_heal": {
		skills = ["anatomy", "healing"],
		name = "응급처치(Emergency Heal)",
		effect = "힐링량 50% 증가",
		passive = true,
	},
	"power_strike": {
		skills = ["lumberjacking", "swordsmanship"],
		name = "파워스트라이크",
		effect = "도끼 25% 추가데미지",
		passive = true,
	},
}
