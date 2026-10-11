class_name Player
extends CharacterBody3D
## The player character: camera-relative movement, jump, health. Reports through
## Events; nothing here knows about UI or audio.

const ACTION_MOVE_LEFT := &"move_left"
const ACTION_MOVE_RIGHT := &"move_right"
const ACTION_MOVE_FORWARD := &"move_forward"
const ACTION_MOVE_BACK := &"move_back"
const ACTION_JUMP := &"jump"
const ACTION_ATTACK := &"attack"
const TURN_RATE := 14.0 # how fast the model turns to face its heading, per second
const DEAD_TILT_RADIANS := PI / 2.0

@export var max_health := 100
@export var walk_speed := 6.0
@export var jump_height := 2.2
@export var gravity := WorldPhysics.GRAVITY

var _health := Health.new()
var _alive := true
var _was_on_floor := false
var _facing_yaw := 0.0

@onready var _camera_rig: CameraRig = $CameraRig
@onready var _attack: AttackController = $Attack
@onready var _model: Node3D = $Model


func _ready() -> void:
	_health.changed.connect(_on_health_changed)
	_health.depleted.connect(_die)
	_health.setup(max_health)


func _physics_process(delta: float) -> void:
	var fall_speed := velocity.y
	if not is_on_floor():
		velocity.y -= gravity * delta
	if _alive and is_on_floor() and Input.is_action_just_pressed(ACTION_JUMP):
		velocity.y = PlayerMath.jump_velocity(jump_height, gravity)
		Events.player_jumped.emit()

	var heading := _heading()
	velocity.x = heading.x * walk_speed
	velocity.z = heading.z * walk_speed
	if heading != Vector3.ZERO:
		_facing_yaw = lerp_angle(_facing_yaw, PlayerMath.yaw_from_direction(heading), minf(TURN_RATE * delta, 1.0))
	if _alive and Input.is_action_pressed(ACTION_ATTACK):
		_swing()
	_model.rotation.y = _facing_yaw

	move_and_slide()

	var on_floor := is_on_floor()
	if PlayerMath.is_hard_landing(_was_on_floor, on_floor, fall_speed):
		Events.player_landed.emit()
	_was_on_floor = on_floor


func equip_attack(attack: AttackData) -> void:
	_attack.equip(attack)


func is_alive() -> bool:
	return _alive


func take_damage(amount: int) -> void:
	if not _alive:
		return
	Events.player_hurt.emit(amount)
	_health.take_damage(amount)


# Swings toward where the camera looks, so the camera is also the aim.
func _swing() -> void:
	var aim_yaw := _camera_rig.yaw
	if _attack.is_ready():
		_facing_yaw = aim_yaw
	_attack.try_attack(global_position, PlayerMath.forward_from_yaw(aim_yaw))


func _heading() -> Vector3:
	if not _alive:
		return Vector3.ZERO
	var input := Input.get_vector(ACTION_MOVE_LEFT, ACTION_MOVE_RIGHT, ACTION_MOVE_FORWARD, ACTION_MOVE_BACK)
	return PlayerMath.world_direction(input, _camera_rig.yaw)


func _on_health_changed(current: int, maximum: int) -> void:
	Events.player_health_changed.emit(current, maximum)


func _die() -> void:
	_alive = false
	_model.rotation.z = DEAD_TILT_RADIANS
	Events.player_died.emit()
