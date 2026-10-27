extends Node

const STORAGE_SOURCE := "res://web/centinela_storage.js"
const SYNC_SOURCE := "res://web/centinela_sync.js"
const PROTOCOL_VERSION := 1

var available := false
var _api: JavaScriptObject
var _sync_api: JavaScriptObject
var _callback_ref: JavaScriptObject
var _pending: Dictionary = {}
var _responses: Dictionary = {}
var _crypto := Crypto.new()

func _ready() -> void:
	if not OS.has_feature("web"):
		return
	var source := FileAccess.get_file_as_string(STORAGE_SOURCE)
	if source.is_empty():
		push_error("WebBridge: no se encontró el servicio IndexedDB")
		return
	JavaScriptBridge.eval(source, true)
	_api = JavaScriptBridge.get_interface("CentinelaStorage")
	if _api == null:
		push_error("WebBridge: no se inicializó CentinelaStorage")
		return
	var sync_source := FileAccess.get_file_as_string(SYNC_SOURCE)
	if not sync_source.is_empty():
		JavaScriptBridge.eval(sync_source, true)
		_sync_api = JavaScriptBridge.get_interface("CentinelaSync")
	_callback_ref = JavaScriptBridge.create_callback(_on_js_response)
	available = true

func request(operation: String, payload: Dictionary = {}, request_id_override: String = "") -> Dictionary:
	if not available:
		return {"success": false, "error": {"code": "WEB_UNAVAILABLE"}}
	var request_id := request_id_override if not request_id_override.is_empty() else _crypto.generate_random_bytes(16).hex_encode()
	var message := JSON.stringify({"protocol_version": PROTOCOL_VERSION,
		"request_id": request_id, "operation": operation, "payload": payload})
	_pending[request_id] = true
	for attempt in 2:
		var target: JavaScriptObject = _sync_api if operation.begins_with("sync_") else _api
		if target == null:
			_pending.erase(request_id)
			return {"success": false, "error": {"code": "SYNC_UNAVAILABLE"}}
		target.request(message, _callback_ref)
		var deadline := Time.get_ticks_msec() + 10000
		while not _responses.has(request_id) and Time.get_ticks_msec() < deadline:
			await get_tree().create_timer(0.05).timeout
		if _responses.has(request_id):
			var response: Dictionary = _responses[request_id]
			_responses.erase(request_id)
			_pending.erase(request_id)
			return response
	_pending.erase(request_id)
	return {"success": false, "error": {"code": "TIMEOUT"}}

func _on_js_response(args: Array) -> void:
	if args.is_empty() or typeof(args[0]) != TYPE_STRING:
		return
	var parsed: Variant = JSON.parse_string(args[0])
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var request_id: String = str(parsed.get("request_id", ""))
	if _pending.has(request_id) and not _responses.has(request_id):
		_responses[request_id] = parsed
