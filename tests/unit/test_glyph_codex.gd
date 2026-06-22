extends "res://tests/support/test_suite.gd"

# The GlyphCodex ships as an autoload, but autoloads are not registered inside the
# headless --script test runner, so we exercise the script directly as a plain
# Node instance.
const GlyphCodexScript = preload("res://scripts/core/glyph_codex.gd")


func run() -> void:
	_test_learn_is_first_write_wins()
	_test_normalizes_and_stamps_level()
	_test_signal_only_fires_for_new_glyphs()
	_test_reset_clears_everything()


func _codex() -> Node:
	return GlyphCodexScript.new()


func _test_learn_is_first_write_wins() -> void:
	start_test("a glyph keeps the meaning it was first learned with")
	var codex := _codex()

	expect_true(codex.learn(&"solar_disc", "S"), "first learn records the glyph")
	expect_false(codex.learn(&"solar_disc", "Z"), "a known glyph is not overwritten")
	expect_true(codex.knows(&"solar_disc"))
	expect_equal(codex.letter_for(&"solar_disc"), "S")
	expect_false(codex.knows(&"open_cup"))
	expect_equal(codex.letter_for(&"open_cup"), "")
	expect_false(codex.learn(&"", "X"), "the empty glyph id is rejected")
	expect_equal(codex.count(), 1)

	codex.free()


func _test_normalizes_and_stamps_level() -> void:
	start_test("letters are upper-cased and the learning level is stamped")
	var codex := _codex()
	codex.set_current_level("level3")

	codex.learn(&"low_horizon", "  l ")
	expect_equal(codex.letter_for(&"low_horizon"), "L")
	expect_equal(codex.learned_in(&"low_horizon"), "level3")
	# An explicit override beats the current level.
	codex.learn(&"split_ring", "x", "level9")
	expect_equal(codex.learned_in(&"split_ring"), "level9")
	expect_equal(codex.known_letters(), {&"low_horizon": "L", &"split_ring": "X"})

	codex.free()


func _test_signal_only_fires_for_new_glyphs() -> void:
	start_test("glyph_learned fires once per genuinely new glyph")
	var codex := _codex()
	var learned: Array[StringName] = []
	codex.glyph_learned.connect(func(glyph_id: StringName, _letter: String) -> void: learned.append(glyph_id))

	codex.learn(&"eastern_arch", "A")
	codex.learn(&"eastern_arch", "A")
	codex.learn(&"relay_fork", "R")
	expect_equal(learned, [&"eastern_arch", &"relay_fork"])

	codex.free()


func _test_reset_clears_everything() -> void:
	start_test("reset wipes the journal for a fresh run")
	var codex := _codex()
	codex.learn(&"prism", "C")
	codex.reset()
	expect_false(codex.knows(&"prism"))
	expect_equal(codex.count(), 0)
	expect_true(codex.all().is_empty())

	codex.free()
