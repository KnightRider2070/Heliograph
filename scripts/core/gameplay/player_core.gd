class_name HeliographPlayerCore
extends RefCounted

const PlayerTuning = preload("res://scripts/core/config/player_tuning.gd")
const MotionInput = preload("res://scripts/core/physics/motion_input.gd")
const CharacterMotor = preload("res://scripts/core/physics/character_motor_2d.gd")
const ChargeModel = preload("res://scripts/core/gameplay/charge_model.gd")

signal charge_changed(current: float, maximum: float)
signal exposure_changed(in_sunlight: bool)
signal died
signal respawn_requested(spawn_position: Vector2)
signal lives_changed(current: int, maximum: int)
signal lives_depleted

enum State {
	ACTIVE,
	INTERACTING,
	RESPAWNING,
}

var tuning: PlayerTuning
var motor: CharacterMotor
var charge: ChargeModel
var state: State = State.ACTIVE
var spawn_position := Vector2.ZERO
var lives_remaining: int


func _init(value: PlayerTuning = null) -> void:
	tuning = value if value != null else PlayerTuning.new()
	motor = CharacterMotor.new(tuning)
	charge = ChargeModel.new(tuning)
	lives_remaining = tuning.maximum_lives
	charge.charge_changed.connect(_on_charge_changed)
	charge.exposure_changed.connect(_on_exposure_changed)


func prepare_motion(input: MotionInput, delta: float, is_on_floor: bool) -> Vector2:
	if state != State.ACTIVE:
		return Vector2.ZERO

	motor.advance(input, delta, is_on_floor)
	if input.dash_pressed and motor.can_start_dash() and charge.try_spend(tuning.dash_cost):
		motor.start_dash(input.move_axis)

	return motor.velocity


func complete_physics_step(delta: float) -> void:
	if state != State.ACTIVE:
		return

	charge.advance(delta)
	if charge.is_depleted():
		request_death()


func enter_sunlight() -> void:
	if state != State.RESPAWNING:
		charge.enter_sunlight()


func exit_sunlight() -> void:
	if state != State.RESPAWNING:
		charge.exit_sunlight()


func set_spawn_point(value: Vector2) -> void:
	spawn_position = value


func set_interacting(active: bool) -> void:
	if state == State.RESPAWNING:
		return
	state = State.INTERACTING if active else State.ACTIVE


func request_death() -> bool:
	if state == State.RESPAWNING:
		return false

	state = State.RESPAWNING
	lives_remaining = maxi(0, lives_remaining - 1)
	died.emit()
	lives_changed.emit(lives_remaining, tuning.maximum_lives)
	motor.reset()
	charge.clear_exposure()
	charge.restore_full()
	if lives_remaining <= 0:
		lives_depleted.emit()
		return true
	respawn_requested.emit(spawn_position)
	return true


func complete_respawn() -> void:
	if state == State.RESPAWNING:
		state = State.ACTIVE


func get_lives_remaining() -> int:
	return lives_remaining


func get_maximum_lives() -> int:
	return tuning.maximum_lives


func _on_charge_changed(current: float, maximum: float) -> void:
	charge_changed.emit(current, maximum)


func _on_exposure_changed(in_sunlight: bool) -> void:
	exposure_changed.emit(in_sunlight)
