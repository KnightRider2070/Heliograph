class_name HeliographGlyphLibrary
extends RefCounted

const TEXTURES := {
	&"solar_disc": preload("res://assets/game/glyphs/solar_disc.svg"),
	&"open_cup": preload("res://assets/game/glyphs/open_cup.svg"),
	&"north_needle": preload("res://assets/game/glyphs/north_needle.svg"),
	&"split_ring": preload("res://assets/game/glyphs/split_ring.svg"),
	&"relay_fork": preload("res://assets/game/glyphs/relay_fork.svg"),
	&"low_horizon": preload("res://assets/game/glyphs/low_horizon.svg"),
	&"glass_lens": preload("res://assets/game/glyphs/glass_lens.svg"),
	&"prism": preload("res://assets/game/glyphs/prism.svg"),
	&"eastern_arch": preload("res://assets/game/glyphs/eastern_arch.svg"),
	&"double_wave": preload("res://assets/game/glyphs/double_wave.svg"),
	&"north_star": preload("res://assets/game/glyphs/north_star.svg"),
}

## The persistent glyph alphabet. Every glyph carries ONE meaning for the whole
## game — this is the rule that makes the codex worth keeping. Levels read the
## canonical letter from here so a glyph can never quietly change meaning. Each
## entry is [letter, name, concept] for the codex journal.
const CATALOG := {
	&"solar_disc": ["S", "Sun", "the source"],
	&"open_cup": ["U", "Cup", "the vessel"],
	&"north_needle": ["N", "Needle", "true north"],
	&"eastern_arch": ["A", "Arch", "the eastern gate"],
	&"relay_fork": ["R", "Fork", "the relay"],
	&"low_horizon": ["L", "Horizon", "the line"],
	&"split_ring": ["X", "Split Ring", "the cut"],
	&"prism": ["C", "Prism", "split light"],
	&"north_star": ["Y", "Star", "the fixed point"],
	&"glass_lens": ["O", "Lens", "focus"],
	&"double_wave": ["M", "Wave", "the tide"],
}


static func texture_for(glyph_id: StringName) -> Texture2D:
	return TEXTURES.get(glyph_id) as Texture2D


## The one letter this glyph means everywhere in the game. Authoring levels should
## match their cipher mappings to this so the codex stays consistent.
static func canonical_letter(glyph_id: StringName) -> String:
	if not CATALOG.has(glyph_id):
		return ""
	return CATALOG[glyph_id][0]


static func display_name(glyph_id: StringName) -> String:
	if not CATALOG.has(glyph_id):
		return String(glyph_id).replace("_", " ").capitalize()
	return CATALOG[glyph_id][1]


static func concept(glyph_id: StringName) -> String:
	if not CATALOG.has(glyph_id):
		return ""
	return CATALOG[glyph_id][2]
