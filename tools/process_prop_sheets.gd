extends SceneTree


func _init() -> void:
	var watcher_error := _process_sheet(
		"res://assets/game/enemies/watcher/source/watcher_sheet_alpha-v1.png",
		"res://assets/game/enemies/watcher/frames",
		["sweeping", "warning", "firing"],
		Vector2i(96, 96),
		Vector2i(92, 92),
		94
	)
	if watcher_error != OK:
		quit(1)
		return

	var aperture_error := _process_sheet(
		"res://assets/game/environment/apertures/source/aperture_sheet_alpha-v1.png",
		"res://assets/game/environment/apertures/frames",
		["narrow", "medium", "wide"],
		Vector2i(192, 96),
		Vector2i(188, 90),
		92,
		[0, 480, 1100, 1928]
	)
	if aperture_error != OK:
		quit(1)
		return

	print("Generated Watcher and sunlight-aperture runtime frames.")
	quit()


func _process_sheet(
	source_path: String,
	output_directory: String,
	frame_names: Array,
	output_size: Vector2i,
	content_limit: Vector2i,
	baseline_y: int,
	column_boundaries: Array = []
) -> Error:
	var source := Image.load_from_file(source_path)
	if source == null or source.is_empty():
		push_error("Could not load source sheet: %s" % source_path)
		return ERR_CANT_OPEN

	for index in frame_names.size():
		var start_x := (
			int(column_boundaries[index])
			if not column_boundaries.is_empty()
			else roundi(float(index) * source.get_width() / frame_names.size())
		)
		var end_x := (
			int(column_boundaries[index + 1])
			if not column_boundaries.is_empty()
			else roundi(float(index + 1) * source.get_width() / frame_names.size())
		)
		var cell := source.get_region(Rect2i(start_x, 0, end_x - start_x, source.get_height()))
		var bounds := _alpha_bounds(cell)
		if bounds.size == Vector2i.ZERO:
			push_error("Frame %s has no visible pixels" % frame_names[index])
			return ERR_FILE_CORRUPT

		var trimmed := cell.get_region(bounds)
		var scale_factor := minf(
			float(content_limit.x) / float(trimmed.get_width()),
			float(content_limit.y) / float(trimmed.get_height())
		)
		var resized_size := Vector2i(
			maxi(1, roundi(trimmed.get_width() * scale_factor)),
			maxi(1, roundi(trimmed.get_height() * scale_factor))
		)
		trimmed.resize(resized_size.x, resized_size.y, Image.INTERPOLATE_NEAREST)

		var output := Image.create_empty(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		var destination := Vector2i(
			(output_size.x - resized_size.x) / 2,
			baseline_y - resized_size.y
		)
		output.blit_rect(trimmed, Rect2i(Vector2i.ZERO, resized_size), destination)

		var output_path := "%s/%s.png" % [output_directory, frame_names[index]]
		var error := output.save_png(output_path)
		if error != OK:
			push_error("Failed to save %s: %s" % [output_path, error_string(error)])
			return error

	return OK


func _alpha_bounds(image: Image) -> Rect2i:
	var minimum := Vector2i(image.get_width(), image.get_height())
	var maximum := Vector2i(-1, -1)
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a <= 0.05:
				continue
			minimum.x = mini(minimum.x, x)
			minimum.y = mini(minimum.y, y)
			maximum.x = maxi(maximum.x, x)
			maximum.y = maxi(maximum.y, y)
	if maximum.x < minimum.x or maximum.y < minimum.y:
		return Rect2i()
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)
