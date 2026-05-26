# class_data.gd — 모든 직업/서브클래스/해금 정의.
# 캐릭터 생성: STARTING_CLASSES 중 선택.
# 서브클래스: base 클래스 유지 + 특화 경로.
# 해금: 조건 충족 시 새 직업으로 전환 가능.
extends RefCounted
class_name ClassData

# ── 모든 직업 데이터 ──
static func classes() -> Dictionary:
	return {
	"fighter": {
		display_name = "전사(Fighter)",
		description = "근접전 특화. 높은 HP와 데미지.",
		skill_levels = {
			"swordsmanship": 50.0,
			"tactics": 50.0,
			"anatomy": 30.0,
		},
		stat_modifiers = {strength = 3, dexterity = 1, constitution = 2, intelligence = -1, wisdom = 0, charisma = -1},
		skill_caps = {tactics = 110},
	},
	"mage": {
		display_name = "마법사(Mage)",
		description = "마법 특화. 낮은 HP, 높은 마법 데미지.",
		skill_levels = {
			"magery": 50.0,
			"eval_int": 50.0,
			"meditation": 30.0,
			"fencing": 25.0,
		},
		stat_modifiers = {strength = -2, dexterity = 0, constitution = -1, intelligence = 3, wisdom = 2, charisma = 0},
		skill_caps = {magery = 110, eval_int = 110},
	},
	"ranger": {
		display_name = "레인저(Ranger)",
		description = "원거리 특화. 높은 회피와 추적.",
		skill_levels = {
			"archery": 50.0,
			"tracking": 40.0,
			"herding": 30.0,
			"swordsmanship": 25.0,
		},
		stat_modifiers = {strength = 0, dexterity = 3, constitution = 0, intelligence = 1, wisdom = 2, charisma = -1},
		skill_caps = {archery = 110, tracking = 110},
	},
	"rogue": {
		display_name = "로그(Rogue)",
		description = "기습 특화. 높은 치명타와 은신.",
		skill_levels = {
			"fencing": 50.0,
			"hiding": 40.0,
			"anatomy": 30.0,
		},
		stat_modifiers = {strength = -1, dexterity = 3, constitution = -1, intelligence = 1, wisdom = 0, charisma = 2},
		skill_caps = {fencing = 110, hiding = 110},
	},
	"barbarian": {
		display_name = "바바리안(Barbarian)",
		description = "야만 전투 특화. 광전사의 막강한 파괴력.",
		skill_levels = {
			"mace_fighting": 50.0,
			"tactics": 40.0,
			"anatomy": 30.0,
		},
		stat_modifiers = {strength = 3, dexterity = 0, constitution = 3, intelligence = -2, wisdom = -1, charisma = -1},
		skill_caps = {mace_fighting = 110},
	},
	"paladin": {
		display_name = "성기사(Paladin)",
		description = "방어+신성 마법 특화. 높은 HP, 마법 내성.",
		skill_levels = {
			"mace_fighting": 50.0,
			"divinity": 50.0,
			"prayer": 30.0,
		},
		stat_modifiers = {strength = 2, dexterity = 0, constitution = 3, intelligence = -2, wisdom = 1, charisma = 0},
		skill_caps = {divinity = 110},
	},
	"bard": {
		display_name = "음유시인(Bard)",
		description = "지원+군중제어 특화. 도발/평온/불협화음.",
		skill_levels = {
			"musicianship": 50.0,
			"provocation": 40.0,
			"dancing": 30.0,
			"fencing": 25.0,
		},
		stat_modifiers = {strength = -2, dexterity = 1, constitution = 0, intelligence = 1, wisdom = 2, charisma = 2},
		skill_caps = {musicianship = 110, provocation = 110},
	},
	"monk": {
		display_name = "무도가(Monk)",
		description = "격투+회피 특화. 장비 없이도 강력.",
		skill_levels = {
			"wrestling": 50.0,
			"meditation": 40.0,
			"anatomy": 30.0,
		},
		stat_modifiers = {strength = 2, dexterity = 2, constitution = 0, intelligence = 0, wisdom = 1, charisma = -1},
		skill_caps = {wrestling = 110},
	},
	"cleric": {
		display_name = "사제(Cleric)",
		description = "치유+신성 마법 특화. 아군 지원, 회복.",
		skill_levels = {
			"divinity": 50.0,
			"healing": 50.0,
			"prayer": 30.0,
			"mace_fighting": 25.0,
		},
		stat_modifiers = {strength = -1, dexterity = 0, constitution = 1, intelligence = 2, wisdom = 2, charisma = 0},
		skill_caps = {divinity = 110, healing = 110},
	},
	"druid": {
		display_name = "드루이드(Druid)",
		description = "자연 마법+치유 특화. 자연의 힘으로 공격과 회복.",
		skill_levels = {
			"nature_magic": 50.0,
			"healing": 50.0,
			"animal_lore": 30.0,
			"mace_fighting": 25.0,
		},
		stat_modifiers = {strength = -2, dexterity = 0, constitution = 1, intelligence = 1, wisdom = 3, charisma = 1},
		skill_caps = {nature_magic = 110},
	},
	"tamer": {
		display_name = "조련사(Tamer)",
		description = "동물 조련+수의학 특화. 야생동물 길들이기, 동물 치료.",
		skill_levels = {
			"animal_taming": 50.0,
			"animal_lore": 50.0,
			"veterinary": 30.0,
			"spear": 25.0,
		},
		stat_modifiers = {strength = 0, dexterity = 1, constitution = 1, intelligence = 0, wisdom = 3, charisma = 1},
		skill_caps = {animal_taming = 110},
	},
	"alchemist": {
		display_name = "연금술사(Alchemist)",
		description = "포션+폭탄 제작 특화. 약초학+연금술 시너지.",
		skill_levels = {
			"alchemy": 50.0,
			"herbalism": 50.0,
			"anatomy": 30.0,
			"fencing": 25.0,
		},
		stat_modifiers = {strength = -1, dexterity = 0, constitution = 0, intelligence = 3, wisdom = 2, charisma = 0},
		skill_caps = {alchemy = 110},
	},
	"blacksmith": {
		display_name = "대장장이(Blacksmith)",
		description = "금속 무기/갑옷 제작. 높은 STR과 내구력.",
		skill_levels = {
			"blacksmithy": 50.0,
			"mining": 50.0,
			"arms_lore": 30.0,
			"mace_fighting": 25.0,
		},
		stat_modifiers = {strength = 3, dexterity = 0, constitution = 2, intelligence = 0, wisdom = 0, charisma = -1},
		skill_caps = {blacksmithy = 110},
	},
	"samurai": {
		display_name = "사무라이(Samurai)",
		description = "양손무기+분신술 특화. 무사도+검술.",
		skill_levels = {
			"bushido": 50.0,
			"swordsmanship": 50.0,
			"parrying": 30.0,
		},
		stat_modifiers = {strength = 2, dexterity = 2, constitution = 1, intelligence = 0, wisdom = 1, charisma = -1},
		skill_caps = {bushido = 110, swordsmanship = 110},
	},
	"necromancer": {
		display_name = "네크로멘서(Necromancer)",
		description = "어둠 마법+흡혈 특화. 사령술+주술.",
		skill_levels = {
			"necromancy": 50.0,
			"mysticism": 50.0,
			"spirit_speak": 30.0,
			"swordsmanship": 25.0,
		},
		stat_modifiers = {strength = -2, dexterity = 0, constitution = 0, intelligence = 3, wisdom = 2, charisma = -1},
		skill_caps = {necromancy = 110, mysticism = 110},
	},
	# ── 해금 직업 (시작 불가, 스킬 조건 충족 시 전환 가능) ──
	"assassin": {
		display_name = "어쌔신(Assassin)",
		description = "맹독과 암살에 특화된 위험한 암살자.",
		skill_levels = {
			"fencing": 50.0,
			"hiding": 40.0,
			"poisoning": 30.0,
		},
		stat_modifiers = {strength = -1, dexterity = 3, constitution = -1, intelligence = 1, wisdom = 0, charisma = 2},
		skill_caps = {fencing = 110, poisoning = 110},
	},
	"knight": {
		display_name = "기사(Knight)",
		description = "방패+중갑 방어형 전사. 검술과 패링으로 전장을 지배.",
		skill_levels = {
			"swordsmanship": 50.0,
			"parrying": 50.0,
			"tactics": 30.0,
		},
		stat_modifiers = {strength = 2, dexterity = 1, constitution = 2, intelligence = 0, wisdom = 1, charisma = 1},
		skill_caps = {parrying = 110},
	},
	"warlock": {
		display_name = "흑마법사(Warlock)",
		description = "암흑 마법 특화. 영매술로 어둠의 힘을 다룸.",
		skill_levels = {
			"magery": 50.0,
			"spirit_speak": 40.0,
			"eval_int": 30.0,
		},
		stat_modifiers = {strength = -2, dexterity = 0, constitution = -1, intelligence = 3, wisdom = 1, charisma = 0},
		skill_caps = {magery = 110, spirit_speak = 110},
	},
}

# ── 캐릭터 생성 시 선택 가능한 직업 ──
const STARTING_CLASSES: PackedStringArray = [
	"fighter",
	"mage",
	"ranger",
	"rogue",
	"barbarian",
	"paladin",
	"bard",
	"monk",
	"cleric",
	"druid",
	"tamer",
	"alchemist",
	"blacksmith",
	"samurai",
]

# ── 서브클래스 ──
# 서브클래스(Subclass) = base 클래스의 특화 경로.
# - 캐릭터 생성 시 선택한 base 클래스는 평생 유지.
# - 조건(특정 스킬 min_level 이상) 충족 시 서브클래스 선택 가능.
# - 서브클래스 선택 시 bonus_skills가 현재 스킬에 추가/오버라이드됨.
# - 서브클래스는 추가 전직 개념이 아니라 동일 직업 내 성장 방향.
#   (예: 메이지가 사령술을 익히면 → 네크로멘서 서브클래스, 여전히 메이지)
static func subclasses() -> Dictionary:
	return {
	# ── 전사(Fighter) ──
	"fighter": {
		"gladiator": {
			display_name = "검투사(Gladiator)",
			description = "전장의 기술을 극한까지 연마한 검투사.",
			require_skill = "tactics",
			min_level = 30.0,
			bonus_skills = {swordsmanship = 50.0, tactics = 40.0},
			bonus_caps = {swordsmanship = 120, tactics = 120},
		},
	},
	# ── 마법사(Mage) ──
	"mage": {
		"necromancer": {
			display_name = "네크로멘서(Necromancer)",
			description = "어둠 마법과 흡혈에 특화된 강령술사.",
			require_skill = "necromancy",
			min_level = 30.0,
			bonus_skills = {necromancy = 50.0, mysticism = 40.0, spirit_speak = 30.0},
			bonus_caps = {necromancy = 120, mysticism = 120},
		},
	},
	# ── 레인저(Ranger) ──
	"ranger": {
		"scout": {
			display_name = "정찰병(Scout)",
			description = "정찰과 은신에 특화된 레인저.",
			require_skill = "tracking",
			min_level = 30.0,
			bonus_skills = {tracking = 50.0, stealth = 30.0},
			bonus_caps = {tracking = 120},
		},
	},
	# ── 로그(Rogue) ──
	"rogue": {
		"ninja": {
			display_name = "닌자(Ninja)",
			description = "은신 이동과 표창술에 특화된 도적.",
			require_skill = "stealth",
			min_level = 30.0,
			bonus_skills = {stealth = 50.0, throwing = 40.0},
			bonus_caps = {stealth = 120, throwing = 120},
		},
	},
	# ── 바바리안(Barbarian) ──
	"barbarian": {
		"berserker": {
			display_name = "광전사(Berserker)",
			description = "광폭한 분노로 적을 파괴하는 광전사.",
			require_skill = "mace_fighting",
			min_level = 30.0,
			bonus_skills = {mace_fighting = 50.0, tactics = 30.0},
			bonus_caps = {mace_fighting = 120},
		},
	},
	# ── 성기사(Paladin) ──
	"paladin": {
		"crusader": {
			display_name = "성전사(Crusader)",
			description = "신성력과 방어를 극대화한 성전사.",
			require_skill = "divinity",
			min_level = 30.0,
			bonus_skills = {divinity = 50.0, parrying = 40.0},
			bonus_caps = {divinity = 120, parrying = 120},
		},
	},
	# ── 음유시인(Bard) ──
	"bard": {
		"jester": {
			display_name = "광대(Jester)",
			description = "춤과 도발로 적을 혼란에 빠뜨리는 광대.",
			require_skill = "dancing",
			min_level = 30.0,
			bonus_skills = {dancing = 50.0, provocation = 30.0},
			bonus_caps = {dancing = 120},
		},
	},
	# ── 무도가(Monk) ──
	"monk": {
		"master": {
			display_name = "격투 달인(Master)",
			description = "맨손 격투의 극한을 추구하는 수행자.",
			require_skill = "wrestling",
			min_level = 30.0,
			bonus_skills = {wrestling = 50.0, meditation = 40.0},
			bonus_caps = {wrestling = 120},
		},
	},
	# ── 사제(Cleric) ──
	"cleric": {
		"priest": {
			display_name = "고위 사제(Priest)",
			description = "신성한 치유와 축복에 특화된 고위 사제.",
			require_skill = "healing",
			min_level = 30.0,
			bonus_skills = {healing = 50.0, prayer = 40.0},
			bonus_caps = {healing = 120},
		},
	},
	# ── 드루이드(Druid) ──
	"druid": {
		"shaman": {
			display_name = "주술사(Shaman)",
			description = "자연의 정령과 교감하는 주술사.",
			require_skill = "herbalism",
			min_level = 30.0,
			bonus_skills = {herbalism = 50.0, nature_magic = 40.0},
			bonus_caps = {herbalism = 120, nature_magic = 120},
		},
	},
	# ── 조련사(Tamer) ──
	"tamer": {
		"beastmaster": {
			display_name = "야수 조련사(Beastmaster)",
			description = "야생 동물을 자유자재로 다루는 조련의 달인.",
			require_skill = "animal_taming",
			min_level = 30.0,
			bonus_skills = {animal_taming = 50.0, animal_lore = 40.0, herding = 30.0},
			bonus_caps = {animal_taming = 120, animal_lore = 120},
		},
	},
	# ── 연금술사(Alchemist) ──
	"alchemist": {
		"toxicologist": {
			display_name = "독학자(Toxicologist)",
			description = "독과 약을 자유자재로 다루는 연금술사.",
			require_skill = "alchemy",
			min_level = 30.0,
			bonus_skills = {alchemy = 50.0, poisoning = 40.0, poison_crafting = 30.0},
			bonus_caps = {alchemy = 120, poisoning = 120, poison_crafting = 120},
		},
		"herbalist": {
			display_name = "약초학자(Herbalist)",
			description = "약초와 자연 치유에 특화된 연금술사.",
			require_skill = "herbalism",
			min_level = 30.0,
			bonus_skills = {herbalism = 50.0, healing = 40.0, herbal_remedy = 30.0},
			bonus_caps = {herbalism = 120, healing = 110, herbal_remedy = 120},
		},
		"anatomist": {
			display_name = "해부학자(Anatomist)",
			description = "신체 구조와 법의학에 통달한 연금술사.",
			require_skill = "anatomy",
			min_level = 30.0,
			bonus_skills = {anatomy = 50.0, forensic_eval = 40.0, enhancement_elixir = 30.0},
			bonus_caps = {anatomy = 120, forensic_eval = 110, enhancement_elixir = 120},
		},
	},
	# ── 대장장이(Blacksmith) ──
	"blacksmith": {
		"weaponsmith": {
			display_name = "무기 장인(Weaponsmith)",
			description = "전설적인 무기를 제작하는 대장장이.",
			require_skill = "blacksmithy",
			min_level = 30.0,
			bonus_skills = {blacksmithy = 50.0, arms_lore = 40.0, mining = 30.0},
			bonus_caps = {blacksmithy = 120, arms_lore = 120},
		},
	},
	# ── 사무라이(Samurai) ──
	"samurai": {
		"ronin": {
			display_name = "로닌(Ronin)",
			description = "주인 없는 무사, 자유로운 검술과 패링의 달인.",
			require_skill = "bushido",
			min_level = 30.0,
			bonus_skills = {bushido = 50.0, parrying = 30.0},
			bonus_caps = {bushido = 120, parrying = 120},
		},
	},
}

# ── 해금 규칙 ──
# key: 해금되는 직업 ID (CLASSES에 정의된)
# skill: 필요한 스킬 ID
# min_level: 필요한 스킬 최소 수치
static func unlocks() -> Dictionary:
	return {
	"assassin": {
		skill = "poisoning",
		min_level = 30.0,
	},
	"knight": {
		skill = "parrying",
		min_level = 30.0,
	},
	"warlock": {
		skill = "spirit_speak",
		min_level = 30.0,
	},
}
