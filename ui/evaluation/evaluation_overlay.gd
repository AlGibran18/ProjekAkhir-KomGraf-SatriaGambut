# ui/evaluation/evaluation_overlay.gd - Pengendali layar evaluasi akhir misi (Panel 6: 100% Hotspot Padam, neraca karbon, dan navigasi level).
class_name EvaluationOverlay
extends Control

@onready var status_title: Label = $CenterPanel/VBox/StatusTitle
@onready var banner_label: Label = $CenterPanel/VBox/BannerPanel/BannerLabel
@onready var checklist_label: Label = $CenterPanel/VBox/ChecklistLabel
@onready var metrics_label: Label = $CenterPanel/VBox/MetricsLabel
@onready var btn_next_level: Button = $CenterPanel/VBox/BtnRow/BtnNextLevel
@onready var btn_retry: Button = $CenterPanel/VBox/BtnRow/BtnRetry
@onready var btn_menu: Button = $CenterPanel/VBox/BtnRow/BtnMenu

func _ready() -> void:
	visible = false
	btn_next_level.pressed.connect(_on_next_level_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	EventBus.game_phase_changed.connect(_on_phase_changed)

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	var is_end: bool = (new_phase == ToolEnums.GamePhase.VICTORY or new_phase == ToolEnums.GamePhase.DEFEAT)
	visible = is_end
	if not is_end:
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var is_victory: bool = (new_phase == ToolEnums.GamePhase.VICTORY)
	var safe_pct: float = (float(GameState.safe_cells) / maxf(1.0, float(GameState.total_cells))) * 100.0
	var mins: int = int(GameState.mission_elapsed_sec) / 60
	var secs: int = int(GameState.mission_elapsed_sec) % 60

	if is_victory:
		status_title.text = "6. MISI BERHASIL!"
		status_title.modulate = Color(0.45, 1.0, 0.55)
		banner_label.text = "100% Hotspot Padam — Cadangan Karbon Selamat"
		checklist_label.text = "[✓] Api Padam Tuntas   |   [✓] Hutan Gambut Pulih   |   [✓] Cadangan Karbon Terjaga"
		checklist_label.modulate = Color(0.75, 1.0, 0.80)
	else:
		status_title.text = "MISI GAGAL"
		status_title.modulate = Color(1.0, 0.42, 0.38)
		banner_label.text = "Kebakaran Lahan Gambut Melampaui Ambang Batas!"
		checklist_label.text = "[X] Gunakan Sekat Api [1] untuk memotong jalur angin & Tombak Gambut [3] untuk bara dalam!"
		checklist_label.modulate = Color(1.0, 0.78, 0.65)

	metrics_label.text = "LAPORAN EVALUASI ILMIAH:\n• Durasi Operasi: %02d:%02d\n• Lahan Gambut Selamat: %.1f%% (%d dari %d petak)\n• Cadangan Karbon Terselamatkan: %.1f ton CO₂e\n• Emisi Karbon Terlepas: %.1f ton CO₂e\n• Total Air Digunakan: %.0f Liter (%d Sumur Air terpasang)\n\nCatatan Edukasi: Lahan gambut menyimpan karbon 3x lebih besar dari hutan biasa. Menyuntikkan air ke bara bawah permukaan mencegah re-ignition!" % [
		mins, secs, safe_pct, GameState.safe_cells, GameState.total_cells,
		GameState.carbon_saved_tons, GameState.carbon_released_tons,
		GameState.water_used_total, GameState.placed_wells.size()
	]

	btn_next_level.visible = is_victory and (GameState.current_level_index < GameState.LEVEL_CONFIGS.size() - 1)

func _on_next_level_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.load_level_config(GameState.current_level_index + 1)
	get_tree().reload_current_scene()

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("click")
	GameState.load_level_config(GameState.current_level_index)
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	AudioManager.play_sfx("click")
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")
