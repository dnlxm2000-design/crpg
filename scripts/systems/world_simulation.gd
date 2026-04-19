# WorldSimulation - Physical variable layer management

extends Node

var fog_density: float = 0.5
var grid_resonance: float = 0.5
var orc_disposition: int = 3

var settlements_data: Dictionary = {}
var resources_data: Dictionary = {}
var political_factions_data: Dictionary = {}

var session_name: String = "New Session"
var day_count: int = 0
var season: String = "autumn"

var settlements: Dictionary = {}
var factions: Dictionary = {}

func _ready():
	_load_data()

func _load_data():
	var file = FileAccess.open("res://data/settlements.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and json is Dictionary:
			settlements_data = json.get("settlements", {})
			var _trade_routes = json.get("trade_routes", [])
		file.close()
	
	file = FileAccess.open("res://data/resources.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and json is Dictionary:
			resources_data = json.get("resource_types", {})
		file.close()
	
	file = FileAccess.open("res://data/political_factions.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json and json is Dictionary:
			political_factions_data = json.get("factions", {})
		file.close()

func initialize_new_session(new_fog: float, new_grid: float, new_orc: int):
	fog_density = clamp(new_fog, 0.0, 1.0)
	grid_resonance = clamp(new_grid, 0.0, 1.0)
	orc_disposition = clamp(new_orc, 1, 5)
	day_count = 0

func get_fog_visibility() -> float:
	return 60.0 * (1.0 - fog_density)

func get_magic_success_modifier() -> float:
	var base = 1.0 - fog_density * 0.5
	return base * grid_resonance

func get_encounter_rate() -> float:
	var base = 0.1
	base += fog_density * 0.2
	base += (1.0 - grid_resonance) * 0.3
	return base

func get_orc_aggression() -> int:
	return orc_disposition

func get_orc_disposition_name() -> String:
	match orc_disposition:
		1: return "Negotiable"
		2: return "Cautious"
		3: return "Hostile"
		4: return "Aggressive"
		5: return "Annihilation"
	return "Unknown"

func advance_day(delta_days: int = 1):
	day_count += delta_days
	_season_check()
	_update_settlements()
	_update_factions()

func _season_check():
	if day_count % 90 == 0:
		var seasons = ["spring", "summer", "autumn", "winter"]
		var idx = int(day_count / 90.0) % 4
		season = seasons[idx]

func _update_settlements():
	for settlement_id in settlements_data.keys():
		var data = settlements_data[settlement_id]
		var output = data.get("resource_output", {})
		var demand = data.get("resource_demand", {})
		
		for res_type in demand.keys():
			var shortfall = demand.get(res_type, 0) - output.get(res_type, 0)
			if shortfall > 0:
				_apply_resource_shortage(settlement_id, res_type, shortfall)

func _apply_resource_shortage(_settlement_id: String, resource_type: String, _shortfall: int):
	var effect_key = resource_type + "_shortage"
	var _effects = resources_data.get("resource_effects", {}).get(effect_key, {})

func _update_factions():
	for faction_id in political_factions_data.keys():
		var faction = political_factions_data[faction_id]
		var personality = faction.get("personality_template", "neutral")
		
		var response_key = ""
		if orc_disposition <= 2:
			response_key = "peace_treaty"
		elif orc_disposition >= 4:
			response_key = "threat_nearby"
		
		if not response_key.is_empty():
			var response = faction.get("environment_response", {}).get(response_key, "")

func get_settlement_by_id(id: String) -> Dictionary:
	return settlements_data.get(id, {})

func get_faction_by_id(id: String) -> Dictionary:
	return political_factions_data.get(id, {})

func get_trade_route_distance(from_id: String, to_id: String) -> int:
	var routes = [
		{"from": "silverhaven", "to": "ventura", "distance": 20},
		{"from": "silverhaven", "to": "hollyetheria", "distance": 15},
		{"from": "ironclad", "to": "ember_forge", "distance": 10},
		{"from": "ironclad", "to": "hollyetheria", "distance": 30},
		{"from": "ventura", "to": "snowfell", "distance": 40}
	]
	
	for route in routes:
		if (route.get("from") == from_id and route.get("to") == to_id) or (route.get("from") == to_id and route.get("to") == from_id):
			return route.get("distance", 999)
	
	return 999

func calculate_trade_cost(from_id: String, to_id: String) -> int:
	var distance = get_trade_route_distance(from_id, to_id)
	if distance >= 999:
		return 999
	
	var base_cost = distance
	var fog_penalty = int(fog_density * 5)
	return base_cost + fog_penalty

func set_fog_density(value: float):
	fog_density = clamp(value, 0.0, 1.0)

func set_grid_resonance(value: float):
	grid_resonance = clamp(value, 0.0, 1.0)

func set_orc_disposition(value: int):
	orc_disposition = clamp(value, 1, 5)

func serialize() -> Dictionary:
	return {
		"session_name": session_name,
		"fog_density": fog_density,
		"grid_resonance": grid_resonance,
		"orc_disposition": orc_disposition,
		"day_count": day_count,
		"season": season
	}

func deserialize(data: Dictionary):
	session_name = data.get("session_name", "New Session")
	fog_density = data.get("fog_density", 0.5)
	grid_resonance = data.get("grid_resonance", 0.5)
	orc_disposition = data.get("orc_disposition", 3)
	day_count = data.get("day_count", 0)
	season = data.get("season", "autumn")
