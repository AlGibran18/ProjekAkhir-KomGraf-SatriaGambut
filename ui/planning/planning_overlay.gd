# ui/planning/planning_overlay.gd - Antarmuka Fase 1 (Rencana & Analisis): peta taktis PFVI interaktif, penempatan Sumur Air, dan transisi ke operasi FPS Satria Gambut.
class_name PlanningOverlay
extends Control

@onready var map_canvas: Control = $CenterPanel/HBox/MapPanel/MapCanvas
@onready var level_title_label: Label = $CenterPanel/HBox/InfoPanel/VBox/LevelTitleLabel
@onready var well_count_label: Label = $CenterPanel/HBox/InfoPanel/VBox/WellCountLabel
@onready var hover_info_label: Label = $CenterPanel/HBox/InfoPanel/VBox/HoverInfoLabel
@onready var weather_info_label: Label = $CenterPanel/HBox/InfoPanel/VBox/WeatherInfoLabel
@onready var btn_auto_well: Button = $CenterPanel/HBox/InfoPanel/VBox/BtnAutoWell
@onready var btn_start_ops: Button = $CenterPanel/HBox/InfoPanel/VBox/BtnStartOps
@onready var btn_back_menu: Button = $CenterPanel/HBox/InfoPanel/VBox/BtnBackMenu

var grid_simulator: GridSimulator
var hovered_grid_pos: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	map_canvas.draw.connect(_on_map_draw)
	map_canvas.gui_input.connect(_on_map_gui_input)
	btn_auto_well.pressed.connect(_on_auto_well_pressed)
	btn_start_ops.pressed.connect(_on_start_ops_pressed)
	btn_back_menu.pressed.connect(_on_back_menu_pressed)
	EventBus.well_placed.connect(_on_well_changed)
	EventBus.well_removed.connect(_on_well_changed)
	EventBus.game_phase_changed.connect(_on_phase_changed)

func setup_planning(simulator: GridSimulator) -> void:
	grid_simulator = simulator
	_refresh_info()
	map_canvas.queue_redraw()

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	visible = (new_phase == ToolEnums.GamePhase.PLANNING)
	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_info()
		map_canvas.queue_redraw()

func _on_well_changed(_pos: Vector2i) -> void:
	AudioManager.play_sfx("click")
	_refresh_info()
	map_canvas.queue_redraw()

func _on_auto_well_pressed() -> void:
	if grid_simulator != null:
		grid_simulator.auto_place_recommended_wells()

func _on_start_ops_pressed() -> void:
	AudioManager.play_sfx("click")
	if grid_simulator != null:
		grid_simulator.start_outbreak()

func _on_back_menu_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")

func _refresh_info() -> void:
	var cfg: Dictionary = GameState.LEVEL_CONFIGS[GameState.current_level_index]
	level_title_label.text = String(cfg["name"])
	well_count_label.text = "Sumur Air Terpasang: %d / %d" % [GameState.placed_wells.size(), GameState.max_wells_allowed]
	weather_info_label.text = "Suhu: %.1f°C | Hujan: %.0f mm\nAngin: %.0f km/h (Arah: %.1f, %.1f)" % [
		GameState.ambient_temperature,
		GameState.global_rainfall_rate,
		GameState.wind_speed_kmh,
		GameState.wind_direction.x,
		GameState.wind_direction.y
	]

func _on_map_gui_input(event: InputEvent) -> void:
	if grid_simulator == null:
		return
	var canvas_size: Vector2 = map_canvas.size
	var cell_w: float = canvas_size.x / float(grid_simulator.grid_width)
	var cell_h: float = canvas_size.y / float(grid_simulator.grid_height)

	if event is InputEventMouseMotion:
		var gx: int = int(floor(event.position.x / cell_w))
		var gy: int = int(floor(event.position.y / cell_h))
		var pos: Vector2i = Vector2i(gx, gy)
		if grid_simulator.cells.has(pos):
			hovered_grid_pos = pos
			var cell: PeatCellData = grid_simulator.get_cell_data(pos)
			hover_info_label.text = "Petak (%d, %d) — PFVI: %.0f (%s)\nMuka Air: %.0f cm | Kedalaman Gambut: %.1f m" % [
				pos.x, pos.y, cell.pfvi_score, PFVICalculator.get_risk_label(cell.risk_category),
				cell.water_table, cell.peat_depth
			]
			map_canvas.queue_redraw()

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var gx_click: int = int(floor(event.position.x / cell_w))
		var gy_click: int = int(floor(event.position.y / cell_h))
		grid_simulator.toggle_well_at(Vector2i(gx_click, gy_click))

func _on_map_draw() -> void:
	if grid_simulator == null:
		return
	var canvas_size: Vector2 = map_canvas.size
	var cell_w: float = canvas_size.x / float(grid_simulator.grid_width)
	var cell_h: float = canvas_size.y / float(grid_simulator.grid_height)

	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		var rect: Rect2 = Rect2(float(pos.x) * cell_w + 1.0, float(pos.y) * cell_h + 1.0, cell_w - 2.0, cell_h - 2.0)
		var col: Color = PFVICalculator.get_risk_color(cell.risk_category)
		map_canvas.draw_rect(rect, col, true)

		if cell.has_well:
			var center: Vector2 = rect.get_center()
			map_canvas.draw_circle(center, minf(cell_w, cell_h) * 0.38, Color(0.1, 0.72, 1.0, 1.0))
			map_canvas.draw_circle(center, minf(cell_w, cell_h) * 0.22, Color.WHITE)

	var spawn_rect: Rect2 = Rect2(float(grid_simulator.grid_width / 2) * cell_w + 2.0, 1.0 * cell_h + 2.0, cell_w - 4.0, cell_h - 4.0)
	map_canvas.draw_rect(spawn_rect, Color.CYAN, false, 2.5)

	if hovered_grid_pos != Vector2i(-1, -1):
		var h_rect: Rect2 = Rect2(float(hovered_grid_pos.x) * cell_w, float(hovered_grid_pos.y) * cell_h, cell_w, cell_h)
		map_canvas.draw_rect(h_rect, Color.WHITE, false, 2.5)
