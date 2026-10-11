extends GutTest
## Movement and camera maths, checked against the formulas they implement.

const PLAYER_JUMP_HEIGHT := 2.2
const PLAYER_GRAVITY := 24.0
const EPSILON := 0.0001


func test_jump_velocity_peaks_at_the_requested_height() -> void:
	var v := PlayerMath.jump_velocity(PLAYER_JUMP_HEIGHT, PLAYER_GRAVITY)
	var apex := v * v / (2.0 * PLAYER_GRAVITY)
	assert_almost_eq(apex, PLAYER_JUMP_HEIGHT, EPSILON)


func test_jump_velocity_grows_with_height() -> void:
	assert_gt(PlayerMath.jump_velocity(3.0, PLAYER_GRAVITY), PlayerMath.jump_velocity(2.0, PLAYER_GRAVITY))


func test_simulated_jump_reaches_the_height_within_one_step_of_error() -> void:
	var step := 1.0 / 60.0
	var v := PlayerMath.jump_velocity(PLAYER_JUMP_HEIGHT, PLAYER_GRAVITY)
	var y := 0.0
	var peak := 0.0
	var steps := 0
	while v > 0.0 or y > 0.0:
		v -= PLAYER_GRAVITY * step
		y += v * step
		peak = maxf(peak, y)
		steps += 1
		assert_lt(steps, 600, "jump must end")
		if steps >= 600:
			return
	assert_almost_eq(peak, PLAYER_JUMP_HEIGHT, 0.1, "discrete jump apex")
	assert_gt(peak, 1.5, "the lowest platform (1.5 m) is reachable")


func test_forward_input_moves_along_camera_forward() -> void:
	for yaw in [0.0, 0.7, -1.9, PI]:
		var direction := PlayerMath.world_direction(Vector2(0.0, -1.0), yaw)
		var expected := PlayerMath.forward_from_yaw(yaw)
		assert_almost_eq(direction.x, expected.x, EPSILON, "x at yaw %f" % yaw)
		assert_almost_eq(direction.z, expected.z, EPSILON, "z at yaw %f" % yaw)


func test_right_input_is_ninety_degrees_clockwise_of_forward() -> void:
	var direction := PlayerMath.world_direction(Vector2(1.0, 0.0), 0.0)
	assert_almost_eq(direction.x, 1.0, EPSILON)
	assert_almost_eq(direction.z, 0.0, EPSILON)


func test_no_input_is_no_direction() -> void:
	assert_eq(PlayerMath.world_direction(Vector2.ZERO, 1.3), Vector3.ZERO)


func test_yaw_and_forward_round_trip() -> void:
	for yaw in [0.0, 1.0, -2.5, 3.0]:
		var round_trip := PlayerMath.yaw_from_direction(PlayerMath.forward_from_yaw(yaw))
		assert_almost_eq(angle_difference(round_trip, yaw), 0.0, EPSILON, "yaw %f" % yaw)


func test_pitch_is_clamped_both_ways() -> void:
	assert_eq(PlayerMath.clamp_pitch(-10.0), PlayerMath.MIN_PITCH)
	assert_eq(PlayerMath.clamp_pitch(10.0), PlayerMath.MAX_PITCH)
	assert_eq(PlayerMath.clamp_pitch(0.1), 0.1)


func test_landing_needs_a_real_fall_onto_the_floor() -> void:
	assert_true(PlayerMath.is_hard_landing(false, true, -8.0), "fall then floor")
	assert_false(PlayerMath.is_hard_landing(true, true, -8.0), "already grounded")
	assert_false(PlayerMath.is_hard_landing(false, false, -8.0), "still airborne")
	assert_false(PlayerMath.is_hard_landing(false, true, -0.4), "spawn settling is not a landing")
	assert_false(PlayerMath.is_hard_landing(false, true, 3.0), "rising is not a landing")
