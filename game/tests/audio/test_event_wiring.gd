extends GutTest
## AudioManager listens to Events: each signal plays the contract's cue, at the
## right position, and the music starts and stops with the run.

const AUDIO_MANAGER_SCRIPT := "res://scripts/audio/audio_manager.gd"
const ARENA_MUSIC := &"music.arena"
const ENEMY_POSITION := Vector3(4.0, 0.0, -2.0)
const DROP_POSITION := Vector3(-3.0, 0.5, 6.0)
const FULL_HEALTH := 100
const SOME_DAMAGE := 10

var _manager: Node


func before_each() -> void:
	_manager = add_child_autofree(load(AUDIO_MANAGER_SCRIPT).new())
	# Any ERROR line fails scripts/check.sh, so a wiring bug surfaces as a failed assert instead.
	_manager.error_reporter = func(message: String) -> void: fail_test("unexpected report: " + message)
	watch_signals(_manager)


func _spawn_enemy() -> Node3D:
	var enemy: Node3D = add_child_autofree(Node3D.new())
	enemy.global_position = ENEMY_POSITION
	return enemy


func _assert_one_cue(id: StringName) -> void:
	assert_signal_emit_count(_manager, "sfx_played", 1)
	assert_signal_emitted_with_parameters(_manager, "sfx_played", [id])


func test_player_jumped_plays_jump() -> void:
	Events.player_jumped.emit()
	_assert_one_cue(&"sfx.jump")
	assert_eq(AudioTestHelpers.configured_spatial_sfx(_manager).size(), 0)


func test_player_landed_plays_land() -> void:
	Events.player_landed.emit()
	_assert_one_cue(&"sfx.land")


func test_player_attacked_plays_swing() -> void:
	Events.player_attacked.emit(AttackData.new())
	_assert_one_cue(&"sfx.attack_swing")


func test_player_hit_enemy_plays_hit_at_the_enemy() -> void:
	Events.player_hit_enemy.emit(_spawn_enemy(), SOME_DAMAGE)
	_assert_one_cue(&"sfx.attack_hit")
	var spatial := AudioTestHelpers.configured_spatial_sfx(_manager)
	assert_eq(spatial.size(), 1)
	assert_eq(AudioTestHelpers.configured_flat_sfx(_manager).size(), 0)
	if spatial.size() == 1:
		assert_eq((spatial[0] as AudioStreamPlayer3D).global_position, ENEMY_POSITION)


func test_player_hurt_plays_hurt() -> void:
	Events.player_hurt.emit(SOME_DAMAGE)
	_assert_one_cue(&"sfx.player_hurt")


func test_player_died_plays_die_and_stops_the_music() -> void:
	_manager.play_music(ARENA_MUSIC)
	Events.player_died.emit()
	assert_signal_emitted_with_parameters(_manager, "sfx_played", [&"sfx.player_die"])
	assert_false(_manager.is_music_active(), "music should stop when the player dies")


func test_enemy_died_plays_die_at_the_enemy() -> void:
	Events.enemy_died.emit(_spawn_enemy())
	_assert_one_cue(&"sfx.enemy_die")
	var spatial := AudioTestHelpers.configured_spatial_sfx(_manager)
	assert_eq(spatial.size(), 1)
	if spatial.size() == 1:
		assert_eq((spatial[0] as AudioStreamPlayer3D).global_position, ENEMY_POSITION)


func test_enemy_off_the_tree_falls_back_to_a_non_positional_cue() -> void:
	var stray := Node3D.new()
	Events.enemy_died.emit(stray)
	stray.free()
	_assert_one_cue(&"sfx.enemy_die")
	assert_eq(AudioTestHelpers.configured_flat_sfx(_manager).size(), 1)
	assert_eq(AudioTestHelpers.configured_spatial_sfx(_manager).size(), 0)


func test_loot_dropped_plays_drop_at_the_world_position() -> void:
	Events.loot_dropped.emit(ItemData.new(), DROP_POSITION)
	_assert_one_cue(&"sfx.loot_drop")
	var spatial := AudioTestHelpers.configured_spatial_sfx(_manager)
	assert_eq(spatial.size(), 1)
	if spatial.size() == 1:
		assert_eq((spatial[0] as AudioStreamPlayer3D).global_position, DROP_POSITION)


func test_loot_picked_up_plays_pickup() -> void:
	Events.loot_picked_up.emit(ItemData.new())
	_assert_one_cue(&"sfx.loot_pickup")
	assert_eq(AudioTestHelpers.configured_spatial_sfx(_manager).size(), 0)


func test_pausing_plays_pause_open_on_the_ui_bus() -> void:
	Events.game_paused.emit(true)
	_assert_one_cue(&"ui.pause_open")
	var flat := AudioTestHelpers.configured_flat_sfx(_manager)
	assert_eq(flat.size(), 1)
	if flat.size() == 1:
		assert_eq((flat[0] as AudioStreamPlayer).bus, &"UI")


func test_unpausing_plays_pause_close() -> void:
	Events.game_paused.emit(false)
	_assert_one_cue(&"ui.pause_close")


func test_arena_cleared_stops_the_music() -> void:
	_manager.play_music(ARENA_MUSIC)
	Events.arena_cleared.emit()
	assert_false(_manager.is_music_active())
	assert_signal_not_emitted(_manager, "sfx_played")


func test_first_health_change_starts_the_arena_music() -> void:
	Events.player_health_changed.emit(FULL_HEALTH, FULL_HEALTH)
	assert_signal_emitted_with_parameters(_manager, "music_started", [ARENA_MUSIC])
	assert_true(_manager.is_music_active())


func test_later_health_changes_do_not_restart_the_music() -> void:
	Events.player_health_changed.emit(FULL_HEALTH, FULL_HEALTH)
	Events.player_health_changed.emit(FULL_HEALTH - SOME_DAMAGE, FULL_HEALTH)
	assert_signal_emit_count(_manager, "music_started", 1)


func test_health_change_to_zero_does_not_start_the_music() -> void:
	Events.player_health_changed.emit(0, FULL_HEALTH)
	assert_signal_not_emitted(_manager, "music_started")


func test_a_new_run_starts_the_music_again_after_it_was_stopped() -> void:
	Events.player_health_changed.emit(FULL_HEALTH, FULL_HEALTH)
	Events.player_died.emit()
	Events.player_health_changed.emit(FULL_HEALTH, FULL_HEALTH)
	assert_signal_emit_count(_manager, "music_started", 2)
	assert_true(_manager.is_music_active())
