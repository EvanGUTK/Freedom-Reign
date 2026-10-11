extends GutTest
## Pause toggles get_tree().paused, announces it, offers Resume / Quit on every
## input device, and is inert once the round has ended.

const MENU_SCENE_PATH := "res://scenes/ui/pause_menu.tscn"
const PAUSE_ACTION := &"pause"
const CANCEL_ACTION := &"ui_cancel"

var _menu: PauseMenu


func before_each() -> void:
	watch_signals(Events)
	_menu = add_child_autofree((load(MENU_SCENE_PATH) as PackedScene).instantiate())


func after_each() -> void:
	get_tree().paused = false


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_menu._unhandled_input(event)


func test_menu_starts_closed_and_always_processes() -> void:
	assert_false(_menu.visible)
	assert_false(get_tree().paused)
	assert_eq(_menu.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_pause_action_opens_pauses_and_announces() -> void:
	_press(PAUSE_ACTION)
	assert_true(_menu.visible)
	assert_true(get_tree().paused)
	assert_signal_emitted_with_parameters(Events, "game_paused", [true])


func test_pause_action_again_resumes_and_announces() -> void:
	_press(PAUSE_ACTION)
	_press(PAUSE_ACTION)
	assert_false(_menu.visible)
	assert_false(get_tree().paused)
	assert_signal_emit_count(Events, "game_paused", 2)
	assert_signal_emitted_with_parameters(Events, "game_paused", [false], 1)


func test_ui_cancel_closes_an_open_menu() -> void:
	_press(PAUSE_ACTION)
	_press(CANCEL_ACTION)
	assert_false(get_tree().paused)


func test_ui_cancel_does_nothing_while_closed() -> void:
	_press(CANCEL_ACTION)
	assert_false(get_tree().paused)
	assert_signal_not_emitted(Events, "game_paused")


func test_opening_focuses_resume() -> void:
	_press(PAUSE_ACTION)
	assert_true((_menu.get_node("%ResumeButton") as Button).has_focus())


func test_resume_button_unpauses() -> void:
	_press(PAUSE_ACTION)
	(_menu.get_node("%ResumeButton") as Button).pressed.emit()
	assert_false(get_tree().paused)
	assert_false(_menu.visible)


func test_quit_button_is_wired_to_quit() -> void:
	assert_connected(_menu.get_node("%QuitButton"), _menu, "pressed", "_on_quit_pressed")


func test_focus_moves_between_the_two_buttons_both_ways() -> void:
	var resume := _menu.get_node("%ResumeButton") as Button
	var quit := _menu.get_node("%QuitButton") as Button
	assert_eq(resume.get_node(resume.focus_neighbor_bottom), quit)
	assert_eq(quit.get_node(quit.focus_neighbor_top), resume)
	assert_eq(resume.get_node(resume.focus_neighbor_top), quit, "wraps")
	assert_eq(quit.get_node(quit.focus_neighbor_bottom), resume, "wraps")


func test_pause_is_ignored_after_the_player_dies() -> void:
	Events.player_died.emit()
	_press(PAUSE_ACTION)
	assert_false(_menu.visible)
	assert_false(get_tree().paused)
	assert_signal_not_emitted(Events, "game_paused")


func test_pause_is_ignored_after_the_arena_is_cleared() -> void:
	Events.arena_cleared.emit()
	_press(PAUSE_ACTION)
	assert_false(get_tree().paused)
	assert_signal_not_emitted(Events, "game_paused")


func test_an_open_menu_hides_when_the_round_ends() -> void:
	_press(PAUSE_ACTION)
	Events.player_died.emit()
	assert_false(_menu.visible)
