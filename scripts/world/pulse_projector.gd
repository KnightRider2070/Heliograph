@tool
class_name HeliographPulseProjector
extends Node2D
## A broken sun projector. It cycles its beam on and off on a timer (the `jitter`
## makes the timing erratic, so it reads as failing rather than as a clean
## metronome). Wire a `sunbeam_platform`'s `light_source` to it and the platform
## becomes an interval bridge: solid only while the beam is firing, so the player
## has to time the crossing. Exposes the same `is_active()` + `active_changed`
## contract as `sunlight_zone`, so the platform links to it identically.

signal active_changed(active: bool)

@export_range(0.2, 6.0, 0.05) var on_time: float = 1.4
@export_range(0.2, 6.0, 0.05) var off_time: float = 1.1
## How erratic the timing is (0 = steady metronome, 1 = badly broken).
@export_range(0.0, 1.0, 0.05) var jitter: float = 0.35
@export var starts_on: bool = true
@export var beam_length: float = 150.0:
	set(value):
		beam_length = maxf(8.0, value)
		_refresh()
@export var beam_spread: float = 44.0:
	set(value):
		beam_spread = maxf(4.0, value)
		_refresh()

var _active: bool = true
var _time_left: float = 0.0
var _flicker: float = 0.0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	_active = starts_on
	_time_left = _next_interval()
	_apply_beam()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_flicker += delta
	_time_left -= delta
	if _time_left <= 0.0:
		_active = not _active
		_time_left = _next_interval()
		active_changed.emit(_active)
	_apply_beam()


func is_active() -> bool:
	return _active


## Length of the next phase, scattered by jitter so a broken projector never
## settles into a predictable rhythm.
func _next_interval() -> float:
	var base := on_time if _active else off_time
	return maxf(0.1, base * (1.0 + randf_range(-jitter, jitter)))


func _apply_beam() -> void:
	if not has_node("Beam"):
		return
	if _active:
		# A failing projector: bright but stuttering.
		$Beam.modulate.a = clampf(0.62 + sin(_flicker * 26.0) * 0.18 + sin(_flicker * 7.0) * 0.1, 0.2, 1.0)
		$BeamCore.visible = true
		$Lens.color = Color(1, 0.92, 0.6, 1)
	else:
		$Beam.modulate.a = 0.05
		$BeamCore.visible = false
		$Lens.color = Color(0.3, 0.27, 0.4, 1)


func _refresh() -> void:
	if not has_node("Beam"):
		return
	var apex := 6.0
	$Beam.polygon = PackedVector2Array([
		Vector2(-apex, 0.0),
		Vector2(apex, 0.0),
		Vector2(beam_spread, beam_length),
		Vector2(-beam_spread, beam_length),
	])
	$BeamCore.polygon = PackedVector2Array([
		Vector2(-apex * 0.5, 0.0),
		Vector2(apex * 0.5, 0.0),
		Vector2(beam_spread * 0.5, beam_length),
		Vector2(-beam_spread * 0.5, beam_length),
	])
