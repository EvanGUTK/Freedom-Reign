class_name AttackController
extends Node
## Owns the player's current attack: cooldown gating and applying a swing to
## every enemy in reach. Enemies are the nodes in group `enemies` that have a
## take_damage(amount) method.

@export var starting_attack: AttackData

var current: AttackData

var _cooldown_remaining := 0.0


func _ready() -> void:
	equip(starting_attack)


func _physics_process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


func is_ready() -> bool:
	return _cooldown_remaining <= 0.0


func equip(attack: AttackData) -> void:
	current = attack
	Events.attack_changed.emit(attack)


## Swings from `origin` toward `forward` if the cooldown has elapsed. Returns
## whether a swing happened.
func try_attack(origin: Vector3, forward: Vector3) -> bool:
	if not is_ready():
		return false
	_cooldown_remaining = current.cooldown_seconds
	Events.player_attacked.emit(current)
	var targets := AttackGeometry.enemies_in_range(
		get_tree().get_nodes_in_group(Groups.ENEMIES), origin, forward, current.reach_meters, current.arc_degrees)
	for enemy in targets:
		_hit(enemy)
	return true


func _hit(enemy: Node3D) -> void:
	if not enemy.has_method(&"take_damage"):
		push_error("Node %s is in group 'enemies' but has no take_damage()" % enemy.name)
		return
	Events.player_hit_enemy.emit(enemy, current.damage)
	enemy.call(&"take_damage", current.damage)
