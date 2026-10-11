extends GutTest
## The arena round: five husks, first kill drops the cleaver, last kill clears the arena once.

const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const EMBER_CLEAVER_ITEM_PATH := "res://data/ember_cleaver.tres"
const HUSK_COUNT := 5
const HUSK_HEALTH := 30

var _main: Node3D


func before_each() -> void:
	watch_signals(Events)
	_main = add_child_autofree((load(MAIN_SCENE_PATH) as PackedScene).instantiate())


func after_each() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _husks() -> Array[Node]:
	return get_tree().get_nodes_in_group(Groups.ENEMIES)


func _kill(husk: Node) -> void:
	(husk as Husk).take_damage(HUSK_HEALTH)


func test_one_husk_spawns_at_every_enemy_marker() -> void:
	var markers := _main.get_node("Arena/Spawns").get_children()
	var husks := _husks()
	assert_eq(husks.size(), HUSK_COUNT)
	var spawned_at: Array[Vector3] = []
	for husk in husks:
		spawned_at.append((husk as Node3D).global_position)
	for marker in markers:
		assert_has(spawned_at, (marker as Marker3D).global_position, "husk at %s" % marker.name)


func test_first_husk_to_die_drops_the_ember_cleaver_where_it_died() -> void:
	var first := _husks()[2] as Node3D
	var died_at := first.global_position
	_kill(first)
	var cleaver := load(EMBER_CLEAVER_ITEM_PATH) as ItemData
	assert_signal_emitted_with_parameters(Events, "loot_dropped", [cleaver, died_at])


func test_only_the_first_death_drops_loot() -> void:
	for husk in _husks().slice(0, 3):
		_kill(husk)
	assert_signal_emit_count(Events, "loot_dropped", 1)


func test_arena_is_cleared_only_when_the_last_husk_dies() -> void:
	var husks := _husks()
	for i in HUSK_COUNT - 1:
		_kill(husks[i])
	assert_signal_not_emitted(Events, "arena_cleared")
	_kill(husks[HUSK_COUNT - 1])
	assert_signal_emit_count(Events, "arena_cleared", 1)
	assert_signal_emit_count(Events, "enemy_died", HUSK_COUNT)


func test_arena_cleared_is_not_repeated_by_a_stray_death_afterwards() -> void:
	for husk in _husks():
		_kill(husk)
	var stray := autofree(Node3D.new()) as Node3D
	Events.enemy_died.emit(stray)
	assert_signal_emit_count(Events, "arena_cleared", 1)
	assert_signal_emit_count(Events, "loot_dropped", 1)
