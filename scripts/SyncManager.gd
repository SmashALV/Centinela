extends Node

const CONFIG_PATH := "res://web/backend_config.json"
const INACTIVITY_SECONDS := 90.0

var configured := false
var rubric_version := ""
var last_error := ""
var connected := false
var blocked := false
var _config: Dictionary = {}
var _slot := -1
var _generation := 0
var _busy := false
var _elapsed := 0.0
var _retry_seconds := 2.0
var sync_completed := false
var _idle_seconds := 0.0

func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_config = parsed
	rubric_version = str(_config.get("rubric_version", ""))
	configured = bool(_config.get("enabled", false)) and not str(_config.get("url", "")).is_empty() and not str(_config.get("public_key", "")).is_empty() and not rubric_version.is_empty()

func on_slot_opened() -> void:
	if not configured or SaveManager.web_slot < 0:
		return
	if _slot == SaveManager.web_slot and _generation == SaveManager.web_generation:
		return
	_slot = SaveManager.web_slot
	_generation = SaveManager.web_generation
	connected = false
	blocked = false
	last_error = ""
	_elapsed = 0.0
	_retry_seconds = 2.0
	sync_completed = false
	_cycle()

func on_slot_closed() -> void:
	SaveManager.end_telemetry_session()
	_idle_seconds = 0.0
	var old_slot := _slot
	var old_generation := _generation
	_slot = -1
	_generation = 0
	connected = false
	blocked = false
	_elapsed = 0.0
	if old_slot >= 0:
		WebBridge.request("sync_close", {"slot": old_slot, "generation": old_generation})

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton):
		return
	if _idle_seconds >= INACTIVITY_SECONDS:
		SaveManager.queue_telemetry("inactivity", {"mode": _activity_mode(), "duration_s": mini(int(_idle_seconds), 999999)})
	_idle_seconds = 0.0

func _activity_mode() -> String:
	var scene := get_tree().current_scene
	if scene != null and scene.scene_file_path.ends_with("MOBAArena.tscn"):
		return "moba"
	if scene != null and str(scene.get("modal_kind")) in ["coral", "preview", "preview_unplaced", "day_intro", "prologue", "stage_guide", "routine", "dialogue"]:
		return "dialogue"
	return "exploration"

func _paused_by_player() -> bool:
	var scene := get_tree().current_scene
	return scene == null or str(scene.get("modal_kind")) in ["pause", "menu", "slot_confirm"] or scene.get("window_too_small") == true

func _process(delta: float) -> void:
	if not SaveManager.telemetry_baseline.is_empty() and not _paused_by_player():
		_idle_seconds += delta
	if not configured or _slot < 0 or _busy or blocked:
		return
	_elapsed += delta
	if _elapsed >= _retry_seconds:
		_elapsed = 0.0
		_cycle()

func _cycle() -> void:
	if _busy or _slot < 0 or _slot != SaveManager.web_slot or _generation != SaveManager.web_generation:
		return
	_busy = true
	var slot := _slot
	var generation := _generation
	var response: Dictionary
	if connected:
		response = await WebBridge.request("sync_flush", {"slot": slot, "generation": generation})
	else:
		response = await WebBridge.request("sync_open", {"slot": slot, "generation": generation,
			"code": GameState.code, "narrative_version": GameState.NARRATIVE_VERSION,
			"config": _config})
	if slot != _slot or generation != _generation:
		_busy = false
		return
	if response.get("success", false):
		if not connected:
			var server_code: String = str(response.result.get("code", GameState.code))
			if server_code != GameState.code:
				var old_code := GameState.code
				GameState.code = server_code
				var code_saved := await SaveManager.save_slot_async()
				if slot != _slot or generation != _generation:
					_busy = false
					return
				if not code_saved:
					GameState.code = old_code
					last_error = "LOCAL_SAVE_FAILED"
					_retry_seconds = 2.0
					_busy = false
					return
		connected = true
		last_error = ""
		_retry_seconds = 10.0
		if not sync_completed and not str(GameState.coral_state.get("ending", "")).is_empty():
			sync_completed = await finalize_story()
	else:
		last_error = str(response.get("error", {}).get("code", "SYNC_ERROR"))
		if last_error == "EVENT_REJECTED" or last_error == "BACKEND_REJECTED":
			blocked = true
		else:
			_retry_seconds = minf(_retry_seconds * 2.0, 32.0) + randf_range(0.0, 0.5)
	_busy = false

func status_label() -> String:
	if not configured:
		return "Sincronización remota no configurada"
	if blocked:
		return "Sincronización pendiente de revisión"
	if connected:
		return "Sincronización conectada"
	return "Sincronización pendiente; la partida está guardada aquí"

func retry_now() -> void:
	if not configured or _slot < 0:
		return
	blocked = false
	_elapsed = 0.0
	_cycle()

func finalize_story() -> bool:
	if not configured or not connected or _slot != SaveManager.web_slot or _generation != SaveManager.web_generation:
		return false
	var flushed: Dictionary = await WebBridge.request("sync_flush", {"slot": _slot, "generation": _generation})
	if not flushed.get("success", false):
		last_error = str(flushed.get("error", {}).get("code", "SYNC_ERROR"))
		return false
	var response: Dictionary = await WebBridge.request("sync_finalize", {"slot": _slot,
		"generation": _generation, "last_sequence": SaveManager.web_sequence})
	if not response.get("success", false):
		last_error = str(response.get("error", {}).get("code", "SYNC_ERROR"))
		return false
	last_error = ""
	return bool(response.result.sync_completed)
