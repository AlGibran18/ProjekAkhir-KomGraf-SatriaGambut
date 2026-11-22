# core/audio_manager.gd - Autoload pemutar efek suara (SFX) offline dengan pool saluran audio untuk aksi alat, thermal, sumur air, dan misi Satria Gambut.
extends Node

var players: Array[AudioStreamPlayer] = []
var sfx_streams: Dictionary = {}
var last_spray_play_ms: int = 0
var last_refill_play_ms: int = 0
var music_player: AudioStreamPlayer
var music_menu: AudioStreamWAV
var music_game: AudioStreamWAV
var current_music: String = ""
var music_volume_db: float = -80.0

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
	_create_original_music()
	play_menu_music()

# Original procedural soundtrack composed directly for Satria Gambut.
# Restrained levels intentionally leave rain, fire, thunder and tool SFX audible.
func _create_original_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "OriginalBackgroundMusic"
	music_player.volume_db = -80.0
	add_child(music_player)
	music_menu = _synthesize_music(false)
	music_game = _synthesize_music(true)

func play_menu_music() -> void:
	_switch_music("menu")

func play_game_music() -> void:
	_switch_music("game")

func _switch_music(mode: String) -> void:
	if music_player == null or current_music == mode:
		return
	current_music = mode
	music_player.stop()
	music_player.stream = music_game if mode == "game" else music_menu
	music_volume_db = -32.0 if mode == "game" else -27.0
	music_player.volume_db = music_volume_db
	music_player.play()

func _synthesize_music(energetic: bool) -> AudioStreamWAV:
	const RATE: int = 11025
	const SECONDS: int = 12
	var sample_count: int = RATE * SECONDS
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)
	# Self-composed major/minor modal motif; all notes and audio are original.
	var roots: Array[float] = [146.83, 174.61, 130.81, 196.00] if energetic else [130.81, 164.81, 146.83, 174.61]
	var motif: Array[int] = [0, 2, 4, 2, 5, 4, 2, 0, 2, 4, 7, 5, 4, 2, 0, 2]
	var pentatonic: Array[float] = [1.0, 1.125, 1.25, 1.5, 1.6667, 2.0, 2.25, 2.5]
	for index in range(sample_count):
		var sec: float = float(index) / float(RATE)
		var beat: float = sec * (2.0 if energetic else 1.5)
		var bar: int = int(floorf(beat / 4.0)) % roots.size()
		var root: float = roots[bar]
		var pulse: float = beat - floorf(beat)
		var pad: float = sin(TAU * root * sec) + 0.55 * sin(TAU * root * 1.5 * sec) + 0.26 * sin(TAU * root * 2.0 * sec)
		var note_index: int = motif[int(floorf(beat * 2.0)) % motif.size()]
		var note: float = root * pentatonic[note_index]
		var pluck: float = sin(TAU * note * sec) * exp(-pulse * (4.2 if energetic else 6.0))
		var bass: float = sin(TAU * root * 0.5 * sec)
		var swell: float = 0.62 + 0.24 * sin(TAU * sec / 6.0)
		var transient: float = 0.0
		if energetic:
			transient = exp(-pulse * 15.0) * sin(TAU * 62.0 * sec) * 0.14
		var sample: float = (pad * 0.14 * swell + pluck * 0.22 + bass * 0.14 + transient) * 0.58
		# Avoid pops at the loop boundary with a short symmetrical fade.
		var edge: float = minf(float(index) / 900.0, float(sample_count - 1 - index) / 900.0)
		sample *= clampf(edge, 0.0, 1.0)
		pcm.encode_s16(index * 2, int(roundf(clampf(sample, -0.94, 0.94) * 32767.0)))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

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
