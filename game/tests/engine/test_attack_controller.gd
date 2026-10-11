extends GutTest
## Cooldown gating, damage application and event order for the player's attack.

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const RUSTED_BLADE_PATH := "res://data/rusted_blade.tres"
const EMBER_CLEAVER_ATTACK_PATH := "res://data/ember_cleaver_attack.tres"
const FORWARD := Vector3(0, 0, -1)


class FakeEnemy:
	extends Node3D
	var damage_taken: Array[int] = []

	func take_damage(amount: int) -> void:
		damage_taken.append(amount)


var _controller: AttackController
var _blade: AttackData


func before_each() -> void:
	watch_signals(Events)
	_blade = load(RUSTED_BLADE_PATH)
	_controller = AttackController.new()
	_controller.starting_attack = _blade
	add_child_autofree(_controller)


func _enemy_at(position: Vector3) -> FakeEnemy:
	var enemy := FakeEnemy.new()
	enemy.add_to_group(Groups.ENEMIES)
	add_child_autofree(enemy)
	enemy.global_position = position
	return enemy


func test_attack_changed_is_emitted_at_ready_with_the_starting_attack() -> void:
	assert_signal_emitted_with_parameters(Events, "attack_changed", [_blade])
	assert_eq(_controller.current, _blade)


func test_swing_emits_player_attacked_and_starts_the_cooldown() -> void:
	assert_true(_controller.try_attack(Vector3.ZERO, FORWARD))
	assert_signal_emitted_with_parameters(Events, "player_attacked", [_blade])
	assert_false(_controller.is_ready())


func test_second_swing_during_cooldown_does_nothing() -> void:
	_controller.try_attack(Vector3.ZERO, FORWARD)
	assert_false(_controller.try_attack(Vector3.ZERO, FORWARD))
	assert_signal_emit_count(Events, "player_attacked", 1)


func test_cooldown_gates_until_exactly_cooldown_seconds_have_passed() -> void:
	_controller.try_attack(Vector3.ZERO, FORWARD)
	_controller.tick(_blade.cooldown_seconds - 0.1)
	assert_false(_controller.is_ready(), "0.1 s early")
	_controller.tick(0.1)
	assert_true(_controller.is_ready(), "cooldown elapsed")
	assert_true(_controller.try_attack(Vector3.ZERO, FORWARD))
	assert_signal_emit_count(Events, "player_attacked", 2)


func test_cooldown_comes_from_the_current_attack() -> void:
	var cleaver := load(EMBER_CLEAVER_ATTACK_PATH) as AttackData
	_controller.equip(cleaver)
	_controller.try_attack(Vector3.ZERO, FORWARD)
	_controller.tick(_blade.cooldown_seconds)
	assert_false(_controller.is_ready(), "cleaver cools down slower than the blade")
	_controller.tick(cleaver.cooldown_seconds - _blade.cooldown_seconds)
	assert_true(_controller.is_ready())


func test_swing_damages_every_enemy_in_reach_and_arc_and_no_others() -> void:
	var in_front := _enemy_at(Vector3(0, 0, -1.0))
	var also_in_front := _enemy_at(Vector3(0.5, 0, -1.2))
	var too_far := _enemy_at(Vector3(0, 0, -4.0))
	var behind := _enemy_at(Vector3(0, 0, 1.0))
	_controller.try_attack(Vector3.ZERO, FORWARD)
	assert_eq(in_front.damage_taken, [_blade.damage] as Array[int])
	assert_eq(also_in_front.damage_taken, [_blade.damage] as Array[int])
	assert_eq(too_far.damage_taken, [] as Array[int])
	assert_eq(behind.damage_taken, [] as Array[int])
	assert_signal_emit_count(Events, "player_hit_enemy", 2)


func test_player_hit_enemy_carries_the_enemy_and_damage() -> void:
	var enemy := _enemy_at(Vector3(0, 0, -1.0))
	_controller.try_attack(Vector3.ZERO, FORWARD)
	assert_signal_emitted_with_parameters(Events, "player_hit_enemy", [enemy, _blade.damage])


func test_swing_with_nobody_in_reach_still_swings() -> void:
	_enemy_at(Vector3(0, 0, -9.0))
	assert_true(_controller.try_attack(Vector3.ZERO, FORWARD))
	assert_signal_not_emitted(Events, "player_hit_enemy")


func test_equip_swaps_the_attack_and_announces_it() -> void:
	var cleaver := load(EMBER_CLEAVER_ATTACK_PATH) as AttackData
	_controller.equip(cleaver)
	assert_eq(_controller.current, cleaver)
	assert_signal_emitted_with_parameters(Events, "attack_changed", [cleaver])
	var enemy := _enemy_at(Vector3(0, 0, -2.1))
	_controller.try_attack(Vector3.ZERO, FORWARD)
	assert_eq(enemy.damage_taken, [cleaver.damage] as Array[int], "cleaver reaches 2.2 m, blade only 1.8")


func test_player_scene_starts_with_the_rusted_blade_and_announces_it() -> void:
	var player := add_child_autofree((load(PLAYER_SCENE_PATH) as PackedScene).instantiate()) as Player
	assert_signal_emitted_with_parameters(Events, "attack_changed", [_blade])
	player.equip_attack(load(EMBER_CLEAVER_ATTACK_PATH))
	assert_signal_emit_count(Events, "attack_changed", 3, "controller in this test, then the player's at ready, then the swap")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
