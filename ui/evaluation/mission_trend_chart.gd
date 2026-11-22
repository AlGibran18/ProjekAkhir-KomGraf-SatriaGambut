# V8: compact chart for mission progression, drawn with regular CanvasItem lines.
class_name MissionTrendChart
extends Control

var points: Array[Dictionary] = []

func set_samples(value: Array[Dictionary]) -> void:
	points = value
	queue_redraw()

func _draw() -> void:
	var region: Rect2 = Rect2(Vector2(54.0, 12.0), Vector2(maxf(40.0, size.x - 78.0), maxf(60.0, size.y - 57.0)))
	draw_rect(region, Color(0.035, 0.09, 0.105, 1.0), true)
	draw_rect(region, Color(0.25, 0.38, 0.40, 0.85), false, 1.0)
	if points.size() < 2:
		draw_string(ThemeDB.fallback_font, region.position + Vector2(10.0, region.size.y * 0.5), "Data belum cukup untuk menampilkan grafik.", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.9, 0.9))
		return
	var max_time: float = maxf(1.0, float(points[points.size() - 1]["time_s"]))
	var max_hotspots: float = 2.0
	var max_water: float = 1.0
	for sample in points:
		max_hotspots = maxf(max_hotspots, float(sample["hotspots"]))
		max_water = maxf(max_water, float(sample["water_used_l"]))
	for line_index in range(5):
		var y: float = region.position.y + region.size.y * float(line_index) / 4.0
		draw_line(Vector2(region.position.x, y), Vector2(region.end.x, y), Color(0.29, 0.41, 0.42, 0.30), 1.0)
	var hot_points: PackedVector2Array = PackedVector2Array()
	var water_points: PackedVector2Array = PackedVector2Array()
	for sample in points:
		var t: float = float(sample["time_s"]) / max_time
		var x: float = region.position.x + t * region.size.x
		hot_points.append(Vector2(x, region.end.y - float(sample["hotspots"]) / max_hotspots * region.size.y))
		water_points.append(Vector2(x, region.end.y - float(sample["water_used_l"]) / max_water * region.size.y))
	if hot_points.size() >= 2:
		draw_polyline(hot_points, Color(1.0, 0.45, 0.22), 2.3, true)
		draw_polyline(water_points, Color(0.25, 0.78, 0.98), 2.1, true)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(6.0, region.position.y + 12.0), str(int(max_hotspots)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.66, 0.42))
	draw_string(font, Vector2(6.0, region.end.y), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.84))
	draw_string(font, Vector2(region.position.x, region.end.y + 17.0), "0 s", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.84))
	draw_string(font, Vector2(region.end.x - 56.0, region.end.y + 17.0), "%d s" % int(max_time), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.84))
	draw_string(font, Vector2(region.position.x, region.end.y + 38.0), "ORANYE: Hotspot aktif    BIRU: Air terpakai (skala masing-masing)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.84, 0.94, 0.92))
