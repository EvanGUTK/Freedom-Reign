extends GutTest
## Contact damage timing: once per interval while in range.

const INTERVAL := 1.0
const RANGE := 1.5
const STEP := 0.25 # exactly representable, so four steps are exactly one interval

var _contact: ContactAttack


func before_each() -> void:
	_contact = ContactAttack.new(INTERVAL, RANGE)


func _count_hits(seconds: float, distance: float) -> int:
	var hits := 0
	for i in int(seconds / STEP):
		if _contact.tick(STEP, distance):
			hits += 1
	return hits


func test_first_tick_in_range_lands_a_hit() -> void:
	assert_true(_contact.tick(STEP, 1.0))


func test_no_second_hit_inside_the_interval() -> void:
	_contact.tick(STEP, 1.0)
	assert_false(_contact.tick(STEP, 1.0))
	assert_false(_contact.tick(STEP, 1.0))
	assert_false(_contact.tick(STEP, 1.0), "0.75 s after the hit")


func test_second_hit_lands_exactly_one_interval_after_the_first() -> void:
	_contact.tick(STEP, 1.0)
	for i in 3:
		_contact.tick(STEP, 1.0)
	assert_true(_contact.tick(STEP, 1.0), "1.0 s after the hit")


func test_three_seconds_in_range_hit_three_times() -> void:
	assert_eq(_count_hits(3.0, 1.0), 3)


func test_out_of_range_never_hits() -> void:
	assert_eq(_count_hits(5.0, 1.51), 0)


func test_range_edge_is_inclusive() -> void:
	assert_true(_contact.tick(STEP, RANGE))


func test_interval_keeps_running_while_out_of_range() -> void:
	_contact.tick(STEP, 1.0)
	_count_hits(1.0, 10.0)
	assert_true(_contact.tick(STEP, 1.0), "a full interval passed while away, so contact hurts at once")
