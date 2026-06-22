class_name HeliographPatrolDrone
extends CharacterBody2D

@export_range(32.0, 800.0, 1.0) var patrol_distance: float = 180.0
@export_range(10.0, 300.0, 1.0) var patrol_speed: float = 78.0

@onready var sprite: AnimatedSprite2D = $Sprite

var _origin_x: float
var _direction: float = 1.0
var _alerting: bool = false


func _ready() -> void:
	add_to_group("moving_enemy")
	_origin_x = global_position.x
	$HazardArea.body_entered.connect(_on_body_entered)
	sprite.play(&"patrol")


func _physics_process(_delta: float) -> void:
	if _alerting:
		velocity = Vector2.ZERO
		return
	var left_limit := _origin_x - patrol_distance * 0.5
	var right_limit := _origin_x + patrol_distance * 0.5
	if global_position.x <= left_limit:
		_direction = 1.0
	elif global_position.x >= right_limit:
		_direction = -1.0
	velocity = Vector2(patrol_speed * _direction, 0.0)
	move_and_slide()
	if is_on_wall():
		_direction *= -1.0
	sprite.flip_h = _direction < 0.0


func _on_body_entered(body: Node2D) -> void:
	if _alerting or not body.has_method("request_death"):
		return
	_alerting = true
	sprite.play(&"alert")
	$SpeechBubble.show_text("PATROL LOCK", 0.65)
	body.request_death()
	get_tree().create_timer(0.7).timeout.connect(_resume_patrol, CONNECT_ONE_SHOT)


func _resume_patrol() -> void:
	_alerting = false
	sprite.play(&"patrol")
