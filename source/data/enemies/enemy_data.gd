# enemy_data.gd — 적 몬스터 데이터베이스.
# 스탯, 드롭, AI 행동, 스킬 레벨, 서식지를 정의한다.
class_name EnemyData
extends RefCounted

## 서식지 카테고리
const HABITAT_FOREST: String = "forest"      # 숲
const HABITAT_PLAINS: String = "plains"      # 평야
const HABITAT_CAVE: String = "cave"          # 동굴
const HABITAT_RUINS: String = "ruins"        # 유적
const HABITAT_MOUNTAIN: String = "mountain"  # 산악

## 서식지별 적 목록 (스폰 풀 필터링용)
const HABITAT_ENEMIES: Dictionary = {
	HABITAT_FOREST: ["wolf", "spider", "deer", "boar", "bear"],
	HABITAT_PLAINS: ["horse", "cow", "sheep"],
	HABITAT_CAVE: ["slime", "skeleton", "skeleton_archer", "giant_rat", "snake"],
	HABITAT_RUINS: ["goblin", "goblin_warrior", "goblin_archer", "goblin_thief", "orc", "orc_warrior"],
	HABITAT_MOUNTAIN: ["scorpion", "harpy", "stone_golem"],
}

## 적 정의: {id: {name, hp, attack, defense, speed, accuracy, evasion, habitat, ...}}
const ENEMIES: Dictionary = {
	# ═══════════════════════════════════════
	# ── 숲 (Forest) 동물 ──
	# ═══════════════════════════════════════

	# ── 늑대 (Wolf) ──
	"wolf": {
		name = "늑대(Wolf)",
		hp = 25, attack = 6, defense = 2, speed = 14,
		accuracy = 45, evasion = 25,
		attack_range = 1,
		skill_levels = {
			"wrestling": 20.0,
			"tracking": 15.0,
		},
		drops = [
			{item_id = "raw_meat", chance = 0.6, qty_min = 1, qty_max = 2},
			{item_id = "wolf_oil", chance = 0.4, qty_min = 1, qty_max = 1},
		],
		color = Color(0.5, 0.5, 0.55),
		ai_behavior = "melee",
		habitat = HABITAT_FOREST,
	},

	# ── 거미 (Spider) ──
	"spider": {
		name = "거미(Spider)",
		hp = 15, attack = 4, defense = 1, speed = 10,
		accuracy = 40, evasion = 20,
		attack_range = 1,
		skill_levels = {
			"hiding": 25.0,
			"poisoning": 15.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.4, qty_min = 1, qty_max = 2},
			{item_id = "spider_oil", chance = 0.5, qty_min = 1, qty_max = 1},
		],
		color = Color(0.3, 0.2, 0.25),
		ai_behavior = "melee",
		habitat = HABITAT_FOREST,
	},

	# ── 사슴 (Deer) ──
	"deer": {
		name = "사슴(Deer)",
		hp = 18, attack = 3, defense = 1, speed = 16,
		accuracy = 30, evasion = 35,
		attack_range = 1,
		skill_levels = {
			"tracking": 10.0,
		},
		drops = [
			{item_id = "raw_meat", chance = 0.7, qty_min = 1, qty_max = 3},
			{item_id = "leather", chance = 0.5, qty_min = 1, qty_max = 2},
			{item_id = "antler", chance = 0.3, qty_min = 1, qty_max = 1},
			{item_id = "lard", chance = 0.3, qty_min = 1, qty_max = 1},
		],
		color = Color(0.6, 0.4, 0.25),
		ai_behavior = "flee",
		habitat = HABITAT_FOREST,
	},

	# ── 멧돼지 (Wild Boar) ──
	"boar": {
		name = "멧돼지(Wild Boar)",
		hp = 35, attack = 8, defense = 4, speed = 10,
		accuracy = 40, evasion = 10,
		attack_range = 1,
		skill_levels = {
			"wrestling": 15.0,
		},
		drops = [
			{item_id = "raw_meat", chance = 0.8, qty_min = 2, qty_max = 4},
			{item_id = "leather", chance = 0.4, qty_min = 1, qty_max = 2},
			{item_id = "tusk", chance = 0.2, qty_min = 1, qty_max = 1},
			{item_id = "lard", chance = 0.5, qty_min = 1, qty_max = 2},
		],
		color = Color(0.35, 0.25, 0.15),
		ai_behavior = "charge",
		habitat = HABITAT_FOREST,
	},

	# ═══════════════════════════════════════
	# ── 유적 (Ruins) 휴머노이드 ──
	# ═══════════════════════════════════════

	# ── 고블린 (Goblin) ──
	"goblin": {
		name = "고블린(Goblin)",
		hp = 30, attack = 5, defense = 2, speed = 8,
		accuracy = 40, evasion = 15,
		attack_range = 1,
		skill_levels = {
			"swordsmanship": 25.0,
			"tactics": 15.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.8, qty_min = 1, qty_max = 5},
		],
		color = Color(0.3, 0.7, 0.2),
		ai_behavior = "melee",
		habitat = HABITAT_RUINS,
	},
	"goblin_warrior": {
		name = "고블린 전사(Goblin Warrior)",
		hp = 45, attack = 8, defense = 4, speed = 6,
		accuracy = 45, evasion = 10,
		attack_range = 1,
		skill_levels = {
			"mace_fighting": 30.0,
			"tactics": 20.0,
			"parrying": 15.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.9, qty_min = 3, qty_max = 10},
			{item_id = "health_potion", chance = 0.4, qty_min = 1, qty_max = 1},
			{item_id = "club", chance = 0.15, qty_min = 1, qty_max = 1},
		],
		color = Color(0.25, 0.6, 0.15),
		ai_behavior = "melee",
		habitat = HABITAT_RUINS,
	},
	"goblin_archer": {
		name = "고블린 궁수(Goblin Archer)",
		hp = 25, attack = 8, defense = 1, speed = 10,
		accuracy = 55, evasion = 20,
		attack_range = 4,
		skill_levels = {
			"archery": 30.0,
			"hiding": 20.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.85, qty_min = 2, qty_max = 8},
			{item_id = "arrow", chance = 0.6, qty_min = 2, qty_max = 8},
			{item_id = "shortbow", chance = 0.15, qty_min = 1, qty_max = 1},
		],
		color = Color(0.35, 0.55, 0.15),
		ai_behavior = "ranged",
		habitat = HABITAT_RUINS,
	},
	"goblin_thief": {
		name = "고블린 도둑(Goblin Thief)",
		hp = 20, attack = 6, defense = 1, speed = 12,
		accuracy = 50, evasion = 30,
		attack_range = 1,
		skill_levels = {
			"fencing": 30.0,
			"hiding": 35.0,
			"stealth": 20.0,
			"stealing": 25.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.95, qty_min = 5, qty_max = 15},
			{item_id = "dagger", chance = 0.2, qty_min = 1, qty_max = 1},
			{item_id = "lockpick", chance = 0.3, qty_min = 1, qty_max = 3},
		],
		color = Color(0.2, 0.5, 0.3),
		ai_behavior = "melee",
		habitat = HABITAT_RUINS,
	},

	# ── 오크 (Orc) ──
	"orc": {
		name = "오크(Orc)",
		hp = 50, attack = 12, defense = 5, speed = 6,
		accuracy = 45, evasion = 10,
		attack_range = 1,
		skill_levels = {
			"swordsmanship": 30.0,
			"tactics": 25.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.9, qty_min = 5, qty_max = 15},
			{item_id = "short_sword", chance = 0.1, qty_min = 1, qty_max = 1},
		],
		color = Color(0.35, 0.5, 0.2),
		ai_behavior = "melee",
		habitat = HABITAT_RUINS,
	},
	"orc_warrior": {
		name = "오크 전사(Orc Warrior)",
		hp = 70, attack = 16, defense = 8, speed = 5,
		accuracy = 50, evasion = 8,
		attack_range = 1,
		skill_levels = {
			"swordsmanship": 40.0,
			"tactics": 35.0,
			"anatomy": 20.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 1.0, qty_min = 10, qty_max = 25},
			{item_id = "long_sword", chance = 0.12, qty_min = 1, qty_max = 1},
			{item_id = "greater_health_potion", chance = 0.2, qty_min = 1, qty_max = 1},
		],
		color = Color(0.3, 0.45, 0.15),
		ai_behavior = "melee",
		habitat = HABITAT_RUINS,
	},

	# ═══════════════════════════════════════
	# ── 동굴 (Cave) 언데드/괴물 ──
	# ═══════════════════════════════════════

	# ── 스켈레톤 (Skeleton) ──
	"skeleton": {
		name = "스켈레톤(Skeleton)",
		hp = 35, attack = 7, defense = 3, speed = 7,
		accuracy = 42, evasion = 12,
		attack_range = 1,
		skill_levels = {
			"swordsmanship": 25.0,
			"resisting_spells": 20.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.7, qty_min = 2, qty_max = 8},
			{item_id = "bandage", chance = 0.3, qty_min = 2, qty_max = 5},
		],
		color = Color(0.85, 0.85, 0.8),
		ai_behavior = "melee",
		habitat = HABITAT_CAVE,
	},
	"skeleton_archer": {
		name = "스켈레톤 궁수(Skeleton Archer)",
		hp = 28, attack = 10, defense = 2, speed = 8,
		accuracy = 58, evasion = 15,
		attack_range = 5,
		skill_levels = {
			"archery": 35.0,
			"resisting_spells": 15.0,
		},
		drops = [
			{item_id = "gold_coin", chance = 0.75, qty_min = 3, qty_max = 10},
			{item_id = "arrow", chance = 0.5, qty_min = 3, qty_max = 10},
			{item_id = "shortbow", chance = 0.1, qty_min = 1, qty_max = 1},
		],
		color = Color(0.8, 0.8, 0.75),
		ai_behavior = "ranged",
		habitat = HABITAT_CAVE,
	},

	# ── 슬라임 (Slime) ──
	"slime": {
		name = "슬라임(Slime)",
		hp = 20, attack = 3, defense = 1, speed = 4,
		accuracy = 30, evasion = 5,
		attack_range = 1,
		skill_levels = {},
		drops = [
			{item_id = "gold_coin", chance = 0.5, qty_min = 1, qty_max = 3},
			{item_id = "slime_gel", chance = 0.7, qty_min = 1, qty_max = 2},
		],
		color = Color(0.2, 0.6, 0.5),
		ai_behavior = "melee",
		habitat = HABITAT_CAVE,
	},

	# ── 뱀 (Snake) ──
	"snake": {
		name = "뱀(Snake)",
		hp = 12, attack = 5, defense = 1, speed = 12,
		accuracy = 35, evasion = 20,
		attack_range = 1,
		skill_levels = {
			"poisoning": 20.0,
		},
		drops = [
			{item_id = "snake_oil", chance = 0.6, qty_min = 1, qty_max = 1},
			{item_id = "poison_vial", chance = 0.3, qty_min = 1, qty_max = 1},
		],
		color = Color(0.2, 0.4, 0.15),
		ai_behavior = "melee",
		habitat = HABITAT_CAVE,
	},

	# ── 곰 (Bear) ──
	"bear": {
		name = "곰(Bear)",
		hp = 60, attack = 14, defense = 6, speed = 8,
		accuracy = 40, evasion = 8,
		attack_range = 1,
		skill_levels = {
			"wrestling": 30.0,
		},
		drops = [
			{item_id = "raw_meat", chance = 0.8, qty_min = 3, qty_max = 5},
			{item_id = "leather", chance = 0.6, qty_min = 2, qty_max = 3},
			{item_id = "bear_fat", chance = 0.5, qty_min = 1, qty_max = 2},
		],
		color = Color(0.35, 0.2, 0.1),
		ai_behavior = "charge",
		habitat = HABITAT_FOREST,
	},
}
