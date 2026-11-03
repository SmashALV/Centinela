extends RefCounted
## Inventario: recoger objetos (la mochila) y quitarlos del mapa.
## Se movió desde Main.gd sin cambios de comportamiento (paso 8 de la migración modular).

var main: Node

func pick_up(item: String, flag: String, message: String) -> void:
	if main.save_in_progress: return
	if GameState.has_item(item):
		main._toast("Ya llevas la " + item + " en tu inventario")
		return
	var previous: Dictionary = GameState.snapshot()
	GameState.add_item(item)
	GameState.flags[flag] = true
	main.save_in_progress = true
	main.world.enabled = false
	if await SaveManager.save_slot_async():
		main.save_in_progress = false
		if not main.is_inside_tree(): return
		# El objeto desaparece del mapa: deja de ser objetivo y de dibujarse.
		main.world.objects.erase(flag)
		if main.daily.active(): main.world.configure_story_targets(main.daily.targets(), main.daily._primary_target())
		main.hud_view.update()
		AudioManager.play_effect("pickup")
		main.world.enabled = main.modal_kind == ""
		main._toast(message)
	else:
		GameState.restore(previous)
		main.save_in_progress = false
		if main.modal_kind == "": main.world.enabled = true
		main._toast("Error al guardar")
