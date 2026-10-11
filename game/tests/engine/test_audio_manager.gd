extends GutTest
## AudioManager registry behaviour: known ids play, unknown ids are loud.

const AUDIO_MANAGER_PATH := "/root/AudioManager"
const AUDIO_MANAGER_SCRIPT := "res://scripts/audio/audio_manager.gd"
const UNKNOWN_ID := &"sfx.does_not_exist"
const KNOWN_ID := &"sfx.test_tone"
const SOME_POSITION := Vector3(1.0, 2.0, 3.0)

var _manager: Node
var _reported_errors: Array[String] = []


func before_each() -> void:
	# A fresh instance keeps the shared autoload's registry untouched.
	_manager = add_child_autofree(load(AUDIO_MANAGER_SCRIPT).new())
	# A real push_error prints "ERROR:" and would fail scripts/check.sh even when
	# a test expects it, so unknown-id reports are captured instead.
	_reported_errors.clear()
	_manager.error_reporter = func(message: String) -> void: _reported_errors.append(message)


func _count_children_of_class(type_name: String) -> int:
	var count := 0
	for child in _manager.get_children():
		if child.is_class(type_name):
			count += 1
	return count


func test_autoload_is_registered_after_events() -> void:
	assert_not_null(get_node_or_null(AUDIO_MANAGER_PATH), "AudioManager autoload should exist")
	var autoload_names: Array[String] = []
	for property in ProjectSettings.get_property_list():
		if property["name"].begins_with("autoload/"):
			autoload_names.append(property["name"].trim_prefix("autoload/"))
	assert_eq(autoload_names, ["Events", "AudioManager"] as Array[String], "autoload order")


func test_registry_starts_empty() -> void:
	assert_eq(_manager.registry.size(), 0)


func test_play_sfx_unknown_id_reports_exactly_one_error() -> void:
	_manager.play_sfx(UNKNOWN_ID)
	assert_eq(_reported_errors.size(), 1, "unknown sfx id should report exactly one error")


func test_play_sfx_unknown_id_names_the_id() -> void:
	_manager.play_sfx(UNKNOWN_ID)
	assert_string_contains(_reported_errors[0] if _reported_errors.size() > 0 else "", String(UNKNOWN_ID))


func test_play_music_unknown_id_reports_one_error_naming_the_id() -> void:
	_manager.play_music(UNKNOWN_ID)
	assert_eq(_reported_errors.size(), 1, "unknown music id should report exactly one error")
	assert_string_contains(_reported_errors[0] if _reported_errors.size() > 0 else "", String(UNKNOWN_ID))


func test_unknown_positional_sfx_reports_error_and_adds_no_player() -> void:
	_manager.play_sfx(UNKNOWN_ID, SOME_POSITION)
	assert_eq(_reported_errors.size(), 1)
	assert_eq(_count_children_of_class("AudioStreamPlayer3D"), 0)


func test_known_sfx_plays_non_positionally() -> void:
	_manager.registry[KNOWN_ID] = AudioStreamGenerator.new()
	_manager.play_sfx(KNOWN_ID)
	assert_eq(_count_children_of_class("AudioStreamPlayer"), 2, "music player plus one sfx player")
	assert_eq(_count_children_of_class("AudioStreamPlayer3D"), 0)


func test_known_sfx_with_position_plays_positionally_at_that_position() -> void:
	_manager.registry[KNOWN_ID] = AudioStreamGenerator.new()
	_manager.play_sfx(KNOWN_ID, SOME_POSITION)
	var players: Array[Node] = _manager.get_children().filter(func(c: Node) -> bool: return c is AudioStreamPlayer3D)
	assert_eq(players.size(), 1)
	if players.size() == 1:
		assert_eq((players[0] as AudioStreamPlayer3D).global_position, SOME_POSITION)


func test_play_and_stop_music() -> void:
	_manager.registry[KNOWN_ID] = AudioStreamGenerator.new()
	_manager.play_music(KNOWN_ID)
	var music_player := _manager._music_player as AudioStreamPlayer
	assert_true(music_player.playing, "music should be playing")
	_manager.stop_music()
	assert_false(music_player.playing, "music should be stopped")


func test_default_reporter_is_push_error_wrapper() -> void:
	var fresh: Node = autofree(load(AUDIO_MANAGER_SCRIPT).new())
	assert_eq(fresh.error_reporter.get_method(), &"_push_error", "default reporter should wrap push_error")
