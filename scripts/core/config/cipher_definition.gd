class_name HeliographCipherDefinition
extends Resource

@export var answer: String = ""
@export var sequence: Array[StringName] = []
@export var mappings: Dictionary = {}

## Glyphs that are clued and collectible in the level but are NOT part of the
## answer. They still need an entry in `mappings` (so the codex can record their
## real letter), but the terminal flags them so collecting stops being automatic.
@export var decoy_glyphs: Array[StringName] = []
## A riddle the player must solve and then encode (the answer is the riddle's
## answer). Empty = the level just decodes the displayed sequence as before.
@export_multiline var riddle: String = ""
## A relational / partial cipher clue ("the missing mark is a vowel", "✦ is not in
## the answer"). Shown at the terminal to turn a level into a small logic puzzle.
@export_multiline var hint_text: String = ""
## Telegraph for ordering puzzles ("read dawn → noon → dusk"). Display only for
## now; the answer is still validated as the final string.
@export var ordering_note: String = ""


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if answer.strip_edges().is_empty():
		errors.append("answer cannot be empty")
	if sequence.is_empty():
		errors.append("sequence cannot be empty")

	for glyph_id in sequence:
		if not mappings.has(glyph_id):
			errors.append("sequence glyph '%s' has no mapping" % glyph_id)

	# A decoy that is secretly in the answer would be a level-authoring mistake.
	for glyph_id in decoy_glyphs:
		if not mappings.has(glyph_id):
			errors.append("decoy glyph '%s' has no mapping" % glyph_id)
		if sequence.has(glyph_id):
			errors.append("decoy glyph '%s' is also in the sequence" % glyph_id)

	return errors


func is_decoy(glyph_id: StringName) -> bool:
	return decoy_glyphs.has(glyph_id)
