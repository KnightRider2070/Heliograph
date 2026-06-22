extends "res://tests/support/test_suite.gd"

const CharacterMotor = preload("res://scripts/core/physics/character_motor_2d.gd")
const MotionInput = preload("res://scripts/core/physics/motion_input.gd")
const PHYSICS_DELTA := 1.0 / 60.0


func run() -> void:
	_test_horizontal_motion_and_facing()
	_test_coyote_jump()
	_test_buffered_jump()
	_test_jump_cut()
	_test_dash_duration_and_distance()
	_test_fall_speed_clamp()


func _test_horizontal_motion_and_facing() -> void:
	start_test("horizontal input maps directly to run velocity")
	var motor := CharacterMotor.new()

	var velocity := motor.advance(MotionInput.new(-1.0), PHYSICS_DELTA, true)

	expect_approx(velocity.x, -220.0)
	expect_equal(motor.facing_direction, -1)


func _test_coyote_jump() -> void:
	start_test("jump remains valid inside the coyote window")
	var motor := CharacterMotor.new()
	motor.advance(MotionInput.new(), PHYSICS_DELTA, true)
	motor.advance(MotionInput.new(), 0.05, false)

	var velocity := motor.advance(MotionInput.new(0.0, true), PHYSICS_DELTA, false)

	expect_true(velocity.y < 0.0)
	expect_approx(motor.jump_buffer_remaining, 0.0)


func _test_buffered_jump() -> void:
	start_test("an airborne jump press is consumed on landing")
	var motor := CharacterMotor.new()
	motor.velocity.y = 100.0
	motor.advance(MotionInput.new(0.0, true), PHYSICS_DELTA, false)

	var velocity := motor.advance(MotionInput.new(), PHYSICS_DELTA, true)

	expect_true(velocity.y < 0.0)
	expect_approx(motor.jump_buffer_remaining, 0.0)


func _test_jump_cut() -> void:
	start_test("releasing jump reduces upward velocity")
	var motor := CharacterMotor.new()
	motor.advance(MotionInput.new(), PHYSICS_DELTA, true)
	motor.advance(MotionInput.new(0.0, true), PHYSICS_DELTA, true)
	var before_cut := motor.velocity.y

	motor.advance(MotionInput.new(0.0, false, true), PHYSICS_DELTA, false)

	expect_true(absf(motor.velocity.y) < absf(before_cut))


func _test_dash_duration_and_distance() -> void:
	start_test("dash lasts 0.15 seconds and covers 90 pixels")
	var motor := CharacterMotor.new()
	var position := 0.0
	motor.advance(MotionInput.new(), PHYSICS_DELTA, true)
	expect_true(motor.start_dash(1.0))
	position += motor.velocity.x * PHYSICS_DELTA

	for frame in range(8):
		motor.advance(MotionInput.new(), PHYSICS_DELTA, false)
		position += motor.velocity.x * PHYSICS_DELTA

	motor.advance(MotionInput.new(), PHYSICS_DELTA, false)

	expect_approx(position, 90.0)
	expect_false(motor.is_dashing())
	expect_approx(motor.velocity.x, 0.0)


func _test_fall_speed_clamp() -> void:
	start_test("gravity never exceeds maximum fall speed")
	var motor := CharacterMotor.new()
	motor.velocity.y = 895.0

	var velocity := motor.advance(MotionInput.new(), PHYSICS_DELTA, false)

	expect_approx(velocity.y, 900.0)
