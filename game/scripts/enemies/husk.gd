class_name Husk
extends CharacterBody3D
## Walks straight at the player (no pathfinding) and hurts it on contact.
## Reports its death through Events; whether it drops loot is the encounter's call.

## Closer than this on the ground plane the husk stands still instead of jittering.
const ARRIVED_DISTANCE := 0.05

@export var max_health := 30
@export var speed := 3.5
@export var contact_damage := 10
@export var contact_interval := 1.0
@export var contact_range := 1.5
@export var gravity := WorldPhysics.GRAVITY

var _health := Health.new()
var _contact: ContactAttack

@onready var _model: Node3D = $Model


func _ready() -> void:
	_contact = ContactAttack.new(contact_interval, contact_range)
	_health.depleted.connect(_die)
	_health.setup(max_health)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	var target := _living_player()
	var heading := _heading_towards(target)
	velocity.x = heading.x * speed
	velocity.z = heading.z * speed
	if heading != Vector3.ZERO:
		_model.rotation.y = PlayerMath.yaw_from_direction(heading)
	move_and_slide()
	if target != null:
		apply_contact_damage(delta, target)


## Advances the contact timer and hurts `target` if it is in range and the timer allows.
func apply_contact_damage(delta: float, target: Player) -> void:
	if _contact.tick(delta, global_position.distance_to(target.global_position)):
		target.take_damage(contact_damage)


func take_damage(amount: int) -> void:
	_health.take_damage(amount)


func _heading_towards(target: Player) -> Vector3:
	if target == null:
		return Vector3.ZERO
	var to_target := target.global_position - global_position
	var flat := Vector3(to_target.x, 0.0, to_target.z)
	if flat.length() < ARRIVED_DISTANCE:
		return Vector3.ZERO
	return flat.normalized()


func _living_player() -> Player:
	var player := get_tree().get_first_node_in_group(Groups.PLAYER) as Player
	if player == null or not player.is_alive():
		return null
	return player


func _die() -> void:
	set_physics_process(false)
	remove_from_group(Groups.ENEMIES)
	Events.enemy_died.emit(self)
	queue_free()
