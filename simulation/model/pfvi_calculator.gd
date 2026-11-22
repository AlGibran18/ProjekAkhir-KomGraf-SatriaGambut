# simulation/model/pfvi_calculator.gd - Helper statis kalkulasi Peat Fire Vulnerability Index (PFVI) berbasis 4 variabel hidrometeorologi riset ITB-Nottingham.
class_name PFVICalculator
extends RefCounted

static func calculate_pfvi(water_table: float, soil_moisture: float, temperature: float, rainfall: float) -> float:
	var wt_factor: float = clampf((-water_table - 10.0) / 70.0, 0.0, 1.0)
	var sm_factor: float = clampf((0.6 - soil_moisture) / 0.5, 0.0, 1.0)
	var temp_factor: float = clampf((temperature - 25.0) / 15.0, 0.0, 1.0)
	var rf_factor: float = clampf((10.0 - rainfall) / 10.0, 0.0, 1.0)

	var raw_pfvi: float = (wt_factor * 90.0) + (sm_factor * 110.0) + (temp_factor * 60.0) + (rf_factor * 40.0)
	return clampf(raw_pfvi, 0.0, 320.0)

static func get_risk_category(pfvi: float) -> ToolEnums.RiskCategory:
	if pfvi <= 75.0:
		return ToolEnums.RiskCategory.RENDAH
	elif pfvi <= 150.0:
		return ToolEnums.RiskCategory.SEDANG
	elif pfvi <= 225.0:
		return ToolEnums.RiskCategory.TINGGI
	else:
		return ToolEnums.RiskCategory.EKSTREM

static func get_risk_label(category: ToolEnums.RiskCategory) -> String:
	match category:
		ToolEnums.RiskCategory.RENDAH:
			return "Rendah (Aman)"
		ToolEnums.RiskCategory.SEDANG:
			return "Sedang (Waspada)"
		ToolEnums.RiskCategory.TINGGI:
			return "Tinggi (Rawan)"
		ToolEnums.RiskCategory.EKSTREM:
			return "Ekstrem (Kritis)"
		_:
			return "Tidak Diketahui"

static func get_risk_color(category: ToolEnums.RiskCategory) -> Color:
	match category:
		ToolEnums.RiskCategory.RENDAH:
			return Color(0.18, 0.72, 0.28, 1.0)
		ToolEnums.RiskCategory.SEDANG:
			return Color(0.92, 0.82, 0.22, 1.0)
		ToolEnums.RiskCategory.TINGGI:
			return Color(0.95, 0.52, 0.15, 1.0)
		ToolEnums.RiskCategory.EKSTREM:
			return Color(0.92, 0.20, 0.18, 1.0)
		_:
			return Color.WHITE
