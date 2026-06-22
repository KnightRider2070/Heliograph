extends SceneTree

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"jump": [KEY_SPACE, KEY_W, KEY_UP],
	"dash": [KEY_SHIFT, KEY_X],
	"interact": [KEY_E, KEY_ENTER],
	"pause": [KEY_ESCAPE],
}


func _init() -> void:
	for action: String in ACTIONS:
		var events: Array[InputEvent] = []
		for keycode: Key in ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			events.append(event)

		ProjectSettings.set_setting(
			"input/%s" % action,
			{
				"deadzone": 0.5,
				"events": events,
			}
		)

	var error := ProjectSettings.save()
	if error != OK:
		push_error("Failed to save project settings: %s" % error_string(error))
		quit(1)
		return

	print("Configured %d input actions." % ACTIONS.size())
	quit()
