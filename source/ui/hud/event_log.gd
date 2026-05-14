# event_log.gd — 전투 및 게임 이벤트 로그 패널.
# EventBus 시그널을 받아 색상 구분된 로그 메시지를 표시한다.
# HUD(CanvasLayer)의 자식으로 배치되어야 한다.
extends Panel

# 최대 로그 줄 수 (초과 시 오래된 항목 제거)
const MAX_ENTRIES: int = 100
# 패널 크기 (화면 1280×720 기준 하단 사각형 영역)
const PANEL_W: int = 470
const PANEL_H: int = 110

var _scroll: ScrollContainer = null       # 스크롤 가능한 로그 영역
var _container: VBoxContainer = null      # 로그 항목들을 쌓는 컨테이너
var _player_unit: Node = null             # 플레이어 참조 (이름 표시용)


func _ready() -> void:
	# ── 패널 외형: 반투명 어두운 배경, 하단 (800, 600) 위치 ──
	size = Vector2(PANEL_W, PANEL_H)
	position = Vector2(800, 600)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.1, 0.75)       # 75% 불투명 진한 남색
	add_theme_stylebox_override("panel", bg)

	# ── 제목 표시줄 ──
	var title := Label.new()
	title.text = "LOG"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	title.position = Vector2(6, 4)
	title.size = Vector2(60, 18)
	add_child(title)

	# ── 최소화 버튼 ──
	var minimize_btn := Button.new()
	minimize_btn.text = "_"
	minimize_btn.position = Vector2(PANEL_W - 56, 2)
	minimize_btn.size = Vector2(24, 18)
	minimize_btn.add_theme_font_size_override("font_size", 10)
	minimize_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	minimize_btn.pressed.connect(_on_toggle_minimize)
	add_child(minimize_btn)

	# ── 닫기 버튼 (X) ──
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.position = Vector2(PANEL_W - 28, 2)
	close_btn.size = Vector2(24, 18)
	close_btn.add_theme_font_size_override("font_size", 10)
	close_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	close_btn.pressed.connect(_on_close)
	add_child(close_btn)

	# ── 스크롤 가능한 로그 목록 ──
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(4, 22)
	_scroll.size = Vector2(PANEL_W - 8, PANEL_H - 26)   # 패널 여백 제외
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED   # 세로 스크롤 전용
	add_child(_scroll)

	_container = VBoxContainer.new()
	_container.size = Vector2(PANEL_W - 16, 0)
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_container)

	# ── EventBus 시그널 연결 (전투 진행/종료, 턴, 피해, 모드 변경 등) ──
	EventBus.combat_started.connect(_on_combat_started)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.combat_victory.connect(_on_combat_victory)
	EventBus.combat_defeat.connect(_on_combat_defeat)
	EventBus.round_started.connect(_on_round_started)
	EventBus.round_ended.connect(_on_round_ended)
	EventBus.turn_started.connect(_on_turn_started)
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.unit_destroyed.connect(_on_unit_destroyed)
	EventBus.player_ended_turn.connect(_on_player_ended_turn)
	EventBus.game_mode_changed.connect(_on_game_mode_changed)
	EventBus.turn_mode_entered.connect(_on_turn_mode_entered)
	EventBus.realtime_mode_entered.connect(_on_realtime_mode_entered)
	EventBus.unit_moved.connect(func(unit, _f, _t): _log_unit_moved(unit))
	EventBus.ap_changed.connect(_on_ap_changed)

	# 씬 트리가 준비된 후 플레이어 찾기
	await get_tree().process_frame
	_find_player()


func _find_player() -> void:
	"""RealTimeManager에서 플레이어 유닛 참조를 가져온다."""
	var rt = get_node("/root/Main/RealTimeManager")
	if rt and rt.get("player_ref"):
		_player_unit = rt.player_ref


func _get_name(unit: Node) -> String:
	"""유닛의 이름을 안전하게 반환한다 (null 안전)."""
	if not unit or not is_instance_valid(unit):
		return "?"
	var name = unit.get("unit_name") if "unit_name" in unit else "Unit"
	return name


## 로그 항목을 추가한다. msg: 내용, clr: 글자색 (기본 회백색).
func add_entry(msg: String, clr: Color = Color(0.8, 0.8, 0.85)) -> void:
	if not _container:
		return
	var entry := Label.new()
	entry.text = msg
	entry.add_theme_color_override("font_color", clr)
	entry.add_theme_font_size_override("font_size", 12)
	entry.size = Vector2(PANEL_W - 24, 0)                 # 패널 양옆 여백
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # 자동 줄바꿈
	entry.max_lines_visible = 4
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_container.add_child(entry)

	# 최대 항목 수 제한 (초과 시 가장 오래된 항목 제거)
	if _container.get_child_count() > MAX_ENTRIES:
		var old = _container.get_child(0)
		_container.remove_child(old)
		old.queue_free()

	# 항상 가장 최신 항목(하단)으로 자동 스크롤
	_scroll.scroll_vertical = 999999


## ─── Signal handlers ───

func _on_combat_started(participants: Array) -> void:
	_find_player()
	var names = PackedStringArray()
	for u in participants:
		names.append(_get_name(u))
	add_entry("⚔ COMBAT! Participants: %s" % ", ".join(names), Color(1.0, 0.9, 0.4))


func _on_combat_ended() -> void:
	add_entry("Combat ended", Color(0.6, 0.6, 0.7))


func _on_combat_victory() -> void:
	add_entry("★ VICTORY", Color(0.3, 1.0, 0.3))


func _on_combat_defeat() -> void:
	add_entry("★ DEFEAT", Color(1.0, 0.3, 0.3))


func _on_round_started(round_num: int) -> void:
	add_entry("── Round %d ──" % round_num, Color(1.0, 0.85, 0.4))


func _on_round_ended(round_num: int) -> void:
	add_entry("   Round %d end" % round_num, Color(0.5, 0.5, 0.5))


func _on_turn_started(unit: Node) -> void:
	if not unit or not is_instance_valid(unit):
		return
	var name = _get_name(unit)
	add_entry("%s's Turn" % name, Color(0.9, 0.9, 0.95))


func _on_unit_damaged(unit: Node, amount: int, source: Node) -> void:
	if not unit or not is_instance_valid(unit):
		return
	var unit_name = _get_name(unit)
	var src_name = _get_name(source)

	var is_player_target: bool = (unit == _player_unit)
	var is_player_source: bool = (source == _player_unit)

	if is_player_target:
		# Player took damage → red
		add_entry("%s hit %s for %d damage" % [src_name, unit_name, amount], Color(1.0, 0.4, 0.4))
	elif is_player_source:
		# Player dealt damage → orange
		add_entry("%s attacks %s for %d damage" % [src_name, unit_name, amount], Color(1.0, 0.7, 0.3))
	else:
		# Enemy vs Enemy → gray
		add_entry("%s hits %s for %d" % [src_name, unit_name, amount], Color(0.6, 0.6, 0.7))


func _on_unit_destroyed(unit: Node) -> void:
	if not unit or not is_instance_valid(unit):
		return
	var name = _get_name(unit)
	if unit == _player_unit:
		add_entry("★ %s defeated!" % name, Color(1.0, 0.3, 0.3))
	else:
		add_entry("%s defeated!" % name, Color(0.3, 1.0, 0.3))


func _on_player_ended_turn(unit: Node) -> void:
	var name = _get_name(unit)
	add_entry("  %s ended their turn" % name, Color(0.55, 0.55, 0.6))


func _on_game_mode_changed(mode: String) -> void:
	add_entry("Mode: %s" % mode.to_upper(), Color(0.5, 0.5, 0.6))


func _on_turn_mode_entered() -> void:
	pass  # combat_started is more informative


func _on_realtime_mode_entered() -> void:
	pass


func _log_unit_moved(unit: Node) -> void:
	if not unit or not is_instance_valid(unit):
		return
	var name = _get_name(unit)
	add_entry("  %s moved" % name, Color(0.5, 0.7, 0.9))


func _on_ap_changed(unit: Node) -> void:
	if unit == _player_unit and unit and is_instance_valid(unit):
		var ap = unit.get("current_action_points") if "current_action_points" in unit else 0
		if ap <= 0:
			add_entry("  AP depleted", Color(0.6, 0.5, 0.3))


## Toggle between full and minimized height.
var _minimized: bool = false
func _on_toggle_minimize() -> void:
	_minimized = not _minimized
	if _minimized:
		size.y = 24  # title-only
		_scroll.visible = false
	else:
		size.y = PANEL_H
		_scroll.visible = true


func _on_close() -> void:
	visible = false
