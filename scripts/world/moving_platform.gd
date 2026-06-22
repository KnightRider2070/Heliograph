@tool
class_name HeliographMovingPlatform
extends AnimatableBody2D
## A ground slab that travels back and forth and carries the player with it. An
## AnimatableBody2D with `sync_to_physics` so a CharacterBody2D rider moves with
## the platform instead of sliding off. Drop it into `World`, set `travel` (the
## offset to the far end) and `speed`; it ping-pongs forever, pausing briefly at
## each end so it reads as deliberate machinery rather than a yo-yo.

@export var size := Vector2(120.0, 18.0):
	set(value):
		size = value.max(Vector2(1.0, 1.0))
		_refresh()
## Offset from the placed position to the far end of the run. Horizontal for a
## ferry, vertical (negative y) for a lift.
@export var travel := Vector2(160.0, 0.0)
@export_range(8.0, 400.0, 1.0) var speed: float = 60.0
## Beat to hold at each end of the run.
@export_range(0.0, 3.0, 0.05) var pause_at_ends: float = 0.4
## Start parked at the far end instead of the near end.
@export var start_at_far_end: bool = false

var _origin: Vector2
var _t: float = 0.0
var _dir: float = 1.0
var _wait: float = 0.0


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	add_to_group("moving_platform")
	_origin = position
	if start_at_far_end:
		_t = 1.0
		_dir = -1.0
		position = _origin + travel


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var span := travel.length()
	if span < 0.001:
		return
	if _wait > 0.0:
		_wait -= delta
		return
	# Advance progress along the run at a constant world-space speed, ping-ponging
	# at the ends with a short pause.
	_t += (speed * delta / span) * _dir
	if _t >= 1.0:
		_t = 1.0
		_dir = -1.0
		_wait = pause_at_ends
	elif _t <= 0.0:
		_t = 0.0
		_dir = 1.0
		_wait = pause_at_ends
	position = _origin + travel * _t


func _refresh() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	if not has_node("Visual") or not has_node("CollisionShape2D"):
		return
	var half := size * 0.5
	$Visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	var shape := $CollisionShape2D.shape as RectangleShape2D
	if shape != null:
		shape.size = size
