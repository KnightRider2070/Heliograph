class_name HeliographSentryModel
extends RefCounted

signal state_changed(state: State)
signal fired

enum State {
	SWEEPING,
	WARNING,
	COOLDOWN,
}

var warning_duration: float = 0.35
var cooldown_duration: float = 0.75
var state: State = State.SWEEPING
var time_remaining: float = 0.0
var target_overlapping: bool = false
var target_exposed: bool = false
## A dormant (un-armed) Watcher still sweeps and tracks, but can never acquire
## a target or fire. The Watchers begin dormant and become armed once the
## Oracle turns hostile.
var armed: bool = true


func advance(delta: float) -> void:
	if delta <= 0.0:
		return

	match state:
		State.WARNING:
			if not can_target():
				_transition_to(State.SWEEPING)
				return

			time_remaining = maxf(0.0, time_remaining - delta)
			if time_remaining <= 0.0:
				fired.emit()
				_transition_to(State.COOLDOWN, cooldown_duration)
		State.COOLDOWN:
			time_remaining = maxf(0.0, time_remaining - delta)
			if time_remaining <= 0.0:
				_transition_to(State.SWEEPING)
				_evaluate_target()


func set_target_overlapping(active: bool) -> void:
	target_overlapping = active
	_evaluate_target()


func set_target_exposed(active: bool) -> void:
	target_exposed = active
	_evaluate_target()


func set_armed(value: bool) -> void:
	if armed == value:
		return
	armed = value
	if not armed and state == State.WARNING:
		_transition_to(State.SWEEPING)
	else:
		_evaluate_target()


func can_target() -> bool:
	return armed and target_overlapping and target_exposed


func _evaluate_target() -> void:
	if state == State.SWEEPING and can_target():
		_transition_to(State.WARNING, warning_duration)
	elif state == State.WARNING and not can_target():
		_transition_to(State.SWEEPING)


func _transition_to(next_state: State, duration: float = 0.0) -> void:
	if state == next_state and is_equal_approx(time_remaining, duration):
		return

	state = next_state
	time_remaining = duration
	state_changed.emit(state)
