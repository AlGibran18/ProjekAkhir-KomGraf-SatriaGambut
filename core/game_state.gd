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
# Cadangan air masing-masing sumur, dalam liter.
var well_reserves: Dictionary = {}
const WELL_MAX_RESERVE: float = 1250.0
const WELL_INFLUENCE_RADIUS: float = 2.8
var station_safe: bool = true
var mission_score: int = 0
var mission_medal: String = "-"
var initial_carbon_tons: float = 0.0
var mission_notes: String = ""
var last_new_record: bool = false
const RECORDS_PATH: String = "user://satria_gambut_records.cfg"
const DISPLAY_SETTINGS_PATH: String = "user://satria_gambut_display.cfg"
const OUTFIT_PATH: String = "user://satria_gambut_outfit.cfg"
const UNIFORM_NAMES: Array[String] = ["Merah Rescue", "Oranye Satgas", "Hijau Rimba", "Biru Operasi"]
const UNIFORM_COLORS: Array[Color] = [
	Color(0.77, 0.12, 0.10), Color(0.96, 0.38, 0.07),
	Color(0.15, 0.39, 0.25), Color(0.13, 0.34, 0.68)
]
const HELMET_NAMES: Array[String] = ["Merah Rescue", "Kuning Safety", "Hitam Taktis", "Putih Komando"]
const HELMET_COLORS: Array[Color] = [
	Color(0.86, 0.12, 0.13), Color(1.0, 0.72, 0.12),
	Color(0.08, 0.12, 0.13), Color(0.90, 0.93, 0.90)
]
var uniform_index: int = 0
var helmet_index: int = 1
var fullscreen_enabled: bool = false
var _display_initialized: bool = false
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
	_load_display_settings()
	_load_outfit()

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
	well_reserves.clear()
	station_safe = true
	mission_score = 0
	mission_medal = "-"
	initial_carbon_tons = 0.0
	mission_notes = ""
	last_new_record = false
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

# Air cadangan di sumur benar-benar berkurang ketika pemain mengisi tangki.
func refill_from_well(pos: Vector2i, amount: float) -> float:
	if not well_reserves.has(pos):
		return 0.0
	var transferred: float = minf(amount, maxf(0.0, max_water_capacity - current_water))
	transferred = minf(transferred, float(well_reserves[pos]))
	if transferred <= 0.0:
		return 0.0
	well_reserves[pos] = float(well_reserves[pos]) - transferred
	refill_water(transferred)
	return transferred

# Rekor lokal tersimpan antar sesi; tidak memerlukan koneksi atau akun.
func get_best_record(level_idx: int) -> Dictionary:
	var config: ConfigFile = ConfigFile.new()
	if config.load(RECORDS_PATH) != OK:
		return {}
	var section: String = "level_%d" % level_idx
	if not config.has_section(section):
		return {}
	return {
		"score": int(config.get_value(section, "score", 0)),
		"time": float(config.get_value(section, "time", 0.0)),
		"medal": String(config.get_value(section, "medal", "-"))
	}

func save_best_record() -> bool:
	last_new_record = false
	var old: Dictionary = get_best_record(current_level_index)
	# Tingkatkan rekor hanya jika skor lebih tinggi, atau skor sama dan waktu lebih singkat.
	if not old.is_empty():
		var old_score: int = int(old.get("score", 0))
		var old_time: float = float(old.get("time", INF))
		if mission_score < old_score or (mission_score == old_score and mission_elapsed_sec >= old_time):
			return false
	var config: ConfigFile = ConfigFile.new()
	config.load(RECORDS_PATH)
	var section: String = "level_%d" % current_level_index
	config.set_value(section, "score", mission_score)
	config.set_value(section, "time", mission_elapsed_sec)
	config.set_value(section, "medal", mission_medal)
	var result: Error = config.save(RECORDS_PATH)
	if result != OK:
		push_warning("Gagal menyimpan rekor lokal: %d" % result)
		return false
	last_new_record = true
	return true

# Fullscreen is a true OS window mode, not just resizing the game canvas.
# F11 works both from the main menu and during FPS gameplay.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		set_fullscreen(not fullscreen_enabled)
		get_viewport().set_input_as_handled()

func set_fullscreen(enabled: bool) -> void:
	fullscreen_enabled = enabled
	_display_initialized = false
	# Switch only after the triggering UI event completes.
	call_deferred("_apply_saved_display")
	var config: ConfigFile = ConfigFile.new()
	config.set_value("display", "fullscreen", enabled)
	var save_result: Error = config.save(DISPLAY_SETTINGS_PATH)
	if save_result != OK:
		push_warning("Pengaturan layar gagal disimpan: %d" % save_result)

func _load_display_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(DISPLAY_SETTINGS_PATH) == OK:
		fullscreen_enabled = bool(config.get_value("display", "fullscreen", false))
	else:
		fullscreen_enabled = false
	# The main menu applies this after its controls have entered the scene tree.

func _apply_saved_display() -> void:
	# Do not reset a window the user maximized, resized, or moved manually.
	# The display mode is applied once at startup and again only for F11/menu toggles.
	if _display_initialized:
		return
	var window: Window = get_window()
	if window == null:
		return
	# Borderless fullscreen retains regular Windows input routing and avoids
	# switching the debug build into an exclusive/window-mode transition.
	window.mode = Window.MODE_WINDOWED
	if fullscreen_enabled:
		window.borderless = true
		window.position = DisplayServer.screen_get_position()
		window.size = DisplayServer.screen_get_size()
	else:
		window.borderless = false
		var usable: Rect2i = DisplayServer.screen_get_usable_rect()
		window.size = Vector2i(mini(1280, usable.size.x), mini(720, usable.size.y))
		window.position = usable.position + (usable.size - window.size) / 2
	# Important: menus must never inherit a captured cursor after scene switches.
	if current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_display_initialized = true
	window.grab_focus()

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

# Outfits persist independently of the mission and do not alter gameplay stats.
func set_outfit(uniform_id: int, helmet_id: int) -> void:
	uniform_index = clampi(uniform_id, 0, UNIFORM_NAMES.size() - 1)
	helmet_index = clampi(helmet_id, 0, HELMET_NAMES.size() - 1)
	var config: ConfigFile = ConfigFile.new()
	config.set_value("outfit", "uniform", uniform_index)
	config.set_value("outfit", "helmet", helmet_index)
	var result: Error = config.save(OUTFIT_PATH)
	if result != OK:
		push_warning("Kustomisasi karakter tidak tersimpan: %d" % int(result))

func _load_outfit() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(OUTFIT_PATH) != OK:
		return
	uniform_index = clampi(int(config.get_value("outfit", "uniform", 0)), 0, UNIFORM_NAMES.size() - 1)
	helmet_index = clampi(int(config.get_value("outfit", "helmet", 1)), 0, HELMET_NAMES.size() - 1)
