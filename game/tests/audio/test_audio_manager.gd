extends GutTest
## AudioManager: the registry is filled, sfx/ui/music take the right path and
## bus, players are pooled, and anything wrong is reported exactly once.
## (Moved here from tests/engine/ when audio took ownership of AudioManager.)

const AUDIO_MANAGER_PATH := "/root/AudioManager"
const AUDIO_MANAGER_SCRIPT := "res://scripts/audio/audio_manager.gd"
const UNKNOWN_ID := &"sfx.does_not_exist"
const TEST_SFX_ID := &"sfx.test_tone"
const TEST_MUSIC_ID := &"music.test_tone"
const REAL_MUSIC_ID := &"music.arena"
const REAL_SFX_ID := &"sfx.jump"
const REAL_UI_ID := &"ui.click"
const SOME_POSITION := Vector3(1.0, 2.0, 3.0)
const SFX_BUSES: Array[StringName] = [&"SFX", &"UI"]
const MUSIC_BUSES: Array[StringName] = [&"Music"]

var _manager: Node
var _reported_errors: Array[String] = []


func before_each() -> void:
	# A fresh instance keeps the shared autoload untouched.
	_manager = add_child_autofree(load(AUDIO_MANAGER_SCRIPT).new())
	# A real push_error prints "ERROR:" and would fail scripts/check.sh even when
	# a test expects it, so reports are captured instead.
	_reported_errors.clear()
	_manager.error_reporter = func(message: String) -> void: _reported_errors.append(message)
	_manager.registry[TEST_SFX_ID] = AudioStreamGenerator.new()
	_manager.registry[TEST_MUSIC_ID] = AudioStreamGenerator.new()
	watch_signals(_manager)


func _players(type_name: String, buses: Array[StringName], only_playing: bool) -> Array[Node]:
	var found: Array[Node] = []
	for child in _manager.get_children():
		if child.is_class(type_name) and child.bus in buses and (child.playing or not only_playing):
			found.append(child)
	return found


func _playing_flat_sfx() -> Array[Node]:
	return _players("AudioStreamPlayer", SFX_BUSES, true)


func _playing_spatial_sfx() -> Array[Node]:
	return _players("AudioStreamPlayer3D", SFX_BUSES, true)


func _music_players() -> Array[Node]:
	return _players("AudioStreamPlayer", MUSIC_BUSES, false)


func _first_error() -> String:
	return _reported_errors[0] if _reported_errors.size() > 0 else ""


func test_autoload_is_registered_after_events() -> void:
	assert_not_null(get_node_or_null(AUDIO_MANAGER_PATH), "AudioManager autoload should exist")
	var autoload_names: Array[String] = []
	for property in ProjectSettings.get_property_list():
		if property["name"].begins_with("autoload/"):
			autoload_names.append(property["name"].trim_prefix("autoload/"))
	assert_eq(autoload_names, ["Events", "AudioManager"] as Array[String], "autoload order")


func test_default_reporter_is_push_error_wrapper() -> void:
	var fresh: Node = autofree(load(AUDIO_MANAGER_SCRIPT).new())
	assert_eq(fresh.error_reporter.get_method(), &"_push_error", "default reporter should wrap push_error")


func test_every_catalog_id_resolves_to_a_stream() -> void:
	for id: StringName in SoundCatalog.PATHS:
		assert_not_null(_manager.registry.get(id), "registry should hold '%s'" % id)
	assert_eq(_reported_errors.size(), 0, "loading the registry should report nothing")


func test_runs_while_the_tree_is_paused() -> void:
	assert_eq(_manager.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_unknown_sfx_reports_exactly_one_error_naming_the_id() -> void:
	_manager.play_sfx(UNKNOWN_ID)
	assert_eq(_reported_errors.size(), 1)
	assert_string_contains(_first_error(), String(UNKNOWN_ID))
	assert_signal_not_emitted(_manager, "sfx_played")


func test_unknown_positional_sfx_reports_once_and_plays_nothing() -> void:
	_manager.play_sfx(UNKNOWN_ID, SOME_POSITION)
	assert_eq(_reported_errors.size(), 1)
	assert_eq(_playing_spatial_sfx().size(), 0)
	assert_signal_not_emitted(_manager, "sfx_played")


func test_unknown_music_reports_exactly_one_error_naming_the_id() -> void:
	_manager.play_music(&"music.does_not_exist")
	assert_eq(_reported_errors.size(), 1)
	assert_string_contains(_first_error(), "music.does_not_exist")
	assert_signal_not_emitted(_manager, "music_started")


func test_music_id_through_play_sfx_is_reported_not_played() -> void:
	_manager.play_sfx(REAL_MUSIC_ID)
	assert_eq(_reported_errors.size(), 1)
	assert_string_contains(_first_error(), "play_music")
	assert_signal_not_emitted(_manager, "sfx_played")
	assert_eq(_playing_flat_sfx().size(), 0)


func test_sfx_id_through_play_music_is_reported_not_played() -> void:
	_manager.play_music(REAL_SFX_ID)
	assert_eq(_reported_errors.size(), 1)
	assert_string_contains(_first_error(), "play_sfx")
	assert_signal_not_emitted(_manager, "music_started")


func test_sfx_without_position_uses_one_flat_player_on_the_sfx_bus() -> void:
	_manager.play_sfx(REAL_SFX_ID)
	var flat := _playing_flat_sfx()
	assert_eq(flat.size(), 1)
	assert_eq(_playing_spatial_sfx().size(), 0, "no positional player for a non-positional sound")
	if flat.size() == 1:
		assert_eq((flat[0] as AudioStreamPlayer).bus, &"SFX")
		assert_eq((flat[0] as AudioStreamPlayer).stream, _manager.registry[REAL_SFX_ID])
	assert_signal_emitted_with_parameters(_manager, "sfx_played", [REAL_SFX_ID])


func test_sfx_with_position_uses_one_spatial_player_at_that_position() -> void:
	_manager.play_sfx(REAL_SFX_ID, SOME_POSITION)
	var spatial := _playing_spatial_sfx()
	assert_eq(spatial.size(), 1)
	assert_eq(_playing_flat_sfx().size(), 0, "no flat player for a positional sound")
	if spatial.size() == 1:
		assert_eq((spatial[0] as AudioStreamPlayer3D).global_position, SOME_POSITION)
		assert_eq((spatial[0] as AudioStreamPlayer3D).bus, &"SFX")
	assert_signal_emitted_with_parameters(_manager, "sfx_played", [REAL_SFX_ID])


func test_ui_sounds_play_on_the_ui_bus() -> void:
	_manager.play_sfx(REAL_UI_ID)
	var flat := _playing_flat_sfx()
	assert_eq(flat.size(), 1)
	if flat.size() == 1:
		assert_eq((flat[0] as AudioStreamPlayer).bus, &"UI")


func test_players_are_pooled_not_created_per_call() -> void:
	var children_before: int = _manager.get_child_count()
	for _i in _manager.POOL_SIZE * 3:
		_manager.play_sfx(TEST_SFX_ID)
		_manager.play_sfx(TEST_SFX_ID, SOME_POSITION)
	assert_eq(_manager.get_child_count(), children_before)


func test_a_full_pool_cuts_in_rather_than_dropping_the_sound() -> void:
	for _i in _manager.POOL_SIZE + 1:
		_manager.play_sfx(TEST_SFX_ID)
	assert_eq(_playing_flat_sfx().size(), _manager.POOL_SIZE)
	assert_signal_emit_count(_manager, "sfx_played", _manager.POOL_SIZE + 1)


func test_music_loops_on_the_music_bus_and_announces_itself() -> void:
	_manager.play_music(REAL_MUSIC_ID)
	var players := _music_players()
	assert_eq(players.size(), 1)
	if players.size() == 1:
		var player := players[0] as AudioStreamPlayer
		assert_true(player.playing)
		assert_true((player.stream as AudioStreamOggVorbis).loop, "arena music should loop")
	assert_signal_emitted_with_parameters(_manager, "music_started", [REAL_MUSIC_ID])


func test_play_music_replaces_the_current_track() -> void:
	_manager.play_music(REAL_MUSIC_ID)
	_manager.play_music(TEST_MUSIC_ID)
	var players := _music_players()
	assert_eq(players.size(), 1, "still one music player")
	if players.size() == 1:
		assert_eq((players[0] as AudioStreamPlayer).stream, _manager.registry[TEST_MUSIC_ID])
		assert_true((players[0] as AudioStreamPlayer).playing)
	assert_signal_emit_count(_manager, "music_started", 2)


func test_stop_music_stops_playback() -> void:
	_manager.play_music(REAL_MUSIC_ID)
	_manager.stop_music()
	for player in _music_players():
		assert_false((player as AudioStreamPlayer).playing)


func test_stop_music_with_nothing_playing_is_harmless() -> void:
	_manager.stop_music()
	assert_eq(_reported_errors.size(), 0)
