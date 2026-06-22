extends Node
## Cross-scene story and threat state, registered as the `GameState` autoload.
##
## The MVP deliberately kept every system level-local (see architecture.md,
## "No speculative global systems"). The narrative layer is the first feature
## that genuinely needs cross-level memory, so this autoload stays intentionally
## small: it only remembers facts that must survive a `change_scene_to_file`.
##
## - `intro_seen`        : the opening only plays once per run.
## - `watchers_hostile`  : the Watchers start dormant and curious; an action at
##                         the end of the first level turns them hostile for the
##                         rest of the run (the "exterminate" turn).

signal watchers_turned_hostile

## How freely the glyph codex may be consulted. EASY = always toggleable (the
## current behaviour); NORMAL/HARD are reserved for gating the journal to
## terminals / between-levels in a later pass. Stored here so the setting
## survives scene changes like the other run-wide facts.
enum CodexMode { EASY, NORMAL, HARD }

var intro_seen: bool = false
var watchers_hostile: bool = false
var codex_mode: CodexMode = CodexMode.EASY


func new_game() -> void:
	intro_seen = false
	watchers_hostile = false
	# The codex is run-wide memory; a fresh game starts the courier knowing nothing.
	GlyphCodex.reset()


func mark_intro_seen() -> void:
	intro_seen = true


func turn_watchers_hostile() -> void:
	if watchers_hostile:
		return
	watchers_hostile = true
	watchers_turned_hostile.emit()
