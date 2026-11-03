extends Node

signal lock_lost

const TelemetryScript = preload("res://scripts/Telemetry.gd")
const CoralFlowScript = preload("res://scripts/narrative/CoralStoryFlow.gd")
const SAVE_PREFIX := "user://centinela_slot_"
const TELEMETRY_DIR := "user://telemetry/"
var storage_prefix := SAVE_PREFIX
var telemetry_dir := TELEMETRY_DIR
var web_slot := -1
var web_generation := 0
var web_sequence := 0
var last_error := ""
var _renew_elapsed := 0.0
var _renew_busy := false
var _write_busy := false
var recovered_slot := -1
var telemetry_baseline: Dictionary = {}
var _queued_facts: Array = []
var _telemetry_key := ""
var _coral_profile := CoralFlowScript.new()
var _crypto := Crypto.new()

func _process(delta: float) -> void:
	if not OS.has_feature("web") or web_slot < 0 or _renew_busy:
		return
	_renew_elapsed += delta
	if _renew_elapsed >= 10.0:
		_renew_elapsed = 0.0
		_renew_web_lock()

func _renew_web_lock() -> void:
	_renew_busy = true
	var slot := web_slot
	var generation := web_generation
	var response: Dictionary = await WebBridge.request("renew_lock", {"slot": slot, "generation": generation})
	_renew_busy = false
	if slot == web_slot and generation == web_generation and not response.get("success", false):
		_handle_web_error(response)

func _handle_web_error(response: Dictionary) -> void:
	last_error = str(response.get("error", {}).get("code", "STORAGE_ERROR"))
	if last_error == "LOCK_LOST":
		web_slot = -1
		web_generation = 0
		web_sequence = 0
		lock_lost.emit()

func list_slots_async() -> Dictionary:
	if not OS.has_feature("web"):
		return {"success": true, "result": []}
	var response: Dictionary = await WebBridge.request("list_slots")
	if not response.get("success", false):
		_handle_web_error(response)
	else:
		last_error = ""
	return response

func acquire_slot_async(chosen_slot: int) -> bool:
	if not OS.has_feature("web"):
		return true
	if web_slot == chosen_slot:
		return true
	if web_slot >= 0:
		await release_slot_async()
	var response: Dictionary = await WebBridge.request("acquire_lock", {"slot": chosen_slot})
	if not response.get("success", false):
		_handle_web_error(response)
		return false
	web_slot = chosen_slot
	web_generation = int(response.result.generation)
	var meta: Dictionary = await WebBridge.request("get_slot_meta", {"slot": chosen_slot, "generation": web_generation})
	if not meta.get("success", false):
		_handle_web_error(meta)
		await release_slot_async()
		return false
	web_sequence = int(meta.result.get("sequence", 0)) if meta.result != null else 0
	_renew_elapsed = 0.0
	last_error = ""
	return true

func release_slot_async() -> void:
	if not OS.has_feature("web") or web_slot < 0:
		return
	var slot := web_slot
	var generation := web_generation
	web_slot = -1
	web_generation = 0
	web_sequence = 0
	await WebBridge.request("release_lock", {"slot": slot, "generation": generation})

func load_slot_data_async(chosen_slot: int) -> Dictionary:
	if not OS.has_feature("web"):
		return {"success": false, "error": {"code": "WEB_UNAVAILABLE"}}
	var response: Dictionary = await WebBridge.request("load_slot", {"slot": chosen_slot})
	if not response.get("success", false):
		_handle_web_error(response)
	else:
		last_error = ""
	return response

func save_slot_async() -> bool:
	if not OS.has_feature("web"):
		var facts := _pending_facts()
		if not save_slot():
			return false
		_telemetry_saved(facts)
		return true
	while _write_busy:
		await get_tree().process_frame
	if web_slot != GameState.slot:
		last_error = "LOCK_LOST"
		return false
	var facts := _pending_facts() if SyncManager.configured else []
	var payload := {"slot": GameState.slot, "generation": web_generation, "snapshot": GameState.snapshot()}
	if not facts.is_empty():
		payload["events"] = _stamp(facts, web_sequence + 1)
	_write_busy = true
	var response: Dictionary = await WebBridge.request("save_snapshot" if facts.is_empty() else "save_event_atomic", payload)
	_write_busy = false
	if not response.get("success", false):
		_handle_web_error(response)
		return false
	web_sequence = int(response.result.sequence)
	_telemetry_saved(facts)
	last_error = ""
	return true

# Abre la sesión de telemetría de la ranura: fija la línea base y registra el inicio.
func begin_telemetry_session(resumed: bool) -> bool:
	# Volver del MOBA reabre la escena principal, pero es la misma sesión.
	if not telemetry_baseline.is_empty() and _telemetry_key == "%d:%s" % [GameState.slot, GameState.code]:
		return true
	telemetry_baseline = {}
	_queued_facts = []
	_telemetry_key = "%d:%s" % [GameState.slot, GameState.code]
	var baseline := TelemetryScript.capture(GameState)
	if TelemetryScript.closed(baseline):
		telemetry_baseline = baseline
		return true
	var day := int(baseline.day)
	_queued_facts.append(_timed(TelemetryScript.fact("session_start", day, GameState.phase,
		{"platform": "web" if OS.has_feature("web") else OS.get_name().to_lower(),
		"build": TelemetryScript.safe_scene(str(ProjectSettings.get_setting("application/config/version", "dev"))),
		"resumed": resumed})))
	if not resumed:
		_queued_facts.append(_timed(TelemetryScript.fact("day_start", day, "D%d" % day)))
	telemetry_baseline = baseline
	return await save_slot_async()

func end_telemetry_session() -> void:
	_telemetry_key = ""
	telemetry_baseline = {}
	_queued_facts = []

# Pausa e inactividad viajan con el siguiente guardado de la partida.
func queue_telemetry(kind: String, context: Dictionary = {}) -> void:
	if (OS.has_feature("web") and not SyncManager.configured) or telemetry_baseline.is_empty() or TelemetryScript.closed(telemetry_baseline) or _queued_facts.size() >= TelemetryScript.MAX_EVENTS_PER_SAVE:
		return
	if kind == "moba_result" and _queued_facts.any(func(queued): return queued.kind == "moba_result"):
		return
	var day := TelemetryScript.current_day(GameState)
	_queued_facts.append(_timed(TelemetryScript.fact(kind, day, GameState.phase, context)))

func _pending_facts() -> Array:
	if telemetry_baseline.is_empty():
		return []
	var current := TelemetryScript.capture(GameState)
	var facts: Array = _queued_facts.duplicate(true)
	facts.append_array(TelemetryScript.diff(telemetry_baseline, current,
		_coral_profile.behavior_profile(GameState.coral_state)))
	return facts.slice(0, TelemetryScript.MAX_EVENTS_PER_SAVE)

func _telemetry_saved(facts: Array) -> void:
	if telemetry_baseline.is_empty():
		return
	telemetry_baseline = TelemetryScript.capture(GameState)
	_queued_facts = _queued_facts.slice(mini(facts.size(), _queued_facts.size()))
	if not OS.has_feature("web") and not facts.is_empty():
		_append_desktop_log(facts)

func _timed(fact: Dictionary) -> Dictionary:
	fact["occurred_at"] = Time.get_datetime_string_from_system(true) + "Z"
	return fact

func _stamp(facts: Array, first_sequence: int) -> Array:
	var stamped: Array = []
	for index in facts.size():
		var event: Dictionary = facts[index].duplicate(true)
		if not event.has("occurred_at"):
			_timed(event)
		event["event_id"] = new_event_id()
		event["sequence"] = first_sequence + index
		event["narrative_version"] = GameState.NARRATIVE_VERSION
		event["rubric_version"] = SyncManager.rubric_version
		stamped.append(event)
	return stamped

func new_event_id() -> String:
	var raw := _crypto.generate_random_bytes(16)
	raw[6] = (raw[6] & 0x0f) | 0x40
	raw[8] = (raw[8] & 0x3f) | 0x80
	var hex := raw.hex_encode()
	return "%s-%s-%s-%s-%s" % [hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4), hex.substr(16, 4), hex.substr(20, 12)]

# En escritorio no hay backend: los eventos quedan en un JSONL por código para entregarlos al investigador.
func telemetry_log_path() -> String:
	return telemetry_dir + "centinela_slot_%d_%s.jsonl" % [GameState.slot, GameState.code]

func _append_desktop_log(facts: Array) -> void:
	# Las suites que cambian el prefijo de guardado no escriben en la carpeta real de telemetría.
	if storage_prefix != SAVE_PREFIX and telemetry_dir == TELEMETRY_DIR:
		return
	DirAccess.make_dir_recursive_absolute(_global_path(telemetry_dir))
	var path := telemetry_log_path()
	var sequence := 0
	if FileAccess.file_exists(path):
		sequence = FileAccess.get_file_as_string(path).count("\n")
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo escribir la telemetría local")
		return
	file.seek_end()
	for event in _stamp(facts, sequence + 1):
		event["code"] = GameState.code
		file.store_line(JSON.stringify(event))
	file.close()

func clear_slot_async(chosen_slot: int, replacement: Dictionary = {}) -> bool:
	if chosen_slot < 1 or chosen_slot > 3:
		last_error = "INVALID_SLOT"
		return false
	if not replacement.is_empty() and (replacement.get("slot") != chosen_slot or GameState.slot != chosen_slot):
		last_error = "INVALID_SLOT"
		return false
	if not OS.has_feature("web"):
		return replace_slot() if not replacement.is_empty() else delete_slot(chosen_slot)
	if not await acquire_slot_async(chosen_slot):
		return false
	while _write_busy:
		await get_tree().process_frame
	_write_busy = true
	var operation := "reset_slot" if not replacement.is_empty() else "delete_slot"
	var payload := {"slot": chosen_slot, "generation": web_generation}
	if not replacement.is_empty():
		payload["snapshot"] = replacement
	var response: Dictionary = await WebBridge.request(operation, payload)
	_write_busy = false
	if not response.get("success", false):
		_handle_web_error(response)
		await release_slot_async()
		return false
	web_slot = -1
	web_generation = 0
	web_sequence = 0
	last_error = ""
	return true

func save_moba_result_async(event_id: String, request_id: String,
		occurred_at: String, frozen_snapshot: Dictionary) -> bool:
	if not OS.has_feature("web") or not SyncManager.configured:
		if not OS.has_feature("web"):
			queue_telemetry("moba_result", {"result": {"victoria": "victory", "derrota": "defeat", "empate": "draw"}.get(GameState.moba_result, "draw")})
		return await save_slot_async()
	while _write_busy:
		await get_tree().process_frame
	if web_slot != GameState.slot:
		last_error = "LOCK_LOST"
		return false
	var english_result: String = {"victoria": "victory", "derrota": "defeat", "empate": "draw"}.get(GameState.moba_result, "")
	if english_result.is_empty():
		last_error = "INVALID_REQUEST"
		return false
	var event := {"event_id": event_id, "sequence": web_sequence + 1,
		"kind": "moba_result", "narrative_version": GameState.NARRATIVE_VERSION,
		"rubric_version": SyncManager.rubric_version, "day": TelemetryScript.current_day(GameState), "scene": "moba",
		"occurred_at": occurred_at,
		"context": {"result": english_result}}
	_write_busy = true
	var response: Dictionary = await WebBridge.request("save_event_atomic", {"slot": web_slot,
		"generation": web_generation, "snapshot": frozen_snapshot, "event": event}, request_id)
	_write_busy = false
	if not response.get("success", false):
		_handle_web_error(response)
		return false
	web_sequence = int(response.result.sequence)
	last_error = ""
	return true

func slot_path(chosen_slot: int) -> String:
	return storage_prefix + str(chosen_slot) + ".json"

func backup_path(chosen_slot: int) -> String:
	return slot_path(chosen_slot) + ".bak"

func _global_path(path: String) -> String:
	return ProjectSettings.globalize_path(path)

func slot_exists(chosen_slot: int) -> bool:
	return FileAccess.file_exists(slot_path(chosen_slot)) or FileAccess.file_exists(backup_path(chosen_slot))

func save_slot() -> bool:
	var path := slot_path(GameState.slot)
	var temporary := path + ".tmp"
	var backup := backup_path(GameState.slot)
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_error("No se pudo guardar la ranura " + str(GameState.slot))
		return false
	file.store_string(JSON.stringify(GameState.snapshot()))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(_global_path(temporary))
		push_error("Error de escritura en ranura " + str(GameState.slot) + ": " + str(write_error))
		return false
	var had_primary := FileAccess.file_exists(path)
	if had_primary:
		if recovered_slot == GameState.slot:
			if DirAccess.remove_absolute(_global_path(path)) != OK:
				DirAccess.remove_absolute(_global_path(temporary))
				return false
		else:
			if FileAccess.file_exists(backup) and DirAccess.remove_absolute(_global_path(backup)) != OK:
				DirAccess.remove_absolute(_global_path(temporary))
				return false
			if DirAccess.rename_absolute(_global_path(path), _global_path(backup)) != OK:
				DirAccess.remove_absolute(_global_path(temporary))
				return false
	if DirAccess.rename_absolute(_global_path(temporary), _global_path(path)) != OK:
		if had_primary and recovered_slot != GameState.slot and FileAccess.file_exists(backup):
			DirAccess.rename_absolute(_global_path(backup), _global_path(path))
		DirAccess.remove_absolute(_global_path(temporary))
		return false
	recovered_slot = -1
	last_error = ""
	return true

func replace_slot() -> bool:
	if not save_slot():
		return false
	var backup := backup_path(GameState.slot)
	if FileAccess.file_exists(backup) and DirAccess.remove_absolute(_global_path(backup)) != OK:
		push_warning("No se pudo retirar la copia anterior de la ranura " + str(GameState.slot))
		last_error = "OLD_BACKUP_REMAINS"
	return true

func delete_slot(chosen_slot: int) -> bool:
	if chosen_slot < 1 or chosen_slot > 3:
		last_error = "INVALID_SLOT"
		return false
	for path in [slot_path(chosen_slot), backup_path(chosen_slot), slot_path(chosen_slot) + ".tmp"]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(_global_path(path)) != OK:
			last_error = "DELETE_FAILED"
			return false
	if recovered_slot == chosen_slot:
		recovered_slot = -1
	last_error = ""
	return true

func load_slot(chosen_slot: int) -> bool:
	if chosen_slot < 1 or chosen_slot > 3:
		return false
	if _load_candidate(slot_path(chosen_slot), chosen_slot):
		recovered_slot = -1
		last_error = ""
		return true
	if _load_candidate(backup_path(chosen_slot), chosen_slot):
		recovered_slot = chosen_slot
		last_error = "RECOVERED_BACKUP"
		return true
	recovered_slot = -1
	last_error = "INVALID_SAVE"
	return false

func _load_candidate(path: String, chosen_slot: int) -> bool:
	var data: Variant = _parse_snapshot(path)
	return typeof(data) == TYPE_DICTIONARY and data.get("slot") == chosen_slot and GameState.restore(data)

func _parse_snapshot(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return parser.data

func slot_summary(chosen_slot: int) -> String:
	var path := slot_path(chosen_slot)
	if not slot_exists(chosen_slot):
		return "Ranura %d · nueva" % chosen_slot
	var data: Variant = _parse_snapshot(path)
	if typeof(data) != TYPE_DICTIONARY:
		if not FileAccess.file_exists(backup_path(chosen_slot)):
			return "Ranura %d · archivo inválido" % chosen_slot
		data = _parse_snapshot(backup_path(chosen_slot))
		if typeof(data) != TYPE_DICTIONARY:
			return "Ranura %d · archivo inválido" % chosen_slot
		return "Ranura %d · copia de recuperación" % chosen_slot
	if data.get("slot") != chosen_slot or data.get("schema_version") != GameState.SCHEMA_VERSION or data.get("narrative_version") != GameState.NARRATIVE_VERSION:
		return "Ranura %d · guardado incompatible" % chosen_slot
	return "Ranura %d · Partida guardada" % chosen_slot
