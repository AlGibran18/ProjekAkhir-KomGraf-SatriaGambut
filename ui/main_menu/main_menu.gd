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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_populate_levels()
	_populate_settings()

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

func _on_start_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.load_level_config(level_option.selected)
	get_tree().change_scene_to_file("res://scenes/main_simulation.tscn")

func _on_quality_selected(idx: int) -> void:
	AudioManager.play_sfx("click")
	GameState.set_graphics_quality(idx as GameState.GraphicsQuality)

func _on_sens_changed(val: float) -> void:
	GameState.mouse_sensitivity = val * 0.001

func _on_vol_changed(val: float) -> void:
	GameState.set_master_volume(val / 100.0)

func _show_only_modal(target: PanelContainer) -> void:
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
