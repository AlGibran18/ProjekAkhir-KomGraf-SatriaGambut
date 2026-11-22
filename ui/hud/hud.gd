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
var proximity_timer: float = 0.0
var danger_strength: float = 0.0
var danger_overlay: ColorRect
var expanded_map: Control
var expanded_map_canvas: Control
var map_is_open: bool = false
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	# Subtle full-screen danger tint rendered behind the existing HUD widgets.
	danger_overlay = ColorRect.new()
	danger_overlay.name = "ProximityFireWarning"
	danger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_overlay.color = Color(0.85, 0.08, 0.025, 0.0)
	add_child(danger_overlay)
	move_child(danger_overlay, 0)
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
	_create_expanded_map()

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
	proximity_timer += delta
	if proximity_timer >= 0.25:
		proximity_timer = 0.0
		_calculate_fire_proximity()
	var pulse: float = 0.86 + sin(Time.get_ticks_msec() * 0.006) * 0.14
	danger_overlay.color = Color(0.85, 0.08, 0.025, clampf(danger_strength * pulse * 0.10, 0.0, 0.10))
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast_panel.visible = false
	if map_is_open and expanded_map_canvas != null:
		expanded_map_canvas.queue_redraw()
	minimap_timer += delta
	if minimap_timer >= 0.12:
		minimap_timer = 0.0
		minimap_canvas.queue_redraw()

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	if new_phase != ToolEnums.GamePhase.ACTIVE_FPS and map_is_open:
		_toggle_map(false)
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

func _input(event: InputEvent) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_map(not map_is_open)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and map_is_open:
			_toggle_map(false)
			get_viewport().set_input_as_handled()

func _toggle_map(open: bool) -> void:
	map_is_open = open
	if expanded_map != null:
		expanded_map.visible = open
	if player_node is PlayerController3D:
		var player: PlayerController3D = player_node as PlayerController3D
		player.tactical_map_open = open
	if open:
		previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS:
			Input.mouse_mode = previous_mouse_mode

func _create_expanded_map() -> void:
	expanded_map = Control.new()
	expanded_map.name = "ExpandedTacticalMap"
	expanded_map.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(expanded_map)
	expanded_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.012, 0.03, 0.037, 0.91)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	expanded_map.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body: VBoxContainer = VBoxContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	body.grow_horizontal = Control.GROW_DIRECTION_BOTH
	body.grow_vertical = Control.GROW_DIRECTION_BOTH
	body.custom_minimum_size = Vector2(570.0, 605.0)
	expanded_map.add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	body.add_theme_constant_override("separation", 8)
	var title: Label = Label.new()
	title.text = "PETA OPERASI  /  SATRIA GAMBUT"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color(0.32, 0.93, 0.80))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var info: Label = Label.new()
	info.text = "M / ESC: Tutup  |  Kuning: Api  |  Biru: Sumur  |  Hijau: Pos"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 13)
	body.add_child(info)
	expanded_map_canvas = Control.new()
	expanded_map_canvas.name = "FullMapCanvas"
	expanded_map_canvas.custom_minimum_size = Vector2(520.0, 520.0)
	expanded_map_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	expanded_map_canvas.draw.connect(_draw_expanded_map)
	body.add_child(expanded_map_canvas)
	var footer: Label = Label.new()
	footer.text = "LIVE GPS SIMULASI • N = UTARA • BARA TERSEMBUNYI HANYA TAMPIL SAAT THERMAL"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 12)
	body.add_child(footer)
	expanded_map.visible = false

func _draw_expanded_map() -> void:
	if expanded_map_canvas != null:
		_draw_radar(expanded_map_canvas, true)

func _on_minimap_draw() -> void:
	_draw_radar(minimap_canvas, false)

func _draw_radar(canvas: Control, expanded: bool) -> void:
	if grid_simulator == null:
		return
	var sz: Vector2 = canvas.size
	if sz.x < 2.0 or sz.y < 2.0:
		return
	var width: int = grid_simulator.grid_width
	var height: int = grid_simulator.grid_height
	var cell_w: float = sz.x / float(width)
	var cell_h: float = sz.y / float(height)
	var dark: Color = Color(0.035, 0.095, 0.115, 1.0)
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), dark, true)
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		var rect: Rect2 = Rect2(Vector2(float(pos.x) * cell_w, float(pos.y) * cell_h), Vector2(cell_w + 0.4, cell_h + 0.4))
		var color: Color = Color(0.16, 0.32, 0.27) if (pos.x + pos.y) % 3 != 0 else Color(0.13, 0.29, 0.25)
		if cell.is_firebreak:
			color = Color(0.39, 0.34, 0.25)
		elif cell.is_burnt:
			color = Color(0.16, 0.12, 0.105)
		elif cell.is_burning():
			color = Color(0.72, 0.23, 0.10)
		elif GameState.is_thermal_active:
			color = PFVICalculator.get_risk_color(cell.risk_category) * 0.63
		canvas.draw_rect(rect, color, true)
	# Subtle roads-like navigation grid; unlike real roads this represents 3m survey cells.
	var line_color: Color = Color(0.50, 0.71, 0.65, 0.16)
	for x in range(0, width + 1, 4):
		var xx: float = float(x) * cell_w
		canvas.draw_line(Vector2(xx, 0), Vector2(xx, sz.y), line_color, 1.0)
	for y in range(0, height + 1, 4):
		var yy: float = float(y) * cell_h
		canvas.draw_line(Vector2(0, yy), Vector2(sz.x, yy), line_color, 1.0)
	var station: Vector2 = Vector2(8.5 * cell_w, 1.5 * cell_h)
	canvas.draw_circle(station, 9.0 if expanded else 4.7, Color(0.18, 0.95, 0.71) if GameState.station_safe else Color(0.98, 0.28, 0.25))
	canvas.draw_arc(station, 13.0 if expanded else 7.0, 0.0, TAU, 24, Color.WHITE, 1.5)
	for well in GameState.placed_wells:
		var wp: Vector2 = Vector2((float(well.x) + 0.5) * cell_w, (float(well.y) + 0.5) * cell_h)
		canvas.draw_circle(wp, 7.0 if expanded else 3.5, Color(0.20, 0.75, 1.0))
		canvas.draw_arc(wp, 10.0 if expanded else 5.5, 0.0, TAU, 16, Color(0.70, 0.95, 1.0), 1.0)
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		if not cell.is_burning() and not (GameState.is_thermal_active and cell.has_ember()):
			continue
		var at: Vector2 = Vector2((float(pos.x) + 0.5) * cell_w, (float(pos.y) + 0.5) * cell_h)
		var radius: float = 6.4 if expanded else 3.0
		var fire_color: Color = Color(1.0, 0.75, 0.18) if cell.is_burning() else Color(0.98, 0.26, 0.43)
		canvas.draw_circle(at, radius, fire_color)
		canvas.draw_arc(at, radius * 1.65, 0.0, TAU, 20, fire_color * Color(1, 1, 1, 0.55), 1.3)
	if player_node != null:
		var cx: float = (player_node.global_position.x / GameState.CELL_SIZE + 0.5) * cell_w
		var cy: float = (player_node.global_position.z / GameState.CELL_SIZE + 0.5) * cell_h
		var player_pos: Vector2 = Vector2(clampf(cx, 3.0, sz.x - 3.0), clampf(cy, 3.0, sz.y - 3.0))
		var basis: Vector3 = -player_node.global_transform.basis.z
		var heading: Vector2 = Vector2(basis.x, basis.z).normalized()
		var perpendicular: Vector2 = Vector2(-heading.y, heading.x)
		var scale: float = 12.0 if expanded else 7.0
		var arrow: PackedVector2Array = PackedVector2Array([
			player_pos + heading * scale,
			player_pos - heading * scale * 0.60 + perpendicular * scale * 0.50,
			player_pos - heading * scale * 0.60 - perpendicular * scale * 0.50
		])
		canvas.draw_colored_polygon(arrow, Color(0.96, 0.98, 0.97))
		canvas.draw_arc(player_pos, scale * 1.40, 0.0, TAU, 24, Color(0.51, 1.0, 0.94, 0.50), 1.0)
	# Animated scanning sweep / compass rings for a modern tactical-radar look.
	# All markers remain grounded in the real 16x16 game grid.
	if player_node != null:
		var radar_center: Vector2 = Vector2(
			clampf((player_node.global_position.x / GameState.CELL_SIZE + 0.5) * cell_w, 3.0, sz.x - 3.0),
			clampf((player_node.global_position.z / GameState.CELL_SIZE + 0.5) * cell_h, 3.0, sz.y - 3.0)
		)
		var radius_unit: float = minf(sz.x, sz.y) * (0.15 if expanded else 0.22)
		for ring_idx in range(1, 4):
			canvas.draw_arc(radar_center, radius_unit * float(ring_idx) / 2.0, 0.0, TAU, 40, Color(0.16, 0.91, 0.79, 0.18), 1.0)
		var angle: float = float(Time.get_ticks_msec()) * 0.0006
		var beam: Vector2 = Vector2(cos(angle), sin(angle)) * radius_unit * 1.5
		canvas.draw_line(radar_center, radar_center + beam, Color(0.19, 0.98, 0.79, 0.23), 2.0)
	if not GameState.station_safe:
		var alarm_phase: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.010)
		canvas.draw_arc(station, (18.0 if expanded else 10.0) + alarm_phase * 4.0, 0.0, TAU, 36, Color(1.0, 0.24, 0.18, 0.25 + alarm_phase * 0.60), 2.0)
	# Corner brackets mimic ruggedized rescue-team GPS/radar displays.
	var corner: float = 18.0 if expanded else 9.0
	var bracket_color: Color = Color(0.52, 0.98, 0.84, 0.85)
	for flip_x in [0.0, 1.0]:
		for flip_y in [0.0, 1.0]:
			var base: Vector2 = Vector2(flip_x * sz.x, flip_y * sz.y)
			var sx: float = 1.0 if flip_x == 0.0 else -1.0
			var sy: float = 1.0 if flip_y == 0.0 else -1.0
			canvas.draw_line(base, base + Vector2(sx * corner, 0), bracket_color, 2.8)
			canvas.draw_line(base, base + Vector2(0, sy * corner), bracket_color, 2.8)
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.20, 0.86, 0.73, 0.85), false, 2.0)
	if expanded:
		var font: Font = ThemeDB.fallback_font
		canvas.draw_string(font, Vector2(14, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.91, 0.97, 0.90))
		canvas.draw_string(font, Vector2(14, sz.y - 12), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.91, 0.97, 0.90))

# Read-only visual feedback: no health, damage or game-rule changes.
# Only visible surface fire triggers this warning; underground embers remain hidden.
func _calculate_fire_proximity() -> void:
	if player_node == null or grid_simulator == null:
		danger_strength = 0.0
		return
	var player_pos: Vector2 = Vector2(player_node.global_position.x, player_node.global_position.z)
	var min_distance: float = INF
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		if not cell.is_burning():
			continue
		var world_pos: Vector2 = Vector2(float(pos.x), float(pos.y)) * GameState.CELL_SIZE
		min_distance = minf(min_distance, player_pos.distance_to(world_pos))
	danger_strength = clampf((9.0 - min_distance) / 7.0, 0.0, 1.0)
