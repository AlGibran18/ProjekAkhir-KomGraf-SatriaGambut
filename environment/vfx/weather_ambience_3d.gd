# Visual-only weather layer. Does not modify the fire simulation.
# Particles follow the player, while lighting and foliage react to the existing GameState weather.
class_name WeatherAmbience3D
extends Node3D

var tracked_player: Node3D
var world_view: SimulationView3D
var rain_particles: GPUParticles3D
var foliage: Array[Node3D] = []
var foliage_phase: Array[float] = []
var foliage_initial_rotations: Array[Vector3] = []
var foliage_tick: float = 0.0
const FOLIAGE_UPDATE_INTERVAL: float = 1.0 / 30.0
var ambient_clock: float = 0.0
var rain_fraction: float = 0.0
var sun_default_energy: float = 1.0
var sun_default_color: Color = Color.WHITE

func initialize(player: Node3D, view: SimulationView3D) -> void:
	tracked_player = player
	world_view = view

func _ready() -> void:
	_create_rain()
	_collect_foliage()
	if world_view != null and world_view.sun_light != null:
		sun_default_energy = world_view.sun_light.light_energy
		sun_default_color = world_view.sun_light.light_color
	EventBus.graphics_quality_changed.connect(_update_quality)
	_update_quality(int(GameState.current_graphics_quality))

func _process(delta: float) -> void:
	if tracked_player == null or world_view == null:
		return
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		rain_particles.emitting = false
		return
	ambient_clock += delta
	var rain_target: float = clampf(GameState.global_rainfall_rate / 9.0, 0.0, 1.0)
	rain_fraction = move_toward(rain_fraction, rain_target, delta * 0.35)
	rain_particles.global_position = tracked_player.global_position + Vector3(0.0, 6.0, 0.0)
	rain_particles.emitting = rain_fraction > 0.08
	var wind: Vector2 = GameState.wind_direction * clampf(GameState.wind_speed_kmh / 15.0, 0.2, 2.5)
	var process_mat: ParticleProcessMaterial = rain_particles.process_material as ParticleProcessMaterial
	if process_mat != null:
		process_mat.direction = Vector3(wind.x * 0.22, -1.0, wind.y * 0.22).normalized()
		process_mat.gravity = Vector3(wind.x * 1.6, -17.0, wind.y * 1.6)
	_update_quality(int(GameState.current_graphics_quality))
	_update_lighting(delta)
	foliage_tick += delta
	if foliage_tick >= FOLIAGE_UPDATE_INTERVAL:
		foliage_tick = fmod(foliage_tick, FOLIAGE_UPDATE_INTERVAL)
		_animate_foliage()

func _create_rain() -> void:
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "CameraLocalRain"
	rain_particles.emitting = false
	rain_particles.amount = 340
	rain_particles.lifetime = 1.15
	rain_particles.visibility_aabb = AABB(Vector3(-12, -12, -12), Vector3(24, 24, 24))
	var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(8.0, 1.8, 8.0)
	material.direction = Vector3(0, -1, 0)
	material.spread = 8.0
	material.initial_velocity_min = 11.0
	material.initial_velocity_max = 16.0
	material.gravity = Vector3(0.0, -17.0, 0.0)
	material.scale_min = 0.65
	material.scale_max = 1.2
	material.color = Color(0.62, 0.78, 0.92, 0.42)
	rain_particles.process_material = material
	var streak: QuadMesh = QuadMesh.new()
	streak.size = Vector2(0.025, 0.55)
	var streak_mat: StandardMaterial3D = StandardMaterial3D.new()
	streak_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	streak_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	streak_mat.albedo_color = Color(0.65, 0.83, 1.0, 0.42)
	streak.material = streak_mat
	rain_particles.draw_pass_1 = streak
	add_child(rain_particles)

# Collect ALL eligible small plants, not just the first 80 grid cells.
# IMPORTANT: animate each living plant, never PlantHolder as it may also
# contain rigid rocks, logs, and stumps.
func _collect_foliage() -> void:
	foliage.clear()
	foliage_phase.clear()
	foliage_initial_rotations.clear()
	if world_view == null:
		return
	for holder_variant in world_view.cell_visual_nodes.values():
		var holder: Node3D = holder_variant as Node3D
		if holder == null:
			continue
		var plant_holder: Node3D = holder.get_node_or_null("PlantHolder") as Node3D
		if plant_holder == null:
			continue
		for plant_node in plant_holder.get_children():
			var plant: Node3D = plant_node as Node3D
			if plant == null:
				continue
			# These names are assigned at spawn time in SimulationView3D.
			# Never move props such as rock, log, stump or mushroom.
			if not plant.name.begins_with("WindPlant_"):
				continue
			foliage.append(plant)
			foliage_initial_rotations.append(plant.rotation)
			# Stable phase offset prevents all foliage swaying in lockstep.
			foliage_phase.append(float(foliage.size()) * 1.618)

func _animate_foliage() -> void:
	var wind_strength: float = clampf(GameState.wind_speed_kmh / 22.0, 0.0, 1.5)
	var target_x: float = GameState.wind_direction.y * wind_strength
	var target_z: float = -GameState.wind_direction.x * wind_strength
	for i in range(foliage.size()):
		var plant: Node3D = foliage[i]
		if not is_instance_valid(plant) or not plant.visible:
			continue
		var wave: float = sin(ambient_clock * (1.35 + wind_strength) + foliage_phase[i])
		var flutter: float = sin(ambient_clock * (2.7 + wind_strength) + foliage_phase[i] * 1.37)
		var start: Vector3 = foliage_initial_rotations[i]
		plant.rotation.x = start.x + (target_x + wave * 0.48 + flutter * 0.12) * 0.055
		plant.rotation.z = start.z + (target_z + wave * 0.48 + flutter * 0.12) * 0.055

func _update_lighting(delta: float) -> void:
	if world_view.sun_light == null:
		return
	var rain_dim: float = rain_fraction * 0.32
	var smoke_dim: float = clampf(float(GameState.active_fire_cells) / 32.0, 0.0, 0.18)
	var target_energy: float = sun_default_energy * (1.0 - rain_dim - smoke_dim)
	world_view.sun_light.light_energy = lerpf(world_view.sun_light.light_energy, target_energy, clampf(delta * 0.55, 0.0, 1.0))
	var target_color: Color = sun_default_color.lerp(Color(0.65, 0.74, 0.86), rain_fraction * 0.40)
	world_view.sun_light.light_color = world_view.sun_light.light_color.lerp(target_color, clampf(delta * 0.6, 0.0, 1.0))

func _update_quality(quality: int) -> void:
	if rain_particles == null:
		return
	var quality_ratio: Array[float] = [0.18, 0.55, 1.0]
	rain_particles.amount_ratio = quality_ratio[clampi(quality, 0, 2)] * rain_fraction
