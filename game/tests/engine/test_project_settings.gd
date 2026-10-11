extends GutTest
## Project settings the other roles rely on: input actions and physics layer names.

const KEYBOARD_MOUSE_AND_GAMEPAD_ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right",
	&"jump", &"attack", &"pause",
]
const PHYSICS_LAYER_NAMES := {
	1: "World",
	2: "Player",
	3: "Enemy",
	4: "Pickup",
}
const PHYSICS_LAYER_SETTING_FORMAT := "layer_names/3d_physics/layer_%d"


func _has_event_of_type(action: StringName, predicate: Callable) -> bool:
	for event in InputMap.action_get_events(action):
		if predicate.call(event):
			return true
	return false


func _is_keyboard_or_mouse(event: InputEvent) -> bool:
	return event is InputEventKey or event is InputEventMouseButton


func _is_gamepad(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion


func test_every_action_exists() -> void:
	for action in KEYBOARD_MOUSE_AND_GAMEPAD_ACTIONS:
		assert_true(InputMap.has_action(action), "input action %s should exist" % action)


func test_every_action_has_keyboard_or_mouse_and_gamepad_binding() -> void:
	for action in KEYBOARD_MOUSE_AND_GAMEPAD_ACTIONS:
		assert_true(_has_event_of_type(action, _is_keyboard_or_mouse), "%s needs a keyboard/mouse binding" % action)
		assert_true(_has_event_of_type(action, _is_gamepad), "%s needs a gamepad binding" % action)


func test_attack_is_left_mouse_button() -> void:
	var found := false
	for event in InputMap.action_get_events(&"attack"):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			found = true
	assert_true(found, "attack should be bound to the left mouse button")


func test_pause_is_escape_and_start() -> void:
	var has_escape := false
	var has_start := false
	for event in InputMap.action_get_events(&"pause"):
		if event is InputEventKey and event.physical_keycode == KEY_ESCAPE:
			has_escape = true
		if event is InputEventJoypadButton and event.button_index == JOY_BUTTON_START:
			has_start = true
	assert_true(has_escape, "pause should be bound to Escape")
	assert_true(has_start, "pause should be bound to the gamepad Start button")


func test_gamepad_face_buttons() -> void:
	var jump_button := -1
	var attack_button := -1
	for event in InputMap.action_get_events(&"jump"):
		if event is InputEventJoypadButton:
			jump_button = event.button_index
	for event in InputMap.action_get_events(&"attack"):
		if event is InputEventJoypadButton:
			attack_button = event.button_index
	assert_eq(jump_button, JOY_BUTTON_A, "jump should be gamepad A")
	assert_eq(attack_button, JOY_BUTTON_X, "attack should be gamepad X")


func test_physics_layer_names() -> void:
	for layer in PHYSICS_LAYER_NAMES:
		var setting := PHYSICS_LAYER_SETTING_FORMAT % layer
		assert_eq(ProjectSettings.get_setting(setting, ""), PHYSICS_LAYER_NAMES[layer], "physics layer %d name" % layer)
