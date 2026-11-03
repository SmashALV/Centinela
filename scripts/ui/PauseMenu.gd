extends RefCounted
## Menú de pausa: opciones de texto, audio y velocidad, y reanudar la pantalla anterior.
## Se movió desde Main.gd sin cambios de comportamiento (paso 2 de la migración modular).

const ConversationUIScript = preload("res://scripts/ConversationUI.gd")

var main: Node

func show_pause() -> void:
	if main.modal_kind == "pause": return
	main.paused_reading = main.conversation_ui.capture_reading_state()
	main.modal_before_pause = main.modal_kind
	SaveManager.queue_telemetry("pause")
	AudioManager.set_music_paused(true)
	render_pause()

func render_pause() -> void:
	main.modal_kind = "pause"
	main._clear_modal()
	main._modal_heading("PAUSA", "pause")
	var body: VBoxContainer = main._preview_content()
	main._preview_text(body, "Tu progreso se guarda en este dispositivo.", 15)
	if SyncManager.configured:
		main._preview_button(body, "Reintentar sincronización", SyncManager.retry_now)
	var continue_button: Button = main._preview_button(body, "Continuar", resume_pause)
	continue_button.grab_focus()
	var size_label: String = {"small": "Pequeño", "normal": "Mediano", "large": "Grande"}[GameState.text_size]
	main._preview_button(body, "Tamaño de texto: " + size_label, cycle_text_size)
	main._preview_button(body, "Música: %d %%" % GameState.music_volume, func(): cycle_audio("music"))
	main._preview_button(body, "Efectos: %d %%" % GameState.effects_volume, func(): cycle_audio("effects"))
	var speed_label: String = {"slow": "Lenta", "normal": "Normal", "fast": "Rápida"}[GameState.dialogue_speed]
	main._preview_button(body, "Velocidad de diálogo: " + speed_label, cycle_dialogue_speed)
	main._preview_button(body, "Guardar", main._manual_save, "save")
	main._preview_button(body, "Menú", main._return_to_menu)

func cycle_text_size() -> void:
	if main.save_in_progress:
		return
	main.save_in_progress = true
	var previous: String = GameState.text_size
	match previous:
		"small": GameState.text_size = "normal"
		"normal": GameState.text_size = "large"
		_: GameState.text_size = "small"
	if await SaveManager.save_slot_async():
		main._refresh_static_fonts()
		if main.is_inside_tree():
			render_pause()
	else:
		GameState.text_size = previous
		main._toast("No se pudo guardar el tamaño de texto")
	main.save_in_progress = false

func cycle_audio(which: String) -> void:
	if main.save_in_progress:
		return
	main.save_in_progress = true
	var saved: bool = await AudioManager.cycle_level(which)
	main.save_in_progress = false
	if saved:
		if main.is_inside_tree():
			render_pause()
	else:
		main._toast("No se pudo guardar el ajuste de audio")

func cycle_dialogue_speed() -> void:
	if main.save_in_progress:
		return
	main.save_in_progress = true
	var previous: String = GameState.dialogue_speed
	match previous:
		"slow": GameState.dialogue_speed = "normal"
		"normal": GameState.dialogue_speed = "fast"
		_: GameState.dialogue_speed = "slow"
	if await SaveManager.save_slot_async():
		if main.is_inside_tree():
			render_pause()
	else:
		GameState.dialogue_speed = previous
		main._toast("No se pudo guardar la velocidad de diálogo")
	main.save_in_progress = false

func resume_pause() -> void:
	if main.window_too_small or main.save_in_progress:
		return
	AudioManager.set_music_paused(false)
	main.modal_kind = main.modal_before_pause
	if main.phase_load_after_pause:
		main.phase_load_after_pause = false
		main.modal_kind = ""
		main._load_phase()
		if main.daily.active():
			main.conversation_ui.restore_reading_state(main.paused_reading)
			main.paused_reading.clear()
			main.modal_before_pause = ""
			return
		if not GameState.dialogue_key.is_empty(): main._resume_saved_dialogue()
		elif GameState.phase in ["bedroom", "courtyard", "computer"] and not GameState.flags.has("d0_guide_active"): main._close_modal()
		main.conversation_ui.restore_reading_state(main.paused_reading)
		main.paused_reading.clear()
		main.modal_before_pause = ""
		return
	match main.modal_before_pause:
		"prologue": main._render_prologue()
		"stage_guide": main._render_stage_guide()
		"phone": main.phone_modal.render_phone()
		"objective": main.objective_modal.render_objective()
		"class": main._render_class()
		"desktop": main._render_desktop()
		"discord_history": main._render_discord_history(main.desktop_direct)
		"dialogue": main._render_dialogue(true)
		"dialogue_history": main._render_dialogue_history()
		"result": main._show_result()
		"day_intro": main.legacy.render_day_intro()
		"preview": main.legacy.render_preview()
		"preview_unplaced": main.legacy.render_unplaced_preview()
		"coral": main._render_coral()
		"routine": main.daily._render_scene()
		"sleep": main.daily._render_sleep()
		_: main._close_modal()
	main.conversation_ui.restore_reading_state(main.paused_reading)
	main.paused_reading.clear()
	main.modal_before_pause = ""
