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
			"tactics": 40.0,
			"tracking": 30.0,
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
}
