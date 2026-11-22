# core/audio_manager.gd - Autoload pemutar efek suara (SFX) offline dengan pool saluran audio untuk aksi alat, thermal, sumur air, dan misi Satria Gambut.
extends Node

var players: Array[AudioStreamPlayer] = []
var sfx_streams: Dictionary = {}
var last_spray_play_ms: int = 0
var last_refill_play_ms: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(6):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

	_load_sfx("dig", "res://assets/audio/dig_firebreak.wav")
	_load_sfx("spray", "res://assets/audio/water_spray.wav")
	_load_sfx("steam", "res://assets/audio/steam_hiss.wav")
	_load_sfx("thermal", "res://assets/audio/thermal_toggle.wav")
	_load_sfx("refill", "res://assets/audio/water_refill.wav")
	_load_sfx("click", "res://assets/audio/ui_click.wav")
	_load_sfx("victory", "res://assets/audio/mission_victory.wav")

	EventBus.thermal_mode_toggled.connect(_on_thermal_toggled)
	EventBus.steam_burst_requested.connect(_on_steam_burst)
	EventBus.tool_action_performed.connect(_on_tool_action)
	EventBus.game_phase_changed.connect(_on_phase_changed)

func _load_sfx(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path)
		if stream != null:
			sfx_streams[key] = stream

func play_sfx(key: String, volume_db: float = -4.0, pitch_scale: float = 1.0) -> void:
	if not sfx_streams.has(key):
		return
	var stream: AudioStream = sfx_streams[key]
	for p in players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	players[0].stream = stream
	players[0].volume_db = volume_db
	players[0].pitch_scale = pitch_scale
	players[0].play()

func play_spray_throttled() -> void:
	var now: int = Time.get_ticks_msec()
	if now - last_spray_play_ms >= 350:
		last_spray_play_ms = now
		play_sfx("spray", -6.0, randf_range(0.95, 1.08))

func play_refill_throttled() -> void:
	var now: int = Time.get_ticks_msec()
	if now - last_refill_play_ms >= 420:
		last_refill_play_ms = now
		play_sfx("refill", -5.0, randf_range(0.95, 1.1))

func _on_thermal_toggled(_enabled: bool) -> void:
	play_sfx("thermal", -4.0)

func _on_steam_burst(_pos: Vector2i) -> void:
	play_sfx("steam", -2.0, randf_range(0.95, 1.05))

func _on_tool_action(tool_type: ToolEnums.ToolType, _pos: Vector2i) -> void:
	match tool_type:
		ToolEnums.ToolType.SEKAT_BAKAR:
			play_sfx("dig", -3.0, randf_range(0.9, 1.1))
		ToolEnums.ToolType.SEMPROT_PERMUKAAN:
			play_spray_throttled()

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	if new_phase == ToolEnums.GamePhase.VICTORY:
		play_sfx("victory", -2.0)
