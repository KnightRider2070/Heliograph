class_name HeliographWinScreen
extends Control


func _ready() -> void:
	AudioDirector.sfx("win_beam")
	$Content/Actions/Replay.pressed.connect(_replay)
	$Content/Actions/Title.pressed.connect(_title)
	$Content/Actions/Quit.pressed.connect(get_tree().quit)
	$Content/Actions/Replay.grab_focus()


func _replay() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")


func _title() -> void:
	get_tree().change_scene_to_file("res://scenes/screens/title_screen.tscn")
