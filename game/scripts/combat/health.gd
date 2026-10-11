class_name Health
extends RefCounted
## Hit points with no scene dependency. Owners translate its signals into Events.

signal changed(current: int, maximum: int)
signal depleted()

var maximum: int = 0
var current: int = 0


func setup(maximum_health: int) -> void:
	maximum = maximum_health
	current = maximum_health
	changed.emit(current, maximum)


func is_dead() -> bool:
	return current <= 0


func take_damage(amount: int) -> void:
	if amount <= 0:
		push_error("Health.take_damage needs a positive amount, got %d" % amount)
		return
	if is_dead():
		return
	current = maxi(current - amount, 0)
	changed.emit(current, maximum)
	if current == 0:
		depleted.emit()
