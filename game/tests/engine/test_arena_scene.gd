extends GutTest
## main.tscn composition and the arena's layout, per docs/CONTRACTS.md.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const ENEMY_SPAWN_COUNT := 5
const FLOOR_SIDE_METERS := 30.0
const PLATFORM_TOP_HEIGHTS := [1.5, 3.0, 4.5]
const HEIGHT_TOLERANCE := 0.001

var _main: Node3D


func before_each() -> void:
	_main = add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate())


func _top_of(body: StaticBody3D) -> float:
	var shape := body.get_node("Shape") as CollisionShape3D
	return body.global_position.y + (shape.shape as BoxShape3D).size.y / 2.0


func test_main_has_arena_and_ui_children() -> void:
	assert_true(_main.get_node("Arena") is Node3D, "Main/Arena")
	assert_true(_main.get_node("UI") is CanvasLayer, "Main/UI")


func test_main_has_no_script() -> void:
	assert_null(_main.get_script(), "Main is a bare Node3D until gameplay needs it")


func test_ui_root_is_a_bare_canvas_layer() -> void:
	var ui := _main.get_node("UI")
	assert_null(ui.get_script(), "ui_root has no script")
	assert_eq(ui.get_child_count(), 0, "ui_root has no content; frontend fills it")


func test_floor_is_30_by_30_with_top_at_ground_level() -> void:
	var floor_body := _main.get_node("Arena/Floor") as StaticBody3D
	var shape := (floor_body.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
	assert_eq(shape.size.x, FLOOR_SIDE_METERS)
	assert_eq(shape.size.z, FLOOR_SIDE_METERS)
	assert_almost_eq(_top_of(floor_body), 0.0, HEIGHT_TOLERANCE)


func test_platform_tops_are_at_contract_heights() -> void:
	var platforms := _main.get_node("Arena/Platforms")
	assert_eq(platforms.get_child_count(), PLATFORM_TOP_HEIGHTS.size(), "platform count")
	var tops: Array[float] = []
	for platform in platforms.get_children():
		tops.append(_top_of(platform as StaticBody3D))
	tops.sort()
	for i in PLATFORM_TOP_HEIGHTS.size():
		assert_almost_eq(tops[i], PLATFORM_TOP_HEIGHTS[i], HEIGHT_TOLERANCE, "platform %d top" % i)


func test_world_geometry_is_on_the_world_layer() -> void:
	var bodies: Array[Node] = [_main.get_node("Arena/Floor")]
	bodies.append_array(_main.get_node("Arena/Platforms").get_children())
	for body in bodies:
		assert_eq((body as StaticBody3D).collision_layer, 1, "%s should be on layer 1 (World)" % body.name)


func test_five_enemy_spawn_markers() -> void:
	var spawns := _main.get_node("Arena/Spawns")
	assert_eq(spawns.get_child_count(), ENEMY_SPAWN_COUNT)
	var positions := {}
	for spawn in spawns.get_children():
		assert_true(spawn is Marker3D, "%s should be a Marker3D" % spawn.name)
		positions[(spawn as Marker3D).position] = true
	assert_eq(positions.size(), ENEMY_SPAWN_COUNT, "spawn markers should be at distinct positions")


func test_player_spawn_marker_exists_inside_the_floor() -> void:
	var spawn := _main.get_node("Arena/PlayerSpawn") as Marker3D
	assert_not_null(spawn)
	if spawn == null:
		return
	assert_lt(absf(spawn.position.x), FLOOR_SIDE_METERS / 2.0)
	assert_lt(absf(spawn.position.z), FLOOR_SIDE_METERS / 2.0)
