class_name LootSpawner
extends Node
## Turns Events.loot_dropped into a pickup in the world.

## Drops hover this far above where the enemy died so they are not buried in the floor.
const HOVER_HEIGHT := 0.6

@export var pickup_scene: PackedScene


func _ready() -> void:
	Events.loot_dropped.connect(_on_loot_dropped)


func _on_loot_dropped(item: ItemData, world_position: Vector3) -> void:
	var pickup := pickup_scene.instantiate() as LootPickup
	pickup.item = item
	add_child(pickup)
	pickup.global_position = world_position + Vector3.UP * HOVER_HEIGHT
