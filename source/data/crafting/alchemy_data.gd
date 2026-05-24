# alchemy_data.gd — 연금술 제조법 데이터베이스.
# 기름 + 플라스크 + 재료 = 효과 플라스크 (투척 아이템)
class_name AlchemyData
extends RefCounted

## 제조법: {result_id: {ingredients: [{item_id, qty}, ...], skill_req, xp}}
const RECIPES: Dictionary = {
	# ═══════════════════════════════════════
	# ── 연금술사의 불 (Alchemist's Fire) ──
	# ═══════════════════════════════════════
	"alchemist_fire": {
		name = "연금술사의 불",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "lard", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 20.0, "poison_crafting": 10.0},
		xp = 15,
		result_qty = 1,
	},
	"alchemist_fire_wolf": {
		name = "연금술사의 불 (늑대기름)",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "wolf_oil", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 25.0, "poison_crafting": 15.0},
		xp = 20,
		result_qty = 2,
	},
	"alchemist_fire_bear": {
		name = "연금술사의 불 (곰기름)",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "bear_fat", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 30.0, "poison_crafting": 20.0},
		xp = 25,
		result_qty = 3,
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
		skill_req = {"alchemy": 20.0, "poison_crafting": 15.0},
		xp = 15,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 병에 담긴 번개 (Bottled Lightning) ──
	# ═══════════════════════════════════════
	"bottled_lightning": {
		name = "병에 담긴 번개",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "lightning_bug", qty = 2},
			{item_id = "reagent", qty = 2},
		],
		skill_req = {"alchemy": 35.0, "enhancement_elixir": 20.0},
		xp = 30,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 빙결 유리병 (Frost Vial) ──
	# ═══════════════════════════════════════
	"frost_vial": {
		name = "빙결 유리병",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "slime_gel", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 25.0, "enhancement_elixir": 10.0},
		xp = 20,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 천둥의 돌 (Thunderstone) ──
	# ═══════════════════════════════════════
	"thunderstone": {
		name = "천둥의 돌",
		ingredients = [
			{item_id = "stinger", qty = 1},
			{item_id = "reagent", qty = 2},
			{item_id = "herb", qty = 1},
		],
		skill_req = {"alchemy": 30.0, "enhancement_elixir": 15.0},
		xp = 25,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 엉겅퀴 가방 (Tanglefoot Bag) ──
	# ═══════════════════════════════════════
	"tanglefoot_bag": {
		name = "엉겅퀴 가방",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "slime_gel", qty = 2},
			{item_id = "herb", qty = 1},
		],
		skill_req = {"alchemy": 15.0, "herbal_remedy": 10.0},
		xp = 10,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 유령 충전물 (Ghost Charge) ──
	# ═══════════════════════════════════════
	"ghost_charge": {
		name = "유령 충전물",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "spectral_essence", qty = 1},
			{item_id = "reagent", qty = 3},
		],
		skill_req = {"alchemy": 40.0, "poison_crafting": 25.0},
		xp = 35,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 브레인 수류탄 (Brain Grenade) ──
	# ═══════════════════════════════════════
	"brain_grenade": {
		name = "브레인 수류탄",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "dragon_scale", qty = 1},
			{item_id = "spectral_essence", qty = 1},
			{item_id = "reagent", qty = 3},
		],
		skill_req = {"alchemy": 60.0, "enhancement_elixir": 40.0},
		xp = 60,
		result_qty = 1,
	},

	# ═══════════════════════════════════════
	# ── 성수 (Holy Water) ──
	# ═══════════════════════════════════════
	"holy_water": {
		name = "성수",
		ingredients = [
			{item_id = "empty_bottle", qty = 1},
			{item_id = "spectral_essence", qty = 1},
			{item_id = "reagent", qty = 1},
		],
		skill_req = {"alchemy": 25.0, "prayer": 20.0},
		xp = 20,
		result_qty = 2,
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
