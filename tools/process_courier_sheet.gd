extends SceneTree

const SOURCE := "res://assets/game/characters/courier/source/courier_sheet_alpha-v1.png"
const OUTPUT_DIRECTORY := "res://assets/game/characters/courier/frames"
const FRAME_NAMES := [
	"idle_0",
	"idle_1",
	"run_0",
	"run_1",
	"run_2",
	"run_3",
	"jump",
	"fall",
	"dash_0",
	"dash_1",
	"death_0",
	"death_1",
]
const COLUMNS := 4
const ROWS := 3
const OUTPUT_SIZE := Vector2i(64, 64)
const CONTENT_LIMIT := Vector2i(60, 56)
const BASELINE_Y := 60


func _init() -> void:
	var source := Image.load_from_file(SOURCE)
	if source == null or source.is_empty():
		push_error("Could not load Courier source sheet")
		quit(1)
		return

	var cell_size := Vector2i(source.get_width() / COLUMNS, source.get_height() / ROWS)
	for index in FRAME_NAMES.size():
		var cell_position := Vector2i(index % COLUMNS, index / COLUMNS) * cell_size
		var cell := source.get_region(Rect2i(cell_position, cell_size))
		var bounds := _alpha_bounds(cell)
		if bounds.size == Vector2i.ZERO:
			push_error("Frame %s has no visible pixels" % FRAME_NAMES[index])
			quit(1)
			return

		var trimmed := cell.get_region(bounds)
		var scale_factor := minf(
			float(CONTENT_LIMIT.x) / float(trimmed.get_width()),
			float(CONTENT_LIMIT.y) / float(trimmed.get_height())
		)
		var resized_size := Vector2i(
			maxi(1, roundi(trimmed.get_width() * scale_factor)),
			maxi(1, roundi(trimmed.get_height() * scale_factor))
		)
		trimmed.resize(resized_size.x, resized_size.y, Image.INTERPOLATE_NEAREST)

		var output := Image.create_empty(OUTPUT_SIZE.x, OUTPUT_SIZE.y, false, Image.FORMAT_RGBA8)
		output.fill(Color.TRANSPARENT)
		var destination := Vector2i(
			(OUTPUT_SIZE.x - resized_size.x) / 2,
			BASELINE_Y - resized_size.y
		)
		output.blit_rect(trimmed, Rect2i(Vector2i.ZERO, resized_size), destination)

		var output_path := "%s/%s.png" % [OUTPUT_DIRECTORY, FRAME_NAMES[index]]
		var error := output.save_png(output_path)
		if error != OK:
			push_error("Failed to save %s: %s" % [output_path, error_string(error)])
			quit(1)
			return

	print("Generated %d normalized Courier frames." % FRAME_NAMES.size())
	quit()


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
