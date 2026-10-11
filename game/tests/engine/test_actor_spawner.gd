extends GutTest
## Main spawns the player at the PlayerSpawn marker.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"

var _main: Node3D


func before_each() -> void:
	_main = add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate())


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_exactly_one_player_spawns_at_the_player_spawn_marker() -> void:
	var players := get_tree().get_nodes_in_group("player")
	assert_eq(players.size(), 1)
	if players.size() != 1:
		return
	var marker := _main.get_node("Arena/PlayerSpawn") as Marker3D
	assert_eq((players[0] as Node3D).global_position, marker.global_position)
