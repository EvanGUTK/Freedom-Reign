class_name PlayerMath
extends RefCounted
## Pure movement and camera maths, kept apart from nodes so it can be tested exactly.

const MIN_PITCH := -1.2
const MAX_PITCH := 0.5
## Falling slower than this on touchdown is not a landing (spawn settling, stair-steps).
const MIN_LANDING_SPEED := 1.0


## Launch speed that peaks exactly `height` metres up under `gravity`: v = sqrt(2 g h).
static func jump_velocity(height: float, gravity: float) -> float:
	return sqrt(2.0 * gravity * height)


## Stick/key input (x right, y back, as Input.get_vector returns it) turned into a
## world-space direction relative to the camera's yaw.
static func world_direction(input: Vector2, camera_yaw: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, camera_yaw)


## Horizontal unit vector a node with this yaw faces (its local -Z).
static func forward_from_yaw(yaw: float) -> Vector3:
	return Vector3(-sin(yaw), 0.0, -cos(yaw))


static func yaw_from_direction(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


static func clamp_pitch(pitch: float) -> float:
	return clampf(pitch, MIN_PITCH, MAX_PITCH)


static func is_hard_landing(was_on_floor: bool, on_floor: bool, vertical_speed_before: float) -> bool:
	return on_floor and not was_on_floor and vertical_speed_before < -MIN_LANDING_SPEED
