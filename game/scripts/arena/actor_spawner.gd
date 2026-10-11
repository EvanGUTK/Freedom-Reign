class_name ActorSpawner
extends Node
## Places the player at its spawn marker and one husk at each enemy marker when
## the round starts. Spawned actors become children of this node.

@export var player_scene: PackedScene
@export var husk_scene: PackedScene
@export var player_spawn: Marker3D
@export var enemy_spawns: Node3D


func _ready() -> void:
	_spawn(player_scene, player_spawn)
	for marker in enemy_spawns.get_children():
		_spawn(husk_scene, marker as Marker3D)


func _spawn(scene: PackedScene, marker: Marker3D) -> Node3D:
	var actor := scene.instantiate() as Node3D
	add_child(actor)
	actor.global_position = marker.global_position
	return actor
