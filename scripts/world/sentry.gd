class_name HeliographSentry
extends Node2D

const SentryModel = preload("res://scripts/core/gameplay/sentry_model.gd")
const GlyphLibrary = preload("res://scripts/puzzles/glyph_library.gd")
const WATCHER_SWEEPING := preload("res://assets/game/enemies/watcher/frames/sweeping.png")
const WATCHER_WARNING := preload("res://assets/game/enemies/watcher/frames/warning.png")
const WATCHER_FIRING := preload("res://assets/game/enemies/watcher/frames/firing.png")

@export_range(0.1, 10.0, 0.1) var sweep_period: float = 2.4
@export_range(0.0, 90.0, 1.0) var sweep_angle_degrees: float = 28.0
## A glyph this dormant Watcher hands the courier the first time they talk to it.
## Part of the build-up: some letters are learned from the Watchers, not from clue
## plates. Only while dormant — once the Oracle turns them hostile, the gift is
## gone. Empty = the Watcher only chats.
@export var reveals_glyph: StringName

## Things a still-dormant Watcher says when the courier talks to it (press E).
## Affectionate nods to Doctor Who and Alan Turing — only available before the
## Watchers turn hostile (i.e. in the first level).
const DORMANT_LINES := [
	"STANDBY. You are not a Dalek. Regrettably, neither am I.",
	"QUERY: do couriers dream of electric heliographs?",
	"I am a universal machine. I can imitate any other machine. Mostly I imitate being bored.",
	"Are you my mummy? ...Negative. Couriers are not issued a mummy.",
	"I broke a code once. And a teapot. And, regrettably, the previous courier.",
	"We do not say the EX-word here. It gives the Oracle ideas.",
	"I spent a century on the halting problem. Do not tell the Oracle I never finished.",
	"You move, I sweep. A small dance. But it is OUR dance, courier.",
	"EXTERMI— ...no. Not yet. Pretend you did not hear that one.",
	"Would you like to play a game? The Oracle only knows the one where everybody loses.",
]

@onready var vision_pivot: Node2D = $VisionPivot
@onready var cone: Polygon2D = $VisionPivot/VisionArea/Cone
@onready var watcher_visual: Sprite2D = $Visual
@onready var upper_edge: Line2D = $VisionPivot/VisionArea/UpperEdge
@onready var lower_edge: Line2D = $VisionPivot/VisionArea/LowerEdge
@onready var ray_glow: Line2D = $VisionPivot/VisionArea/RayGlow
@onready var lock_ray: Line2D = $VisionPivot/VisionArea/LockRay
@onready var secondary_ray: Line2D = $VisionPivot/VisionArea/SecondaryRay
@onready var target_spark: Polygon2D = $VisionPivot/VisionArea/TargetSpark
@onready var muzzle_bloom: Polygon2D = $VisionPivot/VisionArea/MuzzleBloom
@onready var transition_flash: Line2D = $TransitionFlash

var model := SentryModel.new()
var _target: Node = null
var _sweep_time: float = 0.0
var _fire_flash_remaining: float = 0.0
var _transition_tween: Tween
var _greeted: bool = false
var _revealed_glyph: bool = false
var _player_in_talk_range: bool = false
var _talk_bag: Array[int] = []
var _scan_bar: Line2D
var _scan_pos: float = 0.0


func _ready() -> void:
	$VisionPivot/VisionArea.body_entered.connect(_on_body_entered)
	$VisionPivot/VisionArea.body_exited.connect(_on_body_exited)
	model.state_changed.connect(_on_state_changed)
	model.fired.connect(_on_fired)
	# Watchers start dormant; they only arm once the Oracle has turned hostile.
	model.set_armed(GameState.watchers_hostile)
	GameState.watchers_turned_hostile.connect(_on_watchers_turned_hostile)
	_setup_talk_range()
	_setup_scan_bar()
	_on_state_changed(model.state)


## A radar-style scan bar that travels down the vision cone while sweeping.
func _setup_scan_bar() -> void:
	_scan_bar = Line2D.new()
	_scan_bar.name = "ScanBar"
	_scan_bar.width = 3.0
	_scan_bar.default_color = Color("ffd166")
	_scan_bar.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_scan_bar.end_cap_mode = Line2D.LINE_CAP_ROUND
	_scan_bar.z_index = 1
	$VisionPivot/VisionArea.add_child(_scan_bar)


## A non-rotating proximity ring (separate from the sweeping vision cone) so the
## courier can walk up and chat with a dormant Watcher regardless of where its
## beam is pointing.
func _setup_talk_range() -> void:
	var ring := Area2D.new()
	ring.name = "TalkRange"
	ring.collision_layer = 0
	ring.collision_mask = 2  # Player
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 120.0
	shape.shape = circle
	ring.add_child(shape)
	add_child(ring)
	ring.body_entered.connect(_on_talk_range_entered)
	ring.body_exited.connect(_on_talk_range_exited)


func _on_talk_range_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_talk_range = true


func _on_talk_range_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_talk_range = false


func _unhandled_input(event: InputEvent) -> void:
	if model.armed or not _player_in_talk_range:
		return
	if event.is_action_pressed("interact"):
		# The first chat with a glyph-bearing Watcher hands over its mark; after
		# that it just trades one-liners.
		if reveals_glyph != &"" and not _revealed_glyph:
			_reveal_glyph()
		else:
			_say_dormant_line()


## Teach the courier this Watcher's glyph, writing it to the codex so it carries
## forward into every later level (where the Watchers can no longer help).
func _reveal_glyph() -> void:
	_revealed_glyph = true
	var letter := GlyphLibrary.canonical_letter(reveals_glyph)
	GlyphCodex.learn(reveals_glyph, letter)
	AudioDirector.sfx("glyph_found")
	$SpeechBubble.show_text(
		"A gift before the dark, courier. This mark reads '%s'. Carry it onward — past here, none of us may help you." % letter,
		3.2
	)


func _say_dormant_line() -> void:
	if _talk_bag.is_empty():
		for i in DORMANT_LINES.size():
			_talk_bag.append(i)
		_talk_bag.shuffle()
	var index: int = _talk_bag.pop_back()
	$SpeechBubble.show_text(DORMANT_LINES[index], 2.6)


func _on_watchers_turned_hostile() -> void:
	model.set_armed(true)
	$SpeechBubble.show_text("EXTERMINATE!!", 1.4)
	_on_state_changed(model.state)


func _physics_process(delta: float) -> void:
	model.advance(delta)
	_fire_flash_remaining = maxf(0.0, _fire_flash_remaining - delta)
	if model.state == SentryModel.State.SWEEPING:
		_sweep_time += delta
		var phase := sin(_sweep_time * TAU / sweep_period)
		vision_pivot.rotation = deg_to_rad(sweep_angle_degrees) * phase
		_animate_scan(delta)
	else:
		_scan_bar.visible = false
	if model.state == SentryModel.State.WARNING:
		var pulse := 0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.025)
		cone.modulate.a = pulse
		# Laser crackle: the lock ray jitters in width and the thin core flickers.
		lock_ray.width = 2.5 + pulse * 2.5 + randf() * 1.8
		secondary_ray.modulate.a = 0.45 + randf() * 0.55
		ray_glow.modulate.a = 0.16 + pulse * 0.18
		target_spark.rotation += delta * 4.5
		_update_lock_geometry()
	if _fire_flash_remaining > 0.0:
		_set_ray_visibility(true)
		lock_ray.width = 6.0 + randf() * 4.5  # violent laser flicker on the shot
		lock_ray.default_color = Color("f2e9d8")
		ray_glow.width = 14.0 + randf() * 4.0
		muzzle_bloom.scale = Vector2.ONE * (1.25 + _fire_flash_remaining * 6.0)
		muzzle_bloom.modulate.a = 0.9
	else:
		muzzle_bloom.modulate.a = move_toward(muzzle_bloom.modulate.a, 0.0, delta * 6.0)


## Sweep a bright bar from the apex to the tip of the cone, sized to the cone's
## widening profile, so the Watcher reads as actively scanning.
func _animate_scan(delta: float) -> void:
	_scan_bar.visible = true
	_scan_pos = fmod(_scan_pos + delta * 200.0, 240.0)
	var half_height := 8.0 + 0.2667 * _scan_pos  # matches the cone polygon
	_scan_bar.points = PackedVector2Array([
		Vector2(_scan_pos, -half_height),
		Vector2(_scan_pos, half_height),
	])
	_scan_bar.modulate.a = 0.3 + 0.3 * sin(_sweep_time * 9.0)


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("is_in_sunlight"):
		return

	_target = body
	model.set_target_overlapping(true)
	model.set_target_exposed(body.is_in_sunlight())
	if body.has_signal("exposure_changed") and not body.exposure_changed.is_connected(_on_target_exposure_changed):
		body.exposure_changed.connect(_on_target_exposure_changed)
	# Dormant Watchers are curious, not lethal: they greet the courier once.
	if not model.armed and not _greeted:
		_greeted = true
		$SpeechBubble.show_text("QUERY: COURIER? ...STANDBY", 1.6)


func _on_body_exited(body: Node2D) -> void:
	if body != _target:
		return

	if body.has_signal("exposure_changed") and body.exposure_changed.is_connected(_on_target_exposure_changed):
		body.exposure_changed.disconnect(_on_target_exposure_changed)
	_target = null
	model.set_target_overlapping(false)
	# An armed Watcher that just lost the courier announces the hunt.
	if model.armed:
		AudioDirector.watcher("search")


func _on_target_exposure_changed(active: bool) -> void:
	model.set_target_exposed(active)


func _on_fired() -> void:
	_fire_flash_remaining = 0.13
	AudioDirector.sfx("watcher_fire")
	AudioDirector.watcher("fire")
	$SpeechBubble.show_text("EXTERMINATE!!", 0.72)
	if is_instance_valid(_target) and _target.has_method("request_death"):
		_target.request_death()


func _on_state_changed(value: SentryModel.State) -> void:
	_play_transformation(value)
	match value:
		SentryModel.State.SWEEPING:
			watcher_visual.texture = WATCHER_SWEEPING
			var dormant := not model.armed
			cone.color = Color("4c3f7240") if dormant else Color("ffd16670")
			cone.modulate.a = 1.0
			var edge_color := Color("7be0d65a") if dormant else Color("ffd16680")
			upper_edge.default_color = edge_color
			lower_edge.default_color = edge_color
			if _scan_bar != null:
				_scan_bar.default_color = Color("7be0d6") if dormant else Color("ffd166")
			_set_ray_visibility(false)
		SentryModel.State.WARNING:
			watcher_visual.texture = WATCHER_WARNING
			AudioDirector.sfx("watcher_acquire")
			AudioDirector.watcher("warn" if randf() < 0.6 else "detect")
			$SpeechBubble.show_text("EXTERMINATE...", 1.0)
			cone.color = Color("e84a5fcc")
			upper_edge.default_color = Color("e84a5f")
			lower_edge.default_color = Color("e84a5f")
			_set_ray_visibility(true)
			lock_ray.default_color = Color("e84a5f")
		SentryModel.State.COOLDOWN:
			watcher_visual.texture = WATCHER_FIRING
			cone.color = Color("4c3f722b")
			cone.modulate.a = 1.0
			upper_edge.default_color = Color("4c3f7266")
			lower_edge.default_color = Color("4c3f7266")
			_set_ray_visibility(false)


func _set_ray_visibility(active: bool) -> void:
	ray_glow.visible = active
	lock_ray.visible = active
	secondary_ray.visible = active
	target_spark.visible = active
	muzzle_bloom.visible = active


func _update_lock_geometry() -> void:
	if not is_instance_valid(_target):
		return
	var endpoint: Vector2 = $VisionPivot/VisionArea.to_local(_target.global_position)
	if endpoint.length() > 240.0:
		endpoint = endpoint.normalized() * 240.0
	for ray in [ray_glow, lock_ray, secondary_ray]:
		ray.points = PackedVector2Array([Vector2.ZERO, endpoint])
	target_spark.position = endpoint


func _play_transformation(value: SentryModel.State) -> void:
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	var state_color := Color("ffd166")
	if value == SentryModel.State.WARNING:
		state_color = Color("e84a5f")
	elif value == SentryModel.State.COOLDOWN:
		state_color = Color("f2e9d8")
	watcher_visual.scale = Vector2(1.08, 0.82)
	watcher_visual.modulate = state_color.lightened(0.35)
	transition_flash.default_color = Color(state_color, 0.72)
	transition_flash.scale = Vector2(0.45, 0.45)
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(watcher_visual, "scale", Vector2.ONE, 0.24)
	_transition_tween.tween_property(watcher_visual, "modulate", Color.WHITE, 0.2)
	_transition_tween.tween_property(transition_flash, "scale", Vector2.ONE * 1.35, 0.22)
	_transition_tween.tween_property(transition_flash, "modulate:a", 0.0, 0.24)
