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

var analytics_backdrop: Control
var chart: MissionTrendChart
var analytics_info: Label
var export_status: Label

func _ready() -> void:
	_create_analytics_ui()
	visible = false
	btn_next_level.pressed.connect(_on_next_level_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)
	EventBus.game_phase_changed.connect(_on_phase_changed)

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	var is_end: bool = (new_phase == ToolEnums.GamePhase.VICTORY or new_phase == ToolEnums.GamePhase.DEFEAT or new_phase == ToolEnums.GamePhase.ABORTED)
	visible = is_end
	if not is_end:
		return

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var is_victory: bool = (new_phase == ToolEnums.GamePhase.VICTORY)
	var is_aborted: bool = (new_phase == ToolEnums.GamePhase.ABORTED)
	var safe_pct: float = (float(GameState.safe_cells) / maxf(1.0, float(GameState.total_cells))) * 100.0
	var mins: int = int(GameState.mission_elapsed_sec) / 60
	var secs: int = int(GameState.mission_elapsed_sec) % 60

	if is_victory:
		status_title.text = "6. MISI BERHASIL!"
		status_title.modulate = Color(0.45, 1.0, 0.55)
		banner_label.text = "100% Hotspot Padam — Cadangan Karbon Selamat"
		checklist_label.text = "[✓] Api Padam Tuntas   |   [✓] Hutan Gambut Pulih   |   [✓] Cadangan Karbon Terjaga"
		checklist_label.modulate = Color(0.75, 1.0, 0.80)
	elif is_aborted:
		status_title.text = "OPERASI DIHENTIKAN"
		status_title.modulate = Color(1.0, 0.83, 0.43)
		banner_label.text = "Laporan Sementara — Level %d" % (GameState.current_level_index + 1)
		checklist_label.text = "Hotspot tersisa: %d  |  Bara tersembunyi: %d  |  Pos: %s" % [
			GameState.active_fire_cells, GameState.subsurface_only_cells,
			"AMAN" if GameState.station_safe else "TERDAMPAK"
		]
		checklist_label.modulate = Color(1.0, 0.88, 0.64)
	else:
		status_title.text = "MISI GAGAL"
		status_title.modulate = Color(1.0, 0.42, 0.38)
		banner_label.text = "Kebakaran Lahan Gambut Melampaui Ambang Batas!"
		checklist_label.text = "[X] Gunakan Sekat Api [1] untuk memotong jalur angin & Tombak Gambut [3] untuk bara dalam!"
		checklist_label.modulate = Color(1.0, 0.78, 0.65)

	var record_message: String = "REKOR BARU!\n" if is_victory and GameState.last_new_record else ""
	var medal_section: String = "SKOR MISI: %d/100  |  MEDALI: %s\n%s%s\n\n" % [GameState.mission_score, GameState.mission_medal, record_message, GameState.mission_notes]
	if is_aborted:
		medal_section = "STATUS: DIHENTIKAN SUKARELA  |  TIDAK ADA MEDALI\n%s\n\n" % GameState.mission_notes
	metrics_label.text = medal_section + ("RINGKASAN HASIL SEMENTARA:\n" if is_aborted else "LAPORAN EVALUASI ILMIAH:\n") + "• Durasi Operasi: %02d:%02d\n• Lahan Gambut Selamat: %.1f%% (%d dari %d petak)\n• Cadangan Karbon Terselamatkan: %.1f ton CO₂e\n• Emisi Karbon Terlepas: %.1f ton CO₂e\n• Total Air Digunakan: %.0f Liter (%d Sumur Air terpasang)\n\nCatatan Edukasi: Lahan gambut menyimpan karbon 3x lebih besar dari hutan biasa. Menyuntikkan air ke bara bawah permukaan mencegah re-ignition!" % [
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

# Mission data can be viewed during an end-of-level screen only.
func _get_telemetry() -> MissionTelemetry:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("MissionTelemetry") as MissionTelemetry

func _create_analytics_ui() -> void:
	var row: HBoxContainer = $CenterPanel/VBox/BtnRow
	var parent_box: VBoxContainer = $CenterPanel/VBox
	var analytics_button: Button = Button.new()
	analytics_button.name = "BtnAnalytics"
	analytics_button.text = "GRAFIK PERKEMBANGAN MISI & EKSPOR DATA"
	analytics_button.custom_minimum_size = Vector2(0.0, 40.0)
	parent_box.add_child(analytics_button)
	parent_box.move_child(analytics_button, row.get_index())
	analytics_button.pressed.connect(_show_analytics)
	analytics_backdrop = Control.new()
	analytics_backdrop.name = "AnalyticsBackdrop"
	analytics_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(analytics_backdrop)
	analytics_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.01, 0.035, 0.038, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	analytics_backdrop.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "AnalyticsPanel"
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.09, 0.10, 0.98)
	style.border_color = Color(0.22, 0.72, 0.65)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)
	analytics_backdrop.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.offset_left = -390.0
	panel.offset_right = 390.0
	panel.offset_top = -255.0
	panel.offset_bottom = 255.0
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	panel.add_child(stack)
	var title_label: Label = Label.new()
	title_label.text = "ANALISIS OPERASI PEMADAMAN"
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color(0.91, 0.84, 0.38))
	stack.add_child(title_label)
	analytics_info = Label.new()
	analytics_info.add_theme_font_size_override("font_size", 14)
	stack.add_child(analytics_info)
	chart = MissionTrendChart.new()
	chart.custom_minimum_size = Vector2(680, 245)
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(chart)
	var note: Label = Label.new()
	note.text = "Tren simulasi game; estimasi karbon bukan pengukuran lapangan."
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color(0.7, 0.80, 0.78))
	stack.add_child(note)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	stack.add_child(controls)
	var btn_export: Button = Button.new()
	btn_export.text = "SIMPAN CSV + JSON"
	btn_export.custom_minimum_size.x = 205
	controls.add_child(btn_export)
	btn_export.pressed.connect(_export_analytics)
	var close_btn: Button = Button.new()
	close_btn.text = "KEMBALI KE EVALUASI"
	close_btn.custom_minimum_size.x = 200
	controls.add_child(close_btn)
	close_btn.pressed.connect(func() -> void: analytics_backdrop.visible = false)
	export_status = Label.new()
	export_status.add_theme_font_size_override("font_size", 12)
	export_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(export_status)
	analytics_backdrop.visible = false

func _show_analytics() -> void:
	var telemetry: MissionTelemetry = _get_telemetry()
	if telemetry == null or not telemetry.report_ready:
		return
	chart.set_samples(telemetry.samples)
	analytics_info.text = "Level %d  |  %d sampel  |  Puncak %d hotspot  |  Sekat api %d  |  Injeksi %d" % [
		GameState.current_level_index + 1, telemetry.samples.size(), telemetry.peak_hotspots,
		int(telemetry.tool_counts["firebreaks"]), int(telemetry.tool_counts["injections"])
	]
	export_status.text = ""
	analytics_backdrop.visible = true

func _export_analytics() -> void:
	var telemetry: MissionTelemetry = _get_telemetry()
	if telemetry == null:
		export_status.text = "Data misi tidak tersedia."
		return
	var result: Dictionary = telemetry.export_reports()
	if bool(result.get("ok", false)):
		export_status.text = "Tersimpan di folder: user://mission_reports (Project > Open User Data Folder)"
		print("Mission reports: ", result.get("csv_path", ""), " / ", result.get("json_path", ""))
	else:
		export_status.text = String(result.get("message", "Ekspor gagal."))
