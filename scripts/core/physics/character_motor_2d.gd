class_name HeliographCharacterMotor2D
extends RefCounted

const PlayerTuning = preload("res://scripts/core/config/player_tuning.gd")
const MotionInput = preload("res://scripts/core/physics/motion_input.gd")
const TIMER_EPSILON := 0.000001

var tuning: PlayerTuning
var velocity := Vector2.ZERO
var facing_direction: int = 1
var coyote_time_remaining: float = 0.0
var jump_buffer_remaining: float = 0.0
var dash_time_remaining: float = 0.0


func _init(value: PlayerTuning = null) -> void:
	tuning = value if value != null else PlayerTuning.new()


func advance(input: MotionInput, delta: float, is_on_floor: bool) -> Vector2:
	if delta <= 0.0:
		return velocity

	_tick_dash(delta)
	_tick_jump_windows(input, delta, is_on_floor)
	_apply_horizontal_input(input.move_axis)
	_apply_buffered_jump()
	_apply_jump_cut(input.jump_released)
	_apply_gravity(delta)

	return velocity


func can_start_dash() -> bool:
	return not is_dashing() and tuning.dash_duration > 0.0


func start_dash(requested_direction: float = 0.0) -> bool:
	if not can_start_dash():
		return false

	var direction := signf(requested_direction)
	if is_zero_approx(direction):
		direction = float(facing_direction)

	facing_direction = 1 if direction > 0.0 else -1
	dash_time_remaining = tuning.dash_duration
	velocity.x = float(facing_direction) * tuning.dash_speed
	return true


func is_dashing() -> bool:
	return dash_time_remaining > 0.0


func reset() -> void:
	velocity = Vector2.ZERO
	coyote_time_remaining = 0.0
	jump_buffer_remaining = 0.0
	dash_time_remaining = 0.0


func _tick_dash(delta: float) -> void:
	if not is_dashing():
		return

	dash_time_remaining = maxf(0.0, dash_time_remaining - delta)
	if dash_time_remaining <= TIMER_EPSILON:
		dash_time_remaining = 0.0


func _tick_jump_windows(input: MotionInput, delta: float, is_on_floor: bool) -> void:
	if is_on_floor:
		coyote_time_remaining = tuning.coyote_time
	else:
		coyote_time_remaining = maxf(0.0, coyote_time_remaining - delta)

	jump_buffer_remaining = maxf(0.0, jump_buffer_remaining - delta)
	if input.jump_pressed:
		jump_buffer_remaining = tuning.jump_buffer_time


func _apply_horizontal_input(axis: float) -> void:
	if is_dashing():
		return

	var clamped_axis := clampf(axis, -1.0, 1.0)
	if not is_zero_approx(clamped_axis):
		facing_direction = 1 if clamped_axis > 0.0 else -1
	velocity.x = clamped_axis * tuning.run_speed


func _apply_buffered_jump() -> void:
	if jump_buffer_remaining <= 0.0 or coyote_time_remaining <= 0.0:
		return

	velocity.y = tuning.jump_velocity
	jump_buffer_remaining = 0.0
	coyote_time_remaining = 0.0


func _apply_jump_cut(jump_released: bool) -> void:
	if jump_released and velocity.y < 0.0:
		velocity.y *= tuning.jump_cut_multiplier


func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + tuning.gravity * delta, tuning.maximum_fall_speed)
