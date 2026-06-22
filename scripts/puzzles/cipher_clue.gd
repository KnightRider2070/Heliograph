class_name HeliographCipherClue
extends Area2D

const GlyphLibrary = preload("res://scripts/puzzles/glyph_library.gd")

@export var glyph_id: StringName
@export var glyph_mark: String = "?"

@onready var glyph_icon: Sprite2D = $GlyphAnchor/GlyphIcon
@onready var mapping_label: Label = $MappingLabel

var _controller: Node = null
var _player: Node = null
var _player_overlapping: bool = false
var _discovered: bool = false


func _ready() -> void:
	add_to_group("cipher_clue")
	glyph_icon.texture = GlyphLibrary.texture_for(glyph_id)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	set_player_in_sunlight(false)


func bind(controller: Node, player: Node) -> void:
	_controller = controller
	_player = player
	if player.has_signal("exposure_changed") and not player.exposure_changed.is_connected(set_player_in_sunlight):
		player.exposure_changed.connect(set_player_in_sunlight)
	if player.has_method("is_in_sunlight"):
		set_player_in_sunlight(player.is_in_sunlight())


func set_player_in_sunlight(active: bool) -> void:
	if _discovered:
		return
	glyph_icon.modulate = Color("ffd166") if active else Color("4c3f72")
	_offer_read()


func _on_body_entered(body: Node2D) -> void:
	if body != _player:
		return
	_player_overlapping = true
	_offer_read()


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player_overlapping = false


func _process(_delta: float) -> void:
	# Reading a mark is now a deliberate act — walking over it no longer hands you
	# the letter. Stand on a lit mark and press interact to read it.
	if _discovered or not _player_overlapping or not _is_readable():
		return
	if Input.is_action_just_pressed("interact"):
		_read()


func _is_readable() -> bool:
	return is_instance_valid(_player) and _player.has_method("is_in_sunlight") and _player.is_in_sunlight()


## Prompt the player to read, only when a fresh mark is both overlapped and lit.
func _offer_read() -> void:
	if not _discovered and _player_overlapping and _is_readable():
		$SpeechBubble.show_text("E — READ THIS MARK", 1.3)


func _read() -> void:
	if _discovered or not is_instance_valid(_controller):
		return
	if not _controller.discover_mapping(glyph_id):
		return

	_discovered = true
	var mappings: Dictionary = _controller.get_discovered_mappings()
	# Decoding a clue here teaches the glyph for the rest of the run.
	GlyphCodex.learn(glyph_id, String(mappings[glyph_id]))
	mapping_label.text = "%s = %s" % [String(glyph_id).replace("_", " ").to_upper(), mappings[glyph_id]]
	mapping_label.visible = true
	glyph_icon.modulate = Color("7be0d6")
	$Housing.modulate = Color("d8fffb")
	$SpeechBubble.show_text("%s = %s" % [glyph_mark, mappings[glyph_id]])
