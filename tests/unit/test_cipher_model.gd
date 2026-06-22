extends "res://tests/support/test_suite.gd"

const CipherDefinition = preload("res://scripts/core/config/cipher_definition.gd")
const CipherModel = preload("res://scripts/core/gameplay/cipher_model.gd")


func run() -> void:
	_test_discovery_is_validated_and_idempotent()
	_test_wrong_answer_preserves_progress()
	_test_correct_answer_is_normalized_and_emitted_once()
	_test_priming_marks_known_glyphs_silently()
	_test_answer_mappings_cover_the_sequence()
	_test_decoy_glyphs_are_collectible_outside_the_sequence()


func _definition() -> CipherDefinition:
	var definition := CipherDefinition.new()
	definition.answer = "SUN"
	definition.sequence = [&"solar_disc", &"open_cup", &"north_needle"]
	definition.mappings = {
		&"solar_disc": "S",
		&"open_cup": "U",
		&"north_needle": "N",
	}
	return definition


func _test_discovery_is_validated_and_idempotent() -> void:
	start_test("cipher discovery accepts known mappings once")
	var model := CipherModel.new(_definition())
	var events: Array[StringName] = []
	model.mapping_discovered.connect(
		func(glyph_id: StringName, _letter: String, _current: int, _total: int) -> void:
			events.append(glyph_id)
	)

	expect_true(model.discover_mapping(&"solar_disc"))
	expect_false(model.discover_mapping(&"solar_disc"))
	expect_false(model.discover_mapping(&"unknown"))
	expect_equal(events, [&"solar_disc"])
	expect_equal(model.get_discovered_mappings(), {&"solar_disc": "S"})


func _test_wrong_answer_preserves_progress() -> void:
	start_test("wrong answers do not erase discovered mappings")
	var model := CipherModel.new(_definition())
	var rejections: Array[bool] = []
	model.submission_rejected.connect(func() -> void: rejections.append(true))
	model.discover_mapping(&"open_cup")

	expect_false(model.submit_answer("MOON"))
	expect_equal(rejections.size(), 1)
	expect_true(model.is_discovered(&"open_cup"))
	expect_false(model.is_solved())


func _test_correct_answer_is_normalized_and_emitted_once() -> void:
	start_test("correct answers normalize case and solve once")
	var model := CipherModel.new(_definition())
	var solved_events: Array[bool] = []
	model.puzzle_solved.connect(func() -> void: solved_events.append(true))

	expect_true(model.submit_answer("  sun "))
	expect_true(model.submit_answer("SUN"))
	expect_true(model.is_solved())
	expect_equal(solved_events.size(), 1)


func _test_priming_marks_known_glyphs_silently() -> void:
	start_test("remembered glyphs are primed without re-emitting discovery")
	var model := CipherModel.new(_definition())
	var events: Array[StringName] = []
	model.mapping_discovered.connect(
		func(glyph_id: StringName, _l: String, _c: int, _t: int) -> void: events.append(glyph_id)
	)

	# Glyphs the codex already knew (one of ours, one unrelated to this puzzle).
	var primed := model.prime_known([&"solar_disc", &"unrelated"])
	expect_equal(primed, 1, "only this puzzle's glyphs are primed")
	expect_true(model.is_discovered(&"solar_disc"))
	expect_false(model.is_discovered(&"unrelated"))
	expect_equal(events, [], "priming stays silent")
	# A genuine discovery afterwards still works and still announces itself.
	expect_true(model.discover_mapping(&"open_cup"))
	expect_equal(events, [&"open_cup"])


func _test_answer_mappings_cover_the_sequence() -> void:
	start_test("answer mappings expose every sequence glyph for codex commit")
	var model := CipherModel.new(_definition())
	expect_equal(
		model.get_answer_mappings(),
		{&"solar_disc": "S", &"open_cup": "U", &"north_needle": "N"}
	)


func _test_decoy_glyphs_are_collectible_outside_the_sequence() -> void:
	start_test("a decoy glyph is discoverable but never part of the answer")
	var definition := _definition()
	definition.mappings[&"glass_lens"] = "O"
	definition.decoy_glyphs = [&"glass_lens"]

	var model := CipherModel.new(definition)
	expect_true(model.discover_mapping(&"glass_lens"), "the decoy can be collected")
	expect_true(definition.is_decoy(&"glass_lens"))
	expect_false(definition.sequence.has(&"glass_lens"), "the decoy is not in the answer sequence")
	expect_false(&"glass_lens" in model.get_answer_mappings(), "the decoy is excluded from the answer mappings")
