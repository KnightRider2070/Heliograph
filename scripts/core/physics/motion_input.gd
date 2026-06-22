class_name HeliographMotionInput
extends RefCounted

var move_axis: float = 0.0
var jump_pressed: bool = false
var jump_released: bool = false
var dash_pressed: bool = false


func _init(
	axis: float = 0.0,
	wants_jump: bool = false,
	released_jump: bool = false,
	wants_dash: bool = false
) -> void:
	move_axis = clampf(axis, -1.0, 1.0)
	jump_pressed = wants_jump
	jump_released = released_jump
	dash_pressed = wants_dash
