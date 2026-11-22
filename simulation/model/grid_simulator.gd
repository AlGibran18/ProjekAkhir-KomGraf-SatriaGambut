# simulation/model/grid_simulator.gd - Engine Cellular Automata perambatan api permukaan, bara bawah tanah, re-ignition, penempatan sumur air, dan kondisi menang/kalah Satria Gambut.
class_name GridSimulator
extends Node

@export var grid_width: int = 16
@export var grid_height: int = 16
@export var tick_interval_sec: float = 1.6

var cells: Dictionary = {}
var tick_timer: float = 0.0
var outbreak_started: bool = false
var warned_subsurface_once: bool = false
var warned_empty_water_once: bool = false
var active_injection_pos: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	EventBus.cell_clicked.connect(_on_cell_clicked)

func _process(delta: float) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	GameState.mission_elapsed_sec += delta
	tick_timer += delta
	if tick_timer >= tick_interval_sec:
		tick_timer = 0.0
		_simulate_tick()

func initialize_level(level_idx: int) -> void:
	GameState.load_level_config(level_idx)
	GameState.total_cells = grid_width * grid_height
	outbreak_started = false
	warned_subsurface_once = false
	warned_empty_water_once = false
	active_injection_pos = Vector2i(-1, -1)
	tick_timer = 0.0
	cells.clear()

	var center_hazard: Vector2 = Vector2(float(grid_width) * 0.56, float(grid_height) * 0.62)
	for y in range(grid_height):
		for x in range(grid_width):
			var pos: Vector2i = Vector2i(x, y)
			var cell: PeatCellData = PeatCellData.new()
			cell.grid_pos = pos

			var dist_hazard: float = Vector2(float(x), float(y)).distance_to(center_hazard)
			var wave_a: float = sin(float(x) * 0.45 + float(level_idx)) * cos(float(y) * 0.40)
			var wave_b: float = cos(float(x - y) * 0.35)
			var dryness: float = clampf(1.0 - (dist_hazard / 8.5) + (wave_a * 0.16), 0.0, 1.0)

			if y <= 2:
				dryness = clampf(dryness * 0.45, 0.0, 0.45)

			cell.water_table = lerpf(-12.0, -76.0, dryness)
			cell.soil_moisture = lerpf(0.62, 0.10, dryness)
			cell.temperature = GameState.ambient_temperature + (wave_b * 1.5)
			cell.rainfall = GameState.global_rainfall_rate
			cell.peat_depth = clampf(1.2 + (dryness * 1.3) + (wave_a * 0.3), 0.8, 2.8)
			cell.carbon_tons = cell.peat_depth * 8.5
			cell.recalculate_pfvi()

			cells[pos] = cell
			EventBus.cell_state_updated.emit(pos, cell)

	_update_stats()

func toggle_well_at(pos: Vector2i) -> bool:
	if not cells.has(pos):
		return false
	var cell: PeatCellData = cells[pos]
	if cell.has_well:
		cell.has_well = false
		GameState.placed_wells.erase(pos)
		EventBus.well_removed.emit(pos)
		EventBus.cell_state_updated.emit(pos, cell)
		return true

	if GameState.placed_wells.size() >= GameState.max_wells_allowed:
		EventBus.educational_toast.emit("Maksimal %d Sumur Air! Klik sumur lama untuk memindahkannya." % GameState.max_wells_allowed, true)
		return false

	cell.has_well = true
	cell.water_table = -10.0
	cell.soil_moisture = 0.85
	cell.recalculate_pfvi()
	GameState.placed_wells.append(pos)
	EventBus.well_placed.emit(pos)
	EventBus.cell_state_updated.emit(pos, cell)
	return true

func auto_place_recommended_wells() -> void:
	var existing: Array[Vector2i] = GameState.placed_wells.duplicate()
	for old_pos in existing:
		toggle_well_at(old_pos)

	var candidates: Array[Vector2i] = [
		Vector2i(4, 5),
		Vector2i(11, 5),
		Vector2i(4, 11)
	]
	for idx in range(mini(GameState.max_wells_allowed, candidates.size())):
		toggle_well_at(candidates[idx])

func start_outbreak() -> void:
	if GameState.placed_wells.is_empty():
		auto_place_recommended_wells()

	var ranked_cells: Array[PeatCellData] = []
	for pos in cells.keys():
		var cell: PeatCellData = cells[pos]
		if pos.y >= 5 and not cell.has_well and not cell.is_firebreak:
			ranked_cells.append(cell)

	ranked_cells.sort_custom(func(a: PeatCellData, b: PeatCellData) -> bool: return a.pfvi_score > b.pfvi_score)

	var spawned: int = 0
	var chosen_positions: Array[Vector2i] = []
	for candidate in ranked_cells:
		if spawned >= GameState.initial_fires_count:
			break
		var too_close: bool = false
		for cp in chosen_positions:
			if candidate.grid_pos.distance_to(cp) < 2.2:
				too_close = true
				break
		if too_close:
			continue
		candidate.ignite(90.0, 80.0)
		chosen_positions.append(candidate.grid_pos)
		EventBus.cell_state_updated.emit(candidate.grid_pos, candidate)
		EventBus.fire_ignited.emit(candidate.grid_pos)
		spawned += 1

	outbreak_started = true
	GameState.set_game_phase(ToolEnums.GamePhase.ACTIVE_FPS)
	_update_stats()
	EventBus.educational_toast.emit("WABAH KEBAKARAN! Gunakan [1] Sekat Bakar, [2] Semprot, [Tab] Thermal, dan [3] Tombak Gambut!", false)

func _simulate_tick() -> void:
	var pending_ignitions: Array[Vector2i] = []
	var pending_ember_spreads: Array[Vector2i] = []

	for pos in cells.keys():
		var cell: PeatCellData = cells[pos]
		if not cell.is_active_hazard():
			continue

		if cell.is_burning():
			cell.soil_moisture = maxf(0.05, cell.soil_moisture - 0.015)
			cell.water_table = maxf(-80.0, cell.water_table - 0.4)
			cell.recalculate_pfvi()

			var neighbors: Array[Vector2i] = _get_neighbors(pos)
			for n_pos in neighbors:
				var n_cell: PeatCellData = cells[n_pos]
				if n_cell.is_firebreak or n_cell.has_well or n_cell.is_burning():
					continue

				var wind_offset: Vector2 = Vector2(n_pos - pos).normalized()
				var wind_alignment: float = maxf(0.0, wind_offset.dot(GameState.wind_direction))
				var risk_factor: float = clampf(n_cell.pfvi_score / 300.0, 0.0, 1.0)
				var base_chance: float = (0.03 + (wind_alignment * 0.14) + (risk_factor * 0.14)) * GameState.spread_multiplier

				if n_cell.soil_moisture < 0.42 and randf() < base_chance:
					pending_ignitions.append(n_pos)

		if cell.has_ember():
			cell.soil_moisture = maxf(0.04, cell.soil_moisture - 0.010)
			if cell.surface_fire <= 0.0 and cell.soil_moisture < 0.22 and randf() < (0.14 * GameState.spread_multiplier):
				cell.surface_fire = 55.0
				EventBus.cell_state_updated.emit(pos, cell)
				EventBus.educational_toast.emit("RE-IGNITION! Bara bawah gambut di petak (%d, %d) menyala kembali ke permukaan!" % [pos.x, pos.y], true)

			var neighbors_sub: Array[Vector2i] = _get_neighbors(pos)
			for sub_pos in neighbors_sub:
				var sub_cell: PeatCellData = cells[sub_pos]
				if sub_cell.has_ember() or sub_cell.is_firebreak or sub_cell.has_well:
					continue
				if sub_cell.soil_moisture < 0.28 and randf() < (0.06 * GameState.spread_multiplier):
					pending_ember_spreads.append(sub_pos)

	for ignite_pos in pending_ignitions:
		if cells.has(ignite_pos):
			var target: PeatCellData = cells[ignite_pos]
			if not target.is_burning():
				target.ignite(80.0, 65.0)
				EventBus.cell_state_updated.emit(ignite_pos, target)
				EventBus.fire_ignited.emit(ignite_pos)

	for ember_pos in pending_ember_spreads:
		if cells.has(ember_pos):
			var target_sub: PeatCellData = cells[ember_pos]
			if not target_sub.has_ember():
				target_sub.subsurface_ember = 55.0
				EventBus.cell_state_updated.emit(ember_pos, target_sub)

	_update_stats()
	_check_mission_outcome()

func _get_neighbors(center: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1)
	]
	for offset in offsets:
		var target: Vector2i = center + offset
		if cells.has(target):
			result.append(target)
	return result

func _on_cell_clicked(pos: Vector2i) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if not cells.has(pos):
		return

	var cell: PeatCellData = cells[pos]
	if GameState.current_tool == ToolEnums.ToolType.SEKAT_BAKAR:
		if cell.make_firebreak():
			EventBus.cell_state_updated.emit(pos, cell)
			EventBus.tool_action_performed.emit(ToolEnums.ToolType.SEKAT_BAKAR, pos)
			_update_stats()
		elif cell.is_burning():
			EventBus.educational_toast.emit("Tidak bisa menggali parit saat api berkobar! Semprot [2] dahulu.", true)

func apply_continuous_tool(pos: Vector2i, tool: ToolEnums.ToolType, delta: float) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		cancel_injection()
		return
	if not cells.has(pos):
		cancel_injection()
		return

	var cell: PeatCellData = cells[pos]

	if tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN:
		cancel_injection()
		if not GameState.consume_water(26.0 * delta):
			if not warned_empty_water_once:
				warned_empty_water_once = true
				EventBus.educational_toast.emit("Air habis! Mendekatlah ke Sumur Air biru di peta untuk mengisi ulang.", true)
			return
		warned_empty_water_once = false
		EventBus.tool_action_performed.emit(ToolEnums.ToolType.SEMPROT_PERMUKAAN, pos)
		var surface_out_ember_remains: bool = cell.apply_surface_spray(85.0 * delta)
		EventBus.cell_state_updated.emit(pos, cell)
		if surface_out_ember_remains and not warned_subsurface_once:
			warned_subsurface_once = true
			EventBus.educational_toast.emit("Api permukaan padam, tapi bara masih aktif di kedalaman %.1f m! Tekan [Tab] Thermal & gunakan [3] Tombak Gambut!" % cell.peat_depth, true)
		_update_stats()
		_check_mission_outcome()

	elif tool == ToolEnums.ToolType.TOMBAK_GAMBUT:
		if not cell.has_ember() and not cell.is_burning():
			cancel_injection()
			return
		if not GameState.consume_water(32.0 * delta):
			cancel_injection()
			if not warned_empty_water_once:
				warned_empty_water_once = true
				EventBus.educational_toast.emit("Air habis! Isi ulang di Sumur Air terdekat.", true)
			return
		warned_empty_water_once = false
		active_injection_pos = pos
		var finished: bool = cell.apply_peat_spear(0.65 * delta)
		EventBus.injection_progress_changed.emit(cell.injection_progress, not finished)
		EventBus.cell_state_updated.emit(pos, cell)
		if finished:
			active_injection_pos = Vector2i(-1, -1)
			EventBus.steam_burst_requested.emit(pos)
			EventBus.educational_toast.emit("Injeksi air sukses! Bara di bawah tanah petak (%d, %d) padam tuntas." % [pos.x, pos.y], false)
		_update_stats()
		_check_mission_outcome()
	else:
		cancel_injection()

func cancel_injection() -> void:
	if active_injection_pos != Vector2i(-1, -1):
		if cells.has(active_injection_pos):
			var c: PeatCellData = cells[active_injection_pos]
			c.injection_progress = 0.0
		active_injection_pos = Vector2i(-1, -1)
	EventBus.injection_progress_changed.emit(0.0, false)

func _update_stats() -> void:
	var active_fires: int = 0
	var subsurface_only: int = 0
	var burned_count: int = 0
	var safe_count: int = 0
	var carbon_saved: float = 0.0
	var carbon_released: float = 0.0

	for pos in cells.keys():
		var cell: PeatCellData = cells[pos]
		if cell.is_active_hazard():
			active_fires += 1
			carbon_released += cell.carbon_tons * 0.6
			if not cell.is_burning() and cell.has_ember():
				subsurface_only += 1
		elif cell.is_burnt:
			burned_count += 1
			carbon_released += cell.carbon_tons * 0.35
			carbon_saved += cell.carbon_tons * 0.65
		else:
			safe_count += 1
			carbon_saved += cell.carbon_tons

	GameState.active_fire_cells = active_fires
	GameState.subsurface_only_cells = subsurface_only
	GameState.burned_cells = burned_count
	GameState.safe_cells = safe_count
	GameState.carbon_saved_tons = carbon_saved
	GameState.carbon_released_tons = carbon_released
	EventBus.mission_stats_updated.emit(burned_count, safe_count, active_fires)

func _check_mission_outcome() -> void:
	if not outbreak_started or GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if GameState.active_fire_cells == 0:
		cancel_injection()
		GameState.set_game_phase(ToolEnums.GamePhase.VICTORY)
	elif (GameState.burned_cells + GameState.active_fire_cells) > int(float(GameState.total_cells) * 0.50):
		cancel_injection()
		GameState.set_game_phase(ToolEnums.GamePhase.DEFEAT)

func get_cell_data(pos: Vector2i) -> PeatCellData:
	return cells.get(pos, null)
