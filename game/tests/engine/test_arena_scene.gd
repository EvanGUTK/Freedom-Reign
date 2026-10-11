extends GutTest
## main.tscn composition and the arena's layout, per docs/CONTRACTS.md.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const ENEMY_SPAWN_COUNT := 5
const FLOOR_SIDE_METERS := 30.0
const PLATFORM_TOP_HEIGHTS := [1.5, 3.0, 4.5]
const HEIGHT_TOLERANCE := 0.001
const WORLD_LAYER_BIT := 1
const WALL_COUNT := 4

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
	bodies.append_array(_main.get_node("Arena/Walls").get_children())
	for body in bodies:
		assert_eq((body as StaticBody3D).collision_layer, WORLD_LAYER_BIT, "%s should be on the World layer" % body.name)


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


func test_four_walls_enclose_the_floor() -> void:
	var walls := _main.get_node("Arena/Walls").get_children()
	assert_eq(walls.size(), WALL_COUNT)
	for wall in walls:
		var shape := (wall.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		assert_gt(shape.size.y, 4.5, "%s is taller than the highest platform so nobody jumps out" % wall.name)


func test_platforms_are_solid_down_to_the_floor() -> void:
	for platform in _main.get_node("Arena/Platforms").get_children():
		var shape := (platform.get_node("Shape") as CollisionShape3D).shape as BoxShape3D
		assert_almost_eq(platform.global_position.y - shape.size.y / 2.0, 0.0, HEIGHT_TOLERANCE, "%s base on the floor" % platform.name)


func test_steps_between_platform_tops_are_jumpable() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as Player
	var reachable_rise := player.jump_height
	player.free()
	var previous_top := 0.0
	for height in PLATFORM_TOP_HEIGHTS:
		assert_lt(height - previous_top, reachable_rise, "each step up is within the jump height")
		previous_top = height


func test_there_is_a_sun_and_a_world_environment() -> void:
	var sun := _main.get_node("Arena/Sun") as DirectionalLight3D
	assert_not_null(sun)
	assert_lt((sun.global_transform.basis * Vector3.FORWARD).y, -0.5, "the sun shines steeply downward")
	var environment := _main.get_node("Arena/Environment") as WorldEnvironment
	assert_not_null(environment.environment)
