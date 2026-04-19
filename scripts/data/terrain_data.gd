# TerrainData - 지형 타일 데이터 관리

extends Node

var terrain_data: Dictionary = {}

func _ready():
	load_terrain_data()

func load_terrain_data():
	if FileAccess.file_exists("res://data/terrain.json"):
		var file = FileAccess.open("res://data/terrain.json", FileAccess.READ)
		if file:
			var json = JSON.parse_string(file.get_as_text())
			if json:
				terrain_data = json
				print("Loaded terrain data v", terrain_data.get("version", "1.0"))
				file.close()
	else:
		_create_default_terrain_data()

func _create_default_terrain_data():
	terrain_data = {
		"tile_size": 2.0,
		"map_width": 20,
		"map_height": 20,
		"tiles": {
			"0": {"name": "벽", "walkable": false, "height": 2.0, "elevation": 2.0, "slope": 90},
			"1": {"name": "바닥", "walkable": true, "height": 0.1, "elevation": 0.0, "slope": 0},
			"4": {"name": "커버", "walkable": true, "height": 1.0, "elevation": 1.0, "slope": 45}
		}
	}

func get_tile_data(tile_id: String) -> Dictionary:
	return terrain_data.get("tiles", {}).get(tile_id, {})

func get_obstacle_data(obstacle_id: String) -> Dictionary:
	return terrain_data.get("obstacles", {}).get(obstacle_id, {})

func get_tile_size() -> float:
	return terrain_data.get("tile_size", 2.0)

func get_map_size() -> Vector2i:
	return Vector2i(
		terrain_data.get("map_width", 20),
		terrain_data.get("map_height", 20)
	)

func is_walkable(tile_id: int) -> bool:
	var tile = get_tile_data(str(tile_id))
	return tile.get("walkable", false)

func get_elevation(tile_id: int) -> float:
	var tile = get_tile_data(str(tile_id))
	return tile.get("elevation", 0.0)

func get_slope(tile_id: int) -> float:
	var tile = get_tile_data(str(tile_id))
	return tile.get("slope", 0)

func calculate_movement_cost(base_cost: int, tile_id: int) -> int:
	var elevation = get_elevation(tile_id)
	var slope = get_slope(tile_id)
	var cost = base_cost
	
	if elevation > 0:
		cost += terrain_data.get("elevation_rules", {}).get("elevation_bonus", 1)
	if slope > 30:
		cost += terrain_data.get("elevation_rules", {}).get("slope_bonus_AP", 2)
	
	return cost

func get_terrain_effect(tile_id: int) -> Dictionary:
	var terrain_rules = terrain_data.get("terrain_effects", {})
	var elevation = get_elevation(tile_id)
	var slope = get_slope(tile_id)
	
	if elevation > 1.0:
		return terrain_rules.get("high_ground", {})
	if slope > 20 and slope < 60:
		return terrain_rules.get("slope", {})
	if tile_id == 4:
		return terrain_rules.get("cover", {})
	
	return {}