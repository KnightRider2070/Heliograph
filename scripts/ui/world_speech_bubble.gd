class_name HeliographWorldSpeechBubble
extends Node2D

const FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square_mono.ttf")
const FONT_SIZE := 14
const WRAP_WIDTH := 246.0
# Nine-patch insets from the frame edge to the text (match the .tscn margins).
const PAD_LEFT := 54.0
const PAD_RIGHT := 24.0
const PAD_TOP := 20.0
const PAD_BOTTOM := 22.0

@export_range(0.2, 8.0, 0.1) var default_duration: float = 2.2

@onready var frame: NinePatchRect = $Frame
@onready var label: Label = $Frame/Text

var _animation: Tween
var _rest_scale: Vector2


func _ready() -> void:
	_rest_scale = scale
	visible = false


func show_text(value: String, duration: float = -1.0) -> void:
	if value.is_empty():
		return
	if is_instance_valid(_animation):
		_animation.kill()
	label.text = value
	_fit_to_text(value)
	visible = true
	modulate.a = 0.0
	scale = _rest_scale * Vector2(0.82, 0.72)
	var hold_time := default_duration if duration < 0.0 else duration
	_animation = create_tween()
	_animation.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_animation.tween_property(self, "scale", _rest_scale, 0.2)
	_animation.parallel().tween_property(self, "modulate:a", 1.0, 0.12)
	_animation.tween_interval(hold_time)
	_animation.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_animation.tween_property(self, "modulate:a", 0.0, 0.18)
	_animation.tween_callback(func() -> void: visible = false)


## Grow the bubble to fit the wrapped text, anchored at the bottom so the tail
## stays over the speaker. Without this, long lines spill past the frame.
func _fit_to_text(value: String) -> void:
	var text_size := FONT.get_multiline_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, WRAP_WIDTH, FONT_SIZE)
	var text_height := maxf(text_size.y, float(FONT_SIZE))
	var frame_width := PAD_LEFT + WRAP_WIDTH + PAD_RIGHT
	var frame_height := PAD_TOP + text_height + PAD_BOTTOM

	frame.offset_left = -frame_width * 0.5
	frame.offset_right = frame_width * 0.5
	frame.offset_top = -frame_height
	frame.offset_bottom = 0.0

	# The label is a child of the frame, so its offsets are measured from the
	# frame's top-left corner — just the nine-patch padding, NOT the frame's own
	# position. (Adding the frame offset here shoved the text up and out the left.)
	label.offset_left = PAD_LEFT
	label.offset_top = PAD_TOP
	label.offset_right = PAD_LEFT + WRAP_WIDTH
	label.offset_bottom = PAD_TOP + text_height
