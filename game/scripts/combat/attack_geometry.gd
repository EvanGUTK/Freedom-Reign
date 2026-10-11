class_name AttackGeometry
extends RefCounted
## Who a swing hits. Reach is a 3D distance, so height matters: an enemy two
## storeys below is out of reach. The arc is measured on the ground plane.

const ARC_EPSILON := 0.0001 # radians; keeps a target exactly on the edge of the arc inside it


static func is_in_attack(origin: Vector3, forward: Vector3, target: Vector3, reach: float, arc_degrees: float) -> bool:
	var to_target := target - origin
	if to_target.length() > reach:
		return false
	var flat_to_target := Vector3(to_target.x, 0.0, to_target.z)
	if flat_to_target.is_zero_approx():
		return true # directly above or below, within reach
	var flat_forward := Vector3(forward.x, 0.0, forward.z).normalized()
	var angle := flat_forward.angle_to(flat_to_target.normalized())
	return angle <= deg_to_rad(arc_degrees) / 2.0 + ARC_EPSILON


static func enemies_in_range(candidates: Array[Node], origin: Vector3, forward: Vector3, reach: float, arc_degrees: float) -> Array[Node3D]:
	var hit: Array[Node3D] = []
	for candidate in candidates:
		var enemy := candidate as Node3D
		if enemy != null and is_in_attack(origin, forward, enemy.global_position, reach, arc_degrees):
			hit.append(enemy)
	return hit
