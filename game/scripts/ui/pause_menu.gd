class_name PauseMenu
extends Control
## Pause overlay: the `pause` action (or ui_cancel while open) toggles
## get_tree().paused and announces it on Events. Ignored once the round has
## ended. Never touches Input.mouse_mode; gameplay's camera rig owns that.

@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton

var _round_ended := false


func _ready() -> void:
	hide()
	_resume_button.pressed.connect(_on_resume_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	Events.player_died.connect(_on_round_ended)
	Events.arena_cleared.connect(_on_round_ended)


func _unhandled_input(event: InputEvent) -> void:
	var toggles := event.is_action_pressed(&"pause") \
		or (visible and event.is_action_pressed(&"ui_cancel"))
	if toggles and not _round_ended:
		get_viewport().set_input_as_handled()
		set_open(not visible)


func set_open(open: bool) -> void:
	visible = open
	get_tree().paused = open
	Events.game_paused.emit(open)
	if open:
		_resume_button.grab_focus()


func _on_resume_pressed() -> void:
	set_open(false)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_round_ended() -> void:
	_round_ended = true
	hide()
