## Global audio bus. Plays SFX by name, persists mute state to user://audio.cfg.
## Registered as an autoload (`AudioManager`) — call from anywhere via AudioManager.play("flip").
extends Node

const SETTINGS_PATH := "user://audio.cfg"
const POOL_SIZE := 4  ## Number of overlapping SFX players.

const SOUNDS := {
	"flip": "res://assets/sounds/flip.wav",
	"star": "res://assets/sounds/star.wav",
	"death": "res://assets/sounds/death.wav",
	"level_clear": "res://assets/sounds/level_clear.wav",
}

## Per-sound default volume offsets (dB). The placeholder WAVs were generated
## at different peak amplitudes and frequencies, so perceived loudness varies.
## Tuned by ear — flip is the most frequent so it's pulled down, death and
## level_clear are big "moments" so they sit at the loudest reference.
const VOLUMES := {
	"flip": -6.0,
	"star": -3.0,
	"death": 0.0,
	"level_clear": -2.0,
}

signal mute_changed(muted: bool)

var muted: bool = false
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0


func _ready() -> void:
	# Preload streams so first-play has no hitch.
	for name in SOUNDS:
		var path: String = SOUNDS[name]
		if ResourceLoader.exists(path):
			_streams[name] = load(path)

	# Create a small pool of players so overlapping SFX (e.g. flip while collecting star) don't cut each other.
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

	_load_settings()


## Plays a registered sound. `volume_db_offset` is added to the per-sound
## default in VOLUMES — pass 0.0 (default) to use the balanced level.
func play(sound_name: String, volume_db_offset: float = 0.0) -> void:
	if muted:
		return
	var stream = _streams.get(sound_name)
	if stream == null:
		push_warning("AudioManager: unknown sound %s" % sound_name)
		return
	var base_db: float = VOLUMES.get(sound_name, 0.0)
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = stream
	p.volume_db = base_db + volume_db_offset
	p.play()


func toggle_mute() -> void:
	set_muted(not muted)


func set_muted(value: bool) -> void:
	if value == muted:
		return
	muted = value
	_save_settings()
	mute_changed.emit(muted)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		muted = bool(cfg.get_value("audio", "muted", false))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "muted", muted)
	cfg.save(SETTINGS_PATH)
