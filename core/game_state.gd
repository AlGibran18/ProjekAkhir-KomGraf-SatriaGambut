# core/game_state.gd - Autoload penyimpan status global, konfigurasi level, stok air, cuaca, fase simulasi, dan pengaturan grafis Satria Gambut.
extends Node

enum GraphicsQuality {
	LOW,
	MEDIUM,
	HIGH
}

const CELL_SIZE: float = 3.0

const LEVEL_CONFIGS: Array[Dictionary] = [
	{
		"name": "Level 1 — Bara Tersembunyi (Tutorial)",
		"description": "Gambut dangkal risiko sedang-tinggi. Pelajari beda semprot permukaan dan tombak injeksi gambut.",
		"temperature": 33.0,
		"rainfall": 2.0,
		"wind_speed": 10.0,
		"wind_dir": Vector2(1.0, 0.25),
		"max_wells": 2,
		"water_capacity": 600.0,
		"initial_fires": 2,
		"spread_multiplier": 0.65
	},
	{
		"name": "Level 2 — Sabangau Kritis (PFVI 282)",
		"description": "Terinspirasi kasus Sabangau. Gambut sangat kering dengan bara bawah permukaan hingga 2,5 meter.",
		"temperature": 35.0,
		"rainfall": 0.0,
		"wind_speed": 16.0,
		"wind_dir": Vector2(0.85, 0.5),
		"max_wells": 2,
		"water_capacity": 500.0,
		"initial_fires": 3,
		"spread_multiplier": 1.0
	},
	{
		"name": "Level 3 — Musim El Niño (Ekstrem)",
		"description": "Kemarau ekstrem tanpa hujan, angin kencang, dan gambut tebal penyimpan karbon masif.",
		"temperature": 37.5,
		"rainfall": 0.0,
		"wind_speed": 22.0,
		"wind_dir": Vector2(0.7, 0.7),
		"max_wells": 3,
		"water_capacity": 450.0,
		"initial_fires": 4,
		"spread_multiplier": 1.25
	}
]

var current_graphics_quality: GraphicsQuality = GraphicsQuality.MEDIUM
var current_level_index: int = 0
var current_phase: ToolEnums.GamePhase = ToolEnums.GamePhase.PLANNING

var max_water_capacity: float = 500.0
var current_water: float = 500.0
var current_tool: ToolEnums.ToolType = ToolEnums.ToolType.SEMPROT_PERMUKAAN
var is_thermal_active: bool = false

var wind_direction: Vector2 = Vector2(1.0, 0.2).normalized()
var wind_speed_kmh: float = 14.0
var ambient_temperature: float = 34.5
var global_rainfall_rate: float = 0.0
var spread_multiplier: float = 1.0
var initial_fires_count: int = 2

var placed_wells: Array[Vector2i] = []
var max_wells_allowed: int = 2

var mouse_sensitivity: float = 0.0022
var master_volume: float = 0.8

var total_cells: int = 256
var burned_cells: int = 0
var safe_cells: int = 256
var active_fire_cells: int = 0
var subsurface_only_cells: int = 0
var mission_elapsed_sec: float = 0.0
var water_used_total: float = 0.0
var carbon_saved_tons: float = 0.0
var carbon_released_tons: float = 0.0

func _ready() -> void:
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.thermal_mode_toggled.connect(_on_thermal_mode_toggled)
	load_level_config(0)

func load_level_config(level_idx: int) -> void:
	current_level_index = clampi(level_idx, 0, LEVEL_CONFIGS.size() - 1)
	var cfg: Dictionary = LEVEL_CONFIGS[current_level_index]
	ambient_temperature = float(cfg["temperature"])
	global_rainfall_rate = float(cfg["rainfall"])
	wind_speed_kmh = float(cfg["wind_speed"])
	wind_direction = (cfg["wind_dir"] as Vector2).normalized()
	max_wells_allowed = int(cfg["max_wells"])
	max_water_capacity = float(cfg["water_capacity"])
	initial_fires_count = int(cfg["initial_fires"])
	spread_multiplier = float(cfg["spread_multiplier"])
	reset_mission_state()

func reset_mission_state() -> void:
	current_water = max_water_capacity
	current_tool = ToolEnums.ToolType.SEMPROT_PERMUKAAN
	is_thermal_active = false
	placed_wells.clear()
	burned_cells = 0
	safe_cells = total_cells
	active_fire_cells = 0
	subsurface_only_cells = 0
	mission_elapsed_sec = 0.0
	water_used_total = 0.0
	carbon_saved_tons = 0.0
	carbon_released_tons = 0.0
	current_phase = ToolEnums.GamePhase.PLANNING
	EventBus.water_changed.emit(current_water, max_water_capacity)
	EventBus.tool_selected.emit(current_tool)
	EventBus.thermal_mode_toggled.emit(false)

func set_game_phase(new_phase: ToolEnums.GamePhase) -> void:
	current_phase = new_phase
	EventBus.game_phase_changed.emit(new_phase)

func _on_tool_selected(tool_type: ToolEnums.ToolType) -> void:
	current_tool = tool_type

func _on_thermal_mode_toggled(enabled: bool) -> void:
	is_thermal_active = enabled

func consume_water(amount: float) -> bool:
	if current_water >= amount:
		current_water -= amount
		water_used_total += amount
		EventBus.water_changed.emit(current_water, max_water_capacity)
		return true
	elif current_water > 0.0:
		water_used_total += current_water
		current_water = 0.0
		EventBus.water_changed.emit(current_water, max_water_capacity)
	return false

func refill_water(amount: float) -> bool:
	if current_water >= max_water_capacity:
		return false
	current_water = minf(max_water_capacity, current_water + amount)
	EventBus.water_changed.emit(current_water, max_water_capacity)
	return true

func set_graphics_quality(quality: GraphicsQuality) -> void:
	current_graphics_quality = quality
	var vp_rid: RID = get_viewport().get_viewport_rid()
	match quality:
		GraphicsQuality.LOW:
			RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_DISABLED)
		GraphicsQuality.MEDIUM:
			RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_2X)
		GraphicsQuality.HIGH:
			RenderingServer.viewport_set_msaa_3d(vp_rid, RenderingServer.VIEWPORT_MSAA_4X)
	EventBus.graphics_quality_changed.emit(int(quality))

func set_master_volume(vol: float) -> void:
	master_volume = clampf(vol, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, master_volume)))
	AudioServer.set_bus_mute(0, master_volume <= 0.001)
