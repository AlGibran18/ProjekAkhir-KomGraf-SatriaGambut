# tests/board_preview.gd - Pratinjau visual papan kayu jungle sawit pada beberapa ukuran untuk verifikasi manual.
extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.2, 0.28, 0.3)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var specs: Array = [
		{"pos": Vector2(40, 30), "size": Vector2(560, 150), "text": "SATRIA GAMBUT"},
		{"pos": Vector2(660, 30), "size": Vector2(360, 110), "text": "PADAMKAN HOTSPOT  3 / 8"},
		{"pos": Vector2(40, 230), "size": Vector2(300, 90), "text": "MULAI OPERASI"},
		{"pos": Vector2(400, 230), "size": Vector2(520, 200), "text": "Papan panel besar"},
		{"pos": Vector2(40, 380), "size": Vector2(240, 70), "text": "KELUAR"}
	]
	for spec in specs:
		var board: JungleBoard = JungleBoard.new()
		board.position = spec["pos"]
		board.size = spec["size"]
		board.seed_key = int(spec["size"].x)
		bg.add_child(board)
		var label: Label = Label.new()
		label.text = spec["text"]
		label.add_theme_font_size_override("font_size", 28)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		board.add_child(label)
	for i in range(40):
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://tests/shots/board_preview.png"))
	print("saved")
	quit()
