class_name HeliographCipherModel
extends RefCounted

const CipherDefinition = preload("res://scripts/core/config/cipher_definition.gd")

signal mapping_discovered(glyph_id: StringName, letter: String, discovered: int, total: int)
signal submission_rejected
signal puzzle_solved

var definition: CipherDefinition
var _discovered: Dictionary = {}
var _solved: bool = false


func _init(value: CipherDefinition = null) -> void:
	definition = value if value != null else CipherDefinition.new()


func discover_mapping(glyph_id: StringName) -> bool:
	if _discovered.has(glyph_id) or not definition.mappings.has(glyph_id):
		return false

	var letter := String(definition.mappings[glyph_id]).strip_edges().to_upper()
	_discovered[glyph_id] = letter
	mapping_discovered.emit(glyph_id, letter, _discovered.size(), definition.mappings.size())
	return true


func submit_answer(submitted: String) -> bool:
	var accepted := submitted.strip_edges().to_upper() == definition.answer.strip_edges().to_upper()
	if not accepted:
		submission_rejected.emit()
		return false

	if not _solved:
		_solved = true
		puzzle_solved.emit()
	return true


## Mark glyphs the player already learned in earlier levels as known here, without
## emitting discovery events (no fanfare for old news). Uses THIS level's own
## mappings as the source of truth, so a remembered glyph shows the right letter.
## The caller passes the glyph ids the codex knows; we keep only the ones that
## actually appear in this puzzle. Returns how many were primed.
func prime_known(glyph_ids: Array) -> int:
	var primed := 0
	for glyph_id in glyph_ids:
		if _discovered.has(glyph_id) or not definition.mappings.has(glyph_id):
			continue
		_discovered[glyph_id] = String(definition.mappings[glyph_id]).strip_edges().to_upper()
		primed += 1
	return primed


## The full glyph->letter map for the answer sequence, used to commit deduced
## mappings (e.g. an omitted clue the player inferred) to the codex on solve.
func get_answer_mappings() -> Dictionary:
	var out := {}
	for glyph_id in definition.sequence:
		if definition.mappings.has(glyph_id):
			out[glyph_id] = String(definition.mappings[glyph_id]).strip_edges().to_upper()
	return out


func is_discovered(glyph_id: StringName) -> bool:
	return _discovered.has(glyph_id)


func is_solved() -> bool:
	return _solved


func get_discovered_mappings() -> Dictionary:
	return _discovered.duplicate()


func get_discovered_count() -> int:
	return _discovered.size()
