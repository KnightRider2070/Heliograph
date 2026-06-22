class_name HeliographPuzzleMechanism
extends Area2D
## A light relay. The station's power is light itself: the player carries it
## forward one beam at a time. A relay can only fire while the player is standing
## in active light (it "relays the light from the last zone"); firing lights the
## downstream sun zones it points at, which in turn make their cipher clues
## readable and, at the end of the chain, power the exit terminal.

signal activated(mechanism: Mechanism, active: bool)

enum Mechanism {
	PRISM_ROTOR,
	LUNAR_DIAL,
	HELIOSTAT_SWITCH,
}

const TEXTURES := [
	preload("res://assets/game/environment/puzzle_mechanisms/frames/prism_rotor.png"),
	preload("res://assets/game/environment/puzzle_mechanisms/frames/lunar_dial.png"),
	preload("res://assets/game/environment/puzzle_mechanisms/frames/heliostat_switch.png"),
]
const MESSAGES := ["PRISM ALIGNED", "LUNAR PHASE LOCKED", "HELIOSTAT ROUTED"]

@export var mechanism: Mechanism = Mechanism.PRISM_ROTOR
## When latching, the relay can be switched on but not back off. Used wherever the
## relay powers progress, so the player can't accidentally undo it and softlock.
@export var latching: bool = false
## The relay can only fire while the player is in active light. This is what makes
## the chain a puzzle: you must bring light forward before you can send it on.
@export var requires_light: bool = false
## Sun zones this relay lights when it fires (set in the scene or in code).
@export var target_zones: Array[NodePath] = []
## Optional terminal this relay powers when it fires (used by the hand-built
## level; chapter levels wire the same effect through the activated signal).
@export var terminal_path: NodePath

var _player_nearby: bool = false
var _player: Node = null
var _active: bool = false
var _pulse_time: float = 0.0


func _ready() -> void:
	add_to_group("puzzle_mechanism")
	$Visual.texture = TEXTURES[mechanism]
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_pulse_time += delta
	$SignalRing.rotation += delta * (0.8 if _active else 0.2)
	$SignalRing.modulate.a = 0.72 + sin(_pulse_time * 4.0) * 0.18 if _active else 0.34
	if _player_nearby and Input.is_action_just_pressed("interact"):
		_try_toggle()


func _try_toggle() -> void:
	if latching and _active:
		$SpeechBubble.show_text("RELAY LOCKED IN")
		return
	# A relay needs light to relay. If the player isn't standing in an active
	# beam, the relay can't fire — this is the core of the chain puzzle.
	if requires_light and not _active and not _player_is_lit():
		$SpeechBubble.show_text("NO LIGHT TO RELAY — STAND IN THE BEAM")
		return

	_active = not _active
	$Visual.modulate = Color("d8fffb") if _active else Color.WHITE
	if _active:
		AudioDirector.sfx("relay_activate")
		_light_targets()
		_power_terminal(true)
		$SpeechBubble.show_text("LIGHT RELAYED" if not target_zones.is_empty() else MESSAGES[mechanism])
	else:
		_extinguish_targets()
		_power_terminal(false)
		$SpeechBubble.show_text("MECHANISM RELEASED")
	activated.emit(mechanism, _active)


func _power_terminal(value: bool) -> void:
	if terminal_path == NodePath(""):
		return
	var terminal := get_node_or_null(terminal_path)
	if terminal != null and terminal.has_method("set_powered"):
		terminal.set_powered(value)


func _player_is_lit() -> bool:
	return is_instance_valid(_player) and _player.has_method("is_in_sunlight") and _player.is_in_sunlight()


## Height of the overhead rail the relayed light routes along.
const RAIL_Y := 96.0


func _light_targets() -> void:
	for path in target_zones:
		var zone := get_node_or_null(path)
		if zone == null:
			continue
		if zone.has_method("set_active"):
			zone.set_active(true)
		_route_light_to(zone as Node2D)


func _extinguish_targets() -> void:
	for path in target_zones:
		var zone := get_node_or_null(path)
		if zone != null and zone.has_method("set_active"):
			zone.set_active(false)
	for beam in get_tree().get_nodes_in_group("relay_beam"):
		if beam.get_meta("relay", null) == self:
			beam.queue_free()


## Route the light orthogonally instead of as a diagonal UI line: up from the
## relay to a deflector diamond at rail height, across the rail, then down into a
## diamond at the target aperture. The bends happen at the diamonds, which is the
## "it hits a diamond that routes it" read.
func _route_light_to(zone: Node2D) -> void:
	var start := global_position + Vector2(0.0, -16.0)
	var mast := Vector2(global_position.x, RAIL_Y)
	var over := Vector2(zone.global_position.x, RAIL_Y)
	var into := zone.global_position + Vector2(0.0, 8.0)
	var points := PackedVector2Array([start, mast, over, into])

	AudioDirector.sfx("beam_ignite")
	_spawn_beam_line(points, 7.0, Color("ffd16633"), 0.85)  # soft glow
	_spawn_beam_line(points, 1.8, Color("ffe9b0"), 1.0)     # bright core
	_spawn_diamond(mast)
	_spawn_diamond(into)


func _spawn_beam_line(points: PackedVector2Array, line_width: float, line_color: Color, peak: float) -> void:
	var line := Line2D.new()
	line.add_to_group("relay_beam")
	line.set_meta("relay", self)
	line.top_level = true
	line.z_index = -1
	line.width = line_width
	line.default_color = line_color
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.points = points
	line.modulate.a = 0.0
	add_child(line)
	# Light is delivered in a pulse, then the beam clears entirely so nothing
	# lingers on screen — the lit sun zone is the lasting indicator.
	var tween := create_tween()
	tween.tween_property(line, "modulate:a", peak, 0.18)
	tween.tween_interval(0.5)
	tween.tween_property(line, "modulate:a", 0.0, 0.55)
	tween.tween_callback(line.queue_free)


func _spawn_diamond(at: Vector2) -> void:
	var diamond := Polygon2D.new()
	diamond.add_to_group("relay_beam")
	diamond.set_meta("relay", self)
	diamond.top_level = true
	diamond.z_index = 0
	diamond.position = at
	diamond.polygon = PackedVector2Array([Vector2(0, -7), Vector2(7, 0), Vector2(0, 7), Vector2(-7, 0)])
	diamond.color = Color("ffe9b0")
	diamond.modulate.a = 0.0
	add_child(diamond)
	# The deflector flashes as the light passes through it, then clears.
	var tween := create_tween()
	tween.tween_property(diamond, "modulate:a", 1.0, 0.16)
	tween.parallel().tween_property(diamond, "scale", Vector2(1.25, 1.25), 0.16)
	tween.tween_property(diamond, "scale", Vector2(0.9, 0.9), 0.3)
	tween.tween_interval(0.4)
	tween.tween_property(diamond, "modulate:a", 0.0, 0.5)
	tween.tween_callback(diamond.queue_free)


func bind_relay_player(player: Node) -> void:
	_player = player


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_nearby = true
	_player = body
	$Prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_nearby = false
	$Prompt.visible = false
