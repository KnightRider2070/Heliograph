@tool
class_name HeliographChargeMeter
extends Control

@export_range(4, 20, 1) var segment_count: int = 12:
	set(value):
		segment_count = value
		queue_redraw()

var _ratio: float = 1.0
var _pulse_time: float = 0.0


func set_charge(current: float, maximum: float) -> void:
	_ratio = clampf(current / maximum if maximum > 0.0 else 0.0, 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if _ratio > 0.25:
		return
	_pulse_time += delta
	queue_redraw()


func _draw() -> void:
	var gap := 2.0
	var segment_width := (size.x - gap * float(segment_count - 1)) / float(segment_count)
	var active_segments := ceili(_ratio * segment_count)
	var pulse := 0.72 + 0.28 * sin(_pulse_time * 7.0)

	for index in segment_count:
		var rect := Rect2(index * (segment_width + gap), 0.0, segment_width, size.y)
		var active := index < active_segments
		var fill := Color("18233a")
		if active:
			fill = Color("e84a5f") * pulse if _ratio <= 0.25 else Color("ffd166")
		draw_rect(rect, fill)
		draw_rect(rect, Color("4c3f72"), false, 1.0)
