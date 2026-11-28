# ui/main_menu/cinematic_main_menu.gd - Menu utama sinematik berjangkar (anchor) dengan papan kayu jungle sawit; memakai ulang seluruh kontrol dan callback MainMenu.
class_name CinematicMainMenu
extends Control

const NAV_ITEMS: Array[Dictionary] = [
	{"title": "MULAI OPERASI", "action": 0},
	{"title": "PANDUAN & SOP", "action": 2},
	{"title": "HELM & SERAGAM", "action": 3},
	{"title": "PENGATURAN", "action": 4},
	{"title": "CREDITS", "action": 5},
	{"title": "KELUAR", "action": 6}
]

var host
var image_bg: TextureRect
var menu_buttons: Array[Button] = []
var menu_boards: Array[JungleBoard] = []
var selected_button: int = 0
var scenario_board: JungleBoard

func initialize(menu: Node) -> void:
	host = menu

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	_build_brand()
	_build_navigation()
	_build_scenario_card()
	_select_button(0)
	_animate_intro()

func _label(text_value: String, font_size: int, color: Color, title_font: bool = true) -> Label:
	var node: Label = Label.new()
	node.text = text_value
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	node.add_theme_constant_override("shadow_offset_y", 2)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if title_font:
		node.add_theme_font_override("font", UiStyle.title_font())
	return node

func _build_background() -> void:
	image_bg = TextureRect.new()
	image_bg.name = "CinematicPeatlandBackdrop"
	image_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_bg.texture = preload("res://ui/main_menu/rainforest_trail.jpg")
	image_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(image_bg)
	image_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(0.018, 0.034, 0.028, 0.22))
	gradient.set_color(1, Color(0.01, 0.025, 0.012, 0.78))
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.35)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = 256
	var shade: TextureRect = TextureRect.new()
	shade.texture = tex
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_brand() -> void:
	var top: CenterContainer = CenterContainer.new()
	top.name = "BrandHolder"
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	top.anchor_right = 1.0
	top.offset_top = 6.0
	top.offset_bottom = 290.0
	var stack: VBoxContainer = VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", -6)
	top.add_child(stack)
	var medallion: Control = Control.new()
	medallion.custom_minimum_size = Vector2(150, 150)
	medallion.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(medallion)
	var disc: Panel = Panel.new()
	disc.position = Vector2(8, 8)
	disc.size = Vector2(134, 134)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	disc.add_theme_stylebox_override("panel", UiStyle.rounded_box(Color.WHITE, 134))
	medallion.add_child(disc)
	var logo: TextureRect = TextureRect.new()
	logo.name = "UnchangedSatriaGambutLogo"
	logo.texture = host.logo_texture.texture
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(logo)
	logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ring: Control = Control.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	medallion.add_child(ring)
	ring.draw.connect(func() -> void:
		var c: Vector2 = Vector2(75, 75)
		ring.draw_arc(c, 70.0, 0.0, TAU, 64, Color(0, 0, 0, 0.4), 10.0, true)
		ring.draw_arc(c, 69.0, 0.0, TAU, 64, UiStyle.WOOD_DARK, 9.0, true)
		ring.draw_arc(c, 73.0, 0.0, TAU, 64, UiStyle.WOOD, 2.0, true)
		ring.draw_arc(c, 64.0, 0.0, TAU, 64, UiStyle.LEAF, 2.0, true)
	)
	var title_board: JungleBoard = JungleBoard.new()
	title_board.name = "TitleBoard"
	title_board.seed_key = 1
	title_board.pad = Vector2(34, 6)
	title_board.custom_minimum_size = Vector2(560, 0)
	stack.add_child(title_board)
	var title_stack: VBoxContainer = VBoxContainer.new()
	title_stack.add_theme_constant_override("separation", -4)
	title_board.add_child(title_stack)
	var title: Label = _label("SATRIA GAMBUT", 56, UiStyle.CREAM)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_stack.add_child(title)
	var tagline: Label = _label("Selamatkan hutan. Lindungi karbon. Padamkan api.", 19, UiStyle.AMBER, false)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_stack.add_child(tagline)

func _build_navigation() -> void:
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "NavColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", -10)
	add_child(column)
	column.anchor_top = 1.0
	column.anchor_bottom = 1.0
	column.offset_left = 20.0
	column.offset_right = 380.0
	column.offset_top = -420.0
	column.offset_bottom = -14.0
	column.alignment = BoxContainer.ALIGNMENT_END
	for index in range(NAV_ITEMS.size()):
		var info: Dictionary = NAV_ITEMS[index]
		var board: JungleBoard = JungleBoard.new()
		board.name = "NavBoard" + str(index)
		board.bleed = 18.0
		board.pad = Vector2(8, 0)
		board.foliage_amount = 0.5
		board.seed_key = 20 + (index % 3)
		board.custom_minimum_size = Vector2(360, 68)
		board.pivot_offset = Vector2(180, 34)
		column.add_child(board)
		var button: Button = Button.new()
		button.name = "Nav" + str(index)
		button.text = String(info["title"])
		button.flat = true
		button.add_theme_font_size_override("font_size", 25)
		button.add_theme_color_override("font_color", UiStyle.CREAM)
		button.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
		button.add_theme_color_override("font_focus_color", UiStyle.AMBER)
		button.add_theme_color_override("font_pressed_color", UiStyle.AMBER)
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.focus_mode = Control.FOCUS_ALL
		board.add_child(button)
		menu_buttons.append(button)
		menu_boards.append(board)
		var item_index: int = index
		button.pressed.connect(func() -> void:
			_activate(int(NAV_ITEMS[item_index]["action"]))
		)
		button.mouse_entered.connect(func() -> void:
			_select_button(item_index)
		)
		button.focus_entered.connect(func() -> void:
			_select_button(item_index)
		)

func _select_button(index: int) -> void:
	if index < 0 or index >= menu_buttons.size():
		return
	selected_button = index
	for i in range(menu_buttons.size()):
		var active: bool = i == index
		var board: JungleBoard = menu_boards[i]
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(board, "scale", Vector2.ONE * (1.05 if active else 1.0), 0.12)
		tween.tween_property(board, "modulate", Color(1, 1, 1, 1) if active else Color(0.78, 0.8, 0.74, 1), 0.12)
		menu_buttons[i].add_theme_color_override("font_color", UiStyle.AMBER if active else UiStyle.CREAM)

func _activate(action: int) -> void:
	if host == null:
		return
	match action:
		0:
			host._on_start_pressed()
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

func _build_scenario_card() -> void:
	scenario_board = JungleBoard.new()
	scenario_board.name = "ScenarioBoard"
	scenario_board.seed_key = 9
	scenario_board.pad = Vector2(22, 8)
	scenario_board.custom_minimum_size = Vector2(500, 0)
	add_child(scenario_board)
	scenario_board.anchor_left = 1.0
	scenario_board.anchor_right = 1.0
	scenario_board.anchor_top = 1.0
	scenario_board.anchor_bottom = 1.0
	scenario_board.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	scenario_board.grow_vertical = Control.GROW_DIRECTION_BEGIN
	scenario_board.offset_right = -14.0
	scenario_board.offset_bottom = -14.0
	var stack: VBoxContainer = VBoxContainer.new()
	stack.name = "ScenarioStack"
	stack.add_theme_constant_override("separation", 6)
	scenario_board.add_child(stack)
	stack.add_child(_label("PILIH OPERASI", 24, UiStyle.AMBER))
	host.level_option.reparent(stack, false)
	host.level_option.custom_minimum_size = Vector2(420, 42)
	host.level_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.level_desc_label.reparent(stack, false)
	host.level_desc_label.custom_minimum_size = Vector2(420, 96)
	host.level_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.level_desc_label.add_theme_font_size_override("font_size", 18)
	host.level_desc_label.add_theme_color_override("font_color", Color(0.95, 0.93, 0.84))

func _animate_intro() -> void:
	for i in range(menu_boards.size()):
		var board: JungleBoard = menu_boards[i]
		board.modulate.a = 0.0
		create_tween().tween_property(board, "modulate:a", 1.0, 0.25).set_delay(0.2 + 0.06 * i)
	if scenario_board != null:
		scenario_board.modulate.a = 0.0
		create_tween().tween_property(scenario_board, "modulate:a", 1.0, 0.5).set_delay(0.3)

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
