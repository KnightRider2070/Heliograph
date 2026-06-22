class_name HeliographPlayerBodyAdapter
extends CharacterBody2D

const PlayerTuning = preload("res://scripts/core/config/player_tuning.gd")
const PlayerCore = preload("res://scripts/core/gameplay/player_core.gd")
const MotionInput = preload("res://scripts/core/physics/motion_input.gd")

signal charge_changed(current: float, maximum: float)
signal exposure_changed(in_sunlight: bool)
signal died
signal respawned
signal lives_changed(current: int, maximum: int)
signal lives_depleted
signal motion_updated(
	current_velocity: Vector2,
	facing_direction: int,
	is_dashing: bool,
	is_grounded: bool
)

@export var tuning: PlayerTuning

var core: PlayerCore
var _was_dashing: bool = false
var _was_on_floor: bool = true


func _ready() -> void:
	add_to_group("player")
	if tuning == null:
		tuning = PlayerTuning.new()

	core = PlayerCore.new(tuning)
	core.charge_changed.connect(_on_charge_changed)
	core.exposure_changed.connect(_on_exposure_changed)
	core.died.connect(_on_died)
	core.respawn_requested.connect(_on_respawn_requested)
	core.lives_changed.connect(_on_lives_changed)
	core.lives_depleted.connect(_on_lives_depleted)
	core.set_spawn_point(global_position)


func _physics_process(delta: float) -> void:
	var input := MotionInput.new(
		Input.get_axis("move_left", "move_right"),
		Input.is_action_just_pressed("jump"),
		Input.is_action_just_released("jump"),
		Input.is_action_just_pressed("dash")
	)

	if input.jump_pressed and is_on_floor():
		AudioDirector.sfx("jump")
	velocity = core.prepare_motion(input, delta, is_on_floor())
	var dashing := core.motor.is_dashing()
	if dashing and not _was_dashing:
		AudioDirector.sfx("dash")
	_was_dashing = dashing
	move_and_slide()
	var grounded := is_on_floor()
	if grounded and not _was_on_floor:
		AudioDirector.sfx("land")
	_was_on_floor = grounded
	core.motor.velocity = velocity
	core.complete_physics_step(delta)
	motion_updated.emit(
		velocity,
		core.motor.facing_direction,
		core.motor.is_dashing(),
		is_on_floor()
	)


func enter_sunlight() -> void:
	core.enter_sunlight()


func exit_sunlight() -> void:
	core.exit_sunlight()


func set_spawn_point(value: Vector2) -> void:
	core.set_spawn_point(value)


func request_death() -> bool:
	return core.request_death()


func set_interacting(active: bool) -> void:
	core.set_interacting(active)


func is_in_sunlight() -> bool:
	return core.charge.is_in_sunlight()


func get_charge() -> float:
	return core.charge.get_charge()


func get_maximum_charge() -> float:
	return tuning.maximum_charge


func get_lives_remaining() -> int:
	return core.get_lives_remaining()


func get_maximum_lives() -> int:
	return core.get_maximum_lives()


func _on_charge_changed(current: float, maximum: float) -> void:
	charge_changed.emit(current, maximum)


func _on_exposure_changed(active: bool) -> void:
	exposure_changed.emit(active)


func _on_died() -> void:
	AudioDirector.sfx("death")
	$SpeechBubble.show_text("SIGNAL LOST", 0.72)
	died.emit()


func _on_lives_changed(current: int, maximum: int) -> void:
	lives_changed.emit(current, maximum)


func _on_lives_depleted() -> void:
	lives_depleted.emit()
	get_tree().create_timer(1.1).timeout.connect(_reload_after_game_over)


func _reload_after_game_over() -> void:
	get_tree().reload_current_scene()


func _on_respawn_requested(value: Vector2) -> void:
	global_position = value
	velocity = Vector2.ZERO
	core.motor.velocity = Vector2.ZERO
	reset_physics_interpolation()
	core.complete_respawn()
	respawned.emit()
