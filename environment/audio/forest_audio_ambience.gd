# Satria Gambut V5 — offline procedural environmental audio.
# Makes reusable 16-bit PCM loops once, then uses Godot audio players (not CPU audio every frame).
class_name ForestAudioAmbience
extends Node3D

const SAMPLE_RATE: int = 16000
const SAMPLE_SECONDS: int = 3
const UPDATE_INTERVAL: float = 0.25

var tracked_player: Node3D
var simulator: GridSimulator
var wind_player: AudioStreamPlayer
var rain_player: AudioStreamPlayer
var fire_player: AudioStreamPlayer3D
var update_elapsed: float = 0.0
var nearest_fire_distance: float = INF
var current_wind_db: float = -65.0
var current_rain_db: float = -65.0
var current_fire_db: float = -65.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func initialize(player: Node3D, grid: GridSimulator) -> void:
	tracked_player = player
	simulator = grid

func _ready() -> void:
	rng.seed = 20261122
	wind_player = AudioStreamPlayer.new()
	wind_player.name = "WindAmbience"
	wind_player.stream = _build_noise_loop(0)
	wind_player.volume_db = -65.0
	add_child(wind_player)

	rain_player = AudioStreamPlayer.new()
	rain_player.name = "RainAmbience"
	rain_player.stream = _build_noise_loop(1)
	rain_player.volume_db = -65.0
	add_child(rain_player)

	fire_player = AudioStreamPlayer3D.new()
	fire_player.name = "NearestFireCrackle"
	fire_player.stream = _build_noise_loop(2)
	fire_player.volume_db = -65.0
	fire_player.unit_size = 8.0
	fire_player.max_distance = 60.0
	add_child(fire_player)

	# Audio is only heard during the FPS phase; pause/results stop all 3 loops.
	EventBus.game_phase_changed.connect(_on_phase_changed)
	_on_phase_changed(GameState.current_phase)

func _process(delta: float) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	update_elapsed += delta
	if update_elapsed < UPDATE_INTERVAL:
		return
	var elapsed: float = update_elapsed
	update_elapsed = 0.0
	_update_environment_audio(elapsed)

func _on_phase_changed(phase: ToolEnums.GamePhase) -> void:
	var should_play: bool = phase == ToolEnums.GamePhase.ACTIVE_FPS
	if should_play:
		if not wind_player.playing:
			wind_player.play()
		if not rain_player.playing:
			rain_player.play()
		if not fire_player.playing:
			fire_player.play()
		_update_environment_audio(UPDATE_INTERVAL)
	else:
		wind_player.stop()
		rain_player.stop()
		fire_player.stop()

func _update_environment_audio(delta: float) -> void:
	if tracked_player == null or simulator == null:
		return
	var wind_ratio: float = clampf(GameState.wind_speed_kmh / 32.0, 0.0, 1.0)
	var rain_ratio: float = clampf(GameState.global_rainfall_rate / 12.0, 0.0, 1.0)

	# Rain/wind fade smoothly when a weather front changes.
	var wind_target: float = lerpf(-36.0, -18.0, wind_ratio)
	var rain_target: float = lerpf(-80.0, -13.0, rain_ratio)
	current_wind_db = move_toward(current_wind_db, wind_target, delta * 18.0)
	current_rain_db = move_toward(current_rain_db, rain_target, delta * 18.0)
	wind_player.volume_db = current_wind_db
	rain_player.volume_db = current_rain_db

	var player_xz: Vector2 = Vector2(tracked_player.global_position.x, tracked_player.global_position.z)
	var closest: Vector2i = Vector2i(-1, -1)
	nearest_fire_distance = INF
	var intensity: float = 0.0
	for key in simulator.cells.keys():
		var cell: PeatCellData = simulator.cells[key]
		if not cell.is_burning():
			continue
		var pos: Vector2i = key
		var position_2d: Vector2 = Vector2(float(pos.x), float(pos.y)) * GameState.CELL_SIZE
		var distance: float = player_xz.distance_to(position_2d)
		if distance < nearest_fire_distance:
			nearest_fire_distance = distance
			closest = pos
			intensity = clampf(cell.surface_fire / 100.0, 0.2, 1.0)

	var fire_target: float = -65.0
	if closest != Vector2i(-1, -1):
		fire_player.global_position = Vector3(float(closest.x) * GameState.CELL_SIZE, 1.0, float(closest.y) * GameState.CELL_SIZE)
		# Additional soft gain control prevents distant crackles becoming overwhelming.
		fire_target = -12.0 + 8.0 * intensity - clampf(nearest_fire_distance * 0.7, 0.0, 36.0)
	current_fire_db = move_toward(current_fire_db, fire_target, delta * 18.0)
	fire_player.volume_db = current_fire_db

func _build_noise_loop(kind: int) -> AudioStreamWAV:
	var sample_count: int = SAMPLE_RATE * SAMPLE_SECONDS
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)
	var low: float = 0.0
	var medium: float = 0.0
	var crackle: float = 0.0
	for i in range(sample_count):
		var noise: float = rng.randf_range(-1.0, 1.0)
		low = low * 0.993 + noise * 0.007
		medium = medium * 0.82 + noise * 0.18
		var sample: float = 0.0
		match kind:
			0: # Wind: slow, soft low-frequency broadband hiss.
				sample = clampf(low * 5.6 + medium * 0.42, -1.0, 1.0) * 0.48
			1: # Rain: dispersed high-frequency noise, less bass.
				sample = (noise - medium * 0.65) * 0.24
			2: # Fire: soft rumble with randomized transient crackles.
				if rng.randf() < 0.004:
					crackle = rng.randf_range(-1.0, 1.0)
				crackle *= 0.92
				sample = (low * 2.3 + medium * 0.12 + crackle * 0.60) * 0.58
		# Avoid hard clipping or clicks at loop boundaries.
		var edge: float = minf(float(i) / 1200.0, float(sample_count - 1 - i) / 1200.0)
		sample *= clampf(edge, 0.0, 1.0)
		sample = clampf(sample, -0.95, 0.95)
		pcm.encode_s16(i * 2, int(roundf(sample * 32767.0)))

	var result: AudioStreamWAV = AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = SAMPLE_RATE
	result.stereo = false
	result.data = pcm
	result.loop_mode = AudioStreamWAV.LOOP_FORWARD
	result.loop_begin = 0
	result.loop_end = sample_count
	return result
