# alchemy_data.gd — 연금술 제조법 데이터베이스.
# 기름 + 플라스크 + 재료 = 효과 플라스크 (투척 아이템)
class_name AlchemyData
extends RefCounted

## 제조법: {result_id: {ingredients: [{item_id, qty}, ...], skill_req, xp}}
const RECIPES: Dictionary = {
	# ═══════════════════════════════════════
	# ── 화염 플라스크 (Flame Flask) ──
	# ═══════════════════════════════════════
	"flame_flask": {
		name = "화염 플라스크",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "lard", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 20.0},
		xp = 15,
		result_qty = 1,
	},
	"flame_flask_oil": {
		name = "화염 플라스크 (늑대기름)",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "wolf_oil", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 25.0},
		xp = 20,
		result_qty = 1,
	},
	"flame_flask_bear": {
		name = "화염 플라스크 (곰기름)",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "bear_fat", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 30.0},
		xp = 25,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 냉기 플라스크 (Frost Flask) ──
	# ═══════════════════════════════════════
	"frost_flask": {
		name = "냉기 플라스크",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "slime_gel", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 25.0},
		xp = 20,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 산성 플라스크 (Acid Flask) ──
	# ═══════════════════════════════════════
	"acid_flask": {
		name = "산성 플라스크",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "spider_oil", qty = 1},
			{item_id = "herb", qty = 1},
		],
		skill_req = {"alchemy": 20.0},
		xp = 15,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 독 플라스크 (Poison Flask) ──
	# ═══════════════════════════════════════
	"poison_flask": {
		name = "독 플라스크",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "poison_vial", qty = 1},
			{item_id = "spider_oil", qty = 1},
		],
		skill_req = {"alchemy": 30.0},
		xp = 25,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 점착 플라스크 (Sticky Flask) ──
	# ═══════════════════════════════════════
	"sticky_flask": {
		name = "점착 플라스크",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "slime_gel", qty = 2},
			{item_id = "herb", qty = 1},
		],
		skill_req = {"alchemy": 15.0},
		xp = 10,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 기타 제조법 ──
	# ═══════════════════════════════════════
	"health_potion": {
		name = "건강 물약",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "herb", qty = 2},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 10.0},
		xp = 10,
		result_qty = 1,
	},
	"greater_health_potion": {
		name = "상급 건강 물약",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "herb", qty = 3},
			{item_id = "reagent", qty = 2},
		],
		skill_req = {"alchemy": 30.0},
		xp = 25,
		result_qty = 1,
	},
	"antidote": {
		name = "해독제",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "herb", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 15.0},
		xp = 10,
		result_qty = 1,
	},
	"mana_potion": {
		name = "마나 물약",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "reagent", qty = 2},
			{item_id = "herb", qty = 1},
		],
		skill_req = {"alchemy": 20.0},
		xp = 15,
		result_qty = 1,
	},
}

## 제조 가능 여부 확인
static func can_craft(recipe_id: String, player_skills: Dictionary, inventory: Node) -> bool:
	var recipe = RECIPES.get(recipe_id)
	if not recipe:
		return false

	# 스킬 체크
	for skill_name in recipe.skill_req:
		var req = recipe.skill_req[skill_name]
		var have = player_skills.get(skill_name, 0.0)
		if have < req:
			return false

	# 재료 체크
	if not inventory:
		return false
	for ing in recipe.ingredients:
		if not inventory.has_method("get_item_count"):
			return false
		if inventory.get_item_count(ing.item_id) < ing.qty:
			return false

	return true

## 제조 실행. 성공 시 결과 ID 반환, 실패 시 null.
static func craft(recipe_id: String, inventory: Node) -> String:
	var recipe = RECIPES.get(recipe_id)
	if not recipe:
		return ""

	# 재료 소모
	for ing in recipe.ingredients:
		if not inventory.remove_item(ing.item_id, ing.qty):
			# 실패 시 롤백 (이미 소모된 재료는 복구 불가 — 단순 구현)
			push_error("[Alchemy] Craft failed: missing %s x%d" % [ing.item_id, ing.qty])
			return ""

	return recipe_id
