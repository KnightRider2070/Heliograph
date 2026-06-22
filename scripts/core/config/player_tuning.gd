class_name HeliographPlayerTuning
extends Resource

@export_category("Movement")
@export_range(0.0, 2000.0, 1.0, "or_greater") var run_speed: float = 220.0
@export_range(-2000.0, 0.0, 1.0) var jump_velocity: float = -430.0
@export_range(0.0, 5000.0, 1.0, "or_greater") var gravity: float = 1100.0
@export_range(0.0, 5000.0, 1.0, "or_greater") var maximum_fall_speed: float = 900.0
@export_range(0.0, 1.0, 0.01) var coyote_time: float = 0.10
@export_range(0.0, 1.0, 0.01) var jump_buffer_time: float = 0.12
@export_range(0.0, 1.0, 0.05) var jump_cut_multiplier: float = 0.50

@export_category("Dash")
@export_range(0.0, 5000.0, 1.0, "or_greater") var dash_speed: float = 600.0
@export_range(0.0, 2.0, 0.01) var dash_duration: float = 0.15
@export_range(0.0, 1000.0, 1.0, "or_greater") var dash_cost: float = 25.0

@export_category("Charge")
@export_range(0.01, 10000.0, 1.0, "or_greater") var maximum_charge: float = 100.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var sunlight_fill_rate: float = 35.0
@export_range(0.0, 1000.0, 1.0, "or_greater") var shadow_drain_rate: float = 8.0

@export_category("Lives")
@export_range(1, 9, 1) var maximum_lives: int = 3


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()

	if jump_velocity >= 0.0:
		errors.append("jump_velocity must be negative in Godot canvas coordinates")
	if maximum_charge <= 0.0:
		errors.append("maximum_charge must be greater than zero")
	if dash_cost > maximum_charge:
		errors.append("dash_cost cannot exceed maximum_charge")
	if dash_duration <= 0.0 and dash_speed > 0.0:
		errors.append("dash_duration must be greater than zero when dash_speed is configured")
	if maximum_lives < 1:
		errors.append("maximum_lives must be at least one")
	if jump_cut_multiplier <= 0.0 or jump_cut_multiplier > 1.0:
		errors.append("jump_cut_multiplier must be in the range (0, 1]")

	return errors
