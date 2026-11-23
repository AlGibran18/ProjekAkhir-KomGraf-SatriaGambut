# ui/hud/hud_widgets.gd - Widget HUD bulat bergaya game modern: slot alat (ikon vektor) dan pengukur tangki air.
class_name HudToolSlot
extends Control

enum Icon { TRENCH, SPRAY, LANCE, THERMAL }

var icon_kind: Icon = Icon.SPRAY
var key_text: String = "1"
var selected: bool = false
var lit: bool = false
var hovered: bool = false

signal slot_pressed

func _ready() -> void:
	custom_minimum_size = Vector2(76, 92)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		hovered = true
		queue_redraw()
	)
	mouse_exited.connect(func() -> void:
		hovered = false
		queue_redraw()
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_pressed.emit()
		accept_event()

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func set_lit(value: bool) -> void:
	lit = value
	queue_redraw()

func _draw() -> void:
	var radius: float = 33.0
	var center: Vector2 = Vector2(size.x * 0.5, 38.0 - (6.0 if selected else 0.0))
	draw_circle(center + Vector2(0, 4), radius + 2.0, Color(0, 0, 0, 0.35))
	var rim: Color = UiStyle.AMBER if (selected or lit) else UiStyle.LEAF_DARK.lightened(0.15)
	if hovered and not selected:
		rim = UiStyle.LEAF
	draw_circle(center, radius, rim)
	var face: Color = Color(0.16, 0.11, 0.06) if not selected else Color(0.34, 0.21, 0.08)
	draw_circle(center, radius - 4.0, face)
	var tint: Color = UiStyle.CREAM
	match icon_kind:
		Icon.TRENCH:
			var ground: PackedVector2Array = PackedVector2Array([
				center + Vector2(-19, -2), center + Vector2(19, -2), center + Vector2(13, 12), center + Vector2(-13, 12)
			])
			draw_colored_polygon(ground, Color(0.42, 0.27, 0.12))
			draw_line(center + Vector2(-19, -2), center + Vector2(19, -2), tint, 3.0, true)
			draw_line(center + Vector2(-8, -17), center + Vector2(8, -4), tint, 3.5, true)
			draw_circle(center + Vector2(-9, -18), 3.2, tint)
		Icon.SPRAY:
			var tint_water: Color = UiStyle.WATER
			draw_circle(center + Vector2(0, 5), 12.0, tint_water)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-10.5, 1), center + Vector2(10.5, 1), center + Vector2(0, -19)]), tint_water)
			draw_circle(center + Vector2(-4, 4), 3.2, Color(1, 1, 1, 0.65))
		Icon.LANCE:
			draw_line(center + Vector2(-17, 17), center + Vector2(12, -12), tint, 4.0, true)
			draw_colored_polygon(PackedVector2Array([center + Vector2(8, -19), center + Vector2(19, -19), center + Vector2(19, -8)]), UiStyle.WATER)
			draw_circle(center + Vector2(-13, 12), 3.0, UiStyle.WATER)
			draw_circle(center + Vector2(-19, 6), 2.2, UiStyle.WATER)
		Icon.THERMAL:
			var eye: Color = UiStyle.FIRE if lit else tint
			draw_arc(center + Vector2(0, 9), 17.0, deg_to_rad(215.0), deg_to_rad(325.0), 14, eye, 3.4, true)
			draw_arc(center + Vector2(0, -9), 17.0, deg_to_rad(35.0), deg_to_rad(145.0), 14, eye, 3.4, true)
			draw_circle(center, 6.5, eye)
			draw_circle(center, 2.6, face)
	var badge_center: Vector2 = Vector2(center.x - 22.0, center.y + 25.0)
	draw_circle(badge_center, 11.0, UiStyle.BARK_SOLID)
	draw_arc(badge_center, 11.0, 0.0, TAU, 20, UiStyle.AMBER if selected else UiStyle.WOOD, 2.0, true)
	var font: Font = UiStyle.title_font()
	var font_size: int = 14 if key_text.length() < 3 else 10
	var text_size: Vector2 = font.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, badge_center + Vector2(-text_size.x * 0.5, text_size.y * 0.32), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, UiStyle.CREAM)
