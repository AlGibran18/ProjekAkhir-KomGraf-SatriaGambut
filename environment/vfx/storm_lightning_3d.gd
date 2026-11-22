# V6 storm system: short lightning strokes, soft sky illumination and delayed thunder.
# All effects are cosmetic; lightning never starts a new fire.
class_name StormLightning3D
extends Node

var ambience: WeatherAmbience3D
var audio: ForestAudioAmbience
var world_view: SimulationView3D
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var next_strike_sec: float = 26.0
var clock: float = 0.0
var thunder_delay: float = -1.0
var flash_remaining: float = 0.0
var flash_age: float = 0.0
var lightning_layer: CanvasLayer
var flash_rect: ColorRect
var bolt: Control
var bolt_points: PackedVector2Array = PackedVector2Array()
var branch_segments: Array[PackedVector2Array] = []
var normal_sun_energy: float = 1.0
var strike_strength: float = 0.0

func initialize(weather: WeatherAmbience3D, sound: ForestAudioAmbience, view: SimulationView3D) -> void:
	ambience = weather
	audio = sound
	world_view = view

func _ready() -> void:
	rng.randomize()
	next_strike_sec = rng.randf_range(18.0, 33.0)
	normal_sun_energy = world_view.sun_light.light_energy if world_view != null and world_view.sun_light != null else 1.0
	lightning_layer = CanvasLayer.new()
	lightning_layer.layer = 8
	add_child(lightning_layer)
	flash_rect = ColorRect.new()
	flash_rect.name = "LightningSkyFlash"
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(0.78, 0.87, 1.0, 0.0)
	lightning_layer.add_child(flash_rect)
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bolt = Control.new()
	bolt.name = "LightningBoltOverlay"
	bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bolt.draw.connect(_draw_bolt)
	lightning_layer.add_child(bolt)
	bolt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lightning_layer.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# F9 is a safe optional preview of V6 lighting and thunder.
	if GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS and event is InputEventKey:
		if event.pressed and not event.echo and event.keycode == KEY_F9:
			_trigger_strike()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	var active: bool = GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS
	if not active:
		lightning_layer.visible = false
		flash_remaining = 0.0
		thunder_delay = -1.0
		return
	var rain: float = GameState.global_rainfall_rate
	clock += delta
	if clock >= next_strike_sec:
		clock = 0.0
		next_strike_sec = rng.randf_range(22.0, 45.0)
		# Lightning is much more likely during heavy rain, rare during a drizzle.
		if rain >= 4.0 and rng.randf() < clampf(rain / 11.0, 0.25, 0.93):
			_trigger_strike()
	if thunder_delay >= 0.0:
		thunder_delay -= delta
		if thunder_delay < 0.0 and audio != null:
			audio.play_thunder(strike_strength)
	if flash_remaining > 0.0:
		flash_remaining -= delta
		flash_age += delta
		var first: float = 1.0 if flash_age < 0.085 else 0.0
		var second: float = 0.72 if flash_age > 0.14 and flash_age < 0.24 else 0.0
		var tail: float = maxf(0.0, 0.19 - flash_age) * 0.7
		var brightness: float = maxf(maxf(first, second), tail)
		# Limit brightness to avoid harsh flashing; no blank-white screen.
		flash_rect.color = Color(0.78, 0.87, 1.0, brightness * 0.13 * strike_strength)
		bolt.modulate = Color(1.0, 1.0, 1.0, brightness * 0.85)
		bolt.queue_redraw()
		if world_view != null and world_view.sun_light != null:
			var lamp: DirectionalLight3D = world_view.sun_light
			lamp.light_energy = maxf(lamp.light_energy, normal_sun_energy * (1.0 + brightness * 0.50 * strike_strength))
	else:
		lightning_layer.visible = false

func _trigger_strike() -> void:
	strike_strength = rng.randf_range(0.65, 1.0)
	thunder_delay = rng.randf_range(0.6, 2.5)
	flash_age = 0.0
	flash_remaining = 0.30
	lightning_layer.visible = true
	_generate_bolt()

func _generate_bolt() -> void:
	var size_now: Vector2 = get_viewport().get_visible_rect().size
	bolt_points.clear()
	branch_segments.clear()
	var origin: Vector2 = Vector2(size_now.x * rng.randf_range(0.22, 0.78), 0.0)
	var target: Vector2 = origin + Vector2(rng.randf_range(-100.0, 100.0), size_now.y * rng.randf_range(0.35, 0.65))
	var segments: int = 11
	for i in range(segments + 1):
		var ratio: float = float(i) / float(segments)
		var position: Vector2 = origin.lerp(target, ratio)
		if i > 0 and i < segments:
			position.x += rng.randf_range(-19.0, 19.0)
		bolt_points.append(position)
		if i > 2 and i < segments - 2 and i % 3 == 0:
			var branch: PackedVector2Array = PackedVector2Array()
			branch.append(position)
			branch.append(position + Vector2(rng.randf_range(-48.0, 48.0), size_now.y * 0.08))
			branch.append(branch[1] + Vector2(rng.randf_range(-26.0, 26.0), size_now.y * 0.07))
			branch_segments.append(branch)
	bolt.queue_redraw()

func _draw_bolt() -> void:
	if bolt_points.size() < 2:
		return
	# Underlay and thin white core give a small blue-violet glow in GL Compatibility.
	for width in [8.0, 3.0, 1.4]:
		var tone: Color = Color(0.38, 0.55, 1.0, 0.16) if width > 4.0 else (Color(0.72, 0.83, 1.0, 0.50) if width > 2.0 else Color(0.96, 0.98, 1.0, 0.94))
		bolt.draw_polyline(bolt_points, tone, width, true)
	for branch in branch_segments:
		bolt.draw_polyline(branch, Color(0.78, 0.89, 1.0, 0.72), 1.4, true)
