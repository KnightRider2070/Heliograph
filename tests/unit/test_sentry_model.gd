extends "res://tests/support/test_suite.gd"

const SentryModel = preload("res://scripts/core/gameplay/sentry_model.gd")


func run() -> void:
	_test_warning_requires_overlap_and_exposure()
	_test_shadow_cancels_on_the_last_warning_tick()
	_test_warning_fires_once_then_cools_down()


func _test_warning_requires_overlap_and_exposure() -> void:
	start_test("sentry warning requires an overlapping exposed target")
	var model := SentryModel.new()
	model.set_target_overlapping(true)
	expect_equal(model.state, SentryModel.State.SWEEPING)

	model.set_target_exposed(true)
	expect_equal(model.state, SentryModel.State.WARNING)
	expect_approx(model.time_remaining, 0.35)


func _test_shadow_cancels_on_the_last_warning_tick() -> void:
	start_test("entering shadow cancels warning before fire")
	var model := SentryModel.new()
	var fired_events: Array[bool] = []
	model.fired.connect(func() -> void: fired_events.append(true))
	model.set_target_overlapping(true)
	model.set_target_exposed(true)
	model.advance(0.349)

	model.set_target_exposed(false)
	model.advance(0.01)

	expect_equal(model.state, SentryModel.State.SWEEPING)
	expect_equal(fired_events.size(), 0)


func _test_warning_fires_once_then_cools_down() -> void:
	start_test("completed warning fires once and enters cooldown")
	var model := SentryModel.new()
	var fired_events: Array[bool] = []
	model.fired.connect(func() -> void: fired_events.append(true))
	model.set_target_overlapping(true)
	model.set_target_exposed(true)

	model.advance(0.35)
	model.advance(0.50)

	expect_equal(fired_events.size(), 1)
	expect_equal(model.state, SentryModel.State.COOLDOWN)
	model.set_target_exposed(false)
	model.advance(0.25)
	expect_equal(model.state, SentryModel.State.SWEEPING)
