class_name ContactAttack
extends RefCounted
## Timing of an enemy's touch damage: lands on the first tick the target is in
## range, then at most once per interval while it stays in range. The interval
## keeps running while the target is out of range.

var interval: float
var range_meters: float

var _cooldown_remaining := 0.0


func _init(interval_seconds: float, range_in_meters: float) -> void:
	interval = interval_seconds
	range_meters = range_in_meters


## Advances time by `delta`; returns true when a hit lands this tick.
func tick(delta: float, distance_to_target: float) -> bool:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
	if distance_to_target > range_meters or _cooldown_remaining > 0.0:
		return false
	_cooldown_remaining = interval
	return true
