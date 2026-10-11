class_name EndScreen
extends Control
## "Arena cleared" or "You died", with Restart. Showing it pauses the world so
## nothing keeps moving behind the menu; Restart unpauses and reloads the scene.
## Never touches Input.mouse_mode; gameplay's camera rig owns that.

const CLEARED_TEXT := "Arena cleared"
const DIED_TEXT := "You died"

## Replaced by tests so they can check the call path without reloading.
var restart_scene: Callable

@onready var _title: Label = %Title
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	hide()
	restart_scene = get_tree().reload_current_scene
	_restart_button.pressed.connect(_on_restart_pressed)
	Events.arena_cleared.connect(_show_end.bind(CLEARED_TEXT))
	Events.player_died.connect(_show_end.bind(DIED_TEXT))


func _exit_tree() -> void:
	if visible:
		get_tree().paused = false


func _show_end(text: String) -> void:
	if visible:
		return
	_title.text = text
	show()
	get_tree().paused = true
	_restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	restart_scene.call()
