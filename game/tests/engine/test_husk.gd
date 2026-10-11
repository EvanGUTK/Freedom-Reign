extends GutTest
## Husk: contract numbers, contact damage against a real player, death.

const HUSK_SCENE_PATH := "res://scenes/enemies/husk.tscn"
const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const STEP := 0.25

var _husk: Husk


func before_each() -> void:
	watch_signals(Events)
	_husk = add_child_autofree((load(HUSK_SCENE_PATH) as PackedScene).instantiate())


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _player_at(position: Vector3) -> Player:
	var player := add_child_autofree((load(PLAYER_SCENE_PATH) as PackedScene).instantiate()) as Player
	player.global_position = position
	return player


func test_contract_defaults() -> void:
	assert_eq(_husk.max_health, 30)
	assert_eq(_husk.speed, 3.5)
	assert_eq(_husk.contact_damage, 10)
	assert_eq(_husk.contact_interval, 1.0)
	assert_eq(_husk.contact_range, 1.5)
	assert_eq(_husk.gravity, 24.0)


func test_husk_is_on_the_enemy_layer_in_the_enemies_group_and_collides_with_world_player_enemy() -> void:
	assert_eq(_husk.collision_layer, WorldPhysics.LAYER_ENEMY)
	assert_eq(_husk.collision_mask, WorldPhysics.LAYER_WORLD | WorldPhysics.LAYER_PLAYER | WorldPhysics.LAYER_ENEMY)
	assert_true(_husk.is_in_group(Groups.ENEMIES))


func test_contact_in_range_hurts_the_player_for_ten() -> void:
	var player := _player_at(Vector3(1.0, 0, 0))
	_husk.apply_contact_damage(STEP, player)
	assert_signal_emitted_with_parameters(Events, "player_hurt", [10])
	assert_signal_emitted_with_parameters(Events, "player_health_changed", [90, 100])


func test_contact_damage_repeats_once_per_second() -> void:
	var player := _player_at(Vector3(1.0, 0, 0))
	for i in 8:
		_husk.apply_contact_damage(STEP, player)
	assert_signal_emit_count(Events, "player_hurt", 2, "two seconds in range: hits at 0.25 s and 1.25 s")


func test_player_out_of_range_is_not_hurt() -> void:
	var player := _player_at(Vector3(3.0, 0, 0))
	for i in 8:
		_husk.apply_contact_damage(STEP, player)
	assert_signal_not_emitted(Events, "player_hurt")


func test_a_player_standing_one_platform_above_is_out_of_contact_range() -> void:
	var player := _player_at(Vector3(0.9, 1.5, 0))
	_husk.apply_contact_damage(STEP, player)
	assert_signal_not_emitted(Events, "player_hurt")


func test_lethal_damage_emits_enemy_died_once_and_leaves_the_group() -> void:
	_husk.take_damage(20)
	assert_signal_not_emitted(Events, "enemy_died")
	_husk.take_damage(10)
	_husk.take_damage(10)
	assert_signal_emit_count(Events, "enemy_died", 1)
	assert_signal_emitted_with_parameters(Events, "enemy_died", [_husk])
	assert_false(_husk.is_in_group(Groups.ENEMIES), "dead husks no longer count as enemies")
