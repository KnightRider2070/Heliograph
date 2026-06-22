class_name HeliographLevelController
extends Node2D

const CommPanel = preload("res://scripts/ui/comm_panel.gd")
const Story = preload("res://scripts/core/story_script.gd")

@export_file("*.tscn") var completion_scene: String = "res://scenes/screens/win_screen.tscn"
## Which story beat this level plays (level1..level4). Editable per scene so a
## hand-authored level can pick its narration without a custom controller.
@export var story_key: String = "level1"

@onready var player: HeliographPlayerBodyAdapter = $Player
@onready var cipher_controller: HeliographCipherController = $CipherController
@onready var hud: HeliographHUD = $HUD

var _completing: bool = false
var _comm  # HeliographCommPanel; untyped so headless runs don't need the class cache refreshed first


func _ready() -> void:
	# Stamp newly learned glyphs with this level so the codex can show where each
	# was first decoded.
	GlyphCodex.set_current_level(story_key)
	player.set_spawn_point(player.global_position)
	hud.bind(player, cipher_controller)
	cipher_controller.puzzle_solved.connect(_on_puzzle_solved)

	# Sunlight/shadow ambience follows the player's exposure; the hostile bed is
	# synced to the current threat state (so replays and later chapters match).
	player.exposure_changed.connect(AudioDirector.set_exposed)
	AudioDirector.set_exposed(player.is_in_sunlight())
	AudioDirector.set_hostile(GameState.watchers_hostile)

	for node in find_children("*", "", true, false):
		if node.is_in_group("light_reactive") and node.has_method("bind_player"):
			node.bind_player(player)
		elif node.is_in_group("cipher_clue"):
			node.bind(cipher_controller, player)
		elif node.is_in_group("cipher_terminal"):
			node.bind(cipher_controller, player)
		elif node.is_in_group("puzzle_mechanism") and node.has_method("bind_relay_player"):
			node.bind_relay_player(player)

	_apply_camera_bounds()

	_comm = CommPanel.new()
	add_child(_comm)
	_play_intro()


## Fit the player camera's right limit to the actual level width, so it scrolls
## all the way to the exit instead of stopping at a fixed default. Auto-adapts to
## hand-edited levels — extend the floor and the camera follows.
func _apply_camera_bounds() -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	var world := get_node_or_null("World")
	if camera == null or world == null:
		return
	var right := 640.0
	for child in world.get_children():
		if child.name == "DeathZone":
			continue
		var size_value: Variant = child.get("size")
		if size_value is Vector2:
			right = maxf(right, child.position.x + (size_value as Vector2).x * 0.5)
	camera.limit_right = int(ceil(right))


## Story key for this level (set via the exported field, editable per scene).
func get_story_key() -> String:
	return story_key


func _play_intro() -> void:
	var key := get_story_key()
	if key == "level1" and GameState.intro_seen:
		return
	var lines := Story.intro_for(key)
	if lines.is_empty():
		return
	if key == "level1":
		GameState.mark_intro_seen()
		_intro_fade()
	_comm.play(lines)


## "Waking up": the world fades in from black behind the dialogue panel, so ACE's
## first words land over darkness before the station resolves into view.
func _intro_fade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 40  # below the comm panel (50) so the dialogue stays readable
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0.01, 0.02, 0.05, 1.0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var tween := layer.create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(black, "color:a", 0.0, 1.8)
	tween.tween_callback(layer.queue_free)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not get_tree().paused:
		get_tree().change_scene_to_file("res://scenes/screens/title_screen.tscn")


func _on_puzzle_solved() -> void:
	if _completing:
		return
	_completing = true
	hud.show_message("FRAGMENT DECODED")
	# Deferred so the terminal finishes closing (and un-pausing) before the comm
	# panel re-pauses for the reveal; otherwise the two pause toggles collide.
	_begin_reveal.call_deferred()


func _begin_reveal() -> void:
	var lines := Story.reveal_for(get_story_key())
	if lines.is_empty():
		_after_reveal()
		return
	_comm.finished.connect(_after_reveal, CONNECT_ONE_SHOT)
	_comm.play(lines)


func _after_reveal() -> void:
	# Finishing the first fragment is the action that turns the Watchers hostile
	# for the rest of the run.
	if get_story_key() == "level1":
		GameState.turn_watchers_hostile()
	_complete_level()


func _complete_level() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(completion_scene)
