## Analytics autoload — appends events to user://analytics_events.jsonl.
##
## A native Swift file-watcher (AnalyticsBridge.swift in the iOS target)
## polls the file once per second, forwards each line to FirebaseAnalytics
## via the native iOS SDK, and truncates. On non-iOS builds the file just
## piles up locally — that's fine for desktop dev; we never enable Firebase
## off-iOS anyway.
##
## Usage:
##   Analytics.log_event("level_clear", {"level": 3, "stars": 2, "time_s": 12.4})
##
## Event names: lowercase + underscores, ≤40 chars. Param keys: same. Param
## values: String, int, float, or bool. Anything else is stringified by the
## Swift bridge before being passed to Firebase.
extends Node


const EVENT_FILE := "user://analytics_events.jsonl"
const USER_ID_FILE := "user://analytics_user_id.txt"
const APPEND_LIMIT_BYTES := 1024 * 1024  ## Cap the buffer file at 1 MB. If
##  the bridge falls behind (or we're running off-device with no bridge),
##  this stops it from growing without bound.

var _user_id: String = ""
var _session_id: String = ""
var _disabled: bool = false


func _ready() -> void:
	_user_id = _load_or_create_user_id()
	_session_id = _generate_id()
	# Defer the auto session_start one frame so the autoload is fully ready
	# and the file path is writable.
	call_deferred("log_event", "session_start", {
		"platform": OS.get_name(),
		"model": OS.get_model_name(),
	})


## Sets a Firebase Analytics user property — value is sticky, slices every
## subsequent event in the dashboard. Use for low-cardinality dimensions
## like orientation, build_variant, etc. Not for per-event data.
func set_user_property(name: String, value: String) -> void:
	if _disabled:
		return
	_append({"user_property": name, "value": value})


## Appends one event to the JSONL buffer. Drops silently if anything
## fails — analytics must never break the game.
func log_event(name: String, params: Dictionary = {}) -> void:
	if _disabled:
		return
	# Always include user_id + session_id so Firebase can group events
	# even before its own session bookkeeping kicks in.
	var enriched: Dictionary = params.duplicate()
	enriched["user_id"] = _user_id
	enriched["session_id"] = _session_id
	enriched["t"] = Time.get_unix_time_from_system()
	_append({"name": name, "params": enriched})


func _append(record: Dictionary) -> void:
	var line := JSON.stringify(record) + "\n"
	# Open in append mode so concurrent calls don't clobber each other.
	var f: FileAccess
	if FileAccess.file_exists(EVENT_FILE):
		# Stop appending if the buffer has gotten huge (bridge missing /
		# offline). Better to drop new events than fill the device.
		var size := FileAccess.get_file_as_bytes(EVENT_FILE).size()
		if size > APPEND_LIMIT_BYTES:
			_disabled = true
			push_warning("Analytics: buffer exceeded %d bytes, disabling" % APPEND_LIMIT_BYTES)
			return
		f = FileAccess.open(EVENT_FILE, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(EVENT_FILE, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(line)
	f.close()


# ---- private ----

func _load_or_create_user_id() -> String:
	if FileAccess.file_exists(USER_ID_FILE):
		var f := FileAccess.open(USER_ID_FILE, FileAccess.READ)
		if f != null:
			var s := f.get_as_text().strip_edges()
			f.close()
			if s.length() >= 8:
				return s
	var fresh := _generate_id()
	var f2 := FileAccess.open(USER_ID_FILE, FileAccess.WRITE)
	if f2 != null:
		f2.store_string(fresh)
		f2.close()
	return fresh


func _generate_id() -> String:
	# 16 hex chars. Not a real UUID but plenty unique for an MVP audience.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var hex := "0123456789abcdef"
	var s := ""
	for i in 16:
		s += hex[rng.randi_range(0, 15)]
	return s
