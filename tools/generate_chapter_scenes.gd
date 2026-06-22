extends SceneTree
## One-time generator: bakes the formerly-procedural chapters (2-4) into static,
## hand-editable .tscn scenes that use the base level controller. After running
## this, levels 2-4 can be edited in the Godot 2D editor like level 1.
##
##   Godot --headless --path . --script res://tools/generate_chapter_scenes.gd
##
## It reads the layout data from chapter_level_controller (single source of
## truth) so the geometry matches, then writes real node trees.

# Loaded at runtime (not preloaded) so the GameState/AudioDirector autoloads are
# already registered — a --script main is parsed before autoloads exist.
var ChapterCtrl
var LEVEL_SCRIPT
var CIPHER_SCRIPT
var FONT
var BLOCK
var SUN
var CHECKPOINT
var DEATH
var SENTRY
var PATROL
var CLUE
var TERMINAL
var MECH
var PLAYER
var HUD


func _load_resources() -> void:
	ChapterCtrl = load("res://scripts/levels/chapter_level_controller.gd")
	LEVEL_SCRIPT = load("res://scripts/levels/level_controller.gd")
	CIPHER_SCRIPT = load("res://scripts/puzzles/cipher_controller.gd")
	FONT = load("res://assets/vendor/kenney/fonts/kenney_mini_square.ttf")
	BLOCK = load("res://scenes/world/world_block.tscn")
	SUN = load("res://scenes/world/sunlight_zone.tscn")
	CHECKPOINT = load("res://scenes/world/checkpoint.tscn")
	DEATH = load("res://scenes/world/death_zone.tscn")
	SENTRY = load("res://scenes/world/sentry.tscn")
	PATROL = load("res://scenes/world/patrol_drone.tscn")
	CLUE = load("res://scenes/puzzles/cipher_clue.tscn")
	TERMINAL = load("res://scenes/puzzles/cipher_terminal.tscn")
	MECH = load("res://scenes/puzzles/puzzle_mechanism.tscn")
	PLAYER = load("res://scenes/player/player.tscn")
	HUD = load("res://scenes/ui/hud.tscn")

const CHAPTERS := [
	{
		"chapter": 2, "path": "res://scenes/levels/level_02.tscn", "name": "PrismFoundry",
		"next": "res://scenes/levels/level_03.tscn", "story": "level2",
		"cipher": "res://resources/ciphers/level_02.tres",
		"bg": "res://assets/game/backgrounds/prism_foundry-v1.png", "title": "02 / PRISM FOUNDRY",
	},
	{
		"chapter": 3, "path": "res://scenes/levels/level_03.tscn", "name": "LunarArchive",
		"next": "res://scenes/levels/level_04.tscn", "story": "level3",
		"cipher": "res://resources/ciphers/level_03.tres",
		"bg": "res://assets/game/backgrounds/lunar_archive-v1.png", "title": "03 / LUNAR ARCHIVE",
	},
	{
		"chapter": 4, "path": "res://scenes/levels/level_04.tscn", "name": "CrownOfDawn",
		"next": "res://scenes/screens/win_screen.tscn", "story": "level4",
		"cipher": "res://resources/ciphers/level_04.tres",
		"bg": "res://assets/game/backgrounds/crown_of_dawn-v1.png", "title": "04 / CROWN OF DAWN",
	},
]

var _root: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_load_resources()
	for cfg in CHAPTERS:
		_build_and_save(cfg)
	quit()


func _build_and_save(cfg: Dictionary) -> void:
	var ctrl = ChapterCtrl.new()
	ctrl.chapter = cfg["chapter"]
	var layout: Dictionary = ctrl._layout()
	ctrl.free()

	_root = Node2D.new()
	_root.name = cfg["name"]
	_root.set_script(LEVEL_SCRIPT)
	_root.set("completion_scene", cfg["next"])
	_root.set("story_key", cfg["story"])

	_build_background(cfg["bg"])
	_build_labels(cfg["title"])

	var player := _add(PLAYER.instantiate(), "Player")
	player.position = Vector2(86, 278)

	var cipher := Node.new()
	cipher.set_script(CIPHER_SCRIPT)
	cipher.set("definition", load(cfg["cipher"]))
	_add(cipher, "CipherController")

	_build_world(layout, cfg["chapter"])
	_add(HUD.instantiate(), "HUD")

	var packed := PackedScene.new()
	var err := packed.pack(_root)
	if err == OK:
		err = ResourceSaver.save(packed, cfg["path"])
	print("%s -> %s" % [cfg["name"], "OK" if err == OK else "ERROR %d" % err])
	_root.free()


func _build_world(layout: Dictionary, chapter: int) -> void:
	var world := Node2D.new()
	_add(world, "World")

	var blocks: Array = layout["blocks"]
	for i in blocks.size():
		var spec: Vector4 = blocks[i]
		var block = BLOCK.instantiate()
		block.position = Vector2(spec.x, spec.y)
		block.set("size", Vector2(spec.z, spec.w))
		_add_child(world, block, "Platform%02d" % i)

	var lights: Array = layout["lights"]
	for i in lights.size():
		var spec: Vector4 = lights[i]
		var light = SUN.instantiate()
		light.position = Vector2(spec.x, spec.y)
		light.set("size", Vector2(spec.z, spec.w))
		light.set("starts_active", i == 0)
		_add_child(world, light, "Sunlight%02d" % i)

	var checkpoint := _add_child(world, CHECKPOINT.instantiate(), "Checkpoint")
	checkpoint.position = layout["checkpoint"]

	var mechanism = MECH.instantiate()
	mechanism.position = layout["mechanism"]
	mechanism.set("mechanism", chapter - 2)
	mechanism.set("latching", true)
	var targets: Array[NodePath] = [NodePath("../Sunlight01"), NodePath("../Sunlight02")]
	mechanism.set("target_zones", targets)
	mechanism.set("terminal_path", NodePath("../Terminal"))
	_add_child(world, mechanism, "PuzzleMechanism")

	var patrols: Array = layout["patrols"]
	for i in patrols.size():
		var spec: Vector3 = patrols[i]
		var patrol = PATROL.instantiate()
		patrol.position = Vector2(spec.x, spec.y)
		patrol.set("patrol_distance", spec.z)
		_add_child(world, patrol, "Patrol%02d" % i)

	var sentry := _add_child(world, SENTRY.instantiate(), "Watcher")
	sentry.position = layout["sentry"]

	var clues: Array = layout["clues"]
	for i in clues.size():
		var spec: Dictionary = clues[i]
		var clue = CLUE.instantiate()
		clue.position = spec["position"]
		clue.set("glyph_id", spec["glyph"])
		clue.set("glyph_mark", spec["mark"])
		_add_child(world, clue, "CipherClue%02d" % i)

	var terminal := _add_child(world, TERMINAL.instantiate(), "Terminal")
	terminal.position = layout["terminal"]
	terminal.set("starts_powered", false)

	var death := _add_child(world, DEATH.instantiate(), "DeathZone")
	death.position = Vector2(1150, 460)


func _build_background(bg_path: String) -> void:
	var background := Node2D.new()
	background.z_index = -10
	_add(background, "Background")

	var ink := Polygon2D.new()
	ink.polygon = PackedVector2Array([Vector2(0, 0), Vector2(2300, 0), Vector2(2300, 360), Vector2(0, 360)])
	ink.color = Color("08101f")
	_add_child(background, ink, "Ink")

	var backdrop := TextureRect.new()
	backdrop.offset_right = 2300.0
	backdrop.offset_bottom = 360.0
	backdrop.texture = load(bg_path)
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.modulate = Color(0.56, 0.58, 0.72, 0.62)
	_add_child(background, backdrop, "ChapterBackdrop")


func _build_labels(title_text: String) -> void:
	var title := Label.new()
	title.position = Vector2(26, 88)
	title.size = Vector2(340, 30)
	title.text = title_text
	title.z_index = 5
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("7be0d6c7"))
	_add(title, "RoomTitle")


func _add(node: Node, node_name: String) -> Node:
	node.name = node_name
	_root.add_child(node)
	_set_owner(node)
	return node


func _add_child(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node)
	node.owner = _root
	return node


# Set owner on the node and on the manual (non-instanced) children we created,
# without recursing into instanced sub-scenes.
func _set_owner(node: Node) -> void:
	node.owner = _root
	if node.scene_file_path != "":
		return  # instanced sub-scene; leave its internals alone
	for child in node.get_children():
		_set_owner(child)
