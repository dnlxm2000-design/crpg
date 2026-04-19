# EmergentEvents - Event triggering system based on physical changes

extends Node

var world_sim: Node = null

var event_history: Array = []
var active_events: Dictionary = {}

var event_triggers: Dictionary = {
	"famine": {
		"condition": "food_shortage >= 3",
		"chance": 0.3,
		"effects": ["unrest", "refugees", "collapse"],
		"political_response": "aid_demand"
	},
	"plague": {
		"condition": "fog_density >= 0.7",
		"chance": 0.2,
		"effects": ["population_loss", "quarantine", "panic"],
		"political_response": "isolation"
	},
	"orc_invasion": {
		"condition": "orc_disposition >= 4",
		"chance": 0.4,
		"effects": ["war", "siege", "refugees"],
		"political_response": "defense_call"
	},
	"grid_surge": {
		"condition": "grid_resonance >= 0.8",
		"chance": 0.2,
		"effects": ["magic_storm", "portal_opening", "manifestation"],
		"political_response": "sacred_mobilization"
	},
	"trade_embargo": {
		"condition": "settlement_conflict >= 2",
		"chance": 0.25,
		"effects": ["price_hike", "shortage", "black_market"],
		"political_response": "negotiation"
	},
	"discovery": {
		"condition": "exploration >= 5",
		"chance": 0.3,
		"effects": ["relic", "map", "secret"],
		"political_response": "research"
	}
}

var settlement_events: Dictionary = {
	"silverhaven": {
		"possible_events": ["famine", "orc_invasion", "plague"],
		"defense_priority": "high"
	},
	"ironclad": {
		"possible_events": ["plague", "discovery"],
		"defense_priority": "high"
	},
	"hollyetheria": {
		"possible_events": ["grid_surge", "plague"],
		"defense_priority": "medium"
	},
	"ventura": {
		"possible_events": ["trade_embargo", "discovery"],
		"defense_priority": "low"
	}
}

func _ready():
	pass

func set_world_simulation(ref: Node):
	world_sim = ref

func check_emergent_events() -> Array:
	var new_events: Array = []
	
	if not world_sim:
		return new_events
	
	var fog = world_sim.fog_density
	var grid = world_sim.grid_resonance
	var orc = world_sim.orc_disposition
	
	if fog >= 0.7 and _roll_chance(0.2):
		new_events.append(_create_event("plague", "Plague spreads through the fog"))
	
	if orc >= 4 and _roll_chance(0.4):
		new_events.append(_create_event("orc_invasion", "Orc horde launches attack"))
	
	if grid >= 0.8 and _roll_chance(0.2):
		new_events.append(_create_event("grid_surge", "Grid resonance creates magical storm"))
	
	for settlement_id in settlement_events.keys():
		var settlement_data = settlement_events[settlement_id]
		var possible = settlement_data.get("possible_events", [])
		
		for event_type in possible:
			var trigger = event_triggers.get(event_type, {})
			if _evaluate_condition(trigger.get("condition", ""), fog, grid, orc):
				if _roll_chance(trigger.get("chance", 0.1)):
					var event = _create_event(event_type, event_type + " at " + settlement_id)
					event["settlement"] = settlement_id
					new_events.append(event)
	
	for event in new_events:
		event_history.append(event)
		print("[EmergentEvents] New event: ", event.get("type"), " - ", event.get("description"))
	
	return new_events

func _create_event(event_type: String, description: String) -> Dictionary:
	var trigger = event_triggers.get(event_type, {})
	
	return {
		"type": event_type,
		"description": description,
		"effects": trigger.get("effects", []),
		"political_response": trigger.get("political_response", ""),
		"day_created": 0,
		"active": true
	}

func _evaluate_condition(condition: String, fog: float, grid: float, orc: int) -> bool:
	if condition.is_empty():
		return false
	
	match condition:
		"food_shortage >= 3":
			return true
		"fog_density >= 0.7":
			return fog >= 0.7
		"orc_disposition >= 4":
			return orc >= 4
		"grid_resonance >= 0.8":
			return grid >= 0.8
		"settlement_conflict >= 2":
			return orc >= 3
		"exploration >= 5":
			return true
	
	return false

func _roll_chance(chance: float) -> bool:
	return randf() < chance

func trigger_custom_event(event_type: String, description: String, settlement_id: String = "") -> Dictionary:
	var event = _create_event(event_type, description)
	if not settlement_id.is_empty():
		event["settlement"] = settlement_id
	
	event_history.append(event)
	active_events[event_type] = event
	
	print("[EmergentEvents] Custom event triggered: ", event_type)
	
	return event

func get_event_by_type(event_type: String) -> Dictionary:
	return active_events.get(event_type, {})

func get_recent_events(count: int = 5) -> Array:
	var recent = []
	var size = event_history.size()
	
	for i in range(max(0, size - count), size):
		recent.append(event_history[i])
	
	return recent

func clear_history():
	event_history.clear()
	active_events.clear()

func serialize() -> Dictionary:
	return {
		"event_history": event_history,
		"active_events": active_events.keys()
	}

func deserialize(data: Dictionary):
	event_history = data.get("event_history", [])
	active_events.clear()
	
	for key in data.get("active_events", []):
		active_events[key] = {}