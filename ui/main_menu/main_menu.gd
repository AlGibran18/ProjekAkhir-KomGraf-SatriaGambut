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
	_create_wardrobe()
	_populate_settings()
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
