class_name HeliographChargeModel
extends RefCounted

const PlayerTuning = preload("res://scripts/core/config/player_tuning.gd")

signal charge_changed(current: float, maximum: float)
signal exposure_changed(in_sunlight: bool)

var tuning: PlayerTuning
var _charge: float
var _sunlight_sources: int = 0


func _init(value: PlayerTuning = null) -> void:
	tuning = value if value != null else PlayerTuning.new()
	_charge = tuning.maximum_charge


func advance(delta: float) -> void:
	if delta <= 0.0:
		return

	var rate := tuning.sunlight_fill_rate if is_in_sunlight() else -tuning.shadow_drain_rate
	_set_charge(_charge + rate * delta)


func try_spend(amount: float) -> bool:
	if amount < 0.0 or _charge + 0.000001 < amount:
		return false

	_set_charge(_charge - amount)
	return true


func enter_sunlight() -> void:
	var was_in_sunlight := is_in_sunlight()
	_sunlight_sources += 1
	if not was_in_sunlight:
		exposure_changed.emit(true)


func exit_sunlight() -> void:
	var was_in_sunlight := is_in_sunlight()
	_sunlight_sources = maxi(0, _sunlight_sources - 1)
	if was_in_sunlight and not is_in_sunlight():
		exposure_changed.emit(false)


func clear_exposure() -> void:
	var was_in_sunlight := is_in_sunlight()
	_sunlight_sources = 0
	if was_in_sunlight:
		exposure_changed.emit(false)


func restore_full() -> void:
	_set_charge(tuning.maximum_charge)


func get_charge() -> float:
	return _charge


func get_sunlight_source_count() -> int:
	return _sunlight_sources


func is_in_sunlight() -> bool:
	return _sunlight_sources > 0


func is_depleted() -> bool:
	return _charge <= 0.0


func _set_charge(value: float) -> void:
	var next_charge := clampf(value, 0.0, tuning.maximum_charge)
	if is_equal_approx(next_charge, _charge):
		return

	_charge = next_charge
	charge_changed.emit(_charge, tuning.maximum_charge)
