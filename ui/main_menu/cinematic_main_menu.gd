# Cinematic full-screen main menu (V8.6 extension).
# Keeps original logo texture and all MainMenu callbacks / scenario controls.
class_name CinematicMainMenu
extends Control

const DESIGN_SIZE: Vector2 = Vector2(1280.0, 720.0)
var host
var design: Control
var level_name: Label
var level_info: Label
var title_label: Label
var image_bg: TextureRect
var menu_buttons: Array[Button] = []
var selected_button: int = 0
var scenario_panel: PanelContainer
var scenario_heading: Label
var glow_line: ColorRect

func initialize(menu: Node) -> void:
	host = menu

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_design()
	resized.connect(_resize_design)
	call_deferred("_resize_design")
	set_process(true)

func _build_background() -> void:
	image_bg = TextureRect.new()
	image_bg.name = "CinematicPeatlandBackdrop"
	image_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_bg.texture = load("res://ui/main_menu/cinematic_peatland_bg.svg") as Texture2D
	image_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(image_bg)
	image_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wash: ColorRect = ColorRect.new()
	wash.name = "TextLegibilityWash"
	wash.color = Color(0.011, 0.022, 0.028, 0.16)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_bg.add_child(wash)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_design() -> void:
	design = Control.new()
	design.name = "CinematicUILayer"
	design.mouse_filter = Control.MOUSE_FILTER_PASS
	design.custom_minimum_size = DESIGN_SIZE
	design.size = DESIGN_SIZE
	add_child(design)
	_build_brand()
	_build_main_navigation()
	_build_scenario_panel()
	_build_footer()
	_update_scenario()
	host.level_option.item_selected.connect(func(_index: int) -> void:
		_update_scenario()
	)
	# Existing level OptionButton and description are moved, NOT replaced.
	# MainMenu's callbacks, level records and current selection are preserved.
	_select_button(0)
	_animate_intro()

func _label(text_value: String, font_size: int, color: Color) -> Label:
	var node: Label = Label.new()
	node.text = text_value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _placed(node: Control, pos: Vector2, dimensions: Vector2) -> void:
	node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.position = pos
	node.size = dimensions

func _panel_style(fill_color: Color, border_color: Color, rounded: int = 12) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(rounded)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 9
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _build_brand() -> void:
	# Copy the pre-existing logo texture (never replace or edit its JPG).
	var brand_frame: PanelContainer = PanelContainer.new()
	brand_frame.name = "OriginalLogoSpotlight"
	brand_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_frame.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.071, 0.081, 0.65), Color(0.98, 0.75, 0.36, 0.66), 19))
	design.add_child(brand_frame)
	_placed(brand_frame, Vector2(549, 18), Vector2(182, 156))
	var original_logo: TextureRect = TextureRect.new()
	original_logo.name = "UnchangedSatriaGambutLogo"
	original_logo.texture = host.logo_texture.texture
	original_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	original_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	original_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_frame.add_child(original_logo)
	original_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_label = _label("S A T R I A   G A M B U T", 37, Color(0.98, 0.91, 0.75))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.88))
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	design.add_child(title_label)
	_placed(title_label, Vector2(390, 169), Vector2(500, 53))
	var subtitle: Label = _label("OPERASI PENYELAMATAN LAHAN GAMBUT  /  SIMULASI KEBAKARAN 3D", 12, Color(0.77, 0.96, 0.90))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	design.add_child(subtitle)
	_placed(subtitle, Vector2(370, 225), Vector2(540, 24))
	glow_line = ColorRect.new()
	glow_line.color = Color(0.31, 0.95, 0.77, 0.75)
	glow_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	design.add_child(glow_line)
	_placed(glow_line, Vector2(508, 253), Vector2(264, 2))

func _build_main_navigation() -> void:
	var marker: Label = _label("OPERATIONS  /  MAIN MENU", 13, Color(0.91, 0.80, 0.48))
	design.add_child(marker)
	_placed(marker, Vector2(42, 291), Vector2(362, 22))
	var nav_data: Array = [
		{"title":"▶    MULAI OPERASI", "action":0},
		{"title":"▤    PILIH SKENARIO", "action":1},
		{"title":"◈    PANDUAN & SOP", "action":2},
		{"title":"◇    HELM & SERAGAM", "action":3},
		{"title":"⚙    PENGATURAN", "action":4},
		{"title":"✦    CREDITS", "action":5},
		{"title":"↪    KELUAR", "action":6}
	]
	for index in range(nav_data.size()):
		var info: Dictionary = nav_data[index]
		var button: Button = Button.new()
		button.name = "Nav" + str(index)
		button.text = String(info["title"])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size.y = 43
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_color_override("font_color", Color(0.88, 0.98, 0.95))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.78))
		design.add_child(button)
		_placed(button, Vector2(42, 319 + index * 49), Vector2(355, 43))
		menu_buttons.append(button)
		var item_index: int = index
		button.pressed.connect(func() -> void:
			_activate(item_index)
		)
		button.mouse_entered.connect(func() -> void:
			_select_button(item_index)
		)
		button.focus_entered.connect(func() -> void:
			_select_button(item_index)
		)
		_style_nav_button(button, index == 0)
	var nav_hint: Label = _label("SELAMATKAN HUTAN  •  LINDUNGI KARBON  •  PADAMKAN API", 11, Color(0.61, 0.90, 0.83))
	design.add_child(nav_hint)
	_placed(nav_hint, Vector2(44, 679), Vector2(470, 20))

func _nav_box(active: bool, hovered: bool = false) -> StyleBoxFlat:
	var base: Color = Color(0.38, 0.20, 0.060, 0.88) if active else Color(0.018, 0.067, 0.078, 0.84)
	var accent: Color = Color(1.0, 0.73, 0.20, 0.98) if active else Color(0.29, 0.72, 0.67, 0.66)
	if hovered:
		base = base.lightened(0.12)
		accent = accent.lightened(0.13)
	var style: StyleBoxFlat = _panel_style(base, accent, 8)
	style.content_margin_left = 20
	style.content_margin_right = 10
	style.shadow_size = 7 if active else 3
	return style

func _style_nav_button(button: Button, is_selected: bool) -> void:
	button.add_theme_stylebox_override("normal", _nav_box(is_selected))
	button.add_theme_stylebox_override("hover", _nav_box(is_selected, true))
	button.add_theme_stylebox_override("pressed", _nav_box(true, false))
	button.add_theme_stylebox_override("focus", _nav_box(true, false))
	button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.74) if is_selected else Color(0.88, 0.96, 0.93))

func _select_button(index: int) -> void:
	if index < 0 or index >= menu_buttons.size():
		return
	selected_button = index
	for i in range(menu_buttons.size()):
		_style_nav_button(menu_buttons[i], i == index)

func _activate(index: int) -> void:
	if host == null:
		return
	match index:
		0:
			host._on_start_pressed()
		1:
			# Selection is always present in the scenario card.
			host.level_option.grab_focus()
		2:
			host._show_only_modal(host.guide_modal)
		3:
			host._open_wardrobe()
		4:
			host._show_only_modal(host.settings_modal)
		5:
			host._show_only_modal(host.credits_modal)
		6:
			get_tree().quit()

func _build_scenario_panel() -> void:
	scenario_panel = PanelContainer.new()
	scenario_panel.name = "ScenarioIntelCard"
	scenario_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.076, 0.091, 0.88), Color(0.25, 0.84, 0.77), 13))
	design.add_child(scenario_panel)
	_placed(scenario_panel, Vector2(782, 407), Vector2(458, 255))
	var stack: VBoxContainer = VBoxContainer.new()
	stack.name = "MissionCardStack"
	stack.add_theme_constant_override("separation", 7)
	scenario_panel.add_child(stack)
	scenario_heading = _label("◆  SKENARIO  /  PILIH OPERASI", 15, Color(0.43, 1.0, 0.84))
	stack.add_child(scenario_heading)
	var thin: HSeparator = HSeparator.new()
	stack.add_child(thin)
	var info_label: Label = _label("MISI TERPILIH", 11, Color(0.95, 0.78, 0.43))
	stack.add_child(info_label)
	# Reuse live scene nodes, retaining all existing item_selected connections.
	host.level_option.reparent(stack, false)
	host.level_option.custom_minimum_size.y = 39
	host.level_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_scenario_select(host.level_option)
	host.level_desc_label.reparent(stack, false)
	host.level_desc_label.custom_minimum_size.y = 80
	host.level_desc_label.add_theme_color_override("font_color", Color(0.86, 0.94, 0.90))
	host.level_desc_label.add_theme_font_size_override("font_size", 13)
	host.level_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var divider: HSeparator = HSeparator.new()
	stack.add_child(divider)
	level_info = _label("Pilih skenario lalu tekan Mulai Operasi", 12, Color(0.74, 0.91, 0.85))
	stack.add_child(level_info)

func _style_scenario_select(option: OptionButton) -> void:
	var normal: StyleBoxFlat = _panel_style(Color(0.08, 0.19, 0.21), Color(0.38, 0.85, 0.71), 9)
	normal.shadow_size = 0
	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_stylebox_override("hover", _panel_style(Color(0.12, 0.26, 0.28), Color(0.65, 0.96, 0.79), 9))
	option.add_theme_color_override("font_color", Color(0.99, 0.94, 0.75))
	option.add_theme_font_size_override("font_size", 15)

func _update_scenario() -> void:
	if host == null or host.level_option == null or level_info == null:
		return
	var idx: int = host.level_option.selected
	if idx < 0 or idx >= GameState.LEVEL_CONFIGS.size():
		return
	var cfg: Dictionary = GameState.LEVEL_CONFIGS[idx]
	var rain: float = float(cfg.get("rainfall", 0.0))
	var wind: float = float(cfg.get("wind_speed", 0.0))
	level_info.text = "SITUASI  /  HUJAN %.0f mm    •    ANGIN %.0f km/j" % [rain, wind]

func _build_footer() -> void:
	var bottom_bar: PanelContainer = PanelContainer.new()
	bottom_bar.name = "GameMenuFooter"
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.008, 0.034, 0.044, 0.84), Color(0.26, 0.70, 0.66, 0.66), 6))
	design.add_child(bottom_bar)
	_placed(bottom_bar, Vector2(680, 677), Vector2(558, 35))
	var footer: Label = _label("ENTER  Konfirmasi       ESC  Kembali       ↑↓  Navigasi       F11  Fullscreen", 11, Color(0.86, 0.96, 0.93))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bottom_bar.add_child(footer)

func _animate_intro() -> void:
	for button in menu_buttons:
		button.modulate.a = 0.0
		var idx: int = menu_buttons.find(button)
		var tween: Tween = create_tween()
		tween.tween_property(button, "modulate:a", 1.0, 0.24).set_delay(0.06 * idx)
	if scenario_panel != null:
		scenario_panel.modulate.a = 0.0
		create_tween().tween_property(scenario_panel, "modulate:a", 1.0, 0.58).set_delay(0.15)

func _resize_design() -> void:
	if design == null:
		return
	var scale_factor: float = minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	design.scale = Vector2.ONE * scale_factor
	design.position = (size - DESIGN_SIZE * scale_factor) * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if host == null:
		return
	if host.modal_backdrop.visible or host.wardrobe_dialog.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_UP:
			_select_button(posmod(selected_button - 1, menu_buttons.size()))
			menu_buttons[selected_button].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_select_button((selected_button + 1) % menu_buttons.size())
			menu_buttons[selected_button].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_select_button(0)
			get_viewport().set_input_as_handled()
