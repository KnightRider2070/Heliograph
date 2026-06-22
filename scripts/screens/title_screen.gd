class_name HeliographTitleScreen
extends Control


func _ready() -> void:
	$Content/Actions/Start.pressed.connect(_start_game)
	$Content/Actions/Quit.pressed.connect(get_tree().quit)
	$Content/Actions/Start.grab_focus()


func _start_game() -> void:
	AudioDirector.sfx("ui_confirm")
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")
