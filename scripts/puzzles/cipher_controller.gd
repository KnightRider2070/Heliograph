class_name HeliographCipherController
extends Node

const CipherDefinition = preload("res://scripts/core/config/cipher_definition.gd")
const CipherModel = preload("res://scripts/core/gameplay/cipher_model.gd")

signal mapping_discovered(glyph_id: StringName, letter: String, discovered: int, total: int)
signal submission_rejected
signal puzzle_solved

@export var definition: CipherDefinition

var model: CipherModel
## Glyphs the codex already knew when this level began — the terminal tints these
## as "remembered" so the player sees old knowledge carrying forward.
var _remembered_at_start: Dictionary = {}


func _ready() -> void:
	if definition == null:
		push_error("CipherController requires a CipherDefinition resource")
		definition = CipherDefinition.new()

	model = CipherModel.new(definition)
	model.mapping_discovered.connect(_on_mapping_discovered)
	model.submission_rejected.connect(_on_submission_rejected)
	model.puzzle_solved.connect(_on_puzzle_solved)

	# Old knowledge helps: any glyph this courier already decoded in an earlier
	# level starts this puzzle already known, so a later level can omit its clue
	# entirely and trust the player to remember it.
	var known: Dictionary = GlyphCodex.known_letters()
	for glyph_id in known:
		_remembered_at_start[glyph_id] = true
	model.prime_known(known.keys())

	# A glyph can be learned mid-level from a non-clue source (talking to a dormant
	# Watcher). When it lands in the codex, reflect it in this puzzle's key so the
	# terminal shows it live.
	GlyphCodex.glyph_learned.connect(_on_codex_glyph_learned)


func _on_codex_glyph_learned(glyph_id: StringName, _letter: String) -> void:
	if definition.mappings.has(glyph_id) and not model.is_discovered(glyph_id):
		model.discover_mapping(glyph_id)


func discover_mapping(glyph_id: StringName) -> bool:
	return model.discover_mapping(glyph_id)


func submit_answer(value: String) -> bool:
	return model.submit_answer(value)


func get_discovered_mappings() -> Dictionary:
	return model.get_discovered_mappings()


func get_sequence() -> Array[StringName]:
	return definition.sequence


func get_decoys() -> Array[StringName]:
	return definition.decoy_glyphs


func get_riddle() -> String:
	return definition.riddle


func get_hint_text() -> String:
	return definition.hint_text


func get_ordering_note() -> String:
	return definition.ordering_note


## True if the glyph was already in the codex before this level — i.e. the player
## is recalling it rather than discovering it here.
func was_remembered(glyph_id: StringName) -> bool:
	return _remembered_at_start.has(glyph_id)


func _on_mapping_discovered(
	glyph_id: StringName,
	letter: String,
	discovered: int,
	total: int
) -> void:
	AudioDirector.sfx("glyph_found")
	mapping_discovered.emit(glyph_id, letter, discovered, total)


func _on_submission_rejected() -> void:
	submission_rejected.emit()


func _on_puzzle_solved() -> void:
	AudioDirector.sfx("cipher_solved")
	# Solving confirms every glyph in the answer — including any whose clue was
	# omitted and that the player deduced. Commit them all to the codex so the
	# deduced meaning is remembered in later levels.
	var answer_mappings: Dictionary = model.get_answer_mappings()
	for glyph_id in answer_mappings:
		GlyphCodex.learn(glyph_id, answer_mappings[glyph_id])
	puzzle_solved.emit()
