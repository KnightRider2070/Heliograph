class_name HeliographChapterLevelController
extends HeliographLevelController

const WORLD_BLOCK := preload("res://scenes/world/world_block.tscn")
const SUNLIGHT := preload("res://scenes/world/sunlight_zone.tscn")
const CHECKPOINT := preload("res://scenes/world/checkpoint.tscn")
const DEATH_ZONE := preload("res://scenes/world/death_zone.tscn")
const SENTRY := preload("res://scenes/world/sentry.tscn")
const PATROL_DRONE := preload("res://scenes/world/patrol_drone.tscn")
const CIPHER_CLUE := preload("res://scenes/puzzles/cipher_clue.tscn")
const CIPHER_TERMINAL := preload("res://scenes/puzzles/cipher_terminal.tscn")
const PUZZLE_MECHANISM := preload("res://scenes/puzzles/puzzle_mechanism.tscn")
const LEVEL_FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square.ttf")

@export_range(2, 4, 1) var chapter: int = 2
@export var background_texture: Texture2D
@export var room_title: String = "02 / PRISM FOUNDRY"


func _ready() -> void:
	_build_background()
	_build_world(_layout())
	_build_room_labels()
	super._ready()


func get_story_key() -> String:
	return "level%d" % chapter


func _build_background() -> void:
	var background := Node2D.new()
	background.name = "Background"
	background.z_index = -10
	add_child(background)
	move_child(background, 0)

	var ink := Polygon2D.new()
	ink.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(2300, 0), Vector2(2300, 360), Vector2(0, 360),
	])
	ink.color = Color("08101f")
	background.add_child(ink)

	var backdrop := TextureRect.new()
	backdrop.name = "ChapterBackdrop"
	backdrop.offset_right = 2300.0
	backdrop.offset_bottom = 360.0
	backdrop.texture = background_texture
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.modulate = Color(0.56, 0.58, 0.72, 0.62)
	background.add_child(backdrop)


func _build_room_labels() -> void:
	var title := Label.new()
	title.name = "RoomTitle"
	title.position = Vector2(26, 88)
	title.size = Vector2(340, 30)
	title.text = room_title
	title.add_theme_font_override("font", LEVEL_FONT)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color("7be0d6c7"))
	add_child(title)

	var prompt := Label.new()
	prompt.name = "JumpPrompt"
	prompt.position = Vector2(74, 230)
	prompt.size = Vector2(310, 24)
	prompt.text = "SPACE / JUMP THE SIGNAL GAPS"
	prompt.add_theme_font_override("font", LEVEL_FONT)
	prompt.add_theme_font_size_override("font_size", 9)
	prompt.add_theme_color_override("font_color", Color("f2e9d8d8"))
	add_child(prompt)


func _build_world(layout: Dictionary) -> void:
	var world := Node2D.new()
	world.name = "World"
	add_child(world)

	var blocks: Array = layout["blocks"]
	for index in blocks.size():
		var spec: Vector4 = blocks[index]
		var block := WORLD_BLOCK.instantiate() as Node2D
		block.name = "Platform%02d" % index
		block.position = Vector2(spec.x, spec.y)
		block.set("size", Vector2(spec.z, spec.w))
		world.add_child(block)

	var lights: Array = layout["lights"]
	for index in lights.size():
		var spec: Vector4 = lights[index]
		var light := SUNLIGHT.instantiate() as Node2D
		light.name = "Sunlight%02d" % index
		light.position = Vector2(spec.x, spec.y)
		light.set("size", Vector2(spec.z, spec.w))
		# Only the first beam is lit at the start; the relay must carry the light
		# to the others before their clues can be read.
		light.set("starts_active", index == 0)
		world.add_child(light)

	var checkpoint := _spawn(world, CHECKPOINT, "Checkpoint", layout["checkpoint"])
	checkpoint.position = layout["checkpoint"]

	var mechanism := PUZZLE_MECHANISM.instantiate() as Node2D
	mechanism.name = "PuzzleMechanism"
	mechanism.position = layout["mechanism"]
	mechanism.set("mechanism", chapter - 2)
	mechanism.set("latching", true)
	# The relay lights the two downstream beams (where clues 2 and 3 live).
	var relay_targets: Array[NodePath] = [NodePath("../Sunlight01"), NodePath("../Sunlight02")]
	mechanism.set("target_zones", relay_targets)
	world.add_child(mechanism)

	var patrols: Array = layout["patrols"]
	for index in patrols.size():
		var spec: Vector3 = patrols[index]
		var patrol := PATROL_DRONE.instantiate() as Node2D
		patrol.name = "Patrol%02d" % index
		patrol.position = Vector2(spec.x, spec.y)
		patrol.set("patrol_distance", spec.z)
		world.add_child(patrol)

	var sentry_position: Vector2 = layout["sentry"]
	_spawn(world, SENTRY, "Watcher", sentry_position)

	var clues: Array = layout["clues"]
	for index in clues.size():
		var spec: Dictionary = clues[index]
		var clue := CIPHER_CLUE.instantiate() as Node2D
		clue.name = "CipherClue%02d" % index
		clue.position = spec["position"]
		clue.set("glyph_id", spec["glyph"])
		clue.set("glyph_mark", spec["mark"])
		world.add_child(clue)

	var terminal := _spawn(world, CIPHER_TERMINAL, "Terminal", layout["terminal"])
	_spawn(world, DEATH_ZONE, "DeathZone", Vector2(1150, 460))

	# The relay mechanism powers the exit terminal: activating it is required and
	# visibly does something, instead of being a toggle with no consequence.
	terminal.call("set_powered", false)
	mechanism.connect("activated", _on_relay_activated.bind(terminal, mechanism))


func _on_relay_activated(_mechanism_kind: int, active: bool, terminal: Node2D, _mechanism: Node2D) -> void:
	# The relay's own routed light beams + the terminal lighting up are the
	# feedback; no extra straight line is drawn (it only added visual clutter).
	terminal.call("set_powered", active)


func _spawn(parent: Node, scene: PackedScene, node_name: String, at: Vector2) -> Node2D:
	var node := scene.instantiate() as Node2D
	node.name = node_name
	node.position = at
	parent.add_child(node)
	return node


func _layout() -> Dictionary:
	match chapter:
		3:
			return _lunar_layout()
		4:
			return _dawn_layout()
		_:
			return _prism_layout()


# Geometry notes for all three chapters:
# - The floor is continuous (abutting blocks at y=342) so a missed jump drops the
#   player back onto ground, never into the level-wide death zone. This removes
#   blind-playtest softlock risk while the verticality above provides the
#   challenge.
# - Clues and the relay sit on LOW platforms (top ~276-282, a single hop from the
#   floor) so progression is always reachable; the taller stacks are optional
#   flourishes that give each chapter a distinct silhouette.
# - The first beam (Sunlight00) is lit; the relay carries light to the other two.

func _prism_layout() -> Dictionary:
	# Prism Foundry: stacked "prism towers" reaching upward.
	return {
		"blocks": [
			Vector4(600, 342, 1320, 72), Vector4(1860, 342, 1240, 72),
			Vector4(470, 286, 210, 20),
			Vector4(800, 200, 90, 16), Vector4(800, 166, 90, 16), Vector4(800, 132, 90, 16),
			Vector4(1280, 286, 180, 20),
			Vector4(1520, 200, 90, 16), Vector4(1520, 166, 90, 16), Vector4(1520, 132, 90, 16),
			Vector4(1800, 286, 180, 20),
			Vector4(2060, 252, 110, 18), Vector4(2220, 212, 110, 18),
		],
		"lights": [Vector4(470, 150, 210, 300), Vector4(1280, 150, 210, 300), Vector4(1800, 150, 210, 300)],
		"checkpoint": Vector2(720, 270), "mechanism": Vector2(1050, 306),
		"patrols": [Vector3(900, 306, 150), Vector3(1700, 306, 150)],
		"sentry": Vector2(1450, 250),
		"clues": [
			{"position": Vector2(470, 262), "glyph": &"eastern_arch", "mark": "A"},
			{"position": Vector2(1280, 262), "glyph": &"relay_fork", "mark": "R"},
			{"position": Vector2(1800, 262), "glyph": &"open_cup", "mark": "C"},
		],
		"terminal": Vector2(2330, 270),
	}


func _lunar_layout() -> Dictionary:
	# Lunar Archive: staggered "shelves" at alternating heights.
	return {
		"blocks": [
			Vector4(700, 342, 1480, 72), Vector4(1950, 342, 1100, 72),
			Vector4(480, 286, 200, 20),
			Vector4(760, 250, 120, 18), Vector4(980, 218, 120, 18), Vector4(1190, 250, 120, 18),
			Vector4(1300, 286, 190, 20),
			Vector4(1520, 248, 120, 18), Vector4(1720, 214, 120, 18),
			Vector4(1850, 286, 190, 20),
			Vector4(2090, 250, 110, 18), Vector4(2260, 214, 110, 18),
		],
		"lights": [Vector4(480, 150, 200, 300), Vector4(1300, 150, 210, 300), Vector4(1850, 150, 200, 300)],
		"checkpoint": Vector2(700, 270), "mechanism": Vector2(1100, 306),
		"patrols": [Vector3(900, 306, 160), Vector3(1750, 306, 150)],
		"sentry": Vector2(1560, 240),
		"clues": [
			{"position": Vector2(480, 262), "glyph": &"low_horizon", "mark": "L"},
			{"position": Vector2(1300, 262), "glyph": &"open_cup", "mark": "U"},
			{"position": Vector2(1850, 262), "glyph": &"split_ring", "mark": "X"},
		],
		"terminal": Vector2(2330, 270),
	}


func _dawn_layout() -> Dictionary:
	# Crown of Dawn: a rising staircase climbing toward the final array.
	return {
		"blocks": [
			Vector4(650, 342, 1360, 72), Vector4(1850, 342, 1240, 72),
			Vector4(470, 286, 200, 20),
			Vector4(1280, 286, 190, 20),
			Vector4(1500, 278, 110, 18), Vector4(1660, 238, 110, 18), Vector4(1820, 198, 110, 18),
			Vector4(1850, 300, 190, 20),
			Vector4(2050, 252, 120, 18), Vector4(2200, 212, 120, 18), Vector4(2350, 252, 120, 18),
		],
		"lights": [Vector4(470, 150, 200, 300), Vector4(1280, 150, 210, 300), Vector4(1850, 150, 220, 300)],
		"checkpoint": Vector2(700, 270), "mechanism": Vector2(1000, 306),
		"patrols": [Vector3(1100, 306, 150), Vector3(2050, 306, 140)],
		"sentry": Vector2(1560, 250),
		"clues": [
			{"position": Vector2(470, 262), "glyph": &"relay_fork", "mark": "R"},
			{"position": Vector2(1280, 262), "glyph": &"eastern_arch", "mark": "A"},
			{"position": Vector2(1850, 268), "glyph": &"north_needle", "mark": "Y"},
		],
		"terminal": Vector2(2350, 270),
	}
