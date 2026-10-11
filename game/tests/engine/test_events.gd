extends GutTest
## Events declares exactly the contract's signals, with typed arguments.

const EVENTS_PATH := "/root/Events"

## signal name -> argument types, in order.
const CONTRACT_SIGNALS := {
	&"player_health_changed": [TYPE_INT, TYPE_INT],
	&"player_jumped": [],
	&"player_landed": [],
	&"player_attacked": [&"AttackData"],
	&"player_hit_enemy": [&"Node3D", TYPE_INT],
	&"player_hurt": [TYPE_INT],
	&"player_died": [],
	&"attack_changed": [&"AttackData"],
	&"enemy_died": [&"Node3D"],
	&"loot_dropped": [&"ItemData", TYPE_VECTOR3],
	&"loot_picked_up": [&"ItemData"],
	&"arena_cleared": [],
	&"game_paused": [TYPE_BOOL],
}


func _declared_signals() -> Dictionary:
	var declared := {}
	var events := get_node_or_null(EVENTS_PATH)
	if events == null:
		return declared
	var script_signals: Array[StringName] = []
	for entry in events.get_script().get_script_signal_list():
		script_signals.append(entry["name"])
	for entry in events.get_signal_list():
		if entry["name"] in script_signals:
			declared[StringName(entry["name"])] = entry["args"]
	return declared


func test_events_is_registered_as_autoload() -> void:
	assert_not_null(get_node_or_null(EVENTS_PATH), "Events autoload should exist")


func test_events_declares_exactly_the_contract_signals() -> void:
	var declared := _declared_signals()
	var expected: Array = CONTRACT_SIGNALS.keys()
	var actual: Array = declared.keys()
	expected.sort()
	actual.sort()
	assert_eq(actual, expected, "Events signals should match the contract exactly")


func test_every_signal_has_the_contract_arguments() -> void:
	var declared := _declared_signals()
	for signal_name in CONTRACT_SIGNALS:
		if not declared.has(signal_name):
			fail_test("missing signal %s" % signal_name)
			continue
		var expected_types: Array = CONTRACT_SIGNALS[signal_name]
		var args: Array = declared[signal_name]
		assert_eq(args.size(), expected_types.size(), "%s argument count" % signal_name)
		if args.size() != expected_types.size():
			continue
		for i in args.size():
			var expected = expected_types[i]
			if expected is StringName:
				assert_eq(args[i]["class_name"], expected, "%s arg %d class" % [signal_name, i])
			else:
				assert_eq(args[i]["type"], expected, "%s arg %d type" % [signal_name, i])


func test_signal_argument_names_match_the_contract() -> void:
	var declared := _declared_signals()
	var expected_names := {
		&"player_health_changed": ["current", "maximum"],
		&"player_attacked": ["attack"],
		&"player_hit_enemy": ["enemy", "damage"],
		&"player_hurt": ["damage"],
		&"attack_changed": ["attack"],
		&"enemy_died": ["enemy"],
		&"loot_dropped": ["item", "world_position"],
		&"loot_picked_up": ["item"],
		&"game_paused": ["is_paused"],
	}
	for signal_name in expected_names:
		if not declared.has(signal_name):
			fail_test("missing signal %s" % signal_name)
			continue
		var names: Array = []
		for arg in declared[signal_name]:
			names.append(arg["name"])
		assert_eq(names, expected_names[signal_name], "%s argument names" % signal_name)
