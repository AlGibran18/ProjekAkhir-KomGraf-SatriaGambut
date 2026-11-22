# simulation/model/peat_cell_data.gd - Model data murni per-petak lahan gambut: variabel hidrometeorologi, kedalaman, karbon, risiko PFVI, sumur air, serta status api dan bara.
class_name PeatCellData
extends RefCounted

var grid_pos: Vector2i = Vector2i.ZERO
var water_table: float = -40.0
var soil_moisture: float = 0.35
var temperature: float = 34.0
var rainfall: float = 0.0
var peat_depth: float = 1.5
var carbon_tons: float = 12.75
var pfvi_score: float = 180.0
var risk_category: ToolEnums.RiskCategory = ToolEnums.RiskCategory.TINGGI
var surface_fire: float = 0.0
var subsurface_ember: float = 0.0
var injection_progress: float = 0.0
var is_firebreak: bool = false
var is_burnt: bool = false
var has_well: bool = false

func is_burning() -> bool:
	return surface_fire > 0.0

func has_ember() -> bool:
	return subsurface_ember > 0.0

func is_active_hazard() -> bool:
	return is_burning() or has_ember()

func recalculate_pfvi() -> void:
	pfvi_score = PFVICalculator.calculate_pfvi(water_table, soil_moisture, temperature, rainfall)
	risk_category = PFVICalculator.get_risk_category(pfvi_score)

func ignite(surface_amount: float = 85.0, ember_amount: float = 75.0) -> void:
	if is_firebreak or has_well:
		return
	surface_fire = clampf(surface_amount, 0.0, 100.0)
	subsurface_ember = clampf(ember_amount, 0.0, 100.0)
	injection_progress = 0.0
	soil_moisture = clampf(soil_moisture * 0.35, 0.05, 1.0)
	recalculate_pfvi()

func apply_surface_spray(water_power: float) -> bool:
	var had_surface: bool = surface_fire > 0.0
	if had_surface:
		surface_fire = maxf(0.0, surface_fire - water_power)
		soil_moisture = minf(1.0, soil_moisture + (water_power * 0.002))
		if surface_fire <= 0.0:
			is_burnt = true
	return had_surface and surface_fire <= 0.0 and subsurface_ember > 0.0

func apply_peat_spear(delta_progress: float) -> bool:
	if subsurface_ember <= 0.0 and surface_fire <= 0.0:
		return false
	var depth_resistance: float = maxf(0.8, peat_depth * 0.75)
	injection_progress = clampf(injection_progress + (delta_progress / depth_resistance), 0.0, 1.0)
	subsurface_ember = maxf(0.0, subsurface_ember - (delta_progress * 60.0 / depth_resistance))
	soil_moisture = minf(1.0, soil_moisture + (delta_progress * 0.25))
	water_table = minf(-10.0, water_table + (delta_progress * 15.0))
	if injection_progress >= 1.0 or subsurface_ember <= 0.0:
		subsurface_ember = 0.0
		surface_fire = maxf(0.0, surface_fire - 50.0)
		injection_progress = 0.0
		soil_moisture = maxf(soil_moisture, 0.72)
		water_table = maxf(water_table, -15.0)
		recalculate_pfvi()
		return true
	recalculate_pfvi()
	return false

func make_firebreak() -> bool:
	if is_firebreak or has_well or is_burning():
		return false
	is_firebreak = true
	surface_fire = 0.0
	subsurface_ember = 0.0
	injection_progress = 0.0
	water_table = maxf(water_table, -25.0)
	recalculate_pfvi()
	return true
