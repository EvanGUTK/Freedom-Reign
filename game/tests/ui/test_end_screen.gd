extends GutTest
## The end screen shows the right text per outcome and Restart unpauses first.

const END_SCENE_PATH := "res://scenes/ui/end_screen.tscn"

var _end: EndScreen
var _restart_calls := 0
var _paused_at_restart := true


func before_each() -> void:
	_restart_calls = 0
	_paused_at_restart = true
	_end = add_child_autofree((load(END_SCENE_PATH) as PackedScene).instantiate())
	_end.restart_scene = _record_restart


func after_each() -> void:
	get_tree().paused = false


func _record_restart() -> void:
	_restart_calls += 1
	_paused_at_restart = get_tree().paused


func _title_text() -> String:
	return (_end.get_node("%Title") as Label).text


func test_hidden_until_the_round_ends() -> void:
	assert_false(_end.visible)
	assert_false(get_tree().paused)


func test_arena_cleared_shows_arena_cleared() -> void:
	Events.arena_cleared.emit()
	assert_true(_end.visible)
	assert_eq(_title_text(), "Arena cleared")


func test_player_died_shows_you_died() -> void:
	Events.player_died.emit()
	assert_true(_end.visible)
	assert_eq(_title_text(), "You died")


func test_first_outcome_wins() -> void:
	Events.player_died.emit()
	Events.arena_cleared.emit()
	assert_eq(_title_text(), "You died")


func test_showing_pauses_the_world_and_focuses_restart() -> void:
	Events.player_died.emit()
	assert_true(get_tree().paused)
	assert_true((_end.get_node("%RestartButton") as Button).has_focus())


func test_always_processes_while_paused() -> void:
	assert_eq(_end.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_restart_unpauses_then_reloads() -> void:
	Events.arena_cleared.emit()
	(_end.get_node("%RestartButton") as Button).pressed.emit()
	assert_eq(_restart_calls, 1)
	assert_false(_paused_at_restart, "unpaused before the reload call")
	assert_false(get_tree().paused)


func test_default_restart_is_reloading_the_current_scene() -> void:
	var fresh: EndScreen = add_child_autofree((load(END_SCENE_PATH) as PackedScene).instantiate())
	assert_eq(fresh.restart_scene, Callable(get_tree(), "reload_current_scene"))


func test_restart_is_its_own_focus_target() -> void:
	var restart := _end.get_node("%RestartButton") as Button
	assert_eq(restart.get_node(restart.focus_neighbor_bottom), restart)
	assert_eq(restart.get_node(restart.focus_neighbor_top), restart)


func test_leaving_the_tree_releases_the_pause_it_took() -> void:
	Events.player_died.emit()
	remove_child(_end)
	assert_false(get_tree().paused)
	add_child(_end)
