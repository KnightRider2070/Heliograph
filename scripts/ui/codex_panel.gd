class_name HeliographCodexPanel
extends Control
## The glyph journal overlay. The HUD's "CIPHER CACHE" shows only what was decoded
## in the current level; the codex is the persistent superset — every glyph the
## courier has learned across the whole run, so deduction never decays into
## memorisation. Toggled with the `codex` action (C); a non-pausing overlay so the
## player can glance at it mid-level without breaking flow.

const GlyphLibrary = preload("res://scripts/puzzles/glyph_library.gd")
const TITLE_FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square.ttf")
const MONO_FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square_mono.ttf")

const INK := Color(0.0431373, 0.0627451, 0.12549)
const CYAN := Color("7be0d6")
const GOLD := Color("ffd166")
const PARCHMENT := Color("f2e9d8")

var _grid: GridContainer
var _empty: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_build()
	if GlyphCodex.glyph_learned.is_connected(_on_glyph_learned) == false:
		GlyphCodex.glyph_learned.connect(_on_glyph_learned)


func _unhandled_input(event: InputEvent) -> void:
	# Uses _unhandled_input (not polling) so pressing C while typing into the
	# terminal's answer field types a C instead of opening the journal.
	if event.is_action_pressed("codex"):
		toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("pause"):
		hide_panel()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()


func show_panel() -> void:
	_refresh()
	visible = true


func hide_panel() -> void:
	visible = false


func _build() -> void:
	var scrim := ColorRect.new()
	scrim.color = Color(INK.r, INK.g, INK.b, 0.82)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520.0, 150.0)
	panel.offset_left = -260.0
	panel.offset_top = -140.0
	panel.offset_right = 260.0
	panel.offset_bottom = 140.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0941176, 0.137255, 0.227451, 0.97)
	style.set_border_width_all(2)
	style.border_color = Color(CYAN.r, CYAN.g, CYAN.b, 0.7)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)

	var title := Label.new()
	title.text = "GLYPH CODEX"
	title.add_theme_font_override("font", TITLE_FONT)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", GOLD)
	col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Every mark you've decoded. A glyph keeps its meaning across the station."
	subtitle.add_theme_font_override("font", MONO_FONT)
	subtitle.add_theme_font_size_override("font_size", 7)
	subtitle.add_theme_color_override("font_color", Color(CYAN.r, CYAN.g, CYAN.b, 0.7))
	col.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(488.0, 196.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 18)
	_grid.add_theme_constant_override("v_separation", 8)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_grid)

	_empty = Label.new()
	_empty.text = "No glyphs decoded yet. Find clues in the light."
	_empty.add_theme_font_override("font", MONO_FONT)
	_empty.add_theme_font_size_override("font_size", 8)
	_empty.add_theme_color_override("font_color", Color(PARCHMENT.r, PARCHMENT.g, PARCHMENT.b, 0.42))
	col.add_child(_empty)

	var footer := Label.new()
	footer.text = "C  CLOSE"
	footer.add_theme_font_override("font", MONO_FONT)
	footer.add_theme_font_size_override("font_size", 7)
	footer.add_theme_color_override("font_color", Color(GOLD.r, GOLD.g, GOLD.b, 0.6))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	col.add_child(footer)


func _refresh() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		child.queue_free()
	var entries: Dictionary = GlyphCodex.all()
	_empty.visible = entries.is_empty()
	for glyph_id in entries:
		_grid.add_child(_make_entry(glyph_id, entries[glyph_id]))


func _make_entry(glyph_id: StringName, data: Dictionary) -> Control:
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 8)
	card.custom_minimum_size = Vector2(232.0, 34.0)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(30.0, 30.0)
	icon.texture = GlyphLibrary.texture_for(glyph_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = CYAN
	card.add_child(icon)

	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	card.add_child(text)

	var head := Label.new()
	head.text = "%s  =  %s" % [GlyphLibrary.display_name(glyph_id), String(data.get("letter", "?"))]
	head.add_theme_font_override("font", MONO_FONT)
	head.add_theme_font_size_override("font_size", 10)
	head.add_theme_color_override("font_color", PARCHMENT)
	text.add_child(head)

	var sub := Label.new()
	var where := String(data.get("learned_in", ""))
	var concept := GlyphLibrary.concept(glyph_id)
	sub.text = concept if where.is_empty() else "%s · %s" % [concept, where.to_upper()]
	sub.add_theme_font_override("font", MONO_FONT)
	sub.add_theme_font_size_override("font_size", 6)
	sub.add_theme_color_override("font_color", Color(CYAN.r, CYAN.g, CYAN.b, 0.62))
	text.add_child(sub)

	return card


func _on_glyph_learned(_glyph_id: StringName, _letter: String) -> void:
	if visible:
		_refresh()
