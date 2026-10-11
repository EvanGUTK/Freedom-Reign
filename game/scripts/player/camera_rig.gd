class_name CameraRig
extends Node3D
## Third-person camera: yaw on this node, pitch on the SpringArm3D child. Mouse
## look only works while the mouse is captured; the right stick always works.

const MOUSE_SENSITIVITY := 0.003 # radians per pixel
const STICK_SENSITIVITY := 2.8 # radians per second at full deflection
const STICK_DEADZONE := 0.2
const INITIAL_PITCH := -0.35
const GAMEPAD_DEVICE := 0

var yaw := 0.0

var _pitch := INITIAL_PITCH
var _look_enabled := true

@onready var _arm: SpringArm3D = $Arm


func _ready() -> void:
	_apply()
	Events.player_died.connect(_stop_looking)
	Events.arena_cleared.connect(_stop_looking)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if not _look_enabled:
		return
	var stick := Vector2(
		Input.get_joy_axis(GAMEPAD_DEVICE, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(GAMEPAD_DEVICE, JOY_AXIS_RIGHT_Y),
	)
	if stick.length() < STICK_DEADZONE:
		return
	look(-stick.x * STICK_SENSITIVITY * delta, -stick.y * STICK_SENSITIVITY * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _look_enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		look(-motion.relative.x * MOUSE_SENSITIVITY, -motion.relative.y * MOUSE_SENSITIVITY)


# The pause menu needs the mouse back; resuming takes it again.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif what == NOTIFICATION_UNPAUSED and _look_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Turn the camera by the given radians; pitch is clamped.
func look(delta_yaw: float, delta_pitch: float) -> void:
	yaw = wrapf(yaw + delta_yaw, -PI, PI)
	_pitch = PlayerMath.clamp_pitch(_pitch + delta_pitch)
	_apply()


func is_look_enabled() -> bool:
	return _look_enabled


func pitch() -> float:
	return _pitch


func _apply() -> void:
	rotation.y = yaw
	_arm.rotation.x = _pitch


# After death or victory the end screen needs the mouse.
func _stop_looking() -> void:
	_look_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
