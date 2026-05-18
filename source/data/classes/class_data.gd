# class_data.gd — 4직업 정의 (상수 방식, .tres 불필요).
class_name ClassData
extends RefCounted

const CLASSES: Dictionary = {
	"fighter": {
		display_name = "전사(Fighter)",
		description = "근접전 특화. 높은 HP와 데미지.",
		skill_levels = {
			"swordsmanship": 50.0,
			"tactics": 50.0,
			"anatomy": 30.0,
		},
		stat_modifiers = {strength = 3, dexterity = 1, constitution = 2, intelligence = -1, wisdom = 0, charisma = -1},
	},
	"mage": {
		display_name = "마법사(Mage)",
		description = "마법 특화. 낮은 HP, 높은 마법 데미지.",
		skill_levels = {
			"magery": 50.0,
			"eval_int": 50.0,
			"meditation": 30.0,
		},
		stat_modifiers = {strength = -2, dexterity = 0, constitution = -1, intelligence = 3, wisdom = 2, charisma = 0},
	},
	"ranger": {
		display_name = "레인저(Ranger)",
		description = "원거리 특화. 높은 회피와 추적.",
		skill_levels = {
			"archery": 50.0,
			"tracking": 40.0,
			"herding": 30.0,
		},
		stat_modifiers = {strength = 0, dexterity = 3, constitution = 0, intelligence = 1, wisdom = 2, charisma = -1},
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
	},
	"bard": {
		display_name = "음유시인(Bard)",
		description = "지원+군중제어 특화. 도발/평온/불협화음.",
		skill_levels = {
			"musicianship": 50.0,
			"provocation": 40.0,
			"dancing": 30.0,
		},
		stat_modifiers = {strength = -2, dexterity = 1, constitution = 0, intelligence = 1, wisdom = 2, charisma = 2},
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
	},
	"cleric": {
		display_name = "사제(Cleric)",
		description = "치유+신성 마법 특화. 아군 지원, 회복.",
		skill_levels = {
			"divinity": 50.0,
			"healing": 50.0,
			"prayer": 30.0,
		},
		stat_modifiers = {strength = -1, dexterity = 0, constitution = 1, intelligence = 2, wisdom = 2, charisma = 0},
	},
	"tamer": {
		display_name = "조련사(Tamer)",
		description = "동물 조련+수의학 특화. 야생동물 길들이기, 동물 치료.",
		skill_levels = {
			"animal_taming": 50.0,
			"animal_lore": 50.0,
			"veterinary": 30.0,
		},
		stat_modifiers = {strength = 0, dexterity = 1, constitution = 1, intelligence = 0, wisdom = 3, charisma = 1},
	},
	"druid": {
		display_name = "드루이드(Druid)",
		description = "자연 마법+치유 특화. 자연의 힘으로 공격과 회복.",
		skill_levels = {
			"nature_magic": 50.0,
			"healing": 50.0,
			"animal_lore": 30.0,
		},
		stat_modifiers = {strength = -2, dexterity = 0, constitution = 1, intelligence = 1, wisdom = 3, charisma = 1},
	},
}
