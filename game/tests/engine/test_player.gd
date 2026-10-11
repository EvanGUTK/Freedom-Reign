extends GutTest
## The player scene's event contract: health at ready, hurt, died, input lockout.

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"

var _player: Player


func before_each() -> void:
	watch_signals(Events)
	_player = add_child_autofree((load(PLAYER_SCENE_PATH) as PackedScene).instantiate())


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_player_is_on_the_player_layer_and_in_the_player_group() -> void:
	assert_eq(_player.collision_layer, WorldPhysics.LAYER_PLAYER)
	assert_true(_player.is_in_group("player"))


func test_contract_defaults() -> void:
	assert_eq(_player.max_health, 100)
	assert_eq(_player.walk_speed, 6.0)
	assert_eq(_player.jump_height, 2.2)
	assert_eq(_player.gravity, 24.0)


func test_health_is_announced_at_ready() -> void:
	assert_signal_emitted_with_parameters(Events, "player_health_changed", [100, 100])


func test_damage_emits_hurt_then_new_health() -> void:
	_player.take_damage(30)
	assert_signal_emitted_with_parameters(Events, "player_hurt", [30])
	assert_signal_emitted_with_parameters(Events, "player_health_changed", [70, 100])
	assert_signal_not_emitted(Events, "player_died")
	assert_true(_player.is_alive())


func test_lethal_damage_emits_died_exactly_once_and_ignores_later_hits() -> void:
	_player.take_damage(100)
	_player.take_damage(10)
	assert_signal_emit_count(Events, "player_died", 1)
	assert_signal_emit_count(Events, "player_hurt", 1, "a dead player is not hurt again")
	assert_false(_player.is_alive())


func test_camera_stops_looking_when_the_player_dies() -> void:
	var rig := _player.get_node("CameraRig") as CameraRig
	assert_true(rig.is_look_enabled())
	_player.take_damage(100)
	assert_false(rig.is_look_enabled(), "end screen needs the mouse back")


func test_camera_look_turns_and_clamps_pitch() -> void:
	var rig := _player.get_node("CameraRig") as CameraRig
	rig.look(0.5, 0.0)
	assert_almost_eq(rig.yaw, 0.5, 0.0001)
	assert_almost_eq(rig.rotation.y, 0.5, 0.0001)
	rig.look(0.0, 100.0)
	assert_eq(rig.pitch(), PlayerMath.MAX_PITCH)
	rig.look(0.0, -100.0)
	assert_eq(rig.pitch(), PlayerMath.MIN_PITCH)


func test_camera_sits_behind_and_above_the_player() -> void:
	var camera := _player.get_node("CameraRig/Arm/Camera") as Camera3D
	assert_not_null(camera)
	var rig := _player.get_node("CameraRig") as CameraRig
	var arm := rig.get_node("Arm") as SpringArm3D
	assert_gt(arm.spring_length, 0.0)
	assert_lt(arm.rotation.x, 0.0, "pitched down so the camera is above its target")
