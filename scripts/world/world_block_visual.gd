@tool
class_name HeliographWorldBlockVisual
extends Node2D

var _size := Vector2(144.0, 72.0)
var _fill_color := Color("18233a")
var _edge_color := Color("4c3f72")


func configure(size: Vector2, fill_color: Color, edge_color: Color) -> void:
	_size = size
	_fill_color = fill_color
	_edge_color = edge_color
	queue_redraw()


func _draw() -> void:
	var half := _size * 0.5
	var bounds := Rect2(-half, _size)
	draw_rect(bounds, _fill_color)
	draw_rect(Rect2(-half, Vector2(_size.x, 5.0)), _edge_color)
	draw_line(
		Vector2(-half.x, -half.y + 8.0),
		Vector2(half.x, -half.y + 8.0),
		Color("0b1020a6"),
		2.0
	)

	var seam_color := Color(_edge_color, 0.28)
	var rivet_color := Color("ff8c426b")
	var x := -half.x + 36.0
	while x < half.x:
		draw_line(
			Vector2(x, -half.y + 8.0),
			Vector2(x, half.y),
			seam_color,
			1.0
		)
		draw_circle(Vector2(x - 5.0, -half.y + 14.0), 1.5, rivet_color)
		draw_circle(Vector2(x + 5.0, -half.y + 14.0), 1.5, rivet_color)
		x += 36.0
