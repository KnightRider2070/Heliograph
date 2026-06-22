class_name HeliographPlayerVisual
extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var signal_glow: Polygon2D = $SignalGlow

var _exposed: bool = false
var _pulse_time: float = 0.0


func _ready() -> void:
	sprite.play(&"idle")


func _process(delta: float) -> void:
	_pulse_time += delta
	var pulse := 1.0 + sin(_pulse_time * (5.0 if _exposed else 2.5)) * 0.12
	signal_glow.scale = Vector2.ONE * pulse


func set_motion_state(
	current_velocity: Vector2,
	facing_direction: int,
	is_dashing: bool,
	is_grounded: bool
) -> void:
	var next_animation := &"idle"
	if is_dashing:
		next_animation = &"dash"
	elif not is_grounded:
		next_animation = &"jump" if current_velocity.y < 0.0 else &"fall"
	elif absf(current_velocity.x) > 1.0:
		next_animation = &"run"

	if sprite.animation != next_animation:
		sprite.play(next_animation)
	scale.x = absf(scale.x) * float(facing_direction)
	modulate.a = 0.78 if is_dashing else 1.0


func set_exposure_state(active: bool) -> void:
	_exposed = active
	modulate = Color("fff0c2") if active else Color("d7e2ef")
	signal_glow.color = Color("fff3b080") if active else Color("7be0d660")


func play_death() -> void:
	sprite.play(&"death")


func reset_after_respawn() -> void:
	sprite.play(&"idle")
