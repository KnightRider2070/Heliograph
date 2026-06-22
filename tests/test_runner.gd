extends SceneTree

const TEST_SUITES := [
	preload("res://tests/unit/test_charge_model.gd"),
	preload("res://tests/unit/test_character_motor_2d.gd"),
	preload("res://tests/unit/test_player_core.gd"),
	preload("res://tests/unit/test_cipher_model.gd"),
	preload("res://tests/unit/test_sentry_model.gd"),
	preload("res://tests/unit/test_glyph_codex.gd"),
]


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	var assertion_count := 0
	var failure_count := 0

	for suite_script in TEST_SUITES:
		var suite = suite_script.new()
		suite.run()
		assertion_count += suite.assertion_count
		failure_count += suite.failures.size()

		if suite.failures.is_empty():
			print("PASS %s (%d assertions)" % [suite.suite_name(), suite.assertion_count])
		else:
			print("FAIL %s" % suite.suite_name())
			for failure in suite.failures:
				print("  - %s" % failure)

	print("\n%d assertions, %d failures" % [assertion_count, failure_count])
	quit(0 if failure_count == 0 else 1)
