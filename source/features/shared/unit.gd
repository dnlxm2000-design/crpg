# unit.gd ??Base class for all game entities (player, enemies, NPCs).
# Shared between real-time and turn-based modes. 3D version.
extends CharacterBody3D
class_name Unit

## Core stats
@export var unit_name: String = "Unit"
@export var max_hp: int = 100
@export var speed: int = 10
@export var attack: int = 10
@export var defense: int = 5
@export var accuracy: int = 90
@export var evasion: int = 10
@export var is_player: bool = false
@export var attack_range: int = 1
@export var zoc_range: int = 1
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0

## RPG 湲곕낯 ?ㅽ꺈 (D&D 6?띿꽦)
@export var strength: int = 10
@export var dexterity: int = 10
@export var constitution: int = 10
@export var intelligence: int = 10
@export var wisdom: int = 10
@export var charisma: int = 10

## 醫낆”
@export var race: String = "Human"

## 吏곸뾽
@export var character_class: String = ""

## ?좊텇: slave/criminal/serf/commoner/freeman/merchant/noble/clergy/tribesman/otherworlder
@export var social_status: String = "commoner"

## 議곗쭅/湲몃뱶 吏곴툒: {organization_id: rank_id}
var organization_ranks: Dictionary = {}

## ?숈뒿???ㅽ궗: {skill_id: level} (raw float, 10?⑥쐞 踰꾪궥? get_skill_level?먯꽌 泥섎━)
var learned_skills: Dictionary = {}

## ?ㅽ궗蹂??곹븳: {skill_id: max_level} (湲곕낯 100)
var skill_caps: Dictionary = {}

## ?ㅽ궗 XP 濡쒓렇
var _skill_xp_log: Dictionary = {}

## Runtime state
var current_hp: int = 100
var current_action_points: int = 3
var max_action_points: int = 3
var is_alive: bool = true
var status_effects: Array = []

## ?꾪룓 ?덈꺼
enum CoverLevel {
	NONE = 0,
	HALF = 1,
	THREE_QUARTER = 2,
	TOTAL = 3,
}
var current_cover: CoverLevel = CoverLevel.NONE

## 諛붾씪蹂대뒗 諛⑺뼢 (留덉?留??대룞 諛⑺뼢) ??3D: XZ ?됰㈃
var facing_direction: Vector3 = Vector3(0, 0, 1)
## 諛⑺뼢 ?쒖떆??硫붿돩
var _direction_indicator: MeshInstance3D = null
## 洹몃┝??硫붿돩
var _shadow_mesh: MeshInstance3D = null

## Equipment slots
var equipped_weapon = null
var equipped_armor = null
var equipped_helmet = null
var equipped_necklace = null
var equipped_cloak = null
var equipped_belt = null
var equipped_ring1 = null
var equipped_ring2 = null
var equipped_boots = null
var equipped_gloves = null
var equipped_off_hand = null

## Movement component
var movement = null
## Previous movement state for animation transitions
var _prev_moving: bool = false

## Gold
var gold: int = 0

## Drops
@export var gold_drop: int = 0
@export var item_drops: Array = []

## Corpse visual tint
@export var corpse_color: Color = Color(0.4, 0.35, 0.35)


func _ready() -> void:
	current_hp = get_max_hp()
	movement = get_node_or_null("UnitMovement")

	# ?? 洹몃┝??(諛섑닾紐?寃? ?먮컲) ??
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.3)
	shadow_mat.flags_unshaded = true
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.4
	shadow_mesh.bottom_radius = 0.4
	shadow_mesh.height = 0.02

	_shadow_mesh = MeshInstance3D.new()
	_shadow_mesh.name = "ShadowMesh"
	_shadow_mesh.mesh = shadow_mesh
	_shadow_mesh.material_override = shadow_mat
	_shadow_mesh.position = Vector3(0, 0.01, 0)
	add_child(_shadow_mesh)

	# 諛⑺뼢 ?쒖떆???붿궡??
	_direction_indicator = MeshInstance3D.new()
	_direction_indicator.name = "DirectionIndicator"
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	arrow_mat.flags_unshaded = true

	var arrow_mesh := CylinderMesh.new()
	arrow_mesh.top_radius = 0.0
	arrow_mesh.bottom_radius = 0.2
	arrow_mesh.height = 0.4

	_direction_indicator.mesh = arrow_mesh
	_direction_indicator.material_override = arrow_mat
	_direction_indicator.position = Vector3(0, 0.6, 0)
	_direction_indicator.rotation.x = PI / 2  # ?붿궡?쒕? ?섑룊?쇰줈
	add_child(_direction_indicator)


## ?ㅼ떆媛?紐⑤뱶 ?붾뱾由?Bobbing + animation).
func _process(_delta: float) -> void:
	if not is_alive:
		return

	var is_moving_flag: bool = false
	if movement:
		is_moving_flag = movement.get("is_moving") or movement.get("is_tween_moving")

	var in_realtime: bool = (GameState.current_mode == GameState.GameMode.REALTIME) or \
		(GameState.current_mode == GameState.GameMode.MENU)

	# Bobbing ??3D: Y異??대룞
	if is_moving_flag and in_realtime:
		var bob_offset: float = sin(Time.get_ticks_msec() * 0.01) * 0.05
		_sprite_position_y(bob_offset)
	else:
		_sprite_position_y(0.0)

	# ?뚯씠??硫붿꽭??
	_handle_animation(is_moving_flag)


## GLB ?뚯씠??Idle/Walk ?ㅻ㈃ ?ㅼ쟾.
func _handle_animation(is_moving: bool) -> void:
	var anim_player: AnimationPlayer = null
	if has_meta("character_anim_player"):
		anim_player = get_meta("character_anim_player")
	if not anim_player:
		return

	# ???섏씠 ?섏씠 媛??異??섍? ?섏? ?꾨즺??
	if is_moving == _prev_moving:
		return
	_prev_moving = is_moving

	if is_moving:
		var anim_name := "Walking_A"
		if not anim_player.has_animation(anim_name):
			anim_name = "Walking_B"
		if not anim_player.has_animation(anim_name):
			anim_name = "Running_A"
		if not anim_player.has_animation(anim_name):
			# ?듯빀 ?뚯씠??留곸쾅
			var anims: PackedStringArray = anim_player.get_animation_list()
			anim_name = ""
			for a in anims:
				if a.contains("alk") or a.contains("un"):
					anim_name = a
					break
			if anim_name.is_empty():
				return

		var anim: Animation = anim_player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play(anim_name)
	else:
		var anim_name := "Unarmed_Idle" if anim_player.has_animation("Unarmed_Idle") else "Idle"
		if not anim_player.has_animation(anim_name):
			# ?듯빀 ?뚯씠??留곸쾅
			var anims: PackedStringArray = anim_player.get_animation_list()
			anim_name = ""
			for a in anims:
				if a.contains("Idle") or a.contains("Pose"):
					anim_name = a
					break
			if anim_name.is_empty():
				return

		var anim: Animation = anim_player.get_animation(anim_name)
		if anim:
			anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play(anim_name)


## ?먯떇 硫붿돩??y ?꾩튂 議곗젙 (bobbing).
func _sprite_position_y(offset: float) -> void:
	for child in get_children():
		if child is MeshInstance3D and child.name.begins_with("UnitBox"):
			if not child.has_meta("base_y"):
				child.set_meta("base_y", child.position.y)
			var base: float = child.get_meta("base_y", 0.0)
			child.position.y = base + offset


func setup_placeholder_visual(body_color: Color, _collision_size: Vector2i = Vector2i(28, 20), _sprite_size: Vector2i = Vector2i(32, 48)) -> void:
	# ?? CollisionShape3D ??
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.4
	shape.height = 1.0
	collision.shape = shape
	add_child(collision)

	# ?? 3D 諛뺤뒪: low-poly 罹먮┃????
	var box_color: Color = body_color
	var side_l_color: Color = body_color.darkened(0.35)
	var side_r_color: Color = body_color.darkened(0.55)

	var mat_top := StandardMaterial3D.new()
	mat_top.albedo_color = box_color
	mat_top.flags_unshaded = true

	var mat_side_l := StandardMaterial3D.new()
	mat_side_l.albedo_color = side_l_color
	mat_side_l.flags_unshaded = true

	var mat_side_r := StandardMaterial3D.new()
	mat_side_r.albedo_color = side_r_color
	mat_side_r.flags_unshaded = true

	# 紐명넻 (諛뺤뒪)
	var body := MeshInstance3D.new()
	body.name = "UnitBoxBody"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.6, 0.8, 0.4)
	body.mesh = body_mesh
	body.material_override = mat_side_l
	body.position = Vector3(0, 0.5, 0)
	add_child(body)

	# 癒몃━
	var head := MeshInstance3D.new()
	head.name = "UnitBoxHead"
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.3, 0.35)
	head.mesh = head_mesh
	head.material_override = mat_top
	head.position = Vector3(0, 1.05, 0)
	add_child(head)

	# ?붾? Sprite2D ?명솚??
	var _dummy := Sprite3D.new()
	_dummy.name = "UnitSprite"
	_dummy.visible = false
	add_child(_dummy)


## 留덉?留??대룞 諛⑺뼢??留욎떠 諛⑺뼢 ?쒖떆湲??낅뜲?댄듃.
func update_facing_direction(dir: Vector3) -> void:
	if dir == Vector3.ZERO:
		return
	facing_direction = dir.normalized()
	var angle: float = atan2(dir.x, dir.z)

	# 諛⑺뼢 ?쒖떆湲? (硫붾돱 ?꾩튂)
	if _direction_indicator:
		_direction_indicator.rotation.y = angle

	# 3D CharacterModel 諛⑺뼢 ?�?�몄�? �ы�?? (�щ�?? API/�⑸��??�쇰�??��?대�몄�몃�?吏��ъ?대�?)
	var model := get_node_or_null("CharacterModel")
	if model:
		model.rotation.y = angle


func reset_actions() -> void:
	current_action_points = max_action_points


## D&D-style attribute modifier
static func _attr_mod(score: int) -> int:
	return floori((score - 10) / 2.0)


## 醫낆” 蹂댁젙??
const RACE_MODIFIERS: Dictionary = {
	"Human":    {str =  1, dex =  1, con =  1, int =  1, wis =  1, cha =  1},
	"Dwarf":    {str =  2, dex = -1, con =  3, int =  0, wis =  1, cha = -1},
	"Elf":      {str = -1, dex =  2, con = -1, int =  2, wis =  1, cha =  1},
	"Halfling": {str = -2, dex =  3, con =  0, int =  0, wis =  2, cha =  1},
	"HalfElf":  {str =  0, dex =  1, con =  0, int =  1, wis =  0, cha =  2},
	"HalfOrc":  {str =  3, dex =  0, con =  2, int = -1, wis = -1, cha =  0},
}


func get_race_modifier(attr: String) -> int:
	var mods = RACE_MODIFIERS.get(race, {})
	return mods.get(attr, 0)


func get_effective_str() -> int:
	return strength + get_race_modifier("str")

func get_effective_dex() -> int:
	return dexterity + get_race_modifier("dex")

func get_effective_con() -> int:
	return constitution + get_race_modifier("con")

func get_effective_int() -> int:
	return intelligence + get_race_modifier("int")

func get_effective_wis() -> int:
	return wisdom + get_race_modifier("wis")

func get_effective_cha() -> int:
	return charisma + get_race_modifier("cha")


## ??? 吏곸뾽/?ㅽ궗 ?쒖뒪?????

func apply_class(class_def: Resource) -> void:
	if not class_def:
		return
	character_class = class_def.class_id
	learned_skills.clear()
	skill_caps.clear()
	for skill_id in class_def.skill_levels:
		learned_skills[skill_id] = class_def.skill_levels[skill_id]
	for attr in class_def.stat_modifiers:
		var current = get(attr)
		set(attr, current + class_def.stat_modifiers[attr])
	# 吏곸뾽 skill_caps ?곸슜 (湲곕낯 100, ?덉쇅留????
	for skill_id in class_def.skill_caps:
		skill_caps[skill_id] = class_def.skill_caps[skill_id]


func apply_subclass(class_id: String, subclass_id: String) -> void:
	var class_entry = ClassData.subclasses().get(class_id, {})
	var sub_entry = class_entry.get(subclass_id, {})
	if sub_entry.is_empty():
		return
	# 蹂대꼫???ㅽ궗 異붽?
	var bonus: Dictionary = sub_entry.get("bonus_skills", {})
	for skill_id in bonus:
		var current: float = learned_skills.get(skill_id, 0.0)
		learned_skills[skill_id] = max(current, bonus[skill_id])
	# 蹂대꼫??cap ?곸슜 (湲곗〈 cap ?ㅻ쾭?쇱씠??
	var bcaps: Dictionary = sub_entry.get("bonus_caps", {})
	for skill_id in bcaps:
		skill_caps[skill_id] = bcaps[skill_id]


func get_skill_level(skill_id: String) -> float:
	## 10?⑥쐞 踰꾪궥 諛섑솚 ??紐⑤뱺 寃뚯엫 濡쒖쭅(紐낆쨷/?곕?吏/?뚰뵾)? ??媛??ъ슜
	return SkillData.get_bucket(learned_skills.get(skill_id, 0.0))

func get_raw_skill_level(skill_id: String) -> float:
	## ?ㅼ젣 ?먯떆 ?ㅽ궗 ?덈꺼 (XP 吏꾪뻾 / UI ?쒖떆??
	return learned_skills.get(skill_id, 0.0)

func get_skill_cap(skill_id: String) -> float:
	return skill_caps.get(skill_id, 100.0)


func add_skill_xp(skill_id: String, xp: int) -> void:
	if not _skill_xp_log.has(skill_id):
		_skill_xp_log[skill_id] = 0
	_skill_xp_log[skill_id] += xp


func process_skill_xp() -> void:
	for skill_id in _skill_xp_log:
		var current_level: float = learned_skills.get(skill_id, 0.0)
		var cap: float = get_skill_cap(skill_id)
		if current_level >= cap:
			continue
		var xp: int = _skill_xp_log[skill_id]
		var adjusted: float = _calculate_xp_gain(xp, current_level)
		var new_level: float = min(current_level + adjusted / 10.0, cap)
		learned_skills[skill_id] = new_level
		print("[Skill] %s: %.1f ??%.1f (+%.1f) [cap=%.0f]" % [skill_id, current_level, new_level, new_level - current_level, cap])
	_skill_xp_log.clear()


static func _calculate_xp_gain(base_xp: int, current_level: float) -> float:
	if current_level < 30.0:
		return base_xp * 1.5
	elif current_level < 60.0:
		return base_xp * 1.0
	elif current_level < 80.0:
		return base_xp * 0.7
	else:
		return base_xp * 0.4


func has_skill_combo(combo_skills: Array) -> bool:
	for s in combo_skills:
		if get_skill_level(s) < 30.0:
			return false
	return true


func get_total_skill_levels() -> float:
	var total: float = 0.0
	for lvl in learned_skills.values():
		total += lvl
	return total


func get_skill_bonus(skill_id: String, stat: String) -> float:
	var level: float = get_skill_level(skill_id)
	var skill_def = SkillData.skills().get(skill_id)
	if not skill_def:
		return 0.0
	return skill_def.get(stat, 0.0) * (level / 100.0)


func get_attack() -> int:
	var bonus: int = 0
	if equipped_weapon and "damage_bonus" in equipped_weapon:
		bonus += equipped_weapon.damage_bonus
	if equipped_off_hand and "damage_bonus" in equipped_off_hand:
		bonus += equipped_off_hand.damage_bonus
	bonus += _attr_mod(get_effective_str())
	var weapon_skill = _get_equipped_weapon_skill_id()
	if weapon_skill:
		bonus += int(get_skill_bonus(weapon_skill, "damage"))
	return attack + bonus


func _get_equipped_weapon_skill_id() -> String:
	if not equipped_weapon:
		return ""
	var wclass = equipped_weapon.weapon_class
	var wtype = equipped_weapon.weapon_subtype
	if wtype in ["spear", "lance", "pike"]:
		return "spear"
	elif wtype in ["dagger", "dagger", "sai", "fork"]:
		return "fencing"
	elif wtype in ["mace", "hammer", "club", "staff"]:
		return "mace_fighting"
	elif wclass == "ranged":
		return "archery"
	elif wclass == "thrown":
		return "throwing"
	else:
		return "swordsmanship"


func get_defense() -> int:
	var bonus: int = 0
	for slot_item in [equipped_armor, equipped_helmet, equipped_necklace, equipped_cloak, equipped_belt, equipped_boots, equipped_gloves, equipped_off_hand, equipped_ring1, equipped_ring2]:
		if slot_item and "defense_bonus" in slot_item:
			bonus += slot_item.defense_bonus
	bonus += _attr_mod(get_effective_con())
	return defense + bonus


func get_accuracy() -> int:
	var bonus: int = 0
	for slot_item in [equipped_weapon, equipped_off_hand, equipped_gloves, equipped_ring1, equipped_ring2]:
		if slot_item and "accuracy_bonus" in slot_item:
			bonus += slot_item.accuracy_bonus
	bonus += _attr_mod(get_effective_dex())
	var weapon_skill = _get_equipped_weapon_skill_id()
	if weapon_skill:
		bonus += int(get_skill_bonus(weapon_skill, "accuracy"))
	return accuracy + bonus


func get_initiative() -> int:
	return get_effective_dex() * 2 + speed


func get_evasion() -> int:
	var bonus: int = 0
	for slot_item in [equipped_armor, equipped_helmet, equipped_cloak, equipped_belt, equipped_boots, equipped_off_hand, equipped_ring1, equipped_ring2, equipped_necklace, equipped_gloves]:
		if slot_item and "evasion_bonus" in slot_item:
			bonus += slot_item.evasion_bonus
	bonus += _attr_mod(get_effective_dex())
	for skill_id in ["wrestling", "parrying", "hiding", "stealth", "dancing", "peacemaking", "resisting_spells", "nature_magic", "ninjitsu", "bushido"]:
		bonus += int(get_skill_bonus(skill_id, "evasion"))
	return evasion + bonus


func get_max_hp() -> int:
	return max_hp + _attr_mod(get_effective_con()) * 5


func get_magic_power() -> int:
	var bonus: int = _attr_mod(get_effective_int()) * 3
	return bonus


func get_resistance() -> int:
	return _attr_mod(get_effective_wis()) * 2


func get_price_multiplier() -> float:
	return max(0.5, 1.0 - _attr_mod(get_effective_cha()) * 0.05)


static func check_hit(attacker, target) -> bool:
	var atk_acc: int = attacker.get_accuracy() if attacker.has_method("get_accuracy") else 90
	var tgt_ev: int = target.get_evasion() if target.has_method("get_evasion") else 10
	var hit_chance: int = clampi(atk_acc - tgt_ev, 5, 95)
	var roll: float = randf()
	return roll * 100.0 < hit_chance


## item_type ??slot variable name mapping.
var _slot_map: Dictionary = {
	1: "equipped_weapon",
	2: "equipped_armor",
	4: "equipped_helmet",
	5: "equipped_necklace",
	6: "equipped_cloak",
	7: "equipped_belt",
	9: "equipped_boots",
	10: "equipped_off_hand",
	11: "equipped_gloves",
}


func equip_item(item) -> Dictionary:
	if not item or not ("item_type" in item):
		return {previous = null, success = false, slot = ""}

	var slot_var: String = ""
	var item_type: int = item.item_type

	if item_type == 8:
		if equipped_ring1 == null:
			slot_var = "equipped_ring1"
		elif equipped_ring2 == null:
			slot_var = "equipped_ring2"
		else:
			slot_var = "equipped_ring1"
	else:
		slot_var = _slot_map.get(item_type, "")

	if slot_var == "":
		return {previous = null, success = false, slot = ""}

	var prev = get(slot_var)
	set(slot_var, item)

	print("[Unit] Equipped %s -> %s (atk=%d, def=%d)" % [item.item_name, slot_var, get_attack(), get_defense()])
	return {previous = prev, success = true, slot = slot_var}


func unequip_item(slot_var: String):
	var item = get(slot_var) if slot_var in self else null
	if item != null:
		set(slot_var, null)
		print("[Unit] Unequipped %s from %s" % [item.item_name, slot_var])
	return item


func get_all_equipped() -> Dictionary:
	var result: Dictionary = {}
	for s in ["equipped_weapon", "equipped_armor", "equipped_helmet", "equipped_necklace", "equipped_cloak", "equipped_belt", "equipped_ring1", "equipped_ring2", "equipped_boots", "equipped_gloves", "equipped_off_hand"]:
		var it = get(s)
		if it != null:
			result[s] = it
	return result


func take_damage(amount: int, source: Node = null) -> void:
	var actual = max(1, amount - get_defense())
	current_hp = max(0, current_hp - actual)
	EventBus.unit_damaged.emit(self, actual, source)

	if current_hp <= 0:
		die()


func die() -> void:
	is_alive = false
	if not movement:
		EventBus.unit_destroyed.emit(self)
		queue_free()
		return

	movement.stop_moving()
	var gw = movement.get_grid_world()

	var drop_items: Array = []
	for entry in item_drops:
		var drop_item = entry.get("item")
		var chance = entry.get("chance", 1.0)
		if drop_item and randf() <= chance:
			drop_items.append(drop_item)

	if gw:
		var gp: Vector2i = gw.world_to_grid(global_position)
		gw.set_occupied(gp, null)

	_spawn_corpse(gw, gold_drop, drop_items)

	gold_drop = 0
	item_drops = []

	EventBus.unit_destroyed.emit(self)
	queue_free()


func _spawn_corpse(grid_world, corpse_gold: int, items: Array) -> void:
	if not grid_world:
		return
	var gp: Vector2i = grid_world.world_to_grid(global_position)
	var corpse = load("res://source/features/shared/corpse.gd").new()
	get_tree().current_scene.add_child(corpse)
	corpse.setup(grid_world, gp, unit_name, corpse_color, corpse_gold, items)


func _drop_loot() -> void:
	if gold_drop <= 0 and item_drops.is_empty():
		return

	var grid_world = movement.get_grid_world() if movement else null
	if not grid_world:
		return
	var gp: Vector2i = grid_world.world_to_grid(global_position)

	if gold_drop > 0:
		var gold_item = load("res://source/data/items/resources/gold_coin.tres")
		if gold_item:
			_spawn_drop(gold_item, gp)

	for entry in item_drops:
		var drop_item = entry.get("item")
		var chance = entry.get("chance", 1.0)
		if drop_item and randf() <= chance:
			var idx: int = item_drops.find(entry)
			var offset_gp = gp + Vector2i(
				idx % 3 - 1,
				floori(float(idx) / 3.0) % 3 - 1
			)
			_spawn_drop(drop_item, offset_gp)


func _spawn_drop(item_res, grid_pos: Vector2i) -> void:
	var map_item = load("res://source/features/realtime/map_item.gd").new()
	map_item.setup(item_res, grid_pos)
	# 3D: GridWorld??grid_to_world ?ъ슜
	var gw = movement.get_grid_world() if movement else null
	if gw:
		map_item.global_position = gw.grid_to_world(grid_pos)
	else:
		map_item.global_position = Vector3(float(grid_pos.x), 0.0, float(grid_pos.y))
	get_tree().current_scene.add_child(map_item)
