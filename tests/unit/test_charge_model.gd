extends "res://tests/support/test_suite.gd"

const ChargeModel = preload("res://scripts/core/gameplay/charge_model.gd")


func run() -> void:
	_test_shadow_survival_time()
	_test_sunlight_refill_time()
	_test_overlapping_sunlight_sources()
	_test_spending_at_the_exact_threshold()


func _test_shadow_survival_time() -> void:
	start_test("full charge survives exactly 12.5 seconds in shadow")
	var model := ChargeModel.new()

	model.advance(12.5)

	expect_approx(model.get_charge(), 0.0)
	expect_true(model.is_depleted())


func _test_sunlight_refill_time() -> void:
	start_test("sunlight refills at the configured rate and clamps")
	var model := ChargeModel.new()
	model.try_spend(100.0)
	model.enter_sunlight()

	model.advance(100.0 / 35.0)
	model.advance(1.0)

	expect_approx(model.get_charge(), 100.0)


func _test_overlapping_sunlight_sources() -> void:
	start_test("overlapping sunlight emits only semantic transitions")
	var model := ChargeModel.new()
	var transitions: Array[bool] = []
	model.exposure_changed.connect(func(active: bool) -> void: transitions.append(active))

	model.enter_sunlight()
	model.enter_sunlight()
	model.exit_sunlight()
	model.exit_sunlight()
	model.exit_sunlight()

	expect_equal(transitions, [true, false])
	expect_equal(model.get_sunlight_source_count(), 0)
	expect_false(model.is_in_sunlight())


func _test_spending_at_the_exact_threshold() -> void:
	start_test("charge can be spent at the exact threshold")
	var model := ChargeModel.new()
	model.try_spend(75.0)

	expect_true(model.try_spend(25.0))
	expect_approx(model.get_charge(), 0.0)
	expect_false(model.try_spend(0.01))
