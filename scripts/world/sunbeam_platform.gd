@tool
class_name HeliographSunbeamPlatform
extends StaticBody2D
## Ground that only exists where the sun is actually falling. It is solid and lit
## only while its linked light source is active; when the light leaves, the slab
## fades to a faint outline and you drop straight through. Point `light_source` at
## a `sunlight_zone` (so a relay that lights the zone also raises this platform) or
## at a `pulse_projector` (so a broken projector flickers the platform on and off
## as a timed bridge). Both expose the same `is_active()` + `active_changed`
## contract, so this platform never needs to know which it is wired to.

@export var size := Vector2(120.0, 18.0):
	set(value):
		size = value.max(Vector2(1.0, 1.0))
		_refresh()
## The light that decides whether this ground is here. A `sunlight_zone` or a
## `pulse_projector`.
@export var light_source: NodePath

var _active: bool = false


func _ready() -> void:
	_refresh()
	_set_active(false)
	if Engine.is_editor_hint():
		return
	# Resolve and sync deferred so the light source has finished its own _ready
	# (and applied starts_active / starts_on) before we read its state.
	_bind_source.call_deferred()


func _bind_source() -> void:
	var src := get_node_or_null(light_source)
	if src == null:
		return
	if src.has_signal("active_changed") and not src.active_changed.is_connected(_on_source_changed):
		src.active_changed.connect(_on_source_changed)
	if src.has_method("is_active"):
		_set_active(src.is_active())


func _on_source_changed(active: bool) -> void:
	_set_active(active)


func is_solid() -> bool:
	return _active


func _set_active(value: bool) -> void:
	_active = value
	if not has_node("ActiveVisual"):
		return
	$ActiveVisual.visible = value
	$InactiveVisual.visible = not value
	$CollisionShape2D.set_deferred("disabled", not value)


func _refresh() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	if not has_node("ActiveVisual") or not has_node("InactiveVisual") or not has_node("CollisionShape2D"):
		return
	var half := size * 0.5
	var points := PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	$ActiveVisual.polygon = points
	$InactiveVisual.polygon = points
	var shape := $CollisionShape2D.shape as RectangleShape2D
	if shape != null:
		shape.size = size
