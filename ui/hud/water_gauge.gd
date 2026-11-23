# ui/hud/water_gauge.gd - Pengukur tangki air melingkar (cincin kayu + tetes air) untuk HUD, menampilkan sisa liter secara ringkas.
class_name WaterGauge
extends Control

var ratio: float = 1.0
var liters: int = 0
var display_ratio: float = 1.0

func _ready() -> void:
	custom_minimum_size = Vector2(112, 112)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_level(current: float, max_value: float) -> void:
	ratio = clampf(current / maxf(1.0, max_value), 0.0, 1.0)
	liters = int(current)
	queue_redraw()

func _process(delta: float) -> void:
	if absf(display_ratio - ratio) > 0.002:
		display_ratio = lerpf(display_ratio, ratio, clampf(delta * 8.0, 0.0, 1.0))
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 6.0
	draw_circle(center + Vector2(0, 4), radius + 3.0, Color(0, 0, 0, 0.35))
	draw_circle(center, radius, UiStyle.WOOD_DARK)
	draw_circle(center, radius - 6.0, Color(0.06, 0.05, 0.04))
	var low: bool = ratio < 0.25
	var fill_color: Color = UiStyle.WATER if not low else UiStyle.FIRE
	draw_arc(center, radius - 3.0, 0.0, TAU, 48, Color(1, 1, 1, 0.08), 3.0, true)
	var start: float = -PI * 0.5
	if display_ratio > 0.005:
		draw_arc(center, radius - 3.0, start, start + TAU * display_ratio, 48, fill_color, 6.0, true)
	var drop_center: Vector2 = center + Vector2(0, -16)
	draw_circle(drop_center + Vector2(0, 5), 11.0, fill_color)
	draw_colored_polygon(PackedVector2Array([drop_center + Vector2(-9.5, 2), drop_center + Vector2(9.5, 2), drop_center + Vector2(0, -17)]), fill_color)
	draw_circle(drop_center + Vector2(-4, 6), 2.8, Color(1, 1, 1, 0.6))
	var font: Font = UiStyle.title_font()
	var text: String = str(liters)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26)
	draw_string(font, center + Vector2(-text_size.x * 0.5, 26.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiStyle.CREAM)
	var unit_size: Vector2 = font.get_string_size("LITER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(font, center + Vector2(-unit_size.x * 0.5, 39.0), "LITER", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.8, 0.88, 0.8, 0.8))
