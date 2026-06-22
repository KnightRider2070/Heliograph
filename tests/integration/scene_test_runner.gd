extends SceneTree

const PlayerCore = preload("res://scripts/core/gameplay/player_core.gd")

var _assertions: int = 0
var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var level_scene := load("res://scenes/levels/level_01.tscn") as PackedScene
	_expect(level_scene != null, "level scene loads")
	if level_scene == null:
		_finish()
		return

	var level := level_scene.instantiate()
	root.add_child(level)
	current_scene = level
	await process_frame
	await physics_frame
	await physics_frame

	# The first level opens with ACE's narration, which pauses the tree. Dismiss
	# it the way a player would (clicking through) so the rest of the loop drives
	# an un-paused, playable level.
	_expect(level._comm != null and level._comm.is_active(), "level one opens with ACE narration")
	level._comm.skip_all()
	await process_frame
	_expect(not paused, "dismissing narration resumes play")

	var player := level.get_node_or_null("Player")
	var cipher_controller := level.get_node_or_null("CipherController")
	var platform := level.get_node_or_null("World/DashBridge")
	var checkpoint := level.get_node_or_null("World/Checkpoint")
	var clue := level.get_node_or_null("World/SolarDisc")
	var terminal := level.get_node_or_null("World/Terminal")
	var sentry := level.get_node_or_null("World/Watcher")
	var sunlight := level.get_node_or_null("World/EntryLight")

	_expect(player != null and player.core != null, "player adapter constructs PlayerCore")
	_expect(cipher_controller != null and cipher_controller.model != null, "cipher controller constructs its model")
	_expect(terminal != null and terminal._controller == cipher_controller, "terminal is bound by the level controller")
	_expect(clue != null and clue._controller == cipher_controller, "clue is bound by the level controller")
	_expect(sentry != null and sentry.model != null, "watcher script loads and constructs its state model")
	_expect(sunlight.has_node("CollisionPolygon2D"), "sunlight uses a triangular collision polygon")
	_expect(sunlight.get_node("CollisionPolygon2D").polygon.size() == 3, "sunlight collision matches its triangular beam")
	_expect(player.has_node("SpeechBubble"), "player exposes a reusable speech bubble")
	_expect(sentry.has_node("SpeechBubble"), "enemy exposes a reusable speech bubble")
	_expect(checkpoint.has_node("SpeechBubble"), "environment prop exposes a reusable speech bubble")
	_expect(player.get_node("Visual/Sprite").sprite_frames.get_frame_count(&"run") == 6, "courier uses the generated six-frame walk cycle")
	_expect(player.get_lives_remaining() == 3, "player starts with three finite lives")

	var floor_a_shape: Shape2D = level.get_node("World/FloorA/CollisionShape2D").shape
	var floor_b_shape: Shape2D = level.get_node("World/FloorB/CollisionShape2D").shape
	_expect(floor_a_shape != floor_b_shape, "world block instances own local collision shapes")

	_expect(platform.get_node("CollisionShape2D").disabled, "light platform starts without collision")
	player.enter_sunlight()
	await physics_frame
	_expect(not platform.get_node("CollisionShape2D").disabled, "sunlight enables platform collision")
	player.exit_sunlight()
	await physics_frame
	_expect(platform.get_node("CollisionShape2D").disabled, "shadow disables platform collision")

	checkpoint._on_body_entered(player)
	_expect(player.core.spawn_position == checkpoint.global_position, "checkpoint updates the core spawn position")

	clue._on_body_entered(player)
	player.enter_sunlight()
	_expect(not cipher_controller.model.is_discovered(&"solar_disc"), "walking onto a lit clue does NOT auto-reveal it")
	clue._read()
	_expect(cipher_controller.model.is_discovered(&"solar_disc"), "deliberately reading a lit clue records its mapping")
	player.exit_sunlight()
	clue._on_body_exited(player)

	# Light relay chain: a relay only fires while the player stands in light, and
	# lighting it activates the downstream sun zone (which gates the next clues).
	var watcher_light := level.get_node("World/WatcherLight")
	var relay_a := level.get_node("World/RelayA")
	_expect(not watcher_light.active, "downstream sun zone starts dark until relayed")
	relay_a._player = player
	relay_a._try_toggle()
	_expect(not watcher_light.active, "relay refuses to fire with no light to relay")
	player.enter_sunlight()
	relay_a._try_toggle()
	_expect(watcher_light.active, "relay lights its target sun zone when fired in light")
	player.exit_sunlight()

	terminal._open()
	_expect(paused, "terminal pauses the scene tree")
	_expect(player.core.state == PlayerCore.State.INTERACTING, "terminal locks player simulation")
	terminal._close()
	_expect(not paused, "terminal restores the prior pause state")
	_expect(player.core.state == PlayerCore.State.ACTIVE, "terminal restores player simulation")

	var title := (load("res://scenes/screens/title_screen.tscn") as PackedScene).instantiate()
	var win := (load("res://scenes/screens/win_screen.tscn") as PackedScene).instantiate()
	_expect(title.has_node("Content/Actions/Start"), "title screen exposes its start action")
	_expect(win.has_node("Content/Actions/Replay"), "win screen exposes its replay action")
	title.free()
	win.free()

	# Talking to the dormant Watcher hands over its glyph (the build-up: some
	# letters are learned from Watchers, not clue plates) and it lands live in the
	# cipher key via the codex.
	var watcher := level.get_node("World/Watcher")
	_expect(watcher.reveals_glyph == &"open_cup", "the dormant watcher carries a glyph to teach")
	watcher._reveal_glyph()
	_expect(cipher_controller.model.is_discovered(&"open_cup"), "the watcher's gift appears in the cipher key")

	cipher_controller.discover_mapping(&"open_cup")
	cipher_controller.discover_mapping(&"north_needle")
	_expect(cipher_controller.model.get_discovered_count() == 3, "all level mappings can be collected")
	_expect(cipher_controller.submit_answer("SUN"), "level accepts the documented solution")
	# Solving now plays a story reveal before advancing; let it start, then skip it.
	await process_frame
	_expect(level._comm.is_active(), "solving plays ACE's decoded-fragment reveal")
	level._comm.skip_all()
	# Reference the autoload via the tree: in a --script run the main loop is
	# parsed before autoload names register as globals.
	var game_state := root.get_node_or_null("GameState")
	_expect(game_state != null and game_state.watchers_hostile, "finishing the first fragment turns the Watchers hostile")
	await create_timer(0.2).timeout
	await process_frame
	_expect(current_scene != null and current_scene.name == "PrismFoundry", "solving level one advances to the Prism Foundry")

	_finish()


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("PASS scene integration (%d assertions)" % _assertions)
	else:
		print("FAIL scene integration")
		for failure in _failures:
			print("  - %s" % failure)
	print("\n%d assertions, %d failures" % [_assertions, _failures.size()])
	quit(0 if _failures.is_empty() else 1)
