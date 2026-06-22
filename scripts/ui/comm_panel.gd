class_name HeliographCommPanel
extends CanvasLayer
## Cinematic dialogue box for every narrated beat (ACE's opening, the Oracle's
## lines, the post-puzzle reveals, the Watchers).
##
## Built entirely in code so it needs no artist and no second .tscn to keep in
## sync. When `play(lines)` is called it: pauses the game, drops in letterbox
## bars, rises a panel from the bottom, types each line out with a pulsing
## "voiceprint" and a colour-coded speaker chip, advances on Interact / Jump,
## then retracts and emits `finished`.

signal finished

const FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square.ttf")
const MONO := preload("res://assets/vendor/kenney/fonts/kenney_mini_square_mono.ttf")
const TYPE_SPEED := 44.0  # characters per second

const VIEW_W := 640.0
const VIEW_H := 360.0
const BAR_H := 34.0
const PANEL_RECT := Rect2(34, 236, 572, 86)

const SPEAKER_COLORS := {
	"ACE": Color("7be0d6"),         # signal cyan — your guide
	"THE ORACLE": Color("e84a5f"),  # danger red — the station mind
	"WATCHER": Color("ffd166"),     # sun amber — the machines
	"COURIER": Color("f2e9d8"),     # paper — you
}

var _root: Control
var _bar_top: ColorRect
var _bar_bottom: ColorRect
var _panel: Panel
var _accent: ColorRect
var _chip: Panel
var _speaker: Label
var _voiceprint: ColorRect
var _body: Label
var _prompt: Label

var _queue: Array = []
var _full_text: String = ""
var _shown: float = 0.0
var _typing: bool = false
var _active: bool = false
var _blink: float = 0.0
var _last_blip: int = 0
var _line_has_voice: bool = false


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.visible = false


func play(lines: Array) -> void:
	if lines == null or lines.is_empty():
		finished.emit()
		return
	_queue = lines.duplicate()
	_active = true
	_root.visible = true
	get_tree().paused = true
	_animate_in()
	_advance()


func is_active() -> bool:
	return _active


## Immediately end the whole sequence (used when the player skips, and by tests).
func skip_all() -> void:
	if not _active:
		return
	_queue.clear()
	_finish(false)


func _advance() -> void:
	if _queue.is_empty():
		_finish(true)
		return
	var line: Dictionary = _queue.pop_front()
	# Play the line's voice clip if one exists; falls back to the typewriter blips.
	_line_has_voice = false
	if line.has("voice"):
		_line_has_voice = AudioDirector.voice_file(String(line["voice"]))
	var speaker := String(line.get("speaker", ""))
	var color: Color = SPEAKER_COLORS.get(speaker, Color("f2e9d8"))
	_speaker.text = speaker
	_speaker.add_theme_color_override("font_color", color)
	_accent.color = color
	_voiceprint.color = color
	(_chip.get_theme_stylebox("panel") as StyleBoxFlat).border_color = color
	_full_text = String(line.get("text", ""))
	_body.text = ""
	_shown = 0.0
	_last_blip = 0
	_typing = true
	_prompt.visible = false


func _process(delta: float) -> void:
	if not _active:
		return
	if _typing:
		_shown += delta * TYPE_SPEED
		var count := int(_shown)
		if count >= _full_text.length():
			_body.text = _full_text
			_typing = false
		else:
			_body.text = _full_text.substr(0, count)
			if not _line_has_voice and count >= _last_blip + 3:
				_last_blip = count
				AudioDirector.sfx("text_blip")
		# Voiceprint "speaks" while text streams.
		_voiceprint.scale = Vector2(1.0, 0.4 + absf(sin(_shown * 0.6)) * 1.1)
	else:
		_voiceprint.scale = Vector2(1.0, 0.5)
		_blink += delta
		_prompt.visible = fmod(_blink, 0.9) < 0.55


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		get_viewport().set_input_as_handled()
		AudioDirector.sfx("text_advance")
		if _typing:
			_typing = false
			_body.text = _full_text
		else:
			_advance()


func _animate_in() -> void:
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_bar_top, "position:y", 0.0, 0.28)
	tween.tween_property(_bar_bottom, "position:y", VIEW_H - BAR_H, 0.28)
	_panel.position = PANEL_RECT.position + Vector2(0, 26)
	_panel.modulate.a = 0.0
	tween.tween_property(_panel, "position:y", PANEL_RECT.position.y, 0.3)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)


## Teardown. Control and pause state are released synchronously so callers can
## rely on the result immediately; the bars/panel slide-out is cosmetic only.
## `animate` is false when the player skips, true on natural completion.
func _finish(animate: bool) -> void:
	_active = false
	get_tree().paused = false
	if animate:
		var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(_bar_top, "position:y", -BAR_H, 0.22)
		tween.tween_property(_bar_bottom, "position:y", VIEW_H, 0.22)
		tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
		tween.chain().tween_callback(func() -> void: _root.visible = false)
	else:
		_root.visible = false
	finished.emit()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_bar_top = ColorRect.new()
	_bar_top.color = Color(0.02, 0.03, 0.06, 0.96)
	_bar_top.position = Vector2(0, -BAR_H)
	_bar_top.size = Vector2(VIEW_W, BAR_H)
	_bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar_top)

	_bar_bottom = ColorRect.new()
	_bar_bottom.color = Color(0.02, 0.03, 0.06, 0.96)
	_bar_bottom.position = Vector2(0, VIEW_H)
	_bar_bottom.size = Vector2(VIEW_W, BAR_H)
	_bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar_bottom)

	_panel = Panel.new()
	_panel.position = PANEL_RECT.position
	_panel.size = PANEL_RECT.size
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("0b1020f2")
	style.border_color = Color("1d2b45")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 10.0
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	# Speaker-coloured accent line across the top of the panel.
	_accent = ColorRect.new()
	_accent.position = Vector2(0, 0)
	_accent.size = Vector2(PANEL_RECT.size.x, 2)
	_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_accent)

	# Speaker name chip, sitting as a tab on the panel's top edge.
	_chip = Panel.new()
	_chip.position = Vector2(12, -13)
	_chip.size = Vector2(132, 20)
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chip_style := StyleBoxFlat.new()
	chip_style.bg_color = Color("0b1020")
	chip_style.border_color = Color("7be0d6")
	chip_style.set_border_width_all(1)
	chip_style.set_corner_radius_all(3)
	_chip.add_theme_stylebox_override("panel", chip_style)
	_panel.add_child(_chip)

	_speaker = Label.new()
	_speaker.position = Vector2(8, 3)
	_speaker.add_theme_font_override("font", MONO)
	_speaker.add_theme_font_size_override("font_size", 10)
	_chip.add_child(_speaker)

	# A little equaliser bar that pulses while the speaker is "talking".
	_voiceprint = ColorRect.new()
	_voiceprint.position = Vector2(16, 30)
	_voiceprint.size = Vector2(4, 16)
	_voiceprint.pivot_offset = Vector2(2, 8)
	_voiceprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_voiceprint)

	_body = Label.new()
	_body.position = Vector2(30, 22)
	_body.size = Vector2(PANEL_RECT.size.x - 50.0, 50.0)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_override("font", FONT)
	_body.add_theme_font_size_override("font_size", 12)
	_body.add_theme_color_override("font_color", Color("f2e9d8"))
	_panel.add_child(_body)

	_prompt = Label.new()
	_prompt.position = Vector2(PANEL_RECT.size.x - 116.0, PANEL_RECT.size.y - 38.0)
	_prompt.text = "E / SPACE  ▸"
	_prompt.add_theme_font_override("font", MONO)
	_prompt.add_theme_font_size_override("font_size", 9)
	_prompt.add_theme_color_override("font_color", Color("ffd166d0"))
	_panel.add_child(_prompt)
