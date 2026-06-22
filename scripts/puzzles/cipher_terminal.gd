class_name HeliographCipherTerminal
extends Area2D

const GlyphLibrary = preload("res://scripts/puzzles/glyph_library.gd")
const MONO_FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square_mono.ttf")

@onready var prompt: Label = $Prompt
@onready var interface: Control = $Interface/Root
@onready var content: VBoxContainer = $Interface/Root/Panel/Margin/Content
@onready var sequence_icons: HBoxContainer = $Interface/Root/Panel/Margin/Content/SequenceIcons
@onready var sequence_label: Label = $Interface/Root/Panel/Margin/Content/Sequence
@onready var mappings_label: Label = $Interface/Root/Panel/Margin/Content/Mappings
@onready var answer_input: LineEdit = $Interface/Root/Panel/Margin/Content/Answer
@onready var feedback_label: Label = $Interface/Root/Panel/Margin/Content/Feedback

var _controller: Node = null
var _player: Node = null
var _player_nearby: bool = false
var _is_open: bool = false
var _previous_pause_state: bool = false
## Power gate. The terminal is dead until the relay chain reaches it, so the
## final relay activation has a clear, required payoff.
@export var starts_powered: bool = true
var _powered: bool = true


func _ready() -> void:
	add_to_group("cipher_terminal")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	answer_input.text_submitted.connect(_on_answer_submitted)
	$Interface/Root/Panel/Margin/Content/Buttons/Submit.pressed.connect(_submit)
	$Interface/Root/Panel/Margin/Content/Buttons/Cancel.pressed.connect(_close)
	interface.visible = false
	prompt.visible = false
	if not starts_powered:
		set_powered(false)


func _process(_delta: float) -> void:
	if _powered:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.08
		$ScreenGlow.scale = Vector2.ONE * pulse
	if _player_nearby and not _is_open and Input.is_action_just_pressed("interact"):
		if not _powered:
			$SpeechBubble.show_text("TERMINAL OFFLINE — ROUTE THE RELAY", 1.4)
			return
		_open()


func set_powered(value: bool) -> void:
	if _powered == value:
		return
	_powered = value
	$ScreenGlow.modulate.a = 1.0 if _powered else 0.18
	if _powered:
		AudioDirector.sfx("terminal_online")
		$SpeechBubble.show_text("TERMINAL ONLINE", 1.4)
	prompt.visible = _player_nearby and not _is_open and _powered


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("pause"):
		_close()
		get_viewport().set_input_as_handled()


func bind(controller: Node, player: Node) -> void:
	_controller = controller
	_player = player
	if controller.has_signal("mapping_discovered"):
		controller.mapping_discovered.connect(_on_mapping_discovered)
	_refresh_content()


func _open() -> void:
	if not is_instance_valid(_controller) or not is_instance_valid(_player):
		return
	_is_open = true
	_previous_pause_state = get_tree().paused
	_player.set_interacting(true)
	_refresh_content()
	feedback_label.text = ""
	answer_input.text = ""
	interface.visible = true
	prompt.visible = false
	get_tree().paused = true
	answer_input.grab_focus()


func _close() -> void:
	if not _is_open:
		return
	_is_open = false
	interface.visible = false
	get_tree().paused = _previous_pause_state
	if is_instance_valid(_player):
		_player.set_interacting(false)
	prompt.visible = _player_nearby


func _submit() -> void:
	if not _is_open:
		return
	if _controller.submit_answer(answer_input.text):
		_close()
	else:
		feedback_label.text = "NO SIGNAL. CHECK THE MAPPINGS."
		answer_input.select_all()


func _on_answer_submitted(_value: String) -> void:
	_submit()


func _on_mapping_discovered(
	_glyph_id: StringName,
	_letter: String,
	_discovered: int,
	_total: int
) -> void:
	_refresh_content()


func _refresh_content() -> void:
	if not is_instance_valid(_controller) or not is_node_ready():
		return

	var riddle: String = _controller.get_riddle() if _controller.has_method("get_riddle") else ""
	var mappings: Dictionary = _controller.get_discovered_mappings()

	# The encoded word: glyph icons only, no letters. The player has to decode it.
	# Glyphs the player already knows (decoded here or remembered from an earlier
	# level) read cyan; the ones still to work out stay gold. On a riddle level we
	# hide the encoded word entirely — showing it would give the answer away.
	for child in sequence_icons.get_children():
		sequence_icons.remove_child(child)
		child.queue_free()
	for glyph_id in _controller.get_sequence():
		# Glyphs already known from earlier levels are drawn smaller — they need
		# less of the player's attention than the marks still to work out, and it
		# keeps a long word from overflowing the panel.
		var remembered: bool = _controller.has_method("was_remembered") and _controller.was_remembered(glyph_id)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24.0, 24.0) if remembered else Vector2(38.0, 38.0)
		icon.texture = GlyphLibrary.texture_for(glyph_id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color("7be0d6") if mappings.has(glyph_id) else Color("ffd166")
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sequence_icons.add_child(icon)
	sequence_icons.visible = riddle.is_empty()
	sequence_label.text = riddle if not riddle.is_empty() else "DECODE THE TRANSMISSION"

	_rebuild_hint_line()

	# The key: each discovered glyph and the letter it stands for, as cards to
	# match against the sequence above. Reading the answer off a single line is
	# gone — the player works the substitution.
	mappings_label.text = "YOUR GLYPH KEY" if not mappings.is_empty() else "FIND GLYPH CLUES IN THE LIGHT TO BUILD A KEY"
	_rebuild_key_cards(mappings)
	_autoscale_content.call_deferred()


## The hint line and key cards grow with how much of a level's glyph key the
## player has uncovered, but the panel is a fixed size to match the terminal's
## screen art. Once the content needs more height than the panel has, shrink
## it uniformly from the top instead of letting it spill past the border.
func _autoscale_content() -> void:
	content.scale = Vector2.ONE
	var available_height := content.size.y
	var needed_height := content.get_combined_minimum_size().y
	if available_height <= 0.0 or needed_height <= available_height:
		return
	var fit_scale := available_height / needed_height
	content.pivot_offset = Vector2(content.size.x * 0.5, 0.0)
	content.scale = Vector2(fit_scale, fit_scale)


## A single line under the encoded word carrying any relational/partial clue
## (hint_text) and ordering telegraph the level author set, so a level can read as
## a small logic puzzle instead of a flat lookup.
func _rebuild_hint_line() -> void:
	var content := sequence_label.get_parent()
	var existing := content.get_node_or_null("HintLine")
	if existing != null:
		# queue_free() alone doesn't detach the node until end of frame, so the
		# add_child() below would collide with it by name and get silently
		# renamed (e.g. "HintLine2") — orphaning it forever since later lookups
		# only ever match the literal name "HintLine". Detach immediately instead.
		content.remove_child(existing)
		existing.queue_free()
	var parts := PackedStringArray()
	if _controller.has_method("get_ordering_note"):
		var note := String(_controller.get_ordering_note())
		if not note.is_empty():
			parts.append(note)
	if _controller.has_method("get_hint_text"):
		var hint := String(_controller.get_hint_text())
		if not hint.is_empty():
			parts.append(hint)
	if parts.is_empty():
		return
	var lbl := Label.new()
	lbl.name = "HintLine"
	lbl.text = "  •  ".join(parts)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", MONO_FONT)
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("ffd166cc"))
	content.add_child(lbl)
	content.move_child(lbl, sequence_label.get_index() + 1)


func _rebuild_key_cards(mappings: Dictionary) -> void:
	var content := mappings_label.get_parent()
	var existing := content.get_node_or_null("KeyCards")
	if existing != null:
		# See _rebuild_hint_line: detach immediately so the new same-named row
		# doesn't get auto-renamed and orphaned, stacking duplicate key rows.
		content.remove_child(existing)
		existing.queue_free()
	# A flow container so a long key wraps onto more rows instead of running off
	# the side of the panel (and off-screen).
	var row := HFlowContainer.new()
	row.name = "KeyCards"
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 6)
	for glyph_id in mappings:
		row.add_child(_make_key_card(glyph_id, String(mappings[glyph_id])))
	content.add_child(row)
	content.move_child(row, mappings_label.get_index() + 1)


func _make_key_card(glyph_id: StringName, letter: String) -> Control:
	# A decoy is a real glyph with a real letter, but it is not part of THIS
	# transmission. Flag it so the player learns the meaning without being lured
	# into spelling it into the answer.
	var is_decoy: bool = _controller.has_method("get_decoys") and _controller.get_decoys().has(glyph_id)
	var remembered: bool = _controller.has_method("was_remembered") and _controller.was_remembered(glyph_id)

	var card := VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 4)
	card.add_child(top)
	var icon := TextureRect.new()
	# Remembered glyphs are drawn smaller in the key too, matching the sequence.
	icon.custom_minimum_size = Vector2(20.0, 20.0) if remembered else Vector2(28.0, 28.0)
	icon.texture = GlyphLibrary.texture_for(glyph_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color("5a6b7a") if is_decoy else Color("7be0d6")
	top.add_child(icon)
	var lbl := Label.new()
	lbl.text = "= %s" % letter
	if is_decoy:
		lbl.add_theme_color_override("font_color", Color("8a96a3"))
	else:
		lbl.add_theme_color_override("font_color", Color("f2e9d8"))
	top.add_child(lbl)

	# A small caption distinguishes a remembered glyph (recall) from a decoy (trap).
	var caption := ""
	if is_decoy:
		caption = "NOT IN SIGNAL"
	elif remembered:
		caption = "REMEMBERED"
	if not caption.is_empty():
		var tag := Label.new()
		tag.text = caption
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.add_theme_font_size_override("font_size", 8)
		tag.add_theme_color_override("font_color", Color("e84a5f") if is_decoy else Color("7be0d6aa"))
		card.add_child(tag)
	return card


func _on_body_entered(body: Node2D) -> void:
	if body != _player:
		return
	_player_nearby = true
	prompt.visible = not _is_open and _powered
	$SpeechBubble.show_text("CIPHER CONSOLE ONLINE" if _powered else "TERMINAL OFFLINE — ROUTE THE RELAY", 1.4)


func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	_player_nearby = false
	prompt.visible = false
