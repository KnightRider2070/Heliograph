extends SceneTree
## Integration coverage for Level 5 "Solar Yard" — the showcase that ties the
## remix together: a persistent codex that remembers glyphs across levels, a
## missing-mapping puzzle (the O clue is omitted and must be deduced), a decoy,
## and a sun-gated platform that the relay raises.

var _assertions: int = 0
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/levels/level_05.tscn") as PackedScene
	_expect(packed != null, "level five scene loads")
	if packed == null:
		_finish()
		return

	# Prime the codex BEFORE the level loads, simulating glyphs learned in levels
	# 1-4. These must arrive before the cipher controller's _ready primes from them.
	var codex := root.get_node_or_null("GlyphCodex")
	_expect(codex != null, "glyph codex autoload is available")
	codex.reset()
	codex.learn(&"solar_disc", "S", "level1")
	codex.learn(&"low_horizon", "L", "level3")
	codex.learn(&"eastern_arch", "A", "level2")
	codex.learn(&"relay_fork", "R", "level4")
	# Note: glass_lens (O) is deliberately NOT taught — it is the omitted mapping.

	var level := packed.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	await physics_frame
	await physics_frame

	# Solar Yard opens with ACE/Oracle narration; dismiss it like a player would.
	_expect(level._comm != null and level._comm.is_active(), "Solar Yard opens with narration")
	level._comm.skip_all()
	await process_frame
	_expect(not paused, "dismissing narration resumes play")

	var world := level.get_node("World")
	var cipher := level.get_node("CipherController")
	var player := level.get_node("Player")

	_expect(cipher.definition.answer == "SOLAR", "the yard's answer is SOLAR")

	# The new platform mechanics are all present and of the right type.
	_expect(world.get_node("MovingFerry") is HeliographMovingPlatform, "moving ferry is a moving platform")
	_expect(world.get_node("YardProjector") is HeliographPulseProjector, "yard projector is a pulse projector")
	_expect(world.get_node("ProjectorBridge") is HeliographSunbeamPlatform, "projector bridge is a sunbeam platform")
	_expect(world.get_node("SunGate") is HeliographSunbeamPlatform, "sun gate is a sunbeam platform")

	# Missing mapping: there is NO clue for the O glyph (glass_lens) anywhere.
	var has_o_clue := false
	for clue in get_nodes_in_group("cipher_clue"):
		if clue.glyph_id == &"glass_lens":
			has_o_clue = true
	_expect(not has_o_clue, "the O clue is omitted — it must be deduced")
	_expect(cipher.definition.is_decoy(&"prism"), "the prism (C) is a decoy")

	# Old knowledge carries forward: the four glyphs primed into the codex start
	# this puzzle already known, while the omitted O does not.
	_expect(cipher.was_remembered(&"eastern_arch"), "an earlier-learned glyph is remembered here")
	_expect(cipher.model.is_discovered(&"relay_fork"), "remembered glyphs are pre-filled in the terminal key")
	_expect(not cipher.model.is_discovered(&"glass_lens"), "the omitted glyph is not known up front")

	# The sun gate is solid only once the relay lights its source zone.
	var sun_gate := world.get_node("SunGate")
	var gate_collision := sun_gate.get_node("CollisionShape2D")
	_expect(gate_collision.disabled, "sun-gated platform starts intangible")
	var relay := world.get_node("PuzzleMechanism")
	player.enter_sunlight()
	relay._player = player
	relay._try_toggle()
	await process_frame
	await physics_frame
	_expect(not gate_collision.disabled, "relay raises the sun-gated platform")
	_expect(world.get_node("Terminal")._powered, "relay powers the exit terminal")
	player.exit_sunlight()

	# Deduce and submit SOLAR. Solving commits the omitted O to the codex so it is
	# remembered from here on.
	_expect(cipher.submit_answer("solar"), "the yard accepts the deduced word SOLAR")
	_expect(codex.knows(&"glass_lens"), "solving commits the deduced O to the codex")
	_expect(codex.letter_for(&"glass_lens") == "O", "the deduced glyph is remembered as O")

	_finish()


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS level five integration (%d assertions)" % _assertions)
	else:
		print("FAIL level five integration")
		for failure in _failures:
			print("  - %s" % failure)
	print("\n%d assertions, %d failures" % [_assertions, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
