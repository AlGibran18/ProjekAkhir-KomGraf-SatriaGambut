# V8 — lightweight session telemetry for teaching, graphs and data export.
# Samples are recorded only during active play and when the mission ends.
class_name MissionTelemetry
extends Node

const SAMPLE_INTERVAL: float = 5.0
const MAX_SAMPLES: int = 2400
const EXPORT_FOLDER: String = "user://mission_reports"

var grid: GridSimulator
var samples: Array[Dictionary] = []
var sample_clock: float = 0.0
var recording: bool = false
var report_ready: bool = false
var peak_hotspots: int = 0
var tool_counts: Dictionary = {"firebreaks": 0, "spray_ticks": 0, "injections": 0, "thermal_uses": 0}
var run_stamp: String = ""

func initialize(simulator: GridSimulator) -> void:
	grid = simulator

func _ready() -> void:
	EventBus.game_phase_changed.connect(_on_phase_changed)
	EventBus.tool_action_performed.connect(_on_tool_action)
	EventBus.steam_burst_requested.connect(_on_injection_complete)
	EventBus.thermal_mode_toggled.connect(_on_thermal)
	_on_phase_changed(GameState.current_phase)

func _process(delta: float) -> void:
	if not recording or GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	sample_clock += delta
	if sample_clock >= SAMPLE_INTERVAL:
		sample_clock -= SAMPLE_INTERVAL
		_record_snapshot()

func _on_phase_changed(phase: ToolEnums.GamePhase) -> void:
	if phase == ToolEnums.GamePhase.ACTIVE_FPS:
		if not recording and not report_ready and samples.is_empty():
			recording = true
			run_stamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
			_record_snapshot()
		return
	if phase == ToolEnums.GamePhase.VICTORY or phase == ToolEnums.GamePhase.DEFEAT:
		if recording:
			_record_snapshot()
			recording = false
			report_ready = true
		return
	# Pause doesn't reset records. Planning occurs before recording starts.

func _on_tool_action(tool: ToolEnums.ToolType, _pos: Vector2i) -> void:
	if not recording:
		return
	if tool == ToolEnums.ToolType.SEKAT_BAKAR:
		tool_counts["firebreaks"] = int(tool_counts["firebreaks"]) + 1
	elif tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN:
		# Counts successful spray updates, not unique clicks.
		tool_counts["spray_ticks"] = int(tool_counts["spray_ticks"]) + 1

func _on_injection_complete(_pos: Vector2i) -> void:
	if recording:
		tool_counts["injections"] = int(tool_counts["injections"]) + 1

func _on_thermal(enabled: bool) -> void:
	if recording and enabled:
		tool_counts["thermal_uses"] = int(tool_counts["thermal_uses"]) + 1

func _record_snapshot() -> void:
	if samples.size() >= MAX_SAMPLES:
		return
	var active: int = GameState.active_fire_cells
	peak_hotspots = maxi(peak_hotspots, active)
	samples.append({
		"time_s": snappedf(GameState.mission_elapsed_sec, 0.1),
		"hotspots": active,
		"subsurface_only": GameState.subsurface_only_cells,
		"burned_cells": GameState.burned_cells,
		"safe_cells": GameState.safe_cells,
		"water_used_l": snappedf(GameState.water_used_total, 0.1),
		"wind_kmh": snappedf(GameState.wind_speed_kmh, 0.1),
		"rainfall_mm": snappedf(GameState.global_rainfall_rate, 0.1),
		"temperature_c": snappedf(GameState.ambient_temperature, 0.1),
		"carbon_released_t": snappedf(GameState.carbon_released_tons, 0.1),
		"station_safe": int(GameState.station_safe)
	})

func _make_file_name() -> String:
	return "satria_gambut_L%d_%s" % [GameState.current_level_index + 1, run_stamp]

func export_reports() -> Dictionary:
	if not report_ready or samples.is_empty():
		return {"ok": false, "message": "Data misi belum tersedia. Selesaikan misi terlebih dahulu."}
	var absolute: String = ProjectSettings.globalize_path(EXPORT_FOLDER)
	var err: Error = DirAccess.make_dir_recursive_absolute(absolute)
	if err != OK:
		return {"ok": false, "message": "Folder laporan tidak dapat dibuat (error %d)." % int(err)}
	var basename: String = _make_file_name()
	var csv_path: String = "%s/%s.csv" % [EXPORT_FOLDER, basename]
	var csv: FileAccess = FileAccess.open(csv_path, FileAccess.WRITE)
	if csv == null:
		return {"ok": false, "message": "File CSV gagal dibuat (error %d)." % FileAccess.get_open_error()}
	var headings: PackedStringArray = PackedStringArray([
		"time_s", "hotspots", "subsurface_only", "burned_cells", "safe_cells",
		"water_used_l", "wind_kmh", "rainfall_mm", "temperature_c",
		"carbon_released_t", "station_safe"
	])
	csv.store_csv_line(headings)
	for snapshot in samples:
		var values: PackedStringArray = PackedStringArray()
		for heading in headings:
			values.append(str(snapshot.get(heading, 0)))
		csv.store_csv_line(values)
	csv.close()

	var result: String = "VICTORY" if GameState.current_phase == ToolEnums.GamePhase.VICTORY else "DEFEAT"
	var summary: Dictionary = {
		"game": "Satria Gambut",
		"level": GameState.current_level_index + 1,
		"level_name": GameState.LEVEL_CONFIGS[GameState.current_level_index]["name"],
		"result": result,
		"duration_seconds": GameState.mission_elapsed_sec,
		"score": GameState.mission_score,
		"medal": GameState.mission_medal,
		"peak_hotspots": peak_hotspots,
		"hotspots_at_end": GameState.active_fire_cells,
		"safe_cells": GameState.safe_cells,
		"burned_cells": GameState.burned_cells,
		"water_used_l": GameState.water_used_total,
		"carbon_saved_t": GameState.carbon_saved_tons,
		"carbon_released_t": GameState.carbon_released_tons,
		"station_safe": GameState.station_safe,
		"tool_counts": tool_counts.duplicate(true),
		"sample_interval_seconds": SAMPLE_INTERVAL,
		"sample_count": samples.size(),
		"methodology_note": "Educational game simulation, not scientifically validated field observations."
	}
	var json_path: String = "%s/%s.json" % [EXPORT_FOLDER, basename]
	var json_file: FileAccess = FileAccess.open(json_path, FileAccess.WRITE)
	if json_file == null:
		return {"ok": false, "message": "CSV tersimpan, tetapi JSON gagal dibuat.", "csv_path": ProjectSettings.globalize_path(csv_path)}
	json_file.store_string(JSON.stringify(summary, "\t"))
	json_file.close()
	return {
		"ok": true,
		"message": "CSV dan JSON berhasil disimpan.",
		"csv_path": ProjectSettings.globalize_path(csv_path),
		"json_path": ProjectSettings.globalize_path(json_path)
	}
