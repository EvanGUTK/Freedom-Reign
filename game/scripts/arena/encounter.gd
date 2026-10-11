class_name Encounter
extends Node
## The arena's rules: the first enemy to die drops `drop_item`; when the last
## one dies the arena is cleared (once). Counts the enemies present at ready, so
## it must come after the node that spawns them in the tree.

@export var drop_item: ItemData

var _remaining := 0
var _dropped := false
var _cleared := false


func _ready() -> void:
	_remaining = get_tree().get_nodes_in_group(Groups.ENEMIES).size()
	Events.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Node3D) -> void:
	if not _dropped:
		_dropped = true
		Events.loot_dropped.emit(drop_item, enemy.global_position)
	_remaining -= 1
	if _remaining == 0 and not _cleared:
		_cleared = true
		Events.arena_cleared.emit()
