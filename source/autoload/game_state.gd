# game_state.gd — Persisted game state singleton.
# Attach as an Autoload singleton named "GameState".
extends Node

## Current game mode
enum GameMode { MENU, REALTIME, TURNBASED }
var current_mode: GameMode = GameMode.MENU

## Global time tracking
var total_time_elapsed: float = 0.0
var current_round: int = 0

## Player data
var player_party: Array = []
var inventory: Dictionary = {}

## Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"fullscreen": false,
}


func _ready() -> void:
	load_settings()


func save_settings() -> void:
	var file = FileAccess.open("user://settings.cfg", FileAccess.WRITE)
	if file:
		file.store_var(settings)


func load_settings() -> void:
	var file = FileAccess.open("user://settings.cfg", FileAccess.READ)
	if file:
		var loaded = file.get_var()
		if loaded is Dictionary:
			settings = loaded
