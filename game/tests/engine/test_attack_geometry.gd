extends GutTest
## Reach and arc hit test, including the vertical dimension.

const REACH := 2.0
const ARC := 90.0
const ORIGIN := Vector3.ZERO
const FORWARD := Vector3(0, 0, -1)


func _hits(target: Vector3, reach := REACH, arc := ARC) -> bool:
	return AttackGeometry.is_in_attack(ORIGIN, FORWARD, target, reach, arc)


func test_target_straight_ahead_within_reach_is_hit() -> void:
	assert_true(_hits(Vector3(0, 0, -1.5)))


func test_target_beyond_reach_is_missed() -> void:
	assert_false(_hits(Vector3(0, 0, -2.01)))


func test_target_exactly_at_reach_is_hit() -> void:
	assert_true(_hits(Vector3(0, 0, -2.0)))


func test_target_behind_is_missed() -> void:
	assert_false(_hits(Vector3(0, 0, 1.0)))


func test_arc_edge_is_inclusive_and_outside_is_missed() -> void:
	assert_true(_hits(Vector3(1.0, 0, -1.0)), "exactly 45 degrees off forward with a 90 degree arc")
	assert_false(_hits(Vector3(1.0, 0, -0.8)), "about 51 degrees off")
	assert_true(_hits(Vector3(-1.0, 0, -1.0)), "arc is symmetric")


func test_wider_arc_catches_what_a_narrow_one_misses() -> void:
	var target := Vector3(1.4, 0, -0.5) # about 70 degrees off
	assert_false(_hits(target, REACH, 90.0))
	assert_true(_hits(target, REACH, 160.0))


func test_height_counts_towards_reach() -> void:
	assert_true(_hits(Vector3(0, 1.0, -1.0)), "a step below, close enough")
	assert_false(_hits(Vector3(0, 1.8, -1.2)), "horizontally near but 3D distance exceeds reach")
	assert_false(_hits(Vector3(0, -3.0, -0.5)), "far below")


func test_target_directly_above_within_reach_is_hit() -> void:
	assert_true(_hits(Vector3(0, 1.5, 0)))


func test_arc_follows_the_facing_not_the_world() -> void:
	var facing_east := Vector3(1, 0, 0)
	assert_true(AttackGeometry.is_in_attack(ORIGIN, facing_east, Vector3(1.5, 0, 0), REACH, ARC))
	assert_false(AttackGeometry.is_in_attack(ORIGIN, facing_east, Vector3(0, 0, -1.5), REACH, ARC))


func test_enemies_in_range_filters_candidates() -> void:
	var near := autofree(Node3D.new()) as Node3D
	var far := autofree(Node3D.new()) as Node3D
	var behind := autofree(Node3D.new()) as Node3D
	add_child(near)
	add_child(far)
	add_child(behind)
	near.global_position = Vector3(0, 0, -1)
	far.global_position = Vector3(0, 0, -5)
	behind.global_position = Vector3(0, 0, 1)
	var candidates: Array[Node] = [near, far, behind]
	var hit := AttackGeometry.enemies_in_range(candidates, ORIGIN, FORWARD, REACH, ARC)
	assert_eq(hit, [near] as Array[Node3D])
