extends SceneTree

# Clue counts reflect the build-up model: letters are acquired from mixed sources
# (a clue, a dormant Watcher in L1, recall from the codex, or a guess), so later
# levels hand out very few clue plates. L2 = A clue (R, C guessed); L3 = L clue +
# decoy (U recalled, X guessed); L4 = no clues at all (R, A recalled, Y guessed).
# Each chapter also gained one new platform mechanic.
const CHAPTERS := [
	{"path": "res://scenes/levels/level_02.tscn", "name": "PrismFoundry", "answer": "ARC", "mechanism": 0, "clues": 1},
	{"path": "res://scenes/levels/level_03.tscn", "name": "LunarArchive", "answer": "LUX", "mechanism": 1, "clues": 2},
	{"path": "res://scenes/levels/level_04.tscn", "name": "CrownOfDawn", "answer": "RAY", "mechanism": 2, "clues": 0},
]

var _assertions: int = 0
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for info in CHAPTERS:
		await _verify_chapter(info)
	_finish()


func _verify_chapter(info: Dictionary) -> void:
	var packed := load(info["path"]) as PackedScene
	_expect(packed != null, "%s scene loads" % info["name"])
	if packed == null:
		return

	var level := packed.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	await physics_frame
	await physics_frame

	_expect(level.name == info["name"], "%s has the expected scene identity" % info["name"])
	_expect(level.get_node("Background/ChapterBackdrop").texture != null, "%s uses its generated background" % info["name"])
	_expect(level.get_node("CipherController").definition.answer == info["answer"], "%s has its chapter cipher" % info["name"])

	var world := level.get_node("World")
	var elevated_platforms: int = 0
	var lights: Array[Node] = []
	var patrols: Array[Node] = []
	var clues: Array[Node] = []
	var new_toys: int = 0
	for child in world.get_children():
		if child.name.begins_with("Platform") and child.position.y < 320.0:
			elevated_platforms += 1
		if child is HeliographSunlightZone:
			lights.append(child)
		if child.is_in_group("moving_enemy"):
			patrols.append(child)
		if child.is_in_group("cipher_clue"):
			clues.append(child)
		if (child is HeliographMovingPlatform
				or child is HeliographSunbeamPlatform
				or child is HeliographPulseProjector):
			new_toys += 1

	_expect(elevated_platforms >= 5, "%s includes a substantial jump route" % info["name"])
	_expect(lights.size() == 3, "%s includes three sunlight puzzle areas" % info["name"])
	_expect(patrols.size() >= 2, "%s includes moving patrol hazards" % info["name"])
	_expect(clues.size() == info["clues"], "%s includes its cipher clues" % info["name"])
	_expect(new_toys >= 1, "%s adds a new platform mechanic" % info["name"])

	for light in lights:
		var beam: Polygon2D = light.get_node("Beam")
		var left_edge: Line2D = light.get_node("LeftEdge")
		var right_edge: Line2D = light.get_node("RightEdge")
		var motes: CPUParticles2D = light.get_node("Motes")
		_expect(left_edge.points[0].is_equal_approx(beam.polygon[0]), "sunlight left edge begins at its beam apex")
		_expect(left_edge.points[1].is_equal_approx(beam.polygon[2]), "sunlight left edge follows its polygon")
		_expect(right_edge.points[0].is_equal_approx(beam.polygon[0]), "sunlight right edge begins at its beam apex")
		_expect(right_edge.points[1].is_equal_approx(beam.polygon[1]), "sunlight right edge follows its polygon")
		_expect(motes.position.is_equal_approx(beam.polygon[0]), "sunlight particles originate at the beam apex")
		_expect(motes.emission_shape == CPUParticles2D.EMISSION_SHAPE_POINT, "sunlight particles retain point emission")

	for clue in clues:
		_expect(clue.get_node("GlyphAnchor/GlyphIcon").position == Vector2.ZERO, "cipher icon is centered on its optical anchor")

	var mechanism := world.get_node("PuzzleMechanism")
	_expect(mechanism.mechanism == info["mechanism"], "%s uses its generated puzzle mechanism" % info["name"])
	_expect(mechanism.get_node("Visual").texture != null, "puzzle mechanism has a generated sprite")

	# Activating the relay must have visible consequences: the two downstream sun
	# beams (which gate clues 2 and 3) light up, and the exit terminal powers on.
	var terminal := world.get_node("Terminal")
	var beam_b := world.get_node("Sunlight01")
	var beam_c := world.get_node("Sunlight02")
	_expect(not terminal._powered, "%s terminal starts unpowered" % info["name"])
	_expect(not beam_b.active and not beam_c.active, "%s downstream beams start dark" % info["name"])
	mechanism._player = level.get_node_or_null("Player")
	mechanism._try_toggle()
	await process_frame
	_expect(terminal._powered, "%s relay powers the terminal" % info["name"])
	_expect(beam_b.active and beam_c.active, "%s relay lights the downstream beams" % info["name"])
	_expect(not world.get_node("Checkpoint").has_node("Glow"), "checkpoint has no persistent backdrop geometry")
	_expect(not world.get_node("Watcher").has_node("StateHalo"), "watcher has no persistent backdrop geometry")

	var first_patrol := patrols[0] as Node2D
	var starting_x := first_patrol.global_position.x
	await physics_frame
	await physics_frame
	_expect(not is_equal_approx(first_patrol.global_position.x, starting_x), "moving patrol advances along its route")

	var camera: Camera2D = level.get_node("Player/Camera2D")
	var terminal_x: float = world.get_node("Terminal").position.x
	_expect(camera.limit_right >= int(terminal_x), "%s camera scrolls to the exit terminal" % info["name"])

	var top_bar: Control = level.get_node("HUD/Root/TopBar")
	var heart: Control = level.get_node("HUD/Root/TopBar/LivesModule/Heart")
	var lives_value: Control = level.get_node("HUD/Root/TopBar/LivesModule/LivesValue")
	_expect(top_bar.size.x <= 330.0 and top_bar.size.y <= 54.0, "top HUD stays compact")
	_expect(heart.position.x + heart.size.x <= lives_value.position.x, "heart and life count do not overlap")

	level.queue_free()
	current_scene = null
	await process_frame


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS chapter integration (%d assertions)" % _assertions)
	else:
		print("FAIL chapter integration")
		for failure in _failures:
			print("  - %s" % failure)
	print("\n%d assertions, %d failures" % [_assertions, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
