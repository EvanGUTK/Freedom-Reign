extends GutTest
## Loot: drops become pickups; touching one swaps the player's attack.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const PICKUP_SCENE_PATH := "res://scenes/loot/loot_pickup.tscn"
const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"
const EMBER_CLEAVER_ITEM_PATH := "res://data/ember_cleaver.tres"
const RUSTED_BLADE_PATH := "res://data/rusted_blade.tres"

var _item: ItemData


func before_each() -> void:
	_item = load(EMBER_CLEAVER_ITEM_PATH)
	watch_signals(Events)


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _player() -> Player:
	return add_child_autofree((load(PLAYER_SCENE_PATH) as PackedScene).instantiate()) as Player


func _pickup() -> LootPickup:
	var pickup := (load(PICKUP_SCENE_PATH) as PackedScene).instantiate() as LootPickup
	pickup.item = _item
	return add_child_autofree(pickup)


func test_pickup_is_on_the_pickup_layer_and_only_looks_for_the_player() -> void:
	var pickup := _pickup()
	assert_eq(pickup.collision_layer, WorldPhysics.LAYER_PICKUP)
	assert_eq(pickup.collision_mask, WorldPhysics.LAYER_PLAYER)


func test_touch_swaps_the_players_attack_and_announces_both_events() -> void:
	var player := _player()
	var pickup := _pickup()
	pickup.body_entered.emit(player)
	assert_signal_emitted_with_parameters(Events, "loot_picked_up", [_item])
	assert_signal_emitted_with_parameters(Events, "attack_changed", [_item.grants_attack])
	assert_true(pickup.is_queued_for_deletion(), "pickup is used up")


func test_player_swings_the_new_attack_after_pickup() -> void:
	var player := _player()
	_pickup().body_entered.emit(player)
	var attack := player.get_node("Attack") as AttackController
	assert_eq(attack.current, _item.grants_attack)
	assert_eq(attack.current.damage, 25)


func test_touching_twice_picks_up_once() -> void:
	var player := _player()
	var pickup := _pickup()
	pickup.body_entered.emit(player)
	pickup.body_entered.emit(player)
	assert_signal_emit_count(Events, "loot_picked_up", 1)


func test_things_that_are_not_the_player_do_not_collect() -> void:
	var pickup := _pickup()
	var other := autofree(Node3D.new()) as Node3D
	pickup.body_entered.emit(other)
	assert_signal_not_emitted(Events, "loot_picked_up")
	assert_false(pickup.is_queued_for_deletion())


func test_a_dead_player_cannot_collect() -> void:
	var player := _player()
	player.take_damage(100)
	var pickup := _pickup()
	pickup.body_entered.emit(player)
	assert_signal_not_emitted(Events, "loot_picked_up")


func test_pickup_spins_and_bobs() -> void:
	var pickup := _pickup()
	var visual := pickup.get_node("Visual") as Node3D
	var spin_before := visual.rotation.y
	pickup._process(0.5)
	assert_ne(visual.rotation.y, spin_before, "spins")
	assert_ne(visual.position.y, 0.0, "bobs")


func test_loot_dropped_creates_a_pickup_above_the_drop_position() -> void:
	var main := add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate()) as Node3D
	var drop_at := Vector3(4, 0, -3)
	Events.loot_dropped.emit(_item, drop_at)
	var spawner := main.get_node("LootSpawner")
	assert_eq(spawner.get_child_count(), 1)
	var pickup := spawner.get_child(0) as LootPickup
	assert_eq(pickup.item, _item)
	assert_eq(pickup.global_position, drop_at + Vector3.UP * LootSpawner.HOVER_HEIGHT)


func test_killing_the_first_husk_in_a_round_leaves_a_cleaver_pickup() -> void:
	var main := add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate()) as Node3D
	(get_tree().get_nodes_in_group(Groups.ENEMIES)[0] as Husk).take_damage(30)
	var pickups := main.get_node("LootSpawner").get_children()
	assert_eq(pickups.size(), 1)
	assert_eq((pickups[0] as LootPickup).item.id, &"ember_cleaver")
