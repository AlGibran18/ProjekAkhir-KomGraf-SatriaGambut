# ui/pause/pause_menu.gd - Pengendali layar jeda (Pause Menu) saat operasi FPS: pengatur grafis, sensitivitas, volume, ulangi, dan kembali ke menu.
class_name PauseMenu
extends Control

@onready var quality_option: OptionButton = $CenterPanel/VBox/QualityOption
@onready var sens_slider: HSlider = $CenterPanel/VBox/SensSlider
@onready var vol_slider: HSlider = $CenterPanel/VBox/VolSlider
@onready var btn_resume: Button = $CenterPanel/VBox/BtnResume
@onready var btn_restart: Button = $CenterPanel/VBox/BtnRestart
@onready var btn_menu: Button = $CenterPanel/VBox/BtnMenu

var resume_callback: Callable

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_sync_controls()

	quality_option.item_selected.connect(_on_quality_selected)
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	EventBus.game_phase_changed.connect(_on_phase_changed)

func set_resume_callback(cb: Callable) -> void:
	resume_callback = cb

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

func _sync_controls() -> void:
	quality_option.clear()
	quality_option.add_item("Rendah (Hemat GPU)")
	quality_option.add_item("Sedang (Seimbang)")
	quality_option.add_item("Tinggi (Bayangan Penuh)")
	quality_option.select(int(GameState.current_graphics_quality))
	sens_slider.value = GameState.mouse_sensitivity * 1000.0
	vol_slider.value = GameState.master_volume * 100.0

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	var is_paused: bool = (new_phase == ToolEnums.GamePhase.PAUSED)
	visible = is_paused
	get_tree().paused = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_sync_controls()

func _on_quality_selected(idx: int) -> void:
	AudioManager.play_sfx("click")
	GameState.set_graphics_quality(idx as GameState.GraphicsQuality)

func _on_sens_changed(val: float) -> void:
	GameState.mouse_sensitivity = val * 0.001

func _on_vol_changed(val: float) -> void:
	GameState.set_master_volume(val / 100.0)

func _on_resume_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	GameState.set_game_phase(ToolEnums.GamePhase.ACTIVE_FPS)
	if resume_callback.is_valid():
		resume_callback.call()

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	GameState.load_level_config(GameState.current_level_index)
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
