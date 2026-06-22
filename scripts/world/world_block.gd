@tool
class_name HeliographWorldBlock
extends StaticBody2D

@export var size := Vector2(144.0, 72.0):
	set(value):
		size = value.max(Vector2(1.0, 1.0))
		_refresh()
@export var fill_color := Color("18233a"):
	set(value):
		fill_color = value
		_refresh()
@export var edge_color := Color("4c3f72"):
	set(value):
		edge_color = value
		_refresh()


func _ready() -> void:
	_refresh()


func _refresh() -> void:
	if not is_inside_tree() and not Engine.is_editor_hint():
		return
	if not has_node("Visual") or not has_node("CollisionShape2D"):
		return

	$Visual.configure(size, fill_color, edge_color)
	var shape := $CollisionShape2D.shape as RectangleShape2D
	if shape != null:
		shape.size = size
