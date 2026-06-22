extends Node
## AudioDirector autoload — central, fire-and-forget audio.
##
## Every call no-ops gracefully when the asset is not present yet, so audio can
## be added incrementally: generate files (see docs/audio-production.md), drop
## them at the documented paths, re-import in Godot, and they start playing with
## no code changes. Until then the game is silent but fully functional.
##
## Filenames follow docs/audio-production.md exactly.

const SFX_DIR := "res://assets/game/audio/sfx/"
const VOICE_DIR := "res://assets/game/audio/voice/"
const AMB_DIR := "res://assets/game/audio/ambience/"

const SFX_EXT := [".wav", ".ogg", ".mp3"]
const VOICE_EXT := [".ogg", ".wav", ".mp3"]

# Watcher voice pools: category -> file basenames (no extension) under VOICE_DIR.
# Missing files are skipped, so a partial set still works.
const WATCHER_VOICE := {
	"warn": ["watcher/bark_exterminate_warn_01"],
	"fire": ["watcher/bark_exterminate_fire_01", "watcher/bark_exterminate_fire_02",
		"watcher/bark_severed_01"],
	"detect": ["watcher/bark_intruder_01", "watcher/bark_target_exposed_01",
		"watcher/bark_located_01", "watcher/bark_seen_01"],
	"search": ["watcher/search_initiate_01", "watcher/search_find_01",
		"watcher/search_shadow_01", "watcher/search_where_01", "watcher/search_forever_01"],
	"chatter": ["watcher/chatter_report_01", "watcher/chatter_shadow_01",
		"watcher/chatter_oracle_01", "watcher/chatter_crown_01",
		"watcher/chatter_run_01", "watcher/chatter_confirm_01"],
	"idle": ["watcher/idle_light_01", "watcher/idle_hold_01", "watcher/idle_tire_01"],
}

var _cache: Dictionary = {}  # path -> Stream or null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _voice_player: AudioStreamPlayer
var _amb_light: AudioStreamPlayer
var _amb_shadow: AudioStreamPlayer
var _amb_hostile: AudioStreamPlayer
var _chatter_timer: Timer
var _tick_timer: Timer
var _charge_ratio: float = 1.0
var _exposed: bool = false
var _hostile: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_sfx_pool.append(player)
	_voice_player = AudioStreamPlayer.new()
	_voice_player.volume_db = 2.0
	add_child(_voice_player)

	_amb_light = _make_bed(["amb_sunlight"], -11.0)
	_amb_shadow = _make_bed(["amb_shadow"], -9.0)
	_amb_hostile = _make_bed(["amb_hostile"], -9.0)

	_chatter_timer = Timer.new()
	_chatter_timer.one_shot = false
	add_child(_chatter_timer)
	_chatter_timer.timeout.connect(_on_chatter_tick)

	_tick_timer = Timer.new()
	_tick_timer.one_shot = true
	add_child(_tick_timer)
	_tick_timer.timeout.connect(_on_charge_tick)

	GameState.watchers_turned_hostile.connect(_on_turn)
	set_hostile(GameState.watchers_hostile)
	_apply_ambience(true)


# --- Public API ------------------------------------------------------------

## Play a one-shot from sfx/<name>.<ext>. Silent if not present.
func sfx(name: String) -> void:
	var stream := _resolve(SFX_DIR, name, SFX_EXT)
	if stream == null:
		return
	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	player.stream = stream
	player.play()


## Play a random Watcher voice line from a category (warn/fire/detect/search/...).
func watcher(category: String) -> void:
	var names: Array = WATCHER_VOICE.get(category, [])
	var stream := _pick_existing(names)
	if stream == null:
		return
	_voice_player.stream = stream
	_voice_player.play()


## Play a specific voice clip by path relative to the voice dir (e.g. an Oracle
## line). Returns true if a clip actually played.
func voice_file(rel: String) -> bool:
	var stream := _resolve_path(VOICE_DIR + rel, VOICE_EXT)
	if stream == null:
		return false
	_voice_player.stream = stream
	_voice_player.play()
	return true


## Called by the HUD as charge changes; drives an accelerating low-charge tick.
func note_charge(current: float, maximum: float) -> void:
	_charge_ratio = current / maximum if maximum > 0.0 else 1.0
	if _charge_ratio > 0.0 and _charge_ratio < 0.25:
		if _tick_timer.is_stopped():
			_tick_timer.start(_charge_tick_interval())
	else:
		_tick_timer.stop()


func _charge_tick_interval() -> float:
	# Faster as the cell empties: ~0.55s near the 25% threshold down to ~0.16s.
	return lerpf(0.16, 0.55, clampf(_charge_ratio / 0.25, 0.0, 1.0))


func _on_charge_tick() -> void:
	if _charge_ratio > 0.0 and _charge_ratio < 0.25:
		sfx("low_charge_tick")
		_tick_timer.start(_charge_tick_interval())


func set_exposed(value: bool) -> void:
	if _exposed == value:
		return
	_exposed = value
	if value:
		sfx("charge_fill")
	_apply_ambience(false)


func set_hostile(value: bool) -> void:
	if _hostile == value:
		return
	_hostile = value
	_apply_ambience(false)
	if _hostile:
		_chatter_timer.start(randf_range(9.0, 15.0))
	else:
		_chatter_timer.stop()


# --- Internals -------------------------------------------------------------

func _on_turn() -> void:
	sfx("watchers_hostile_stinger")
	voice_file("oracle/turn_exterminate")
	set_hostile(true)


func _on_chatter_tick() -> void:
	if not _hostile:
		return
	watcher("chatter" if randf() < 0.6 else "idle")
	_chatter_timer.start(randf_range(12.0, 22.0))


func _make_bed(candidates: Array, target_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.volume_db = -80.0
	player.set_meta("target_db", target_db)
	add_child(player)  # must be in the tree before play()
	var stream: AudioStream = null
	for base in candidates:
		stream = _resolve_path(AMB_DIR + String(base), VOICE_EXT)
		if stream != null:
			break
	if stream != null:
		_set_loop(stream)
		player.stream = stream
		player.play()
	return player


func _apply_ambience(_immediate: bool) -> void:
	_fade(_amb_light, _amb_light.get_meta("target_db") if _exposed else -80.0)
	_fade(_amb_shadow, _amb_shadow.get_meta("target_db") if not _hostile else -80.0)
	_fade(_amb_hostile, _amb_hostile.get_meta("target_db") if _hostile else -80.0)


func _fade(player: AudioStreamPlayer, to_db: float) -> void:
	if player.stream == null:
		return
	if not player.playing:
		player.play()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, 0.8)


func _pick_existing(names: Array) -> AudioStream:
	var shuffled := names.duplicate()
	shuffled.shuffle()
	for base in shuffled:
		var stream := _resolve_path(VOICE_DIR + String(base), VOICE_EXT)
		if stream != null:
			return stream
	return null


func _resolve(dir: String, name: String, exts: Array) -> AudioStream:
	return _resolve_path(dir + name, exts)


func _resolve_path(path_no_ext: String, exts: Array) -> AudioStream:
	if _cache.has(path_no_ext):
		return _cache[path_no_ext]
	var found: AudioStream = null
	for ext in exts:
		var path: String = path_no_ext + ext
		if ResourceLoader.exists(path):
			found = load(path) as AudioStream
			break
	_cache[path_no_ext] = found
	return found


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
