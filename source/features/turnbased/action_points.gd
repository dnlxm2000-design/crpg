# action_points.gd — Action Point component for turn-based units.
# Attach to any unit that needs AP management.
class_name ActionPoints
extends Node

## Maximum AP per turn.
@export var max_ap: int = 4
## Current AP (reset each turn).
var current_ap: int = 4
## Bonus AP from equipment/buffs (added on turn start).
var bonus_ap: int = 0


func _ready() -> void:
	current_ap = max_ap


func reset_for_turn() -> void:
	current_ap = max_ap + bonus_ap


func can_afford(cost: int) -> bool:
	return current_ap >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	current_ap -= cost
	return true


func add_bonus(amount: int) -> void:
	bonus_ap += amount


func remove_bonus(amount: int) -> void:
	bonus_ap = max(0, bonus_ap - amount)
