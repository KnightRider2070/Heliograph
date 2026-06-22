@tool
class_name HeliographSunlightZone
extends Area2D

## Emitted whenever the beam lights or goes dark. Lets sun-gated platforms (and any
## other light-reactive prop) follow a zone the relay chain switches on, without
## polling. Shares its shape with `pulse_projector` so a platform can link to
## either a steady beam or a flickering projector.
signal active_changed(active: bool)

const APERTURE_NARROW := preload("res://assets/game/environment/apertures/frames/narrow.png")
const APERTURE_MEDIUM := preload("res://assets/game/environment/apertures/frames/medium.png")
const APERTURE_WIDE := preload("res://assets/game/environment/apertures/frames/wide.png")

@export var size := Vector2(180.0, 240.0):
	set(value):
		size = value.max(Vector2(1.0, 1.0))
		_refresh()
## When false the beam is dark at spawn and grants no charge until a relay lights
## it. A faint aperture still shows where the light *could* fall (telegraphing).
@export var starts_active: bool = true

var active: bool = true
var _drift_time: float = 0.0
var _bodies: Array[Node] = []


func _ready() -> void:
	_refresh()
	_style_shafts()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		active = starts_active
		_apply_active_visual()


## Turn the hard edge lines into soft light shafts that fade to nothing toward
## the floor, so they read as light rather than UI triangles.
func _style_shafts() -> void:
	if not has_node("LeftEdge"):
		return
	for edge in [$LeftEdge, $RightEdge]:
		var base: Color = edge.default_color
		var grad := Gradient.new()
		# Subtle: a soft top that fades to nothing, so the shaft reads as light
		# rather than a hard outline competing with everything else on screen.
		grad.set_color(0, Color(base.r, base.g, base.b, base.a * 0.4))
		grad.set_color(1, Color(base.r, base.g, base.b, 0.0))
		edge.gradient = grad
		edge.width = 2.0


func is_active() -> bool:
	return active


## Light or extinguish the beam. Grants/revokes exposure for anyone already
## standing inside so the player's charge counter stays balanced.
func set_active(value: bool) -> void:
	if active == value:
		return
	active = value
	_apply_active_visual()
	active_changed.emit(active)
	for body in _bodies:
		if not is_instance_valid(body):
			continue
		if active and body.has_method("enter_sunlight"):
			body.enter_sunlight()
		elif not active and body.has_method("exit_sunlight"):
			body.exit_sunlight()


func _apply_active_visual() -> void:
	if not has_node("Beam"):
		return
	$Beam.visible = active
	$BeamCore.visible = active
	$SourceBloom.visible = active
	$Motes.emitting = active
	$LeftEdge.modulate.a = 1.0 if active else 0.16
	$RightEdge.modulate.a = 1.0 if active else 0.16
	$Aperture.modulate.a = 1.0 if active else 0.4


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_drift_time += delta
	$SourceBloom.scale = Vector2.ONE * (1.0 + sin(_drift_time * 3.0) * 0.08)


func _refresh() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	if not has_node("Beam") or not has_node("Aperture") or not has_node("CollisionPolygon2D"):
		return

	var half := size * 0.5

	var aperture_texture: Texture2D = APERTURE_NARROW
	if size.x >= 360.0:
		aperture_texture = APERTURE_WIDE
	elif size.x >= 220.0:
		aperture_texture = APERTURE_MEDIUM
	$Aperture.texture = aperture_texture
	var aperture_width := minf(size.x * 0.78, 210.0)
	var aperture_scale := aperture_width / 192.0
	$Aperture.scale = Vector2.ONE * aperture_scale
	var aperture_height := 96.0 * aperture_scale
	$Aperture.position.y = -half.y + aperture_height * 0.5 - 2.0

	# The beam apex sits at the mouth of the fixture so the shaft of light emerges
	# directly from the aperture instead of leaving an odd gap beneath it.
	var aperture_bottom: float = $Aperture.position.y + aperture_height * 0.5
	var source := Vector2(0.0, aperture_bottom - 4.0)
	var left_foot := Vector2(-half.x, half.y)
	var right_foot := Vector2(half.x, half.y)
	var points := PackedVector2Array([source, right_foot, left_foot])
	$Beam.polygon = points
	$Beam.uv = PackedVector2Array([
		Vector2(0.5, 0.0),
		Vector2(1.0, 1.0),
		Vector2(0.0, 1.0),
	])
	$BeamCore.polygon = PackedVector2Array([
		source,
		Vector2(half.x * 0.68, half.y),
		Vector2(-half.x * 0.68, half.y),
	])
	$LeftEdge.points = PackedVector2Array([source, left_foot])
	$RightEdge.points = PackedVector2Array([source, right_foot])
	$SourceBloom.position = source
	var beam_height := maxf(1.0, half.y - source.y)
	$Motes.position = source
	$Motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	$Motes.direction = Vector2.DOWN
	$Motes.spread = clampf(rad_to_deg(atan2(half.x, beam_height)), 8.0, 42.0)
	$Motes.initial_velocity_min = beam_height * 0.18
	$Motes.initial_velocity_max = beam_height * 0.32
	$CollisionPolygon2D.polygon = points


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("enter_sunlight"):
		return
	if not _bodies.has(body):
		_bodies.append(body)
	if active:
		body.enter_sunlight()


func _on_body_exited(body: Node2D) -> void:
	if not body.has_method("exit_sunlight"):
		return
	_bodies.erase(body)
	if active:
		body.exit_sunlight()
