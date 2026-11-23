# ui/hud/hud.gd - HUD gameplay ringkas bergaya game modern: radar bulat, hotbar alat, tangki air, tag petak kontekstual, dan toast papan kayu jungle.
class_name HUD
extends CanvasLayer

const MARGIN: float = 20.0
const RADAR_SIZE: float = 188.0

var frame: Control
var water_gauge: WaterGauge
var tool_slots: Array[HudToolSlot] = []
var tool_name_label: Label
var toast_board: JungleBoard
var toast_holder: CenterContainer
var toast_label: Label
var well_prompt: PanelContainer
var hover_tag: PanelContainer
var hover_title: Label
var hover_detail: Label
var crosshair_control: Control
var crosshair_reticle: Control
var injection_panel: PanelContainer
var injection_bar: ProgressBar
var thermal_visor: TextureRect
var minimap_canvas: Control
var radar_ring: Control
var wind_label: Label
var radar_caption: Label

var grid_simulator: GridSimulator
var player_node: Node3D
var toast_timer: float = 0.0
var minimap_timer: float = 0.0
var proximity_timer: float = 0.0
var weather_timer: float = 0.0
var danger_strength: float = 0.0
var danger_overlay: ColorRect
var expanded_map: Control
var expanded_map_canvas: Control
var map_is_open: bool = false
var previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var nav_cell: Vector2i = Vector2i(-1, -1)
var nav_category: String = ""
var nav_pulse: float = 0.0
var toast_tween: Tween

func _ready() -> void:
	danger_overlay = ColorRect.new()
	danger_overlay.name = "ProximityFireWarning"
	danger_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_overlay.color = Color(0.85, 0.08, 0.025, 0.0)
	add_child(danger_overlay)
	_build_thermal_visor()
	frame = Control.new()
	frame.name = "Frame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_crosshair()
	_build_radar()
	_build_hotbar()
	_build_water_gauge()
	_build_toast()
	_build_well_prompt()
	_create_expanded_map()
	EventBus.water_changed.connect(_on_water_changed)
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.thermal_mode_toggled.connect(_on_thermal_mode_toggled)
	EventBus.cell_hovered.connect(_on_cell_hovered)
	EventBus.educational_toast.connect(_on_educational_toast)
	EventBus.injection_progress_changed.connect(_on_injection_progress_changed)
	EventBus.well_proximity_changed.connect(_on_well_proximity_changed)
	EventBus.game_phase_changed.connect(_on_phase_changed)
	EventBus.navigator_target_changed.connect(_on_navigator_target_changed)
	_on_phase_changed(GameState.current_phase)
	_update_weather_display()
	_on_water_changed(GameState.current_water, GameState.max_water_capacity)
	_on_tool_selected(GameState.current_tool)

func _make_label(text_value: String, font_size: int, color: Color, use_title_font: bool = false) -> Label:
	var node: Label = Label.new()
	node.text = text_value
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	node.add_theme_constant_override("shadow_offset_y", 2)
	if use_title_font:
		node.add_theme_font_override("font", UiStyle.title_font())
	return node

func _pill_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = UiStyle.rounded_box(fill, 22, border, 2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style

func _build_thermal_visor() -> void:
	thermal_visor = TextureRect.new()
	thermal_visor.name = "ThermalVisor"
	thermal_visor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thermal_visor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thermal_visor.stretch_mode = TextureRect.STRETCH_SCALE
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1.0, 0.25, 0.1, 0.0))
	gradient.set_color(1, Color(1.0, 0.25, 0.1, 0.38))
	gradient.set_offset(0, 0.55)
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 1.0)
	tex.width = 256
	tex.height = 256
	thermal_visor.texture = tex
	thermal_visor.visible = false
	add_child(thermal_visor)
	thermal_visor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_crosshair() -> void:
	crosshair_control = Control.new()
	crosshair_control.name = "CenterCrosshair"
	crosshair_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_control.set_anchors_preset(Control.PRESET_CENTER)
	frame.add_child(crosshair_control)
	crosshair_reticle = Control.new()
	crosshair_reticle.name = "Reticle"
	crosshair_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair_control.add_child(crosshair_reticle)
	crosshair_reticle.draw.connect(func() -> void:
		crosshair_reticle.draw_circle(Vector2.ZERO, 2.4, Color.WHITE)
		for quarter in range(4):
			var start: float = float(quarter) * PI * 0.5 + 0.38
			crosshair_reticle.draw_arc(Vector2.ZERO, 13.0, start, start + 0.8, 8, Color.WHITE, 2.6, true)
	)
	crosshair_reticle.queue_redraw()
	hover_tag = PanelContainer.new()
	hover_tag.name = "CellTag"
	hover_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_tag.position = Vector2(30, -22)
	hover_tag.add_theme_stylebox_override("panel", _pill_style(Color(0.06, 0.045, 0.03, 0.86), UiStyle.WOOD))
	hover_tag.visible = false
	crosshair_control.add_child(hover_tag)
	var tag_box: VBoxContainer = VBoxContainer.new()
	tag_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_box.add_theme_constant_override("separation", -2)
	hover_tag.add_child(tag_box)
	hover_title = _make_label("", 20, UiStyle.CREAM, true)
	hover_detail = _make_label("", 16, Color(0.86, 0.9, 0.82))
	tag_box.add_child(hover_title)
	tag_box.add_child(hover_detail)
	injection_panel = PanelContainer.new()
	injection_panel.name = "InjectionPanel"
	injection_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	injection_panel.position = Vector2(-96, 34)
	injection_panel.custom_minimum_size = Vector2(192, 0)
	injection_panel.add_theme_stylebox_override("panel", _pill_style(Color(0.04, 0.09, 0.12, 0.88), UiStyle.WATER))
	injection_panel.visible = false
	crosshair_control.add_child(injection_panel)
	var injection_box: VBoxContainer = VBoxContainer.new()
	injection_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	injection_panel.add_child(injection_box)
	var injection_title: Label = _make_label("Injeksi Air", 17, UiStyle.WATER, true)
	injection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	injection_box.add_child(injection_title)
	injection_bar = ProgressBar.new()
	injection_bar.custom_minimum_size = Vector2(0, 12)
	injection_bar.show_percentage = false
	injection_bar.add_theme_stylebox_override("fill", UiStyle.rounded_box(UiStyle.WATER, 8))
	injection_box.add_child(injection_bar)

func _build_radar() -> void:
	var holder: Control = Control.new()
	holder.name = "RadarHolder"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(holder)
	holder.anchor_left = 1.0
	holder.anchor_right = 1.0
	holder.offset_left = -(RADAR_SIZE + 28.0 + MARGIN)
	holder.offset_right = -MARGIN
	holder.offset_top = MARGIN - 4.0
	holder.offset_bottom = MARGIN + RADAR_SIZE + 66.0
	var disc_size: float = RADAR_SIZE
	var holder_width: float = holder.offset_right - holder.offset_left
	var clip: Panel = Panel.new()
	clip.name = "RadarDisc"
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.position = Vector2((holder_width - disc_size) * 0.5, 10)
	clip.size = Vector2(disc_size, disc_size)
	clip.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	clip.add_theme_stylebox_override("panel", UiStyle.rounded_box(Color.WHITE, int(disc_size)))
	holder.add_child(clip)
	minimap_canvas = Control.new()
	minimap_canvas.name = "MiniMapCanvas"
	minimap_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(minimap_canvas)
	minimap_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	minimap_canvas.draw.connect(_on_minimap_draw)
	radar_ring = Control.new()
	radar_ring.name = "RadarRing"
	radar_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar_ring.position = clip.position
	radar_ring.size = clip.size
	holder.add_child(radar_ring)
	radar_ring.draw.connect(func() -> void:
		var c: Vector2 = radar_ring.size * 0.5
		var r: float = radar_ring.size.x * 0.5
		radar_ring.draw_arc(c, r + 3.0, 0.0, TAU, 64, Color(0, 0, 0, 0.4), 10.0, true)
		radar_ring.draw_arc(c, r + 2.0, 0.0, TAU, 64, UiStyle.WOOD_DARK, 9.0, true)
		radar_ring.draw_arc(c, r + 5.0, 0.0, TAU, 64, UiStyle.WOOD, 2.0, true)
		radar_ring.draw_arc(c, r - 2.0, 0.0, TAU, 64, UiStyle.LEAF_DARK, 2.0, true)
		radar_ring.draw_string(UiStyle.title_font(), Vector2(c.x - 6.0, 21.0), "U", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UiStyle.AMBER)
	)
	radar_caption = _make_label("M  Peta     H  Pandu", 15, Color(0.9, 0.93, 0.8, 0.85))
	radar_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(radar_caption)
	radar_caption.position = Vector2(0, disc_size + 18.0)
	radar_caption.size = Vector2(holder_width, 20)
	wind_label = _make_label("", 17, UiStyle.CREAM, true)
	wind_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	holder.add_child(wind_label)
	wind_label.position = Vector2(0, disc_size + 36.0)
	wind_label.size = Vector2(holder_width, 24)

func _build_hotbar() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.name = "ToolHotbar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	frame.add_child(bar)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_left = -220.0
	bar.offset_right = 220.0
	bar.offset_top = -108.0
	bar.offset_bottom = -12.0
	var defs: Array = [
		{"icon": HudToolSlot.Icon.TRENCH, "key": "1"},
		{"icon": HudToolSlot.Icon.SPRAY, "key": "2"},
		{"icon": HudToolSlot.Icon.LANCE, "key": "3"},
		{"icon": HudToolSlot.Icon.THERMAL, "key": "Tab"}
	]
	for def in defs:
		var slot: HudToolSlot = HudToolSlot.new()
		slot.icon_kind = def["icon"]
		slot.key_text = String(def["key"])
		bar.add_child(slot)
		tool_slots.append(slot)
	tool_slots[0].slot_pressed.connect(func() -> void: _select_tool(ToolEnums.ToolType.SEKAT_BAKAR))
	tool_slots[1].slot_pressed.connect(func() -> void: _select_tool(ToolEnums.ToolType.SEMPROT_PERMUKAAN))
	tool_slots[2].slot_pressed.connect(func() -> void: _select_tool(ToolEnums.ToolType.TOMBAK_GAMBUT))
	tool_slots[3].slot_pressed.connect(_toggle_thermal)
	tool_name_label = _make_label("", 22, UiStyle.AMBER, true)
	tool_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(tool_name_label)
	tool_name_label.anchor_left = 0.5
	tool_name_label.anchor_right = 0.5
	tool_name_label.anchor_top = 1.0
	tool_name_label.anchor_bottom = 1.0
	tool_name_label.offset_left = -200.0
	tool_name_label.offset_right = 200.0
	tool_name_label.offset_top = -140.0
	tool_name_label.offset_bottom = -110.0

func _build_water_gauge() -> void:
	water_gauge = WaterGauge.new()
	water_gauge.name = "WaterGauge"
	frame.add_child(water_gauge)
	water_gauge.anchor_top = 1.0
	water_gauge.anchor_bottom = 1.0
	water_gauge.offset_left = MARGIN
	water_gauge.offset_right = MARGIN + 112.0
	water_gauge.offset_top = -MARGIN - 112.0
	water_gauge.offset_bottom = -MARGIN

func _build_toast() -> void:
	toast_holder = CenterContainer.new()
	toast_holder.name = "ToastHolder"
	toast_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(toast_holder)
	toast_holder.anchor_right = 1.0
	toast_holder.offset_top = 6.0
	toast_holder.offset_bottom = 160.0
	toast_board = JungleBoard.new()
	toast_board.name = "ToastBoard"
	toast_board.seed_key = 3
	toast_board.pad = Vector2(20, 8)
	toast_board.custom_minimum_size = Vector2(520, 0)
	toast_board.visible = false
	toast_holder.add_child(toast_board)
	toast_label = _make_label("", 20, UiStyle.CREAM)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.custom_minimum_size = Vector2(430, 0)
	toast_board.add_child(toast_label)

func _build_well_prompt() -> void:
	well_prompt = PanelContainer.new()
	well_prompt.name = "WellPrompt"
	well_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	well_prompt.add_theme_stylebox_override("panel", _pill_style(Color(0.04, 0.12, 0.17, 0.9), UiStyle.WATER))
	well_prompt.visible = false
	frame.add_child(well_prompt)
	well_prompt.anchor_left = 0.5
	well_prompt.anchor_right = 0.5
	well_prompt.anchor_top = 1.0
	well_prompt.anchor_bottom = 1.0
	well_prompt.grow_horizontal = Control.GROW_DIRECTION_BOTH
	well_prompt.offset_top = -186.0
	well_prompt.offset_bottom = -150.0
	well_prompt.add_child(_make_label("Sumur Air  -  tangki terisi    [E] isi penuh", 20, Color(0.82, 0.96, 1.0), true))

func _process(delta: float) -> void:
	if not visible:
		return
	nav_pulse += delta
	proximity_timer += delta
	if proximity_timer >= 0.25:
		proximity_timer = 0.0
		_calculate_fire_proximity()
	weather_timer += delta
	if weather_timer >= 1.0:
		weather_timer = 0.0
		_update_weather_display()
	var pulse: float = 0.86 + sin(Time.get_ticks_msec() * 0.006) * 0.14
	danger_overlay.color = Color(0.85, 0.08, 0.025, clampf(danger_strength * pulse * 0.10, 0.0, 0.10))
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			_hide_toast()
	if map_is_open and expanded_map_canvas != null:
		expanded_map_canvas.queue_redraw()
	minimap_timer += delta
	if minimap_timer >= 0.12:
		minimap_timer = 0.0
		minimap_canvas.queue_redraw()

func setup_hud(simulator: GridSimulator, player: Node3D) -> void:
	grid_simulator = simulator
	player_node = player
	_update_weather_display()
	minimap_canvas.queue_redraw()

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	if new_phase != ToolEnums.GamePhase.ACTIVE_FPS and map_is_open:
		_toggle_map(false)
	visible = (new_phase == ToolEnums.GamePhase.ACTIVE_FPS)
	if visible:
		_update_weather_display()
		minimap_canvas.queue_redraw()

func _select_tool(tool_type: ToolEnums.ToolType) -> void:
	GameState.current_tool = tool_type
	EventBus.tool_selected.emit(tool_type)

func _toggle_thermal() -> void:
	GameState.is_thermal_active = not GameState.is_thermal_active
	EventBus.thermal_mode_toggled.emit(GameState.is_thermal_active)

func _on_water_changed(current: float, max_val: float) -> void:
	if water_gauge != null:
		water_gauge.set_level(current, max_val)

func _on_tool_selected(tool_type: ToolEnums.ToolType) -> void:
	if tool_slots.size() < 4:
		return
	tool_slots[0].set_selected(tool_type == ToolEnums.ToolType.SEKAT_BAKAR)
	tool_slots[1].set_selected(tool_type == ToolEnums.ToolType.SEMPROT_PERMUKAAN)
	tool_slots[2].set_selected(tool_type == ToolEnums.ToolType.TOMBAK_GAMBUT)
	var names: Dictionary = {
		ToolEnums.ToolType.SEKAT_BAKAR: "Sekat Api",
		ToolEnums.ToolType.SEMPROT_PERMUKAAN: "Semprot Air",
		ToolEnums.ToolType.TOMBAK_GAMBUT: "Tombak Gambut"
	}
	tool_name_label.text = String(names.get(tool_type, ""))

func _on_thermal_mode_toggled(enabled: bool) -> void:
	thermal_visor.visible = enabled
	if tool_slots.size() >= 4:
		tool_slots[3].set_lit(enabled)
	minimap_canvas.queue_redraw()

func _on_educational_toast(message: String, is_warning: bool) -> void:
	toast_label.text = message
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.6) if is_warning else UiStyle.CREAM)
	toast_board.modulate.a = 0.0
	toast_board.visible = true
	toast_timer = 5.5
	if toast_tween != null:
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_interval(0.12)
	toast_tween.tween_property(toast_board, "modulate:a", 1.0, 0.25)

func _hide_toast() -> void:
	if toast_tween != null:
		toast_tween.kill()
	toast_tween = create_tween()
	toast_tween.tween_property(toast_board, "modulate:a", 0.0, 0.3)
	toast_tween.tween_callback(func() -> void: toast_board.visible = false)

func _on_injection_progress_changed(progress: float, is_active: bool) -> void:
	injection_panel.visible = is_active
	if is_active:
		injection_bar.value = progress * 100.0

func _on_well_proximity_changed(is_near_well: bool) -> void:
	well_prompt.visible = is_near_well

func _on_cell_hovered(pos: Vector2i, cell: PeatCellData) -> void:
	if cell == null or pos == Vector2i(-1, -1):
		hover_tag.visible = false
		crosshair_reticle.modulate = Color(1.0, 1.0, 1.0, 0.88)
		return
	var title: String = ""
	var title_color: Color = UiStyle.CREAM
	crosshair_reticle.modulate = Color(1.0, 1.0, 1.0, 0.92)
	if cell.has_well:
		title = "Sumur Air"
		title_color = UiStyle.WATER
		crosshair_reticle.modulate = Color(0.25, 0.88, 1.0, 1.0)
	elif cell.is_burning() and cell.has_ember():
		title = "Api + Bara Dalam"
		title_color = UiStyle.FIRE
	elif cell.is_burning():
		title = "Api Permukaan"
		title_color = UiStyle.FIRE
	elif cell.has_ember():
		title = "Bara Bawah Tanah"
		title_color = Color(1.0, 0.35, 0.45)
	elif cell.is_firebreak:
		title = "Sekat Api"
		title_color = UiStyle.AMBER
	elif cell.is_burnt:
		title = "Bekas Terbakar"
		title_color = Color(0.7, 0.68, 0.62)
	elif cell.risk_category >= ToolEnums.RiskCategory.TINGGI:
		title = "Rawan Terbakar"
		title_color = PFVICalculator.get_risk_color(cell.risk_category)
	if cell.is_active_hazard():
		crosshair_reticle.modulate = Color(1.0, 0.48, 0.14, 1.0)
	if title.is_empty():
		hover_tag.visible = false
		return
	hover_tag.visible = true
	hover_title.text = title
	hover_title.add_theme_color_override("font_color", title_color)
	hover_detail.text = "Lembap %d%%   Muka air %.0f cm" % [int(cell.soil_moisture * 100.0), cell.water_table]

func _update_weather_display() -> void:
	if wind_label == null:
		return
	var parts: String = "Angin %.0f km/j   %.0f°C" % [GameState.wind_speed_kmh, GameState.ambient_temperature]
	if GameState.global_rainfall_rate >= 1.0:
		parts += "   Hujan"
	wind_label.text = parts

func _input(event: InputEvent) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			_toggle_map(not map_is_open)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and map_is_open:
			_toggle_map(false)
			get_viewport().set_input_as_handled()

func _toggle_map(open: bool) -> void:
	map_is_open = open
	if expanded_map != null:
		expanded_map.visible = open
	if player_node is PlayerController3D:
		var player: PlayerController3D = player_node as PlayerController3D
		player.tactical_map_open = open
	if open:
		previous_mouse_mode = Input.mouse_mode
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS:
			Input.mouse_mode = previous_mouse_mode

func _create_expanded_map() -> void:
	expanded_map = Control.new()
	expanded_map.name = "ExpandedTacticalMap"
	expanded_map.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(expanded_map)
	expanded_map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.015, 0.03, 0.02, 0.86)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	expanded_map.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	expanded_map.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var body: VBoxContainer = VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 10)
	center.add_child(body)
	var title_board: JungleBoard = JungleBoard.new()
	title_board.seed_key = 11
	title_board.custom_minimum_size = Vector2(420, 0)
	title_board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(title_board)
	var title: Label = _make_label("PETA OPERASI", 32, UiStyle.CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_board.add_child(title)
	expanded_map_canvas = Control.new()
	expanded_map_canvas.name = "FullMapCanvas"
	expanded_map_canvas.custom_minimum_size = Vector2(470.0, 470.0)
	expanded_map_canvas.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	expanded_map_canvas.draw.connect(_draw_expanded_map)
	body.add_child(expanded_map_canvas)
	var footer: Label = _make_label("M / Esc  tutup      Kuning  api      Biru  sumur      Hijau  pos", 18, Color(0.9, 0.94, 0.82))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(footer)
	expanded_map.visible = false

func _on_navigator_target_changed(cell: Vector2i, category: String) -> void:
	nav_cell = cell
	nav_category = category
	minimap_canvas.queue_redraw()
	if expanded_map_canvas != null:
		expanded_map_canvas.queue_redraw()

func _draw_expanded_map() -> void:
	if expanded_map_canvas != null:
		_draw_radar(expanded_map_canvas, true)

func _on_minimap_draw() -> void:
	_draw_radar(minimap_canvas, false)

func _draw_radar(canvas: Control, expanded: bool) -> void:
	if grid_simulator == null:
		return
	var sz: Vector2 = canvas.size
	if sz.x < 2.0 or sz.y < 2.0:
		return
	var width: int = grid_simulator.grid_width
	var height: int = grid_simulator.grid_height
	var cell_w: float = sz.x / float(width)
	var cell_h: float = sz.y / float(height)
	var dark: Color = Color(0.035, 0.095, 0.115, 1.0)
	canvas.draw_rect(Rect2(Vector2.ZERO, sz), dark, true)
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		var rect: Rect2 = Rect2(Vector2(float(pos.x) * cell_w, float(pos.y) * cell_h), Vector2(cell_w + 0.4, cell_h + 0.4))
		var color: Color = Color(0.16, 0.32, 0.27) if (pos.x + pos.y) % 3 != 0 else Color(0.13, 0.29, 0.25)
		if cell.is_firebreak:
			color = Color(0.39, 0.34, 0.25)
		elif cell.is_burnt:
			color = Color(0.16, 0.12, 0.105)
		elif cell.is_burning():
			color = Color(0.72, 0.23, 0.10)
		elif GameState.is_thermal_active:
			color = PFVICalculator.get_risk_color(cell.risk_category) * 0.63
		canvas.draw_rect(rect, color, true)
	var line_color: Color = Color(0.50, 0.71, 0.65, 0.16)
	for x in range(0, width + 1, 4):
		var xx: float = float(x) * cell_w
		canvas.draw_line(Vector2(xx, 0), Vector2(xx, sz.y), line_color, 1.0)
	for y in range(0, height + 1, 4):
		var yy: float = float(y) * cell_h
		canvas.draw_line(Vector2(0, yy), Vector2(sz.x, yy), line_color, 1.0)
	var station: Vector2 = Vector2(8.5 * cell_w, 1.5 * cell_h)
	canvas.draw_circle(station, 9.0 if expanded else 4.7, Color(0.18, 0.95, 0.71) if GameState.station_safe else Color(0.98, 0.28, 0.25))
	canvas.draw_arc(station, 13.0 if expanded else 7.0, 0.0, TAU, 24, Color.WHITE, 1.5)
	for well in GameState.placed_wells:
		var wp: Vector2 = Vector2((float(well.x) + 0.5) * cell_w, (float(well.y) + 0.5) * cell_h)
		canvas.draw_circle(wp, 7.0 if expanded else 3.5, Color(0.20, 0.75, 1.0))
		canvas.draw_arc(wp, 10.0 if expanded else 5.5, 0.0, TAU, 16, Color(0.70, 0.95, 1.0), 1.0)
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		if not cell.is_burning() and not (GameState.is_thermal_active and cell.has_ember()):
			continue
		var at: Vector2 = Vector2((float(pos.x) + 0.5) * cell_w, (float(pos.y) + 0.5) * cell_h)
		var radius: float = 6.4 if expanded else 3.0
		var fire_color: Color = Color(1.0, 0.75, 0.18) if cell.is_burning() else Color(0.98, 0.26, 0.43)
		canvas.draw_circle(at, radius, fire_color)
		canvas.draw_arc(at, radius * 1.65, 0.0, TAU, 20, fire_color * Color(1, 1, 1, 0.55), 1.3)
	if player_node != null:
		var cx: float = (player_node.global_position.x / GameState.CELL_SIZE + 0.5) * cell_w
		var cy: float = (player_node.global_position.z / GameState.CELL_SIZE + 0.5) * cell_h
		var player_pos: Vector2 = Vector2(clampf(cx, 3.0, sz.x - 3.0), clampf(cy, 3.0, sz.y - 3.0))
		var basis: Vector3 = -player_node.global_transform.basis.z
		var heading: Vector2 = Vector2(basis.x, basis.z).normalized()
		var perpendicular: Vector2 = Vector2(-heading.y, heading.x)
		var scale: float = 12.0 if expanded else 7.0
		var arrow: PackedVector2Array = PackedVector2Array([
			player_pos + heading * scale,
			player_pos - heading * scale * 0.60 + perpendicular * scale * 0.50,
			player_pos - heading * scale * 0.60 - perpendicular * scale * 0.50
		])
		canvas.draw_colored_polygon(arrow, Color(0.96, 0.98, 0.97))
		canvas.draw_arc(player_pos, scale * 1.40, 0.0, TAU, 24, Color(0.51, 1.0, 0.94, 0.50), 1.0)
	if player_node != null:
		var radar_center: Vector2 = Vector2(
			clampf((player_node.global_position.x / GameState.CELL_SIZE + 0.5) * cell_w, 3.0, sz.x - 3.0),
			clampf((player_node.global_position.z / GameState.CELL_SIZE + 0.5) * cell_h, 3.0, sz.y - 3.0)
		)
		var radius_unit: float = minf(sz.x, sz.y) * (0.15 if expanded else 0.22)
		for ring_idx in range(1, 4):
			canvas.draw_arc(radar_center, radius_unit * float(ring_idx) / 2.0, 0.0, TAU, 40, Color(0.16, 0.91, 0.79, 0.18), 1.0)
		var angle: float = float(Time.get_ticks_msec()) * 0.0006
		var beam: Vector2 = Vector2(cos(angle), sin(angle)) * radius_unit * 1.5
		canvas.draw_line(radar_center, radar_center + beam, Color(0.19, 0.98, 0.79, 0.23), 2.0)
	if not GameState.station_safe:
		var alarm_phase: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.010)
		canvas.draw_arc(station, (18.0 if expanded else 10.0) + alarm_phase * 4.0, 0.0, TAU, 36, Color(1.0, 0.24, 0.18, 0.25 + alarm_phase * 0.60), 2.0)
	if nav_cell != Vector2i(-1, -1) and player_node != null:
		var target_point: Vector2 = Vector2((float(nav_cell.x) + 0.5) * cell_w, (float(nav_cell.y) + 0.5) * cell_h)
		var from_point: Vector2 = Vector2(
			(player_node.global_position.x / GameState.CELL_SIZE + 0.5) * cell_w,
			(player_node.global_position.z / GameState.CELL_SIZE + 0.5) * cell_h
		)
		var nav_color: Color = Color(1.0, 0.68, 0.25)
		if nav_category == "SUMUR AIR":
			nav_color = Color(0.30, 0.82, 1.0)
		elif nav_category == "POS PENGAMATAN":
			nav_color = Color(0.22, 1.0, 0.69)
		var wave: float = 0.5 + 0.5 * sin(nav_pulse * 5.5)
		var small: float = 7.0 if not expanded else 13.0
		var heading: Vector2 = target_point - from_point
		if heading.length_squared() > 1.0:
			var direction: Vector2 = heading.normalized()
			var perp: Vector2 = Vector2(-direction.y, direction.x)
			canvas.draw_line(from_point, target_point, Color(nav_color.r, nav_color.g, nav_color.b, 0.38), 2.0 if expanded else 1.4, true)
			var moving: Vector2 = from_point.lerp(target_point, fposmod(nav_pulse * 0.3, 1.0))
			var chevron: PackedVector2Array = PackedVector2Array([
				moving + direction * small * 0.65,
				moving - direction * small * 0.35 + perp * small * 0.38,
				moving - direction * small * 0.35 - perp * small * 0.38
			])
			canvas.draw_colored_polygon(chevron, nav_color)
		canvas.draw_arc(target_point, small + 3.0 + wave * 5.0, 0.0, TAU, 32, Color(nav_color.r, nav_color.g, nav_color.b, 0.55 + wave * 0.42), 2.1)
		canvas.draw_circle(target_point, 3.8 if not expanded else 6.0, nav_color)
	if expanded:
		canvas.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.40, 0.66, 0.20, 0.9), false, 3.0)
		var font: Font = ThemeDB.fallback_font
		canvas.draw_string(font, Vector2(14, 22), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.91, 0.97, 0.90))
		canvas.draw_string(font, Vector2(14, sz.y - 12), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.91, 0.97, 0.90))

func _calculate_fire_proximity() -> void:
	if player_node == null or grid_simulator == null:
		danger_strength = 0.0
		return
	var player_pos: Vector2 = Vector2(player_node.global_position.x, player_node.global_position.z)
	var min_distance: float = INF
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		if not cell.is_burning():
			continue
		var world_pos: Vector2 = Vector2(float(pos.x), float(pos.y)) * GameState.CELL_SIZE
		min_distance = minf(min_distance, player_pos.distance_to(world_pos))
	danger_strength = clampf((9.0 - min_distance) / 7.0, 0.0, 1.0)
