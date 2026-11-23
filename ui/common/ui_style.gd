# ui/common/ui_style.gd - Palet warna, font, dan pembuat StyleBox bertema jungle sawit yang dipakai seragam oleh seluruh antarmuka Satria Gambut.
class_name UiStyle
extends RefCounted

const FONT_TITLE_PATH: String = "res://assets/fonts/LilitaOne-Regular.ttf"
const FONT_BODY_PATH: String = "res://assets/fonts/BarlowCondensed-Medium.ttf"
const FONT_BODY_BOLD_PATH: String = "res://assets/fonts/BarlowCondensed-SemiBold.ttf"

const BARK: Color = Color(0.075, 0.055, 0.035, 0.92)
const BARK_SOLID: Color = Color(0.11, 0.08, 0.05, 1.0)
const WOOD: Color = Color(0.46, 0.30, 0.15, 1.0)
const WOOD_DARK: Color = Color(0.25, 0.15, 0.075, 1.0)
const LEAF: Color = Color(0.40, 0.66, 0.20, 1.0)
const LEAF_DARK: Color = Color(0.13, 0.30, 0.12, 1.0)
const AMBER: Color = Color(1.0, 0.78, 0.30, 1.0)
const CREAM: Color = Color(0.99, 0.95, 0.82, 1.0)
const WATER: Color = Color(0.32, 0.82, 1.0, 1.0)
const FIRE: Color = Color(1.0, 0.46, 0.16, 1.0)
const DANGER: Color = Color(0.95, 0.26, 0.20, 1.0)
const SAFE: Color = Color(0.48, 0.90, 0.38, 1.0)

static func title_font() -> Font:
	return load(FONT_TITLE_PATH) as Font

static func body_font() -> Font:
	return load(FONT_BODY_PATH) as Font

static func body_bold_font() -> Font:
	return load(FONT_BODY_BOLD_PATH) as Font

static func rounded_box(fill: Color, radius: int, border: Color = Color(0, 0, 0, 0), border_width: int = 0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.2
	return style

static func panel_box(radius: int = 22) -> StyleBoxFlat:
	var style: StyleBoxFlat = rounded_box(BARK, radius, LEAF_DARK.lightened(0.1), 3)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func button_box(fill: Color, rim: Color, radius: int = 20) -> StyleBoxFlat:
	var style: StyleBoxFlat = rounded_box(fill, radius, rim, 2)
	style.border_width_bottom = 5
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style

static func build_theme() -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = 19
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	theme.set_constant("shadow_offset_y", "Label", 1)
	for type_name in ["Button", "OptionButton", "MenuButton"]:
		theme.set_font("font", type_name, title_font())
		theme.set_font_size("font_size", type_name, 20)
		theme.set_color("font_color", type_name, CREAM)
		theme.set_color("font_hover_color", type_name, Color(1, 1, 0.9))
		theme.set_color("font_pressed_color", type_name, AMBER)
		theme.set_color("font_focus_color", type_name, CREAM)
		theme.set_color("font_disabled_color", type_name, Color(0.6, 0.58, 0.5))
		theme.set_stylebox("normal", type_name, button_box(Color(0.20, 0.34, 0.14), LEAF_DARK))
		theme.set_stylebox("hover", type_name, button_box(Color(0.28, 0.46, 0.17), LEAF))
		theme.set_stylebox("pressed", type_name, button_box(Color(0.60, 0.38, 0.10), AMBER))
		theme.set_stylebox("focus", type_name, button_box(Color(0.28, 0.46, 0.17), AMBER))
		theme.set_stylebox("disabled", type_name, button_box(Color(0.18, 0.18, 0.15), Color(0.3, 0.3, 0.25)))
	for state in ["normal", "pressed", "hover", "hover_pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "CheckBox", StyleBoxEmpty.new())
	theme.set_color("font_color", "CheckBox", CREAM)
	theme.set_color("font_pressed_color", "CheckBox", AMBER)
	theme.set_color("font_hover_pressed_color", "CheckBox", AMBER)
	theme.set_font("font", "CheckBox", body_bold_font())
	theme.set_font_size("font_size", "CheckBox", 20)
	theme.set_stylebox("panel", "PanelContainer", panel_box())
	theme.set_stylebox("panel", "Panel", panel_box())
	theme.set_stylebox("panel", "PopupPanel", panel_box(14))
	var fill: StyleBoxFlat = rounded_box(LEAF, 10)
	var groove: StyleBoxFlat = rounded_box(Color(0.05, 0.04, 0.03, 0.85), 10, WOOD_DARK, 2)
	theme.set_stylebox("fill", "ProgressBar", fill)
	theme.set_stylebox("background", "ProgressBar", groove)
	var slider_groove: StyleBoxFlat = rounded_box(Color(0.05, 0.04, 0.03, 0.85), 6, WOOD_DARK, 1)
	slider_groove.content_margin_top = 5
	slider_groove.content_margin_bottom = 5
	var slider_fill: StyleBoxFlat = rounded_box(LEAF, 6)
	slider_fill.content_margin_top = 5
	slider_fill.content_margin_bottom = 5
	theme.set_stylebox("slider", "HSlider", slider_groove)
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	theme.set_color("font_color", "RichTextLabel", CREAM)
	theme.set_color("default_color", "RichTextLabel", CREAM)
	return theme
