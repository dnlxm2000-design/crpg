# targeting.gd — 전투 타겟팅 시스템.
# HUD의 자식으로 배치한다. 타겟 가능한 적을 순환하고 시각적 하이라이트를 표시한다.
extends Node

## 타겟 변경 시 방출.
signal target_changed(target: Node)

## 현재 선택된 타겟.
var current_target: Node = null
## 타겟 가능한 적 목록.
var _targets: Array[Node] = []
## 현재 타겟 인덱스.
var _current_index: int = -1

## 타겟 하이라이트를 위한 ColorRect (그리드 타일 위에 표시).
var _highlight: ColorRect = null
## 타겟 이름/HP 표시 레이블.
var _target_label: Label = null

## 그리드 월드 참조.
var _grid_world = null


func _ready() -> void:
	# 타겟 하이라이트 생성 (빨강 테두리)
	_highlight = ColorRect.new()
	_highlight.name = "TargetHighlight"
	_highlight.color = Color(1.0, 0.2, 0.2, 0.3)
	_highlight.size = Vector2(30, 30)
	_highlight.visible = false
	_highlight.z_index = 50
	add_child(_highlight)

	# 타겟 정보 레이블 생성
	_target_label = Label.new()
	_target_label.name = "TargetLabel"
	_target_label.add_theme_font_size_override("font_size", 14)
	_target_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	_target_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_target_label.add_theme_constant_override("shadow_outline_size", 2)
	_target_label.visible = false
	_target_label.z_index = 51
	add_child(_target_label)

	# 시그널
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.unit_destroyed.connect(_on_unit_destroyed)
	EventBus.unit_moved.connect(_on_unit_moved)
	EventBus.game_mode_changed.connect(_on_mode_changed)

	_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")


func _on_combat_started(participants: Array) -> void:
	# 전투 시작 시 타겟 목록 업데이트
	_targets = _find_targetable_enemies()
	if _targets.size() > 0:
		select_target(0)
	else:
		clear_target()


func _on_combat_ended() -> void:
	clear_target()
	_targets.clear()


func _on_turn_started(unit: Node) -> void:
	if unit.get("is_player") != true:
		_highlight.visible = false
		_target_label.visible = false
		return
	# 타겟 목록 새로고침
	_targets = _find_targetable_enemies()
	if current_target and current_target in _targets:
		_update_highlight()
	else:
		select_first_target()


func _on_unit_destroyed(unit: Node) -> void:
	_targets.erase(unit)
	if unit == current_target:
		select_first_target()


func _on_unit_moved(unit: Node, _from: Vector2, _to: Vector2) -> void:
	if unit == current_target:
		_update_highlight()


func _on_mode_changed(mode: String) -> void:
	if mode != "turnbased":
		_highlight.visible = false
		_target_label.visible = false


## 타겟 가능한 적 목록 갱신 (같은 그리드 내 살아있는 적).
func refresh_targets() -> void:
	_targets = _find_targetable_enemies()
	if _targets.is_empty():
		clear_target()
	elif current_target not in _targets:
		select_first_target()


## 타겟 가능한 적 찾기.
func _find_targetable_enemies() -> Array[Node]:
	var enemies: Array[Node] = []
	var tm = get_node_or_null("/root/Main/GameLoop/TurnManager")
	if not tm or not tm.get("combatants"):
		return []

	for c in tm.combatants:
		if not is_instance_valid(c):
			continue
		var is_alive = c.get("is_alive") if "is_alive" in c else false
		var is_player = c.get("is_player") if "is_player" in c else false
		if is_alive and not is_player:
			enemies.append(c)

	return enemies


## 다음 타겟으로 이동.
func cycle_next() -> void:
	if _targets.is_empty():
		return
	if _current_index < _targets.size() - 1:
		select_target(_current_index + 1)
	else:
		select_target(0)


## 이전 타겟으로 이동.
func cycle_prev() -> void:
	if _targets.is_empty():
		return
	if _current_index > 0:
		select_target(_current_index - 1)
	else:
		select_target(_targets.size() - 1)


## 인덱스로 타겟 선택.
func select_target(index: int) -> void:
	if index < 0 or index >= _targets.size():
		return
	_current_index = index
	current_target = _targets[index]
	_update_highlight()
	target_changed.emit(current_target)


## 첫 번째 타겟 선택.
func select_first_target() -> void:
	if _targets.is_empty():
		clear_target()
		return
	select_target(0)


## 타겟 해제.
func clear_target() -> void:
	current_target = null
	_current_index = -1
	_highlight.visible = false
	_target_label.visible = false


## 하이라이트 위치 업데이트.
func _update_highlight() -> void:
	if not current_target or not is_instance_valid(current_target):
		_highlight.visible = false
		_target_label.visible = false
		return

	if not _grid_world:
		_grid_world = get_node_or_null("/root/Main/GameLoop/GridWorld")
	if not _grid_world:
		return

	var grid_pos: Vector2i = _grid_world.world_to_grid(current_target.global_position)
	var world_pos: Vector2 = _grid_world.grid_to_world(grid_pos)

	_highlight.position = world_pos - Vector2(15, 15)  # Center on tile
	_highlight.visible = true

	# 타겟 정보 레이블 (하이라이트 위에 표시)
	var unit_name = current_target.get("unit_name") if "unit_name" in current_target else "Enemy"
	var hp = current_target.get("current_hp") if "current_hp" in current_target else 0
	var max_hp = current_target.get("max_hp") if "max_hp" in current_target else 100
	_target_label.text = "%s\nHP: %d/%d" % [unit_name, hp, max_hp]
	_target_label.position = world_pos - Vector2(40, 60)
	_target_label.visible = true
