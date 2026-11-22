# ui/hud/hud.gd - Pengendali antarmuka First-Person (HUD): crosshair dinamis, bar injeksi, minimap real-time, toast animasi halus, dan layout anti-tabrakan.
class_name HUD
extends CanvasLayer

@onready var water_progress_bar: ProgressBar = $RootMargin/MainContainer/TopRow/TopLeftBox/TopBar/WaterPanel/HBox/WaterProgressBar
@onready var water_label: Label = $RootMargin/MainContainer/TopRow/TopLeftBox/TopBar/WaterPanel/HBox/WaterLabel
@onready var weather_label: Label = $RootMargin/MainContainer/TopRow/TopLeftBox/TopBar/WeatherPanel/WeatherLabel
@onready var stats_label: Label = $RootMargin/MainContainer/TopRow/TopLeftBox/TopBar/StatsPanel/StatsLabel

@onready var toast_panel: PanelContainer = $RootMargin/MainContainer/TopRow/TopLeftBox/ToastPanel
@onready var toast_label: Label = $RootMargin/MainContainer/TopRow/TopLeftBox/ToastPanel/ToastLabel
@onready var well_prompt_panel: PanelContainer = $RootMargin/MainContainer/TopRow/TopLeftBox/WellPromptPanel

@onready var minimap_canvas: Control = $RootMargin/MainContainer/TopRow/MiniMapPanel/VBox/MiniMapCanvas

@onready var crosshair_control: Control = $CenterCrosshair
@onready var crosshair_reticle: Control = $CenterCrosshair/Reticle
@onready var injection_panel: PanelContainer = $CenterCrosshair/InjectionPanel
@onready var injection_bar: ProgressBar = $CenterCrosshair/InjectionPanel/VBox/InjectionBar

@onready var thermal_visor: Panel = $ThermalVisor

@onready var hover_panel: PanelContainer = $RootMargin/MainContainer/BottomRow/CellInfoPanel
@onready var cell_coords_label: Label = $RootMargin/MainContainer/BottomRow/CellInfoPanel/VBox/CoordsLabel
@onready var cell_stats_label: Label = $RootMargin/MainContainer/BottomRow/CellInfoPanel/VBox/CellStatsLabel
@onready var cell_risk_label: Label = $RootMargin/MainContainer/BottomRow/CellInfoPanel/VBox/RiskLabel

@onready var btn_sekat: Button = $RootMargin/MainContainer/BottomRow/ToolBar/BtnSekat
@onready var btn_semprot: Button = $RootMargin/MainContainer/BottomRow/ToolBar/BtnSemprot
@onready var btn_tombak: Button = $RootMargin/MainContainer/BottomRow/ToolBar/BtnTombak
@onready var btn_thermal: Button = $RootMargin/MainContainer/BottomRow/ToolBar/BtnThermal

var grid_simulator: GridSimulator
var player_node: Node3D
var toast_timer: float = 0.0
var minimap_timer: float = 0.0

func _ready() -> void:
	EventBus.water_changed.connect(_on_water_changed)
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.thermal_mode_toggled.connect(_on_thermal_mode_toggled)
	EventBus.cell_hovered.connect(_on_cell_hovered)
	EventBus.mission_stats_updated.connect(_on_mission_stats_updated)
	EventBus.educational_toast.connect(_on_educational_toast)
	EventBus.injection_progress_changed.connect(_on_injection_progress_changed)
	EventBus.well_proximity_changed.connect(_on_well_proximity_changed)
	EventBus.game_phase_changed.connect(_on_phase_changed)
	minimap_canvas.draw.connect(_on_minimap_draw)

	btn_sekat.pressed.connect(func() -> void: _select_tool(ToolEnums.ToolType.SEKAT_BAKAR))
	btn_semprot.pressed.connect(func() -> void: _select_tool(ToolEnums.ToolType.SEMPROT_PERMUKAAN))
	btn_tombak.pressed.connect(func() -> void: _select_tool(ToolEnums.ToolType.TOMBAK_GAMBUT))
	btn_thermal.pressed.connect(func() -> void: _toggle_thermal())

	_on_phase_changed(GameState.current_phase)
	_update_weather_display()
	_on_water_changed(GameState.current_water, GameState.max_water_capacity)
	_on_tool_selected(GameState.current_tool)

func setup_hud(simulator: GridSimulator, player: Node3D) -> void:
	grid_simulator = simulator
	player_node = player
	_update_weather_display()
	minimap_canvas.queue_redraw()

func _process(delta: float) -> void:
	if not visible:
		return
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_panel.visible = false
	minimap_timer += delta
	if minimap_timer >= 0.12:
		minimap_timer = 0.0
		minimap_canvas.queue_redraw()

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	visible = (new_phase == ToolEnums.GamePhase.ACTIVE_FPS)
	if visible:
		_update_weather_display()
		minimap_canvas.queue_redraw()

func _select_tool(tool_type: ToolEnums.ToolType) -> void:
	GameState.current_tool = tool_type
	EventBus.tool_selected.emit(tool_type)

func _toggle_thermal() -> void:
	GameState.is_thermal_active = not GameState.is_thermal_active
	EventBus.thermal_mode_toggled.emit(GameState.is_thermal_active)

func _on_water_changed(current: float, max_val: float) -> void:
	if water_progress_bar != null:
		water_progress_bar.max_value = max_val
		water_progress_bar.value = current
	if water_label != null:
		water_label.text = "Air: %d / %d L" % [int(current), int(max_val)]

func _on_tool_selected(tool_type: ToolEnums.ToolType) -> void:
	btn_sekat.button_pressed = (tool_type == ToolEnums.ToolType.SEKAT_BAKAR)
	btn_semprot.button_pressed = (tool_type == ToolEnums.ToolType.SEMPROT_PERMUKAAN)
	btn_tombak.button_pressed = (tool_type == ToolEnums.ToolType.TOMBAK_GAMBUT)

func _on_thermal_mode_toggled(enabled: bool) -> void:
	btn_thermal.text = "Thermal: ON [Tab]" if enabled else "Thermal: OFF [Tab]"
	thermal_visor.visible = enabled
	btn_thermal.modulate = Color(1.0, 0.45, 0.45) if enabled else Color.WHITE
	minimap_canvas.queue_redraw()

func _on_mission_stats_updated(burned: int, safe: int, active: int) -> void:
	if stats_label != null:
		var safe_pct: float = (float(safe) / maxf(1.0, float(GameState.total_cells))) * 100.0
		stats_label.text = "Hotspot: %d (Bara Dalam: %d) | Aman: %.0f%% | Hangus: %d" % [
			active, GameState.subsurface_only_cells, safe_pct, burned
		]

func _on_educational_toast(message: String, is_warning: bool) -> void:
	toast_label.text = message
	toast_panel.modulate = Color(1.0, 0.72, 0.42, 0.0) if is_warning else Color(0.55, 1.0, 0.70, 0.0)
	toast_panel.visible = true
	toast_timer = 5.5
	var tw: Tween = create_tween()
	tw.tween_property(toast_panel, "modulate:a", 1.0, 0.18)

func _on_injection_progress_changed(progress: float, is_active: bool) -> void:
	injection_panel.visible = is_active
	if is_active:
		injection_bar.value = progress * 100.0

func _on_well_proximity_changed(is_near_well: bool) -> void:
	well_prompt_panel.visible = is_near_well

func _on_cell_hovered(pos: Vector2i, cell: PeatCellData) -> void:
	if cell == null or pos == Vector2i(-1, -1):
		hover_panel.visible = false
		if crosshair_reticle != null:
			crosshair_reticle.modulate = Color(1.0, 1.0, 1.0, 0.88)
		return

	if crosshair_reticle != null:
		if cell.is_active_hazard():
			crosshair_reticle.modulate = Color(1.0, 0.48, 0.14, 1.0)
		elif cell.has_well:
			crosshair_reticle.modulate = Color(0.25, 0.88, 1.0, 1.0)
		else:
			crosshair_reticle.modulate = Color(1.0, 1.0, 1.0, 0.92)

	hover_panel.visible = true
	cell_coords_label.text = "Petak (%d, %d)" % [pos.x, pos.y]

	var moisture_pct: int = int(cell.soil_moisture * 100.0)
	var status_hazard: String = "Aman"
	if cell.has_well:
		status_hazard = "Sumur Air (Isi Ulang)"
	elif cell.is_burning() and cell.has_ember():
		status_hazard = "Api Permukaan + Bara Dalam!"
	elif cell.is_burning():
		status_hazard = "Api Permukaan!"
	elif cell.has_ember():
		status_hazard = "Bara Bawah Tanah!"
	elif cell.is_firebreak:
		status_hazard = "Parit Sekat Api"
	elif cell.is_burnt:
		status_hazard = "Bekas Terbakar"

	cell_stats_label.text = "Muka Air: %.1f cm | Lembap: %d%%\nKedalaman Gambut: %.1f m | %s" % [
		cell.water_table, moisture_pct, cell.peat_depth, status_hazard
	]

	var risk_str: String = PFVICalculator.get_risk_label(cell.risk_category)
	cell_risk_label.text = "PFVI: %.0f (%s)" % [cell.pfvi_score, risk_str]
	cell_risk_label.modulate = PFVICalculator.get_risk_color(cell.risk_category)

func _update_weather_display() -> void:
	if weather_label != null:
		weather_label.text = "Suhu: %.1f°C | Angin: %.0f km/h" % [
			GameState.ambient_temperature, GameState.wind_speed_kmh
		]

func _on_minimap_draw() -> void:
	if grid_simulator == null:
		return
	var sz: Vector2 = minimap_canvas.size
	var cw: float = sz.x / float(grid_simulator.grid_width)
	var ch: float = sz.y / float(grid_simulator.grid_height)

	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		var rect: Rect2 = Rect2(float(pos.x) * cw, float(pos.y) * ch, cw, ch)
		var col: Color = Color(0.18, 0.38, 0.20)
		if cell.has_well:
			col = Color(0.15, 0.72, 1.0)
		elif cell.is_firebreak:
			col = Color(0.45, 0.40, 0.35)
		elif cell.is_burning():
			col = Color(1.0, 0.45, 0.05)
		elif cell.has_ember():
			col = Color(1.0, 0.12, 0.12) if GameState.is_thermal_active else Color(0.35, 0.25, 0.18)
		elif cell.is_burnt:
			col = Color(0.12, 0.10, 0.09)
		elif GameState.is_thermal_active:
			col = PFVICalculator.get_risk_color(cell.risk_category) * 0.65
		minimap_canvas.draw_rect(rect, col, true)

	# Penanda lokasi pos yang wajib dilindungi; lingkaran berkedip saat terancam.
	var station_pos: Vector2 = Vector2(8.5 * cw, 1.5 * ch)
	minimap_canvas.draw_circle(station_pos, 5.0, Color(0.28, 1.0, 0.90) if GameState.station_safe else Color.RED)
	minimap_canvas.draw_arc(station_pos, 7.0, 0.0, TAU, 24, Color.WHITE, 1.5)
	# Penanda hotspot yang tampak di permukaan; bara tersembunyi hanya tampil saat Thermal.
	for pos in grid_simulator.cells.keys():
		var info: PeatCellData = grid_simulator.cells[pos]
		if info.is_burning() or (GameState.is_thermal_active and info.has_ember()):
			var marker: Vector2 = Vector2((float(pos.x) + 0.5) * cw, (float(pos.y) + 0.5) * ch)
			minimap_canvas.draw_arc(marker, minf(cw, ch) * 0.45, 0.0, TAU, 12, Color(1.0, 0.85, 0.20), 1.2)
	if player_node != null:
		var px: float = (player_node.global_position.x / GameState.CELL_SIZE + 0.5) * cw
		var pz: float = (player_node.global_position.z / GameState.CELL_SIZE + 0.5) * ch
		var p_vec: Vector2 = Vector2(clampf(px, 3.0, sz.x - 3.0), clampf(pz, 3.0, sz.y - 3.0))
		var fwd: Vector3 = -player_node.global_transform.basis.z
		var dir2: Vector2 = Vector2(fwd.x, fwd.z).normalized()
		minimap_canvas.draw_line(p_vec, p_vec + dir2 * 10.0, Color.CYAN, 2.0)
		minimap_canvas.draw_circle(p_vec, 4.0, Color.WHITE)
