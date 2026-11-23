# tests/ui_shot.gd - Skrip tangkap layar UI pada beberapa ukuran jendela untuk verifikasi visual.
extends SceneTree

var shot_dir: String = "res://tests/shots"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scene_path: String = args[0] if args.size() > 0 else "res://ui/main_menu/main_menu.tscn"
	var sizes: Array = [Vector2i(1280, 720)]
	var packed: PackedScene = load(scene_path)
	var inst: Node = packed.instantiate()
	root.add_child(inst)
	var mode: String = args[1] if args.size() > 1 else ""
	var tag: String = mode
	if scene_path.contains("main_simulation") and mode != "fire":
		var phases: Dictionary = {"": ToolEnums.GamePhase.ACTIVE_FPS, "planning": ToolEnums.GamePhase.PLANNING, "pause": ToolEnums.GamePhase.PAUSED, "victory": ToolEnums.GamePhase.VICTORY}
		root.get_node("GameState").set_game_phase(phases[mode])
	if mode == "fire":
		var sim = inst.get_node("GridSimulator")
		sim.start_outbreak()
		root.get_node("GameState").set_game_phase(ToolEnums.GamePhase.ACTIVE_FPS)
		var bus: Node = root.get_node("EventBus")
		for i in range(5):
			await process_frame
		for pos in sim.cells.keys():
			if sim.cells[pos].is_burning():
				bus.cell_hovered.emit(pos, sim.cells[pos])
				break
		bus.educational_toast.emit("PERINGATAN CUACA: Arah angin berubah, laju api meningkat!", true)
		bus.well_proximity_changed.emit(true)
		bus.thermal_mode_toggled.emit(true)
		bus.tool_selected.emit(ToolEnums.ToolType.TOMBAK_GAMBUT)
		bus.water_changed.emit(130.0, 600.0)
	elif mode == "settings":
		inst._show_only_modal(inst.settings_modal)
	elif mode == "guide":
		inst._show_only_modal(inst.guide_modal)
	for s in sizes:
		root.size = s
		DisplayServer.window_set_size(s)
		for i in range(25):
			await process_frame
		var img: Image = root.get_texture().get_image()
		var name: String = scene_path.get_file().get_basename()
		var path: String = ProjectSettings.globalize_path(shot_dir) + "/%s%s_%dx%d.png" % [name, tag, s.x, s.y]
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(shot_dir))
		img.save_png(path)
		print("saved ", path)
	quit()
