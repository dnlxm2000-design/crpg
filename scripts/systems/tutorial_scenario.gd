# TutorialScenario - Tutorial scenario

extends Node

signal scenario_started
signal scenario_completed
signal step_completed(step_id: String)
signal enemy_spawned(enemy: Node)

enum TutorialStep {
	INTRO,
	MOVE_TUTORIAL,
	ATTACK_TUTORIAL,
	COVER_TUTORIAL,
	COMBAT_START,
	VICTORY
}

var current_step: TutorialStep = TutorialStep.INTRO
var enemies: Array = []
var is_active: bool = false
var world_sim: Node = null

func _ready():
	add_to_group("scenarios")
	_connect_session()

func _connect_session():
	if has_node("/root/WorldSimulation"):
		world_sim = get_node("/root/WorldSimulation")

func start_tutorial():
	is_active = true
	current_step = TutorialStep.INTRO
	_apply_modifiers()
	scenario_started.emit()
	_show_text("Tutorial: 아이런스컬 습격!\nWASD 이동, SPACE 공격")

func _show_text(text: String):
	print("[TUTORIAL] ", text)

func _apply_modifiers():
	if not world_sim:
		return
	
	var fog_level = world_sim.fog_density
	var orc_level = world_sim.orc_disposition
	var grid_level = world_sim.grid_resonance
	
	var extra = 0
	if fog_level >= 0.7: extra += 1
	if orc_level >= 4: extra += 1
	if grid_level >= 0.7: extra += 1
	
	if extra > 0:
		print("[TUTORIAL] Extra enemies: +", extra)

func next_step():
	current_step += 1
	match current_step:
		TutorialStep.MOVE_TUTORIAL:
			_show_text("이동: WASD 키")
		TutorialStep.ATTACK_TUTORIAL:
			_show_text("공격: SPACE 키")
		TutorialStep.COVER_TUTORIAL:
			_show_text("커버: 회색 타일에서 방어")
		TutorialStep.COMBAT_START:
			_spawn_enemies()
		TutorialStep.VICTORY:
			_complete_tutorial()

func _spawn_enemies():
	var count = 2
	var extra = 0
	
	if world_sim:
		var fog = world_sim.fog_density
		var orc = world_sim.orc_disposition
		
		if fog >= 0.7: extra += 1
		if orc >= 4: extra += 1
	
	var total = count + extra
	_show_text("적 등장! 아이런스컬 " + str(total) + "마리")
	
	var enemy_scene = load("res://scenes/enemy.tscn")
	
	for i in range(total):
		var enemy = enemy_scene.instantiate()
		enemy.enemy_name = "아이런스컬 오크"
		enemy.grid_position = Vector2i(15, 3 + i * 3)
		
		var hp_mult = 1.0
		if world_sim:
			hp_mult = 1.0 + (world_sim.fog_density * 0.2)
			hp_mult += (world_sim.orc_disposition - 3) * 0.1
		
		enemy.max_hp = int(15 * hp_mult)
		enemy.current_hp = enemy.max_hp
		enemy.cr = 1.0
		enemy.xp_reward = 100
		
		enemies.append(enemy)
		enemy_spawned.emit(enemy)

func _complete_tutorial():
	is_active = false
	_show_text("Tutorial Complete!")
	
	var gm = get_node("/root/GameManager")
	if gm:
		gm.set_tutorial_completed()
	
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scenes/scene_selector.tscn")
	scenario_completed.emit()

func check_step_complete() -> bool:
	match current_step:
		TutorialStep.COMBAT_START:
			for e in enemies:
				if is_instance_valid(e) and e.current_hp > 0:
					return false
			return true
	return false

func get_enemies() -> Array:
	return enemies

func _exit_tree():
	is_active = false