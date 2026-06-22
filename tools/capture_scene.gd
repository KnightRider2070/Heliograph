extends SceneTree


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: -- <scene_path> <output.png> [player_x]")
		quit(1)
		return

	var packed := load(args[0]) as PackedScene
	if packed == null:
		push_error("Could not load scene: %s" % args[0])
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	current_scene = scene

	if args.size() >= 3 and scene.has_node("Player"):
		var player := scene.get_node("Player") as Node2D
		player.global_position.x = args[2].to_float()

	await process_frame
	await process_frame
	if args.size() >= 4 and args[3] == "terminal" and scene.has_node("World/Terminal"):
		scene.get_node("World/Terminal").call("_open")
	elif args.size() >= 4 and args[3] == "mappings" and scene.has_node("CipherController"):
		var cipher_controller := scene.get_node("CipherController")
		cipher_controller.discover_mapping(&"solar_disc")
		cipher_controller.discover_mapping(&"open_cup")
		cipher_controller.discover_mapping(&"north_needle")
	elif args.size() >= 4 and args[3] == "warning" and scene.has_node("World/Watcher"):
		var warning_player := scene.get_node("Player")
		warning_player.enter_sunlight()
		scene.get_node("World/Watcher").call("_on_body_entered", warning_player)
	await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("The active rendering backend does not provide viewport images")
		quit(1)
		return
	var error := image.save_png(args[1])
	if error != OK:
		push_error("Could not save screenshot: %s" % error_string(error))
		quit(1)
		return

	print("Saved %s" % args[1])
	quit()
