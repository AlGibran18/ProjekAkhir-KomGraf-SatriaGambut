# Runtime mission director: weather fronts, onboarding, progress tracking and emergency intelligence.
class_name MissionDirector
extends Node

var simulator: GridSimulator
var weather_clock: float = 0.0
var ui_clock: float = 0.0
var tutorial_step: int = 0
var tutorial_done: Array[bool] = [false, false, false, false]
var mission_layer: CanvasLayer
var objective_label: Label
var weather_label: Label
var tutorial_label: Label
var reserve_label: Label
var progress_bar: ProgressBar
var weather_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var event_number: int = 0

func initialize(sim: GridSimulator) -> void:
	simulator = sim

func _ready() -> void:
	weather_rng.randomize()
	_create_mission_hud()
	EventBus.game_phase_changed.connect(_on_phase_changed)
	EventBus.tool_action_performed.connect(_on_tool_action)
	EventBus.thermal_mode_toggled.connect(_on_thermal)
	EventBus.mission_stats_updated.connect(_on_stats)
	_on_phase_changed(GameState.current_phase)

func _process(delta: float) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	weather_clock += delta
	ui_clock += delta
	if weather_clock >= 40.0:
		weather_clock = 0.0
		_change_weather()
	if ui_clock >= 0.4:
		ui_clock = 0.0
		_refresh_ui()

func _create_mission_hud() -> void:
	mission_layer = CanvasLayer.new()
	mission_layer.layer = 6
	add_child(mission_layer)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "MissionPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(18, 144)
	panel.custom_minimum_size = Vector2(330, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.085, 0.88)
	style.border_color = Color(0.17, 0.82, 0.71, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", style)
	mission_layer.add_child(panel)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	var title: Label = Label.new()
	title.text = "OPERASI SATRIA GAMBUT"
	title.add_theme_color_override("font_color", Color(0.42, 0.95, 0.75))
	title.add_theme_font_size_override("font_size", 17)
	stack.add_child(title)
	objective_label = Label.new()
	objective_label.text = "OBJEKTIF: Padamkan hotspot dan lindungi pos"
	objective_label.add_theme_font_size_override("font_size", 13)
	stack.add_child(objective_label)
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 10.0
	progress_bar.show_percentage = false
	progress_bar.max_value = 100.0
	stack.add_child(progress_bar)
	weather_label = Label.new()
	weather_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(weather_label)
	reserve_label = Label.new()
	reserve_label.add_theme_font_size_override("font_size", 12)
	stack.add_child(reserve_label)
	tutorial_label = Label.new()
	tutorial_label.add_theme_font_size_override("font_size", 12)
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(tutorial_label)

func _on_phase_changed(phase: ToolEnums.GamePhase) -> void:
	if mission_layer != null:
		mission_layer.visible = phase == ToolEnums.GamePhase.ACTIVE_FPS
	if phase == ToolEnums.GamePhase.ACTIVE_FPS:
		_refresh_ui()
		if GameState.current_level_index == 0 and tutorial_step == 0:
			EventBus.educational_toast.emit("TUTORIAL: Gunakan [2] untuk semprot permukaan, lalu [Tab] mencari bara tersembunyi.", false)

func _on_tool_action(tool: ToolEnums.ToolType, _pos: Vector2i) -> void:
	if GameState.current_level_index != 0:
		return
	if tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN:
		tutorial_done[0] = true
	elif tool == ToolEnums.ToolType.SEKAT_BAKAR:
		tutorial_done[2] = true
	elif tool == ToolEnums.ToolType.TOMBAK_GAMBUT:
		tutorial_done[3] = true
	_advance_tutorial()

func _on_thermal(enabled: bool) -> void:
	if enabled:
		tutorial_done[1] = true
	_advance_tutorial()

func _advance_tutorial() -> void:
	var previous: int = tutorial_step
	while tutorial_step < tutorial_done.size() and tutorial_done[tutorial_step]:
		tutorial_step += 1
	if tutorial_step != previous and GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS:
		if tutorial_step == tutorial_done.size():
			EventBus.educational_toast.emit("LATIHAN SELESAI! Padamkan semua bara untuk meraih medali emas.", false)
		else:
			EventBus.educational_toast.emit("Bagus! Lanjutkan instruksi latihan pada panel misi.", false)
	_refresh_ui()

func _on_stats(_burned: int, _safe: int, _active: int) -> void:
	if mission_layer != null and mission_layer.visible:
		_refresh_ui()

func _refresh_ui() -> void:
	if simulator == null or objective_label == null:
		return
	var active: int = GameState.active_fire_cells
	var base_hotspots: int = maxi(1, GameState.initial_fires_count)
	var cleared: int = maxi(0, base_hotspots - active)
	var prog: float = clampf(100.0 * float(cleared) / float(base_hotspots), 0.0, 100.0)
	progress_bar.value = prog
	objective_label.text = "HOTSPOT: %d aktif  |  Pos: %s" % [active, "AMAN" if GameState.station_safe else "HANCUR"]
	weather_label.text = "CUACA: %.1f C  | Angin %.0f km/j  | Hujan %.1f mm" % [GameState.ambient_temperature, GameState.wind_speed_kmh, GameState.global_rainfall_rate]
	var reserve_total: float = 0.0
	for amount in GameState.well_reserves.values():
		reserve_total += float(amount)
	reserve_label.text = "CADANGAN SUMUR: %.0f L  | Air dipakai: %.0f L" % [reserve_total, GameState.water_used_total]
	if GameState.current_level_index == 0:
		var tips: Array[String] = [
			"LATIHAN 1/4: [2] semprot api menggunakan klik kiri.",
			"LATIHAN 2/4: [Tab] aktifkan thermal untuk melihat bara.",
			"LATIHAN 3/4: [1] buat sekat api di petak aman.",
			"LATIHAN 4/4: [3] injeksikan air ke bara dalam.",
			"LATIHAN 4/4: Semua alat sudah dicoba!"
		]
		tutorial_label.text = tips[mini(tutorial_step, tips.size() - 1)]
	else:
		tutorial_label.text = "MISI: Lindungi pos utara. Gunakan thermal dan minimap."

func _change_weather() -> void:
	# Deterministic bounds but varying fronts. Rain and wind affect cell risk and spreading.
	var intensity: float = 1.0 + float(GameState.current_level_index) * 0.35
	event_number += 1
	var roll: int = weather_rng.randi_range(0, 2)
	if roll == 0:
		GameState.wind_speed_kmh = clampf(GameState.wind_speed_kmh + weather_rng.randf_range(1.0, 5.0) * intensity, 3.0, 32.0)
		GameState.wind_direction = GameState.wind_direction.rotated(weather_rng.randf_range(-0.8, 0.8)).normalized()
		GameState.global_rainfall_rate = maxf(0.0, GameState.global_rainfall_rate - 1.0)
		EventBus.educational_toast.emit("PERINGATAN CUACA: Arah angin berubah, laju api meningkat!", true)
	elif roll == 1:
		GameState.global_rainfall_rate = clampf(GameState.global_rainfall_rate + weather_rng.randf_range(2.0, 6.0), 0.0, 12.0)
		GameState.ambient_temperature = maxf(27.0, GameState.ambient_temperature - 1.0)
		EventBus.educational_toast.emit("HUJAN TURUN: Gambut mulai lembap. Manfaatkan kesempatan ini!", false)
	else:
		GameState.ambient_temperature = minf(41.0, GameState.ambient_temperature + 1.5)
		GameState.global_rainfall_rate = maxf(0.0, GameState.global_rainfall_rate - 2.0)
		EventBus.educational_toast.emit("GELOMBANG PANAS: Risiko kebakaran meningkat!", true)
	# Apply weather front to all cells; dampen spread in rainy conditions.
	for pos in simulator.cells.keys():
		var cell: PeatCellData = simulator.cells[pos]
		cell.rainfall = GameState.global_rainfall_rate
		cell.temperature = GameState.ambient_temperature
		cell.soil_moisture = clampf(cell.soil_moisture + GameState.global_rainfall_rate * 0.004 - (0.004 if roll == 2 else 0.0), 0.05, 1.0)
		cell.recalculate_pfvi()
		EventBus.cell_state_updated.emit(pos, cell)
	_refresh_ui()
