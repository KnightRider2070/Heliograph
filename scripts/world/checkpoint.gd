class_name HeliographCheckpoint
extends Area2D

signal activated

var _activated: bool = false
var _pulse_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not _activated:
		return
	_pulse_time += delta
	var energy := 0.82 + sin(_pulse_time * 4.0) * 0.18
	$Visual.modulate = Color("d8fffb").lerp(Color.WHITE, energy)


func _on_body_entered(body: Node2D) -> void:
	if _activated or not body.has_method("set_spawn_point"):
		return

	_activated = true
	body.set_spawn_point(global_position)
	AudioDirector.sfx("checkpoint")
	$Visual.modulate = Color("d8fffb")
	$SpeechBubble.show_text("RESPAWN LINKED")
	activated.emit()
