extends GutTest
## The swing visual matches the attack it shows.

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const EMBER_CLEAVER_ATTACK_PATH := "res://data/ember_cleaver_attack.tres"

var _weapon: WeaponSwing
var _blade: MeshInstance3D


func before_each() -> void:
	var player: Node = add_child_autofree((load(PLAYER_SCENE_PATH) as PackedScene).instantiate())
	_weapon = player.get_node("Model/Weapon")
	_blade = _weapon.get_node("Blade")


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_blade_is_hidden_until_a_swing() -> void:
	assert_false(_blade.visible)


func test_player_attacked_shows_a_blade_as_long_as_the_reach() -> void:
	var cleaver := load(EMBER_CLEAVER_ATTACK_PATH) as AttackData
	Events.player_attacked.emit(cleaver)
	assert_true(_blade.visible)
	assert_almost_eq(_blade.scale.z, cleaver.reach_meters, 0.0001)
	assert_almost_eq(_blade.position.z, -cleaver.reach_meters / 2.0, 0.0001, "blade extends forward from the pivot")


func test_swing_starts_at_one_edge_of_the_arc() -> void:
	var cleaver := load(EMBER_CLEAVER_ATTACK_PATH) as AttackData
	_weapon.play(cleaver)
	assert_almost_eq(_weapon.rotation.y, deg_to_rad(cleaver.arc_degrees) / 2.0, 0.0001)
