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
var stop_confirmation: ConfirmationDialog
var outfit_dialog: ConfirmationDialog
var outfit_suit: OptionButton
var outfit_helmet: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_sync_controls()

	quality_option.item_selected.connect(_on_quality_selected)
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_menu.pressed.connect(_on_stop_requested)
	_create_stop_confirmation()
	_create_pause_wardrobe()
	EventBus.game_phase_changed.connect(_on_phase_changed)

func set_resume_callback(cb: Callable) -> void:
	resume_callback = cb

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if (outfit_dialog != null and outfit_dialog.visible) or (stop_confirmation != null and stop_confirmation.visible):
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

func _create_stop_confirmation() -> void:
	stop_confirmation = ConfirmationDialog.new()
	stop_confirmation.title = "Akhiri Operasi?"
	stop_confirmation.dialog_text = "Operasi ini akan dihentikan tanpa kemenangan.\n\nHasil sementara, jumlah hotspot, air yang terpakai, dan grafik akan ditampilkan di layar evaluasi.\n\nAnda masih bisa mengulang level atau kembali ke menu setelah melihat evaluasi."
	stop_confirmation.ok_button_text = "AKHIRI & LIHAT HASIL"
	stop_confirmation.cancel_button_text = "LANJUTKAN MISI"
	add_child(stop_confirmation)
	stop_confirmation.confirmed.connect(_on_stop_confirmed)

func _on_stop_requested() -> void:
	AudioManager.play_sfx("click")
	stop_confirmation.popup_centered()

func _on_stop_confirmed() -> void:
	if GameState.current_phase != ToolEnums.GamePhase.PAUSED:
		return
	AudioManager.play_sfx("click")
	# Resume the scene tree before changing the phase: evaluation input and
	# telemetry must run even though the stop originated from Pause.
	get_tree().paused = false
	GameState.mission_score = 0
	GameState.mission_medal = "-"
	GameState.last_new_record = false
	GameState.mission_notes = "Operasi dihentikan sukarela. Statistik merupakan hasil sementara; hotspot masih aktif."
	GameState.set_game_phase(ToolEnums.GamePhase.ABORTED)

# Wardrobe is accessible during a paused mission and updates the TPP avatar
# immediately; it doesn't restart the level or spend resources.
func _create_pause_wardrobe() -> void:
	var button: Button = Button.new()
	button.name = "BtnOutfit"
	button.text = "GANTI HELM & SERAGAM"
	button.custom_minimum_size.y = 39.0
	var box: VBoxContainer = btn_resume.get_parent() as VBoxContainer
	box.add_child(button)
	box.move_child(button, btn_resume.get_index() + 1)
	button.pressed.connect(_open_pause_wardrobe)
	outfit_dialog = ConfirmationDialog.new()
	outfit_dialog.title = "KOSTUM PETUGAS"
	outfit_dialog.ok_button_text = "PAKAI KOSTUM"
	outfit_dialog.cancel_button_text = "BATAL"
	outfit_dialog.min_size = Vector2i(375, 240)
	add_child(outfit_dialog)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 9)
	outfit_dialog.add_child(content)
	var suit_label: Label = Label.new()
	suit_label.text = "JAKET / SERAGAM"
	content.add_child(suit_label)
	outfit_suit = OptionButton.new()
	for title in GameState.UNIFORM_NAMES:
		outfit_suit.add_item(title)
	content.add_child(outfit_suit)
	var helmet_label: Label = Label.new()
	helmet_label.text = "HELM"
	content.add_child(helmet_label)
	outfit_helmet = OptionButton.new()
	for title in GameState.HELMET_NAMES:
		outfit_helmet.add_item(title)
	content.add_child(outfit_helmet)
	outfit_dialog.confirmed.connect(_apply_pause_wardrobe)

func _open_pause_wardrobe() -> void:
	outfit_suit.select(GameState.uniform_index)
	outfit_helmet.select(GameState.helmet_index)
	outfit_dialog.popup_centered()

func _apply_pause_wardrobe() -> void:
	GameState.set_outfit(outfit_suit.selected, outfit_helmet.selected)
	AudioManager.play_sfx("click")
