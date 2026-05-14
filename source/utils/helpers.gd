# helpers.gd — Shared utility functions (static methods only).
extends Node


static func clampf(value: float, min_val: float, max_val: float) -> float:
	return max(min_val, min(value, max_val))


## Check if a value is approximately zero.
static func is_zero(value: float, epsilon: float = 0.001) -> bool:
	return abs(value) < epsilon


## Convert a direction vector to a facing angle in degrees.
static func direction_to_angle(direction: Vector2) -> float:
	return rad_to_deg(atan2(direction.y, direction.x))
