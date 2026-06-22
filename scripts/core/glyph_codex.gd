extends Node
## The player's glyph journal, registered as the `GlyphCodex` autoload.
##
## Heliograph's puzzles turn on a single rule: a glyph keeps its meaning across
## levels. The codex is the memory that makes that rule fair — once a glyph is
## decoded anywhere, it is remembered here so later levels can reuse it (or omit
## its clue entirely and let the player recall it). This is the one piece of
## cipher state that must survive a `change_scene_to_file`, so it lives as an
## autoload alongside `GameState` rather than in any single level.
##
## Scene scripts (clues, the cipher controller) read and write this directly;
## the pure `cipher_model` deliberately does NOT, so the headless unit runner —
## where autoloads are not registered — can exercise the model in isolation.

signal glyph_learned(glyph_id: StringName, letter: String)

## glyph_id -> { "letter": String, "learned_in": String }
var _entries: Dictionary = {}
## Story key of the level currently playing, stamped onto newly learned glyphs so
## the codex can show "learned in 02 / PRISM FOUNDRY".
var _current_level: String = ""


## Called by the level controller on load so `learn()` can stamp where a glyph
## was first decoded without every clue having to know the level key.
func set_current_level(level_key: String) -> void:
	_current_level = level_key


## Record a glyph's meaning. The first time wins: a glyph keeps the meaning it was
## learned with, which is the whole point of the codex. Returns true only when a
## new glyph is added so callers can react to genuine discoveries.
func learn(glyph_id: StringName, letter: String, learned_in: String = "") -> bool:
	if glyph_id == &"" or _entries.has(glyph_id):
		return false
	var where := learned_in if not learned_in.is_empty() else _current_level
	_entries[glyph_id] = {
		"letter": String(letter).strip_edges().to_upper(),
		"learned_in": where,
	}
	glyph_learned.emit(glyph_id, _entries[glyph_id]["letter"])
	return true


func knows(glyph_id: StringName) -> bool:
	return _entries.has(glyph_id)


func letter_for(glyph_id: StringName) -> String:
	if not _entries.has(glyph_id):
		return ""
	return _entries[glyph_id]["letter"]


func learned_in(glyph_id: StringName) -> String:
	if not _entries.has(glyph_id):
		return ""
	return _entries[glyph_id]["learned_in"]


## glyph_id -> letter, for any caller that just wants the known substitutions
## (e.g. priming a level's terminal with remembered glyphs).
func known_letters() -> Dictionary:
	var out := {}
	for glyph_id in _entries:
		out[glyph_id] = _entries[glyph_id]["letter"]
	return out


## Full snapshot (glyph_id -> { letter, learned_in }) for the codex UI.
func all() -> Dictionary:
	return _entries.duplicate(true)


func count() -> int:
	return _entries.size()


## Wipe the journal for a fresh run. Called from `GameState.new_game()` so the
## title/win screens start the courier with nothing remembered.
func reset() -> void:
	_entries.clear()
	_current_level = ""
