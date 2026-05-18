# unit.gd — Base class for all game entities (player, enemies, NPCs).
# Shared between real-time and turn-based modes.
class_name Unit
extends CharacterBody2D

## Core stats
@export var unit_name: String = "Unit"
@export var max_hp: int = 100
@export var speed: int = 10       # Initiative for turn-based, movement for real-time
@export var attack: int = 10
@export var defense: int = 5
@export var accuracy: int = 90      # Base hit chance (%) — used in combat rolls
@export var evasion: int = 10       # Base dodge chance (%) — reduces attacker's hit
@export var is_player: bool = false  # Stoneshard: player vs NPC distinction
@export var attack_range: int = 1    # 1=melee, 2+=ranged
@export var zoc_range: int = 1       # 0=none, 1=adjacent 8 tiles, 2+=larger zone
@export var crit_chance: float = 0.05   # 치명타 확률 (0.0~1.0)
@export var crit_multiplier: float = 2.0  # 치명타 데미지 배율

## RPG 기본 스탯 (D&D 6속성)
@export var strength: int = 10       # STR: 근접 데미지, 운반
@export var dexterity: int = 10      # DEX: 선제권, 회피, 원거리
@export var constitution: int = 10   # CON: HP, 저항
@export var intelligence: int = 10   # INT: 마법 데미지, 지식
@export var wisdom: int = 10         # WIS: 지각, 의지력
@export var charisma: int = 10       # CHA: 교섭, 상점 가격

## 종족 (race modifiers applied on top of base stats)
@export var race: String = "Human"

## 직업 (class determines starting skills and stat modifiers)
@export var character_class: String = ""  # "fighter", "mage", "ranger", "rogue"

## 학습된 스킬: {skill_id: level}
var learned_skills: Dictionary = {}

## 스킬 XP 로그 (전투 중 누적, 전투 종료 시 일괄 처리)
var _skill_xp_log: Dictionary = {}

## Runtime state
var current_hp: int = 100
var current_action_points: int = 3
var max_action_points: int = 3
var is_alive: bool = true
var status_effects: Array = []

## 엄폐 레벨 (cover system)
enum CoverLevel {
	NONE = 0,       # 엄폐 없음
	HALF = 1,       # 절반 엄폐: AC/DEX +2
	THREE_QUARTER = 2,  # 3/4 엄폐: AC/DEX +5
	TOTAL = 3,      # 완전 엄폐: 직접 공격 불가
}
var current_cover: CoverLevel = CoverLevel.NONE

## 바라보는 방향 (마지막 이동 방향)
var facing_direction: Vector2 = Vector2.DOWN
## 방향 표시용 삼각형 노드
var _direction_indicator: Node2D = null
## 그림자 스프라이트
var _shadow_sprite: Sprite2D = null

## Equipment slots (references to Item resources, null = empty)
var equipped_weapon = null   # WEAPON → right_hand
var equipped_armor = null    # ARMOR → body
var equipped_helmet = null   # HELMET → head
var equipped_necklace = null # NECKLACE → necklace
var equipped_cloak = null    # CLOAK → cloak
var equipped_belt = null     # BELT → belt
var equipped_ring1 = null    # RING → ring slot 1
var equipped_ring2 = null    # RING → ring slot 2
var equipped_boots = null    # BOOTS → boots
var equipped_gloves = null   # GLOVE → gloves
var equipped_off_hand = null # OFF_HAND → left_hand

## Movement component (optional)
var movement = null

## Gold (player wallet)
var gold: int = 0

## Drops (enemies)
@export var gold_drop: int = 0    # Gold dropped on death
@export var item_drops: Array = []  # [{item=Resource, chance=0.0-1.0}, ...]

## Corpse visual tint (set by spawner). Gray default.
@export var corpse_color: Color = Color(0.4, 0.35, 0.35)


func _ready() -> void:
	current_hp = get_max_hp()
	movement = get_node_or_null("UnitMovement")

	# ── 그림자 (반투명 검은 타원) ──
	_shadow_sprite = Sprite2D.new()
	_shadow_sprite.name = "ShadowSprite"
	var shadow_img := Image.create(40, 16, false, Image.FORMAT_RGBA8)
	shadow_img.fill(Color.TRANSPARENT)
	# 타원형 그림자
	var shadow_color := Color(0.0, 0.0, 0.0, 0.25)
	for px in 40:
		for py in 16:
			var nx: float = (px - 20) / 20.0
			var ny: float = (py - 8) / 8.0
			if nx * nx + ny * ny <= 1.0:
				shadow_img.set_pixel(px, py, shadow_color)
	_shadow_sprite.texture = ImageTexture.create_from_image(shadow_img)
	_shadow_sprite.position = Vector2(0, 2)  # 유닛 발 아래
	_shadow_sprite.z_index = -1
	add_child(_shadow_sprite)

	# 방향 표시 삼각형 생성
	_direction_indicator = Node2D.new()
	_direction_indicator.name = "DirectionIndicator"
	var arm_l := ColorRect.new()
	arm_l.color = Color(1.0, 1.0, 1.0, 0.7)
	arm_l.size = Vector2(10, 3)
	arm_l.position = Vector2(-5, 0)
	arm_l.rotation = 2.356
	_direction_indicator.add_child(arm_l)
	var arm_r := ColorRect.new()
	arm_r.color = Color(1.0, 1.0, 1.0, 0.7)
	arm_r.size = Vector2(10, 3)
	arm_r.position = Vector2(-5, 0)
	arm_r.rotation = -2.356
	_direction_indicator.add_child(arm_r)
	_direction_indicator.position = Vector2(16, 24)
	_direction_indicator.z_index = 10
	_direction_indicator.z_as_relative = false
	add_child(_direction_indicator)


## 실시간 모드 흔들림(Bobbing) + 스프라이트 반전.
func _process(_delta: float) -> void:
	if not is_alive:
		return

	var is_moving_flag: bool = false
	if movement:
		is_moving_flag = movement.get("is_moving") or movement.get("is_keyboard_moving")

	var in_realtime: bool = (GameState.current_mode == GameState.GameMode.REALTIME) or \
		(GameState.current_mode == GameState.GameMode.MENU)

	# Bobbing
	if is_moving_flag and in_realtime:
		var bob_offset: float = sin(Time.get_ticks_msec() * 0.01) * 2.0
		_sprite_position_y(bob_offset)
	else:
		_sprite_position_y(0.0)

	# Flip-H: 가로 이동 방향에 따라 스프라이트 반전
	_sprite_flip_h(facing_direction.x < 0 if in_realtime else false)


## Polygon2D 박스 전체의 y 위치 조정 (bobbing).
func _sprite_position_y(offset: float) -> void:
	for child in get_children():
		if child is Polygon2D and child.name.begins_with("UnitBox"):
			# 기준 y 위치를 offset만큼 이동 (원래 위치 유지)
			if not child.has_meta("base_y"):
				child.set_meta("base_y", child.position.y if "position" in child else 0)
			var base: float = child.get_meta("base_y", 0.0)
			child.position.y = base + offset


## UnitSprite의 flip_h 설정 (사각형 → 박스 좌우 색상 반전).
func _sprite_flip_h(flip: bool) -> void:
	var l: Polygon2D = get_node_or_null("UnitBoxSideL")
	var r: Polygon2D = get_node_or_null("UnitBoxSideR")
	if l and r:
		var tmp := l.color
		l.color = r.color
		r.color = tmp


func setup_placeholder_visual(body_color: Color, collision_size: Vector2i = Vector2i(28, 20), sprite_size: Vector2i = Vector2i(32, 48)) -> void:
	# ── CollisionShape (클릭/물리 영역) ──
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(collision_size.x, collision_size.y)
	collision.shape = shape
	add_child(collision)

	# ── 3D 박스: z_index 제거 → y_sort 위임
	var box_color: Color = body_color
	var side_l_color: Color = body_color.darkened(0.35)
	var side_r_color: Color = body_color.darkened(0.55)

	var side_l := Polygon2D.new()
	side_l.polygon = PackedVector2Array([
		Vector2(-28, -32), Vector2(0, -16),
		Vector2(0, 24), Vector2(-28, 8),
	])
	side_l.color = side_l_color
	side_l.name = "UnitBoxSideL"
	add_child(side_l)

	var side_r := Polygon2D.new()
	side_r.polygon = PackedVector2Array([
		Vector2(28, -32), Vector2(0, -16),
		Vector2(0, 24), Vector2(28, 8),
	])
	side_r.color = side_r_color
	side_r.name = "UnitBoxSideR"
	add_child(side_r)

	var top_face := Polygon2D.new()
	top_face.polygon = PackedVector2Array([
		Vector2(0, -48), Vector2(28, -32),
		Vector2(0, -16), Vector2(-28, -32),
	])
	top_face.color = box_color
	top_face.name = "UnitBoxTop"
	add_child(top_face)

	var _dummy := Sprite2D.new()
	_dummy.name = "UnitSprite"
	_dummy.visible = false
	add_child(_dummy)


## 마지막 이동 방향에 맞춰 방향 표시기 업데이트.
func update_facing_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	facing_direction = dir
	if _direction_indicator:
		_direction_indicator.rotation = dir.angle()


func reset_actions() -> void:
	current_action_points = max_action_points


## D&D-style attribute modifier: floor((score - 10) / 2)
static func _attr_mod(score: int) -> int:
	return floori((score - 10) / 2.0)


## 종족 보정표: {race: {str, dex, con, int, wis, cha}}
const RACE_MODIFIERS: Dictionary = {
	"Human":    {str =  1, dex =  1, con =  1, int =  1, wis =  1, cha =  1},
	"Dwarf":    {str =  2, dex = -1, con =  3, int =  0, wis =  1, cha = -1},
	"Elf":      {str = -1, dex =  2, con = -1, int =  2, wis =  1, cha =  1},
	"Halfling": {str = -2, dex =  3, con =  0, int =  0, wis =  2, cha =  1},
	"HalfElf":  {str =  0, dex =  1, con =  0, int =  1, wis =  0, cha =  2},
	"HalfOrc":  {str =  3, dex =  0, con =  2, int = -1, wis = -1, cha =  0},
}


## 종족 보정을 적용한 최종 속성값 반환.
func get_race_modifier(attr: String) -> int:
	var mods = RACE_MODIFIERS.get(race, {})
	return mods.get(attr, 0)


## 종족 보정을 반영한 최종 STR.
func get_effective_str() -> int:
	return strength + get_race_modifier("str")

## 종족 보정을 반영한 최종 DEX.
func get_effective_dex() -> int:
	return dexterity + get_race_modifier("dex")

## 종족 보정을 반영한 최종 CON.
func get_effective_con() -> int:
	return constitution + get_race_modifier("con")

## 종족 보정을 반영한 최종 INT.
func get_effective_int() -> int:
	return intelligence + get_race_modifier("int")

## 종족 보정을 반영한 최종 WIS.
func get_effective_wis() -> int:
	return wisdom + get_race_modifier("wis")

## 종족 보정을 반영한 최종 CHA.
func get_effective_cha() -> int:
	return charisma + get_race_modifier("cha")


## ─── 직업/스킬 시스템 ───

## 직업 적용: 스킬 부여 + 스탯 보정.
func apply_class(class_def: Resource) -> void:
	if not class_def:
		return
	character_class = class_def.class_id
	# 스킬 부여
	for skill_id in class_def.skill_levels:
		learned_skills[skill_id] = class_def.skill_levels[skill_id]
	# 스탯 보정 적용
	for attr in class_def.stat_modifiers:
		var current = get(attr)
		set(attr, current + class_def.stat_modifiers[attr])


## 특정 스킬 레벨 조회.
func get_skill_level(skill_id: String) -> float:
	return learned_skills.get(skill_id, 0.0)


## 스킬 XP 추가 (전투 중 누적).
func add_skill_xp(skill_id: String, xp: int) -> void:
	if not _skill_xp_log.has(skill_id):
		_skill_xp_log[skill_id] = 0
	_skill_xp_log[skill_id] += xp


## 전투 종료 시 스킬 XP 일괄 처리 + 레벨업.
func process_skill_xp() -> void:
	for skill_id in _skill_xp_log:
		var current_level: float = learned_skills.get(skill_id, 0.0)
		if current_level >= 100.0:
			continue
		var xp: int = _skill_xp_log[skill_id]
		var adjusted: float = _calculate_xp_gain(xp, current_level)
		var new_level: float = min(current_level + adjusted / 10.0, 100.0)
		learned_skills[skill_id] = new_level
		print("[Skill] %s: %.1f → %.1f (+%.1f)" % [skill_id, current_level, new_level, new_level - current_level])
	_skill_xp_log.clear()


## 차등 XP 보정: 낮은 스킬이 빨리 오름.
static func _calculate_xp_gain(base_xp: int, current_level: float) -> float:
	if current_level < 30.0:
		return base_xp * 1.5
	elif current_level < 60.0:
		return base_xp * 1.0
	elif current_level < 80.0:
		return base_xp * 0.7
	else:
		return base_xp * 0.4


## 스킬 콤보 체크: 모든 요구 스킬이 30 이상이면 true.
func has_skill_combo(combo_skills: Array) -> bool:
	for s in combo_skills:
		if get_skill_level(s) < 30.0:
			return false
	return true


## 전체 스킬 레벨 합계 (720 캡 체크용).
func get_total_skill_levels() -> float:
	var total: float = 0.0
	for lvl in learned_skills.values():
		total += lvl
	return total


## 스킬 레벨에 따른 전투 보정 계산.
func get_skill_bonus(skill_id: String, stat: String) -> float:
	var level: float = get_skill_level(skill_id)
	var skill_def = SkillData.SKILLS.get(skill_id)
	if not skill_def:
		return 0.0
	return skill_def.get(stat, 0.0) * (level / 100.0)


## 장비를 포함한 최종 공격력 반환 (weapon + off_hand + STR 보정 + 스킬 보정).
func get_attack() -> int:
	var bonus: int = 0
	if equipped_weapon and "damage_bonus" in equipped_weapon:
		bonus += equipped_weapon.damage_bonus
	if equipped_off_hand and "damage_bonus" in equipped_off_hand:
		bonus += equipped_off_hand.damage_bonus
	bonus += _attr_mod(get_effective_str())
	# 주무기 스킬 보정 적용
	var weapon_skill = _get_equipped_weapon_skill_id()
	if weapon_skill:
		bonus += int(get_skill_bonus(weapon_skill, "damage"))
	return attack + bonus


## 현재 장비된 무기에 해당하는 스킬 ID 반환.
func _get_equipped_weapon_skill_id() -> String:
	if not equipped_weapon:
		return ""
	var wclass = equipped_weapon.get("weapon_class", "")
	var wtype = equipped_weapon.get("weapon_subtype", "")
	# 무기 타입 → 스킬 매핑
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
		return "swordsmanship"  # 기본값


## 장비를 포함한 최종 방어력 반환 (모든 방어구 합산 + CON 보정).
func get_defense() -> int:
	var bonus: int = 0
	for slot_item in [equipped_armor, equipped_helmet, equipped_necklace, equipped_cloak, equipped_belt, equipped_boots, equipped_gloves, equipped_off_hand, equipped_ring1, equipped_ring2]:
		if slot_item and "defense_bonus" in slot_item:
			bonus += slot_item.defense_bonus
	bonus += _attr_mod(get_effective_con())
	return defense + bonus


## 장비를 포함한 최종 명중률 반환 (장비 보정 + DEX 보정 + 스킬 보정).
func get_accuracy() -> int:
	var bonus: int = 0
	for slot_item in [equipped_weapon, equipped_off_hand, equipped_gloves, equipped_ring1, equipped_ring2]:
		if slot_item and "accuracy_bonus" in slot_item:
			bonus += slot_item.accuracy_bonus
	bonus += _attr_mod(get_effective_dex())
	# 주무기 스킬 명중 보정
	var weapon_skill = _get_equipped_weapon_skill_id()
	if weapon_skill:
		bonus += int(get_skill_bonus(weapon_skill, "accuracy"))
	return accuracy + bonus


## 선제권 계산 (턴 순서 결정).
## effective_dex * 2 + speed.
func get_initiative() -> int:
	return get_effective_dex() * 2 + speed


## 장비를 포함한 최종 회피율 반환 (장비 보정 + DEX 보정).
func get_evasion() -> int:
	var bonus: int = 0
	for slot_item in [equipped_armor, equipped_helmet, equipped_cloak, equipped_belt, equipped_boots, equipped_off_hand, equipped_ring1, equipped_ring2, equipped_necklace, equipped_gloves]:
		if slot_item and "evasion_bonus" in slot_item:
			bonus += slot_item.evasion_bonus
	bonus += _attr_mod(get_effective_dex())
	return evasion + bonus


## CON 보정을 반영한 최대 HP.
func get_max_hp() -> int:
	return max_hp + _attr_mod(get_effective_con()) * 5


## INT 기반 마법 공격력 (미래 확장용).
func get_magic_power() -> int:
	var bonus: int = _attr_mod(get_effective_int()) * 3
	return bonus


## WIS 기반 마법 저항 (미래 확장용).
func get_resistance() -> int:
	return _attr_mod(get_effective_wis()) * 2


## CHA 기반 상점 가격 배율 (1.0 기준, 낮을수록 할인).
func get_price_multiplier() -> float:
	return max(0.5, 1.0 - _attr_mod(get_effective_cha()) * 0.05)


## 공격 명중 여부 판정. attacker → target.
static func check_hit(attacker, target) -> bool:
	var atk_acc: int = attacker.get_accuracy() if attacker.has_method("get_accuracy") else 90
	var tgt_ev: int = target.get_evasion() if target.has_method("get_evasion") else 10
	var hit_chance: int = clampi(atk_acc - tgt_ev, 5, 95)
	var roll: float = randf()
	return roll * 100.0 < hit_chance


## item_type → slot variable name mapping.
var _slot_map: Dictionary = {
	1: "equipped_weapon",      # WEAPON
	2: "equipped_armor",       # ARMOR
	4: "equipped_helmet",      # HELMET
	5: "equipped_necklace",    # NECKLACE
	6: "equipped_cloak",       # CLOAK
	7: "equipped_belt",        # BELT
	9: "equipped_boots",       # BOOTS
	10: "equipped_off_hand",   # OFF_HAND
	11: "equipped_gloves",     # GLOVE
}


## 아이템을 장비한다. item_type에 따라 적절한 슬롯에 설정.
## ring(8)은 ring1 → ring2 순서로 채운다.
## 이전에 장비한 아이템이 있으면 반환하고 새 아이템으로 교체.
## 반환값: {previous: 이전 아이템(or null), success: true, slot: 사용된 슬롯명}
func equip_item(item) -> Dictionary:
	if not item or not ("item_type" in item):
		return {previous = null, success = false, slot = ""}

	var slot_var: String = ""
	var item_type: int = item.item_type

	if item_type == 8:  # RING: try ring1 first, then ring2
		if equipped_ring1 == null:
			slot_var = "equipped_ring1"
		elif equipped_ring2 == null:
			slot_var = "equipped_ring2"
		else:
			slot_var = "equipped_ring1"  # both full, overwrite ring1
	else:
		slot_var = _slot_map.get(item_type, "")

	if slot_var == "":
		return {previous = null, success = false, slot = ""}

	var prev = get(slot_var)
	set(slot_var, item)

	print("[Unit] Equipped %s -> %s (atk=%d, def=%d)" % [item.item_name, slot_var, get_attack(), get_defense()])
	return {previous = prev, success = true, slot = slot_var}


## 장비를 해제한다. slot_var: "equipped_weapon", "equipped_armor", "equipped_ring1" 등.
## 반환값: 해제된 아이템 (없으면 null).
func unequip_item(slot_var: String):
	var item = get(slot_var) if slot_var in self else null
	if item != null:
		set(slot_var, null)
		print("[Unit] Unequipped %s from %s" % [item.item_name, slot_var])
	return item


## 장비된 모든 아이템을 {slot_var: item} Dictionary로 반환 (UI용).
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

	# Collect drops that would have spawned
	var drop_items: Array = []
	for entry in item_drops:
		var drop_item = entry.get("item")
		var chance = entry.get("chance", 1.0)
		if drop_item and randf() <= chance:
			drop_items.append(drop_item)

	# Clear grid occupancy (corpse will re-set it)
	if gw:
		var gp: Vector2i = gw.world_to_grid(global_position)
		gw.set_occupied(gp, null)

	# Spawn lootable corpse
	_spawn_corpse(gw, gold_drop, drop_items)

	# Legacy: spawn MapItem drops for backward compatibility (empty since we pass to corpse)
	gold_drop = 0
	item_drops = []

	EventBus.unit_destroyed.emit(self)
	queue_free()


## Create a lootable corpse at this unit's position.
func _spawn_corpse(grid_world, gold: int, items: Array) -> void:
	if not grid_world:
		return
	var gp: Vector2i = grid_world.world_to_grid(global_position)
	var corpse = load("res://source/features/shared/corpse.gd").new()
	corpse.setup(grid_world, gp, unit_name, corpse_color, gold, items)
	get_tree().current_scene.add_child(corpse)


## 사망 시 금화와 아이템을 MapItem으로 드랍한다.
func _drop_loot() -> void:
	if gold_drop <= 0 and item_drops.is_empty():
		return

	var grid_world = movement.get_grid_world() if movement else null
	if not grid_world:
		return
	var gp: Vector2i = grid_world.world_to_grid(global_position)

	# Gold drop
	if gold_drop > 0:
		var gold_item = load("res://source/data/items/resources/gold_coin.tres")
		if gold_item:
			_spawn_drop(gold_item, gp)

	# Item drops (roll chance)
	for entry in item_drops:
		var drop_item = entry.get("item")
		var chance = entry.get("chance", 1.0)
		if drop_item and randf() <= chance:
			# Offset each drop slightly so they don't stack visually
			var offset_gp = gp + Vector2i(
				item_drops.find(entry) % 3 - 1,
				(item_drops.find(entry) / 3) % 3 - 1
			)
			_spawn_drop(drop_item, offset_gp)


func _spawn_drop(item_res, grid_pos: Vector2i) -> void:
	var map_item = load("res://source/features/realtime/map_item.gd").new()
	map_item.setup(item_res, grid_pos)
	map_item.global_position = Vector2(grid_pos.x * 64 + 32, grid_pos.y * 64 + 32)
	get_tree().current_scene.add_child(map_item)
