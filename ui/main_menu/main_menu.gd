# ui/main_menu/main_menu.gd - Pengendali layar utama (Main Menu), pemilih skenario level, modal animasi halus, pengaturan grafis/audio, dan Credits Satria Gambut.
class_name MainMenu
extends Control

@onready var level_option: OptionButton = $MainMargin/MainHBox/LeftPanel/VBox/LevelBox/ContentVBox/LevelOption
@onready var level_desc_label: Label = $MainMargin/MainHBox/LeftPanel/VBox/LevelBox/ContentVBox/LevelDescLabel
@onready var btn_start: Button = $MainMargin/MainHBox/LeftPanel/VBox/BtnStart
@onready var btn_guide: Button = $MainMargin/MainHBox/LeftPanel/VBox/BtnGuide
@onready var btn_settings: Button = $MainMargin/MainHBox/LeftPanel/VBox/BtnSettings
@onready var btn_credits: Button = $MainMargin/MainHBox/LeftPanel/VBox/BtnCredits
@onready var btn_quit: Button = $MainMargin/MainHBox/LeftPanel/VBox/BtnQuit

@onready var modal_backdrop: ColorRect = $ModalBackdrop
@onready var guide_modal: PanelContainer = $GuideModal
@onready var settings_modal: PanelContainer = $SettingsModal
@onready var credits_modal: PanelContainer = $CreditsModal

@onready var quality_option: OptionButton = $SettingsModal/VBox/QualityOption
@onready var sens_slider: HSlider = $SettingsModal/VBox/SensSlider
@onready var vol_slider: HSlider = $SettingsModal/VBox/VolSlider

var display_option: OptionButton
var guide_display_checkbox: CheckBox
var wardrobe_dialog: ConfirmationDialog
var uniform_choice: OptionButton
var helmet_choice: OptionButton
@onready var main_margin: MarginContainer = $MainMargin
@onready var menu_columns: HBoxContainer = $MainMargin/MainHBox
@onready var left_panel: PanelContainer = $MainMargin/MainHBox/LeftPanel
@onready var logo_texture: TextureRect = $MainMargin/MainHBox/RightPanel/VBox/LogoTexture

func _ready() -> void:
	AudioManager.play_menu_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_populate_levels()
	_create_display_setting()
	_create_guide_display_setting()
	_create_wardrobe()
	_populate_settings()
	_apply_modern_menu_design()
	resized.connect(_on_menu_resized)
	call_deferred("_on_menu_resized")
	# Defer display restoration until buttons, modals and mouse handling exist.
	GameState.call_deferred("_apply_saved_display")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	level_option.item_selected.connect(_on_level_selected)
	btn_start.pressed.connect(_on_start_pressed)
	btn_guide.pressed.connect(func() -> void: _show_only_modal(guide_modal))
	btn_settings.pressed.connect(func() -> void: _show_only_modal(settings_modal))
	btn_credits.pressed.connect(func() -> void: _show_only_modal(credits_modal))
	btn_quit.pressed.connect(func() -> void: get_tree().quit())

	$GuideModal/VBox/BtnCloseGuide.pressed.connect(_close_modals)
	$SettingsModal/VBox/BtnCloseSettings.pressed.connect(_close_modals)
	$CreditsModal/VBox/BtnCloseCredits.pressed.connect(_close_modals)

	quality_option.item_selected.connect(_on_quality_selected)
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)

# The native window maximize button and edge dragging need no extra hotkey.
# Anchored layout follows viewport size; margins and image minimums adapt.
func _on_menu_resized() -> void:
	if main_margin == null or menu_columns == null:
		return
	var size_now: Vector2 = size
	var compact: bool = size_now.x < 1180.0 or size_now.y < 680.0
	var margin_x: int = 18 if compact else 48
	var margin_y: int = 16 if compact else 36
	main_margin.add_theme_constant_override("margin_left", margin_x)
	main_margin.add_theme_constant_override("margin_right", margin_x)
	main_margin.add_theme_constant_override("margin_top", margin_y)
	main_margin.add_theme_constant_override("margin_bottom", margin_y)
	menu_columns.add_theme_constant_override("separation", 14 if compact else 32)
	left_panel.custom_minimum_size.x = 390.0 if compact else 540.0
	var menu_stack: VBoxContainer = $MainMargin/MainHBox/LeftPanel/VBox
	menu_stack.add_theme_constant_override("separation", 8 if compact else 12)
	logo_texture.custom_minimum_size = Vector2(220, 220) if compact else Vector2(360, 360)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _populate_levels() -> void:
	level_option.clear()
	for cfg in GameState.LEVEL_CONFIGS:
		level_option.add_item(String(cfg["name"]))
	level_option.select(GameState.current_level_index)
	_update_level_desc(GameState.current_level_index)

func _populate_settings() -> void:
	quality_option.clear()
	quality_option.add_item("Rendah (Laptop Standar / Hemat GPU)")
	quality_option.add_item("Sedang (Seimbang)")
	quality_option.add_item("Tinggi (Laptop Gaming / Bayangan Penuh)")
	quality_option.select(int(GameState.current_graphics_quality))
	if display_option != null:
		display_option.select(1 if GameState.fullscreen_enabled else 0)
	if guide_display_checkbox != null:
		guide_display_checkbox.button_pressed = GameState.show_world_guide_arrow
	sens_slider.value = GameState.mouse_sensitivity * 1000.0
	vol_slider.value = GameState.master_volume * 100.0

func _on_level_selected(idx: int) -> void:
	AudioManager.play_sfx("click")
	GameState.current_level_index = idx
	_update_level_desc(idx)

func _update_level_desc(idx: int) -> void:
	var cfg: Dictionary = GameState.LEVEL_CONFIGS[idx]
	level_desc_label.text = "%s\nSuhu: %.1f°C | Hujan: %.0f mm | Angin: %.0f km/h | Air: %.0f L" % [
		String(cfg["description"]),
		float(cfg["temperature"]),
		float(cfg["rainfall"]),
		float(cfg["wind_speed"]),
		float(cfg["water_capacity"])
	]
	var record: Dictionary = GameState.get_best_record(idx)
	if record.is_empty():
		level_desc_label.text += "\nRekor: Belum ada"
	else:
		var elapsed: int = int(float(record.get("time", 0.0)))
		level_desc_label.text += "\nRekor: %d/100 (%s) • %02d:%02d" % [
			int(record.get("score", 0)), String(record.get("medal", "-")), elapsed / 60, elapsed % 60
		]

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.load_level_config(level_option.selected)
	get_tree().change_scene_to_file("res://scenes/main_simulation.tscn")

func _create_display_setting() -> void:
	# Construct in code to keep older scenes compatible.
	var settings_box: VBoxContainer = $SettingsModal/VBox
	var display_label: Label = Label.new()
	display_label.text = "Mode Tampilan (F11 untuk berganti):"
	display_label.name = "DisplayModeLabel"
	var volume_label: Control = $SettingsModal/VBox/VLabel
	var insertion_index: int = volume_label.get_index()
	settings_box.add_child(display_label)
	settings_box.move_child(display_label, insertion_index)
	display_option = OptionButton.new()
	display_option.name = "DisplayModeOption"
	display_option.add_item("Windowed (Jendela)")
	display_option.add_item("Fullscreen Borderless (Layar Penuh)")
	settings_box.add_child(display_option)
	settings_box.move_child(display_option, insertion_index + 1)
	display_option.item_selected.connect(_on_display_mode_selected)

func _create_guide_display_setting() -> void:
	guide_display_checkbox = CheckBox.new()
	guide_display_checkbox.name = "ShowNavigationArrow"
	guide_display_checkbox.text = "Tampilkan panah panduan di depan pemain (FPS/TPP)"
	guide_display_checkbox.tooltip_text = "Penanda pada radar tetap ada walau panah depan dimatikan."
	guide_display_checkbox.button_pressed = GameState.show_world_guide_arrow
	var settings_box: VBoxContainer = $SettingsModal/VBox
	var close_button: Control = $SettingsModal/VBox/BtnCloseSettings
	settings_box.add_child(guide_display_checkbox)
	settings_box.move_child(guide_display_checkbox, close_button.get_index())
	guide_display_checkbox.toggled.connect(GameState.set_world_guide_arrow_visible)

func _on_display_mode_selected(index: int) -> void:
	AudioManager.play_sfx("click")
	GameState.set_fullscreen(index == 1)

func _on_quality_selected(idx: int) -> void:
	AudioManager.play_sfx("click")
	GameState.set_graphics_quality(idx as GameState.GraphicsQuality)

func _on_sens_changed(val: float) -> void:
	GameState.mouse_sensitivity = val * 0.001

func _on_vol_changed(val: float) -> void:
	GameState.set_master_volume(val / 100.0)

func _show_only_modal(target: PanelContainer) -> void:
	if target == settings_modal and display_option != null:
		display_option.select(1 if GameState.fullscreen_enabled else 0)
	AudioManager.play_sfx("click")
	modal_backdrop.visible = true
	modal_backdrop.modulate.a = 0.0
	guide_modal.visible = (target == guide_modal)
	settings_modal.visible = (target == settings_modal)
	credits_modal.visible = (target == credits_modal)
	target.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(modal_backdrop, "modulate:a", 1.0, 0.16)
	tw.tween_property(target, "modulate:a", 1.0, 0.16)

func _close_modals() -> void:
	AudioManager.play_sfx("click")
	modal_backdrop.visible = false
	guide_modal.visible = false
	settings_modal.visible = false
	credits_modal.visible = false

# Character appearance is a local cosmetic preference saved between sessions.
func _create_wardrobe() -> void:
	var button: Button = Button.new()
	button.name = "BtnWardrobe"
	button.text = "KUSTOMISASI PETUGAS  [HELM & SERAGAM]"
	button.custom_minimum_size.y = 43.0
	var menu_box: VBoxContainer = btn_start.get_parent() as VBoxContainer
	menu_box.add_child(button)
	menu_box.move_child(button, btn_start.get_index() + 1)
	button.pressed.connect(_open_wardrobe)
	wardrobe_dialog = ConfirmationDialog.new()
	wardrobe_dialog.title = "PERLENGKAPAN SATRIA GAMBUT"
	wardrobe_dialog.ok_button_text = "SIMPAN PENAMPILAN"
	wardrobe_dialog.cancel_button_text = "BATAL"
	wardrobe_dialog.min_size = Vector2i(390, 250)
	add_child(wardrobe_dialog)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	wardrobe_dialog.add_child(stack)
	var info: Label = Label.new()
	info.text = "Pilih penampilan petugas untuk kamera TPP.\nTidak memengaruhi tingkat kesulitan atau alat."
	stack.add_child(info)
	var uniform_label: Label = Label.new()
	uniform_label.text = "WARNA JAKET / SERAGAM"
	stack.add_child(uniform_label)
	uniform_choice = OptionButton.new()
	for name_str in GameState.UNIFORM_NAMES:
		uniform_choice.add_item(name_str)
	stack.add_child(uniform_choice)
	var helmet_label: Label = Label.new()
	helmet_label.text = "WARNA HELM"
	stack.add_child(helmet_label)
	helmet_choice = OptionButton.new()
	for name_str in GameState.HELMET_NAMES:
		helmet_choice.add_item(name_str)
	stack.add_child(helmet_choice)
	wardrobe_dialog.confirmed.connect(_save_wardrobe)

func _open_wardrobe() -> void:
	AudioManager.play_sfx("click")
	uniform_choice.select(GameState.uniform_index)
	helmet_choice.select(GameState.helmet_index)
	wardrobe_dialog.popup_centered()

func _save_wardrobe() -> void:
	GameState.set_outfit(uniform_choice.selected, helmet_choice.selected)
	AudioManager.play_sfx("click")

# V8.6: visual redesign only. The original Satria Gambut logo texture,
# scene destinations, navigation buttons and game settings are untouched.
func _apply_modern_menu_design() -> void:
	var base: ColorRect = $Background
	base.color = Color(0.017, 0.039, 0.047, 1.0)
	_add_menu_ambient_accents()

	var right_panel: PanelContainer = $MainMargin/MainHBox/RightPanel
	left_panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.24, 0.88, 0.69), true))
	right_panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.24, 0.58, 0.61), true))
	var level_box: PanelContainer = $MainMargin/MainHBox/LeftPanel/VBox/LevelBox
	level_box.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.90, 0.69, 0.30), false))

	var heading: Label = $MainMargin/MainHBox/LeftPanel/VBox/TitleLabel
	heading.add_theme_font_size_override("font_size", 35)
	heading.add_theme_color_override("font_color", Color(0.97, 0.82, 0.32))
	heading.add_theme_color_override("font_shadow_color", Color(0.02, 0.17, 0.16, 0.65))
	heading.add_theme_constant_override("shadow_offset_x", 1)
	heading.add_theme_constant_override("shadow_offset_y", 3)
	var subtitle: Label = $MainMargin/MainHBox/LeftPanel/VBox/SubtitleLabel
	subtitle.add_theme_color_override("font_color", Color(0.66, 0.85, 0.79))
	subtitle.add_theme_font_size_override("font_size", 13)
	var level_title: Label = $MainMargin/MainHBox/LeftPanel/VBox/LevelBox/ContentVBox/SelectLabel
	level_title.text = "01   /   PILIH OPERASI LAPANGAN"
	level_title.add_theme_color_override("font_color", Color(1.0, 0.79, 0.36))
	level_title.add_theme_font_size_override("font_size", 12)
	level_desc_label.add_theme_color_override("font_color", Color(0.78, 0.89, 0.84))

	_style_menu_button(btn_start, Color(0.12, 0.53, 0.39), true)
	_style_menu_button(btn_guide, Color(0.10, 0.23, 0.26), false)
	_style_menu_button(btn_settings, Color(0.10, 0.23, 0.26), false)
	_style_menu_button(btn_credits, Color(0.10, 0.23, 0.26), false)
	_style_menu_button(btn_quit, Color(0.29, 0.13, 0.15), false)
	btn_start.text = "MULAI OPERASI    /    ▶"
	btn_guide.text = "PANDUAN    •    PROSEDUR LAPANGAN"
	btn_settings.text = "PENGATURAN    •    TAMPILAN & AUDIO"
	btn_credits.text = "CREDITS    •    TIM PENGEMBANG"
	btn_quit.text = "KELUAR DARI PERMAINAN"

	var wardrobe_button: Button = $MainMargin/MainHBox/LeftPanel/VBox/BtnWardrobe
	_style_menu_button(wardrobe_button, Color(0.18, 0.35, 0.29), false)
	wardrobe_button.text = "PERSONALISASI    •    HELM & SERAGAM"
	_style_menu_option(level_option)

	var fact: Label = $MainMargin/MainHBox/RightPanel/VBox/FactLabel
	fact.add_theme_color_override("font_color", Color(0.68, 0.85, 0.79))
	fact.add_theme_font_size_override("font_size", 13)
	# LogoTexture is deliberately not changed or replaced.
	for panel in [guide_modal, settings_modal, credits_modal]:
		panel.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.32, 0.89, 0.75), true))
	for title in [
		$GuideModal/VBox/Title,
		$SettingsModal/VBox/Title,
		$CreditsModal/VBox/Title
	]:
		(title as Label).add_theme_color_override("font_color", Color(0.98, 0.81, 0.39))
		(title as Label).add_theme_font_size_override("font_size", 22)
	for item in [
		$GuideModal/VBox/BtnCloseGuide,
		$SettingsModal/VBox/BtnCloseSettings,
		$CreditsModal/VBox/BtnCloseCredits
	]:
		_style_menu_button(item as Button, Color(0.14, 0.49, 0.40), true)
	_style_menu_option(quality_option)
	if display_option != null:
		_style_menu_option(display_option)
	if guide_display_checkbox != null:
		guide_display_checkbox.add_theme_color_override("font_color", Color(0.78, 0.96, 0.85))
		guide_display_checkbox.add_theme_font_size_override("font_size", 12)
	for slider in [sens_slider, vol_slider]:
		_style_menu_slider(slider)
	for modal_body in [$GuideModal/VBox/Body, $CreditsModal/VBox/Body]:
		(modal_body as Label).add_theme_color_override("font_color", Color(0.82, 0.92, 0.89))
		(modal_body as Label).add_theme_font_size_override("font_size", 13)
	# The wardrobe dialog is also restyled without replacing its controls.
	if wardrobe_dialog != null:
		wardrobe_dialog.add_theme_stylebox_override("panel", _menu_panel_style(Color(0.33, 0.85, 0.66), true))
		_style_menu_option(uniform_choice)
		_style_menu_option(helmet_choice)
	modal_backdrop.color = Color(0.007, 0.025, 0.031, 0.87)
	_animate_menu_intro()

func _menu_panel_style(accent: Color, prominent: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.033, 0.080, 0.093, 0.96) if prominent else Color(0.062, 0.125, 0.132, 0.92)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.75)
	style.set_border_width_all(2 if prominent else 1)
	style.set_corner_radius_all(19 if prominent else 13)
	style.content_margin_left = 22 if prominent else 16
	style.content_margin_right = 22 if prominent else 16
	style.content_margin_top = 18 if prominent else 12
	style.content_margin_bottom = 18 if prominent else 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.38)
	style.shadow_size = 14 if prominent else 8
	return style

func _button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _style_menu_button(button: Button, base_color: Color, emphasized: bool) -> void:
	if button == null:
		return
	button.add_theme_stylebox_override("normal", _button_style(base_color, base_color.lightened(0.30)))
	button.add_theme_stylebox_override("hover", _button_style(base_color.lightened(0.16), Color(0.45, 0.98, 0.75)))
	button.add_theme_stylebox_override("pressed", _button_style(base_color.darkened(0.18), Color(0.90, 0.79, 0.35)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.0, 0.0, 0.0, 0.0), Color(0.66, 1.0, 0.85)))
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.80))
	button.add_theme_font_size_override("font_size", 16 if emphasized else 13)
	button.custom_minimum_size.y = 49 if emphasized else 39
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pivot_offset = button.size / 2.0
	button.mouse_entered.connect(func() -> void:
		if not is_instance_valid(button):
			return
		var tween: Tween = create_tween()
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	button.mouse_exited.connect(func() -> void:
		if not is_instance_valid(button):
			return
		var tween: Tween = create_tween()
		tween.tween_property(button, "modulate", Color(0.92, 0.97, 0.95, 1.0), 0.14)
	)

func _style_menu_option(option: OptionButton) -> void:
	if option == null:
		return
	var base_color: Color = Color(0.07, 0.17, 0.19)
	option.add_theme_stylebox_override("normal", _button_style(base_color, Color(0.22, 0.65, 0.56)))
	option.add_theme_stylebox_override("hover", _button_style(base_color.lightened(0.11), Color(0.42, 0.92, 0.74)))
	option.add_theme_stylebox_override("pressed", _button_style(base_color.darkened(0.1), Color(0.35, 0.80, 0.65)))
	option.add_theme_color_override("font_color", Color(0.92, 0.97, 0.93))
	option.custom_minimum_size.y = 39

func _style_menu_slider(slider: HSlider) -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0.09, 0.26, 0.28)
	track.set_corner_radius_all(5)
	track.content_margin_top = 4
	track.content_margin_bottom = 4
	var filled: StyleBoxFlat = StyleBoxFlat.new()
	filled.bg_color = Color(0.27, 0.86, 0.68)
	filled.set_corner_radius_all(5)
	filled.content_margin_top = 4
	filled.content_margin_bottom = 4
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)

func _add_menu_ambient_accents() -> void:
	# Static decorative layers; they cannot intercept mouse input.
	var strip: ColorRect = ColorRect.new()
	strip.name = "AccentStripeTop"
	strip.color = Color(0.21, 0.78, 0.62, 0.35)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.set_anchors_preset(Control.PRESET_TOP_WIDE)
	strip.custom_minimum_size.y = 3
	add_child(strip)
	move_child(strip, 1)
	strip.offset_bottom = 3
	var ribbon: ColorRect = ColorRect.new()
	ribbon.name = "AmbientBottomRibbon"
	ribbon.color = Color(0.10, 0.33, 0.33, 0.20)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	add_child(ribbon)
	move_child(ribbon, 2)
	ribbon.offset_top = -58

func _animate_menu_intro() -> void:
	left_panel.modulate.a = 0.0
	var right_panel: PanelContainer = $MainMargin/MainHBox/RightPanel
	right_panel.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(left_panel, "modulate:a", 1.0, 0.34)
	tween.parallel().tween_property(right_panel, "modulate:a", 1.0, 0.50).set_delay(0.10)
