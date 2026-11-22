# V7: Clean cinematic exploration and in-game PNG screenshots for presentations.
# No pause/reload: existing weather, fire, sound and camera keep running normally.
class_name CinematicCapture
extends Node

const SCREENSHOT_FOLDER: String = "user://screenshots"

var player: PlayerController3D
var hud: HUD
var mission_director: MissionDirector
var cinematic_active: bool = false
var overlay_layer: CanvasLayer
var hint: Label
var notification_label: Label
var notification_clock: float = 0.0
var capture_busy: bool = false

func initialize(actor: PlayerController3D, game_hud: HUD, mission: MissionDirector) -> void:
	player = actor
	hud = game_hud
	mission_director = mission

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_overlay()
	EventBus.game_phase_changed.connect(_on_phase_changed)
	_on_phase_changed(GameState.current_phase)

func _create_overlay() -> void:
	overlay_layer = CanvasLayer.new()
	overlay_layer.name = "CinematicOverlay"
	overlay_layer.layer = 25
	add_child(overlay_layer)
	var root: Control = Control.new()
	root.name = "CaptureGuides"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint = Label.new()
	hint.text = "MODE SINEMATIK  |  F10: Kembali   F12: Foto PNG"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.add_theme_color_override("font_color", Color(0.90, 0.97, 0.92, 0.78))
	hint.add_theme_font_size_override("font_size", 15)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hint)
	hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hint.offset_left = 10.0
	hint.offset_right = -22.0
	hint.offset_top = 18.0
	hint.offset_bottom = 44.0
	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.add_theme_color_override("font_color", Color(0.72, 1.0, 0.81))
	notification_label.add_theme_font_size_override("font_size", 17)
	notification_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(notification_label)
	notification_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	notification_label.offset_left = 14.0
	notification_label.offset_right = -14.0
	notification_label.offset_top = -70.0
	notification_label.offset_bottom = -30.0
	overlay_layer.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return
	if event.keycode == KEY_F10:
		_set_cinematic(not cinematic_active)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_F12:
		_capture_screenshot()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if notification_clock > 0.0:
		notification_clock -= delta
		if notification_clock <= 0.0 and notification_label != null:
			notification_label.text = ""

func _on_phase_changed(phase: ToolEnums.GamePhase) -> void:
	if phase != ToolEnums.GamePhase.ACTIVE_FPS:
		# Keep all other overlays managed by their original phase listeners.
		cinematic_active = false
		if overlay_layer != null:
			overlay_layer.visible = false
		if player != null:
			player.cinematic_mode_enabled = false
			if player.held_tools != null:
				player.held_tools.visible = not player.third_person_enabled
	else:
		_apply_cinematic_visibility()

func _set_cinematic(enabled: bool) -> void:
	cinematic_active = enabled
	_apply_cinematic_visibility()

func _apply_cinematic_visibility() -> void:
	var playing: bool = GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS
	if player != null:
		player.cinematic_mode_enabled = playing and cinematic_active
		if player.held_tools != null:
			player.held_tools.visible = not player.third_person_enabled and not (playing and cinematic_active)
	if hud != null:
		hud.visible = playing and not cinematic_active
	if mission_director != null and mission_director.mission_layer != null:
		mission_director.mission_layer.visible = playing and not cinematic_active
	if overlay_layer != null:
		overlay_layer.visible = playing and cinematic_active
	if hint != null:
		hint.visible = playing and cinematic_active
	if not cinematic_active and notification_label != null:
		notification_label.text = ""

func _capture_screenshot() -> void:
	if capture_busy:
		return
	capture_busy = true
	# No HUD, tool model, warning or helper text is included in the screenshot.
	var was_cinematic: bool = cinematic_active
	_set_cinematic(true)
	if hint != null:
		hint.visible = false
	if notification_label != null:
		notification_label.visible = false
	# Await the next fully rendered frame before reading viewport pixels.
	await RenderingServer.frame_post_draw
	var folder_abs: String = ProjectSettings.globalize_path(SCREENSHOT_FOLDER)
	var dir_result: Error = DirAccess.make_dir_recursive_absolute(folder_abs)
	var result: Error = dir_result
	var file_path: String = ""
	if dir_result == OK:
		var stamp: String = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
		var suffix: String = str(Time.get_ticks_msec() % 100000)
		file_path = "%s/satria_gambut_%s_%s.png" % [SCREENSHOT_FOLDER, stamp, suffix]
		var image: Image = get_viewport().get_texture().get_image()
		if image != null and not image.is_empty():
			result = image.save_png(file_path)
		else:
			result = ERR_CANT_CREATE
	if GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS:
		_set_cinematic(was_cinematic)
	if notification_label != null:
		notification_label.visible = true
	if result == OK:
		print("Screenshot Satria Gambut saved: ", ProjectSettings.globalize_path(file_path))
		_show_notification("Foto tersimpan di folder user://screenshots")
	else:
		push_warning("Screenshot gagal disimpan. Error: %d" % int(result))
		_show_notification("Gagal menyimpan foto — periksa Output Godot")
	capture_busy = false

func _show_notification(message: String) -> void:
	if notification_label == null or overlay_layer == null:
		return
	notification_label.text = message
	notification_clock = 3.0
	if not cinematic_active:
		EventBus.educational_toast.emit(message, false)
