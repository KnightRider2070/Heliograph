@tool
class_name HeliographLightPlatform
extends StaticBody2D

@export var size := Vector2(144.0, 18.0):
	set(value):
		size = value.max(Vector2(1.0, 1.0))
		_refresh()

var _active: bool = false
var _pulse_time: float = 0.0


func _ready() -> void:
	add_to_group("light_reactive")
	_refresh()
	set_player_in_sunlight(false)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _active:
		return
	_pulse_time += delta
	$ActiveVisual.modulate.a = 0.78 + sin(_pulse_time * 6.0) * 0.18


func bind_player(player: Node) -> void:
	if player.has_signal("exposure_changed"):
		player.exposure_changed.connect(set_player_in_sunlight)
	if player.has_method("is_in_sunlight"):
		set_player_in_sunlight(player.is_in_sunlight())


func set_player_in_sunlight(active: bool) -> void:
	_active = active
	if not has_node("ActiveVisual"):
		return
	$ActiveVisual.visible = active
	$InactiveVisual.visible = not active
	$CollisionShape2D.set_deferred("disabled", not active)


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
