extends GutTest
## The project's default bus layout: Master with Music, SFX and UI routed into it.

const MASTER_BUS := &"Master"
const CHILD_BUSES: Array[StringName] = [&"Music", &"SFX", &"UI"]


func test_child_buses_exist_by_name() -> void:
	for bus_name in CHILD_BUSES:
		assert_ne(AudioServer.get_bus_index(bus_name), -1, "bus '%s' should exist" % bus_name)


func test_child_buses_send_to_master() -> void:
	for bus_name in CHILD_BUSES:
		var index := AudioServer.get_bus_index(bus_name)
		if index == -1:
			fail_test("bus '%s' missing" % bus_name)
			continue
		assert_eq(AudioServer.get_bus_send(index), MASTER_BUS, "bus '%s' send" % bus_name)


func test_master_is_bus_zero_and_layout_has_exactly_four_buses() -> void:
	assert_eq(AudioServer.get_bus_name(0), String(MASTER_BUS))
	assert_eq(AudioServer.bus_count, 1 + CHILD_BUSES.size())
