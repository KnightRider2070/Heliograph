extends "res://tests/support/test_suite.gd"

const PlayerCore = preload("res://scripts/core/gameplay/player_core.gd")
const MotionInput = preload("res://scripts/core/physics/motion_input.gd")
const PHYSICS_DELTA := 1.0 / 60.0


func run() -> void:
	_test_dash_spends_charge()
	_test_dash_rejected_below_cost()
	_test_depletion_requests_clean_respawn()
	_test_death_is_guarded_until_respawn_completes()
	_test_lives_deplete_after_configured_deaths()
	_test_interaction_locks_simulation()


func _test_dash_spends_charge() -> void:
	start_test("a valid dash spends exactly 25 charge")
	var core := PlayerCore.new()

	var velocity := core.prepare_motion(
		MotionInput.new(1.0, false, false, true),
		PHYSICS_DELTA,
		true
	)

	expect_approx(core.charge.get_charge(), 75.0)
	expect_approx(velocity.x, 600.0)
	expect_true(core.motor.is_dashing())


func _test_dash_rejected_below_cost() -> void:
	start_test("dash cannot start below its charge cost")
	var core := PlayerCore.new()
	core.charge.try_spend(76.0)

	var velocity := core.prepare_motion(
		MotionInput.new(1.0, false, false, true),
		PHYSICS_DELTA,
		true
	)

	expect_approx(core.charge.get_charge(), 24.0)
	expect_approx(velocity.x, 220.0)
	expect_false(core.motor.is_dashing())


func _test_depletion_requests_clean_respawn() -> void:
	start_test("depletion resets runtime state and requests the checkpoint")
	var core := PlayerCore.new()
	var requested_positions: Array[Vector2] = []
	var exposure_transitions: Array[bool] = []
	var death_events: Array[bool] = []
	core.respawn_requested.connect(
		func(position: Vector2) -> void: requested_positions.append(position)
	)
	core.exposure_changed.connect(
		func(active: bool) -> void: exposure_transitions.append(active)
	)
	core.died.connect(func() -> void: death_events.append(true))
	core.set_spawn_point(Vector2(72.0, 144.0))
	core.enter_sunlight()
	core.exit_sunlight()
	core.charge.try_spend(92.0)
	core.motor.start_dash(1.0)

	core.complete_physics_step(1.0)

	expect_equal(core.state, PlayerCore.State.RESPAWNING)
	expect_equal(death_events.size(), 1)
	expect_equal(requested_positions, [Vector2(72.0, 144.0)])
	expect_vector_approx(core.motor.velocity, Vector2.ZERO)
	expect_false(core.motor.is_dashing())
	expect_approx(core.charge.get_charge(), 100.0)
	expect_false(core.charge.is_in_sunlight())
	expect_equal(exposure_transitions, [true, false])


func _test_death_is_guarded_until_respawn_completes() -> void:
	start_test("death cannot re-enter while respawning")
	var core := PlayerCore.new()

	expect_true(core.request_death())
	expect_false(core.request_death())
	core.complete_respawn()
	expect_true(core.request_death())


func _test_lives_deplete_after_configured_deaths() -> void:
	start_test("lives decrement and final death does not request another respawn")
	var core := PlayerCore.new()
	var life_values: Array[int] = []
	var respawn_events: Array[bool] = []
	var depleted_events: Array[bool] = []
	core.lives_changed.connect(
		func(current: int, _maximum: int) -> void: life_values.append(current)
	)
	core.respawn_requested.connect(func(_position: Vector2) -> void: respawn_events.append(true))
	core.lives_depleted.connect(func() -> void: depleted_events.append(true))

	for death in core.get_maximum_lives():
		expect_true(core.request_death())
		if death < core.get_maximum_lives() - 1:
			core.complete_respawn()

	expect_equal(life_values, [2, 1, 0])
	expect_equal(respawn_events.size(), 2)
	expect_equal(depleted_events.size(), 1)
	expect_equal(core.get_lives_remaining(), 0)


func _test_interaction_locks_simulation() -> void:
	start_test("interaction state locks movement and charge simulation")
	var core := PlayerCore.new()
	core.set_interacting(true)

	var velocity := core.prepare_motion(MotionInput.new(1.0), 1.0, true)
	core.complete_physics_step(1.0)

	expect_vector_approx(velocity, Vector2.ZERO)
	expect_approx(core.charge.get_charge(), 100.0)
