class_name HeliographHUD
extends CanvasLayer

const EXPOSURE_MOON := preload("res://assets/game/ui/exposure_moon.svg")
const EXPOSURE_SUN := preload("res://assets/game/ui/exposure_sun.svg")
const GlyphLibrary = preload("res://scripts/puzzles/glyph_library.gd")
const HUD_FONT := preload("res://assets/vendor/kenney/fonts/kenney_mini_square_mono.ttf")
const CODEX_PANEL := preload("res://scenes/ui/codex_panel.tscn")

@onready var charge_meter: HeliographChargeMeter = $Root/TopBar/ChargeMeter
@onready var charge_value: Label = $Root/TopBar/ChargeValue
@onready var exposure_icon: TextureRect = $Root/TopBar/ExposureModule/ExposureIcon
@onready var exposure: Label = $Root/TopBar/ExposureModule/Exposure
@onready var exposure_module: Panel = $Root/TopBar/ExposureModule
@onready var lives_value: Label = $Root/TopBar/LivesModule/LivesValue
@onready var mapping_cards: HBoxContainer = $Root/Notebook/MappingCards
@onready var empty_mappings: Label = $Root/Notebook/EmptyMappings
@onready var message: Label = $Root/Message

var _cipher_controller: Node = null


func _ready() -> void:
	# The persistent glyph journal lives above the HUD so it can be opened any time
	# with C. The in-HUD "CIPHER CACHE" only tracks the current level's finds.
	add_child(CODEX_PANEL.instantiate())
	_add_codex_hint()


## A quiet prompt so the player knows the journal exists.
func _add_codex_hint() -> void:
	var hint := Label.new()
	hint.text = "[C] CODEX"
	hint.add_theme_font_override("font", HUD_FONT)
	hint.add_theme_font_size_override("font_size", 7)
	hint.add_theme_color_override("font_color", Color(1.0, 0.819608, 0.4, 0.55))
	hint.position = Vector2(440.0, 332.0)
	$Root.add_child(hint)


func bind(player: Node, cipher_controller: Node) -> void:
	_cipher_controller = cipher_controller
	player.charge_changed.connect(_on_charge_changed)
	player.exposure_changed.connect(_on_exposure_changed)
	player.lives_changed.connect(_on_lives_changed)
	player.lives_depleted.connect(_on_lives_depleted)
	cipher_controller.mapping_discovered.connect(_on_mapping_discovered)
	_on_charge_changed(player.get_charge(), player.get_maximum_charge())
	_on_exposure_changed(player.is_in_sunlight())
	_on_lives_changed(player.get_lives_remaining(), player.get_maximum_lives())
	_refresh_mappings(cipher_controller.get_discovered_mappings())


func show_message(value: String) -> void:
	message.text = value
	message.visible = true


func _on_charge_changed(current: float, maximum: float) -> void:
	charge_meter.set_charge(current, maximum)
	charge_value.text = "%03d" % roundi(current)
	charge_value.modulate = Color("e84a5f") if current <= maximum * 0.25 else Color("ffd166")
	AudioDirector.note_charge(current, maximum)


func _on_exposure_changed(active: bool) -> void:
	exposure_icon.texture = EXPOSURE_SUN if active else EXPOSURE_MOON
	exposure.text = "EXPOSED" if active else "HIDDEN"
	exposure.modulate = Color("ffd166") if active else Color("7be0d6")
	exposure_module.modulate = Color("fff3d0") if active else Color.WHITE


func _on_lives_changed(current: int, maximum: int) -> void:
	lives_value.text = "%d / %d" % [current, maximum]
	lives_value.modulate = Color("e84a5f") if current <= 1 else Color("f2e9d8")


func _on_lives_depleted() -> void:
	show_message("SIGNAL LOST")


func _on_mapping_discovered(
	_glyph_id: StringName,
	_letter: String,
	discovered: int,
	total: int
) -> void:
	if is_instance_valid(_cipher_controller):
		_refresh_mappings(_cipher_controller.get_discovered_mappings())
	$Root/Notebook/Progress.text = "%d / %d" % [discovered, total]


func _refresh_mappings(values: Dictionary) -> void:
	for child in mapping_cards.get_children():
		child.free()
	empty_mappings.visible = values.is_empty()
	$Root/Notebook/Progress.text = "%d / 3" % values.size()

	for glyph_id in values:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(58.0, 30.0)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("10192ae8")
		style.border_color = Color("7be0d6a8")
		style.set_border_width_all(1)
		style.corner_radius_top_left = 3
		style.corner_radius_top_right = 3
		style.corner_radius_bottom_left = 3
		style.corner_radius_bottom_right = 3
		style.content_margin_left = 5.0
		style.content_margin_right = 6.0
		style.content_margin_top = 3.0
		style.content_margin_bottom = 3.0
		card.add_theme_stylebox_override("panel", style)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		card.add_child(row)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(22.0, 22.0)
		icon.texture = GlyphLibrary.texture_for(glyph_id)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color("7be0d6")
		row.add_child(icon)
		var letter := Label.new()
		letter.text = String(values[glyph_id])
		letter.add_theme_font_override("font", HUD_FONT)
		letter.add_theme_font_size_override("font_size", 12)
		letter.add_theme_color_override("font_color", Color("f2e9d8"))
		row.add_child(letter)
		mapping_cards.add_child(card)
