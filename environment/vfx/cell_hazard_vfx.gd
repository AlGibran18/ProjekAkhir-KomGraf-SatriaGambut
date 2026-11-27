# environment/vfx/cell_hazard_vfx.gd - Pengelola efek partikel api permukaan, asap miring angin, asap bara gambut, cahaya ember thermal, dan uap tombak gambut.
class_name CellHazardVFX
extends Node3D

@onready var flame_particles: GPUParticles3D = $FlameParticles
@onready var trunk_shell: MeshInstance3D = $TrunkFlameShell
@onready var tree_flames: GPUParticles3D = $TreeFlames
@onready var thick_smoke_particles: GPUParticles3D = $ThickSmokeParticles
@onready var subsurface_smoke_particles: GPUParticles3D = $SubsurfaceSmokeParticles
@onready var ember_glow_mesh: MeshInstance3D = $EmberGlowMesh
@onready var steam_burst_particles: GPUParticles3D = $SteamBurstParticles
@onready var fire_light: OmniLight3D = $FireLight

var allow_dynamic_light: bool = false
var pulse_time: float = 0.0
var is_thermal_ember: bool = false
var last_intensity: float = 1.0
var ember_sparks: GPUParticles3D
var tree_height: float = 0.0
var tree_base: Vector3 = Vector3.ZERO
var burning_now: bool = false
var light_phase: float = 0.0
var burn_wind: Vector2 = Vector2.RIGHT
var weather_refresh_elapsed: float = 0.0

func _ready() -> void:
	EventBus.graphics_quality_changed.connect(_on_graphics_quality_changed)
	# Scene particle materials can be shared among multiple hazard instances.
	# Duplicate the mutable resources so each hotspot has independent wind.
	for particles: GPUParticles3D in [flame_particles, tree_flames, thick_smoke_particles, subsurface_smoke_particles]:
		if particles.process_material != null:
			particles.process_material = particles.process_material.duplicate(true)
	if ember_glow_mesh.material_override != null:
		ember_glow_mesh.material_override = ember_glow_mesh.material_override.duplicate(true)
	_create_flying_embers()
	light_phase = randf_range(0.0, TAU)
	_apply_quality_ratio()

# A small, GPU-based particle layer creates floating embers above surface fires.
# Subsurface heat alone does NOT emit flying sparks: Thermal still matters.
func _create_flying_embers() -> void:
	ember_sparks = GPUParticles3D.new()
	ember_sparks.name = "FlyingEmbers"
	ember_sparks.emitting = false
	ember_sparks.amount = 26
	ember_sparks.lifetime = 1.6
	ember_sparks.visibility_aabb = AABB(Vector3(-7, -1, -7), Vector3(14, 11, 14))
	ember_sparks.position = Vector3(0.0, 0.9, 0.0)
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.75, 0.2, 0.75)
	process.direction = Vector3.UP
	process.spread = 35.0
	process.initial_velocity_min = 1.0
	process.initial_velocity_max = 3.0
	process.gravity = Vector3(0.0, 0.8, 0.0)
	process.scale_min = 0.35
	process.scale_max = 0.85
	process.color = Color(1.0, 0.50, 0.12, 0.94)
	ember_sparks.process_material = process
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.09, 0.14)
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(1.0, 0.50, 0.14, 0.90)
	mesh.material = mat
	ember_sparks.draw_pass_1 = mesh
	add_child(ember_sparks)

func _process(delta: float) -> void:
	# Weather fronts can change the wind without a local ignition event.
	# Refresh the particle drift periodically, not on every frame.
	if burning_now:
		weather_refresh_elapsed += delta
		if weather_refresh_elapsed >= 0.65:
			weather_refresh_elapsed = 0.0
			_update_particle_wind(GameState.wind_direction)
	# Flicker costs no additional lights and only runs while the cell is burning.
	if burning_now and fire_light.visible:
		light_phase += delta * 11.0
		var flicker: float = 0.88 + 0.08 * sin(light_phase) + 0.04 * sin(light_phase * 2.3)
		fire_light.light_energy = lerpf(0.8, 2.7, last_intensity) * flicker
	if ember_glow_mesh.visible:
		pulse_time += delta * 4.5
		var pulse: float = 0.7 + (0.3 * sin(pulse_time))
		var mat: StandardMaterial3D = ember_glow_mesh.material_override as StandardMaterial3D
		if mat != null:
			if is_thermal_ember:
				mat.albedo_color = Color(1.0, 0.22 * pulse, 0.04, 0.90)
			else:
				mat.albedo_color = Color(0.85, 0.20, 0.04, 0.35 * pulse)

func update_state(cell: PeatCellData, thermal_active: bool, wind_dir: Vector2, can_use_light: bool) -> void:
	allow_dynamic_light = can_use_light
	var burning: bool = cell.is_burning()
	burning_now = burning
	burn_wind = wind_dir
	var has_ember: bool = cell.has_ember()
	last_intensity = clampf(cell.surface_fire / 100.0, 0.2, 1.0)
	_apply_quality_ratio()
	fire_light.light_energy = lerpf(0.8, 2.7, last_intensity)
	fire_light.omni_range = lerpf(3.8, 7.0, last_intensity)
	_update_particle_wind(wind_dir)
	ember_sparks.emitting = burning and GameState.current_graphics_quality != GameState.GraphicsQuality.LOW

	flame_particles.emitting = burning
	tree_flames.emitting = burning and tree_height > 0.0 and not cell.is_firebreak and not cell.has_well
	trunk_shell.visible = tree_flames.emitting
	var plume_origin: Vector3 = Vector3.UP
	if tree_flames.emitting:
		var climb: float = tree_height * lerpf(0.16, 0.86, last_intensity)
		tree_flames.position = tree_base + Vector3.UP * climb * 0.5
		trunk_shell.position = tree_flames.position
		trunk_shell.scale = Vector3(1.0, climb, 1.0)
		var fuel: ParticleProcessMaterial = tree_flames.process_material as ParticleProcessMaterial
		var width: float = lerpf(0.26, 0.9, last_intensity)
		fuel.emission_box_extents = Vector3(width, climb * 0.5, width)
		plume_origin = tree_base + Vector3.UP * climb
	thick_smoke_particles.position = plume_origin
	thick_smoke_particles.emitting = burning
	subsurface_smoke_particles.emitting = (not burning) and has_ember

	is_thermal_ember = thermal_active and has_ember
	ember_glow_mesh.visible = has_ember and (thermal_active or not burning)
	fire_light.visible = burning and allow_dynamic_light and (GameState.current_graphics_quality != GameState.GraphicsQuality.LOW)

func _update_particle_wind(wind_dir: Vector2) -> void:
	var wind_speed: float = GameState.wind_speed_kmh / 12.0
	var spark_mat: ParticleProcessMaterial = ember_sparks.process_material as ParticleProcessMaterial
	if spark_mat != null:
		spark_mat.gravity = Vector3(wind_dir.x * wind_speed * 2.0, 0.7, wind_dir.y * wind_speed * 2.0)
	var flame_mat: ParticleProcessMaterial = flame_particles.process_material as ParticleProcessMaterial
	if flame_mat != null:
		flame_mat.gravity = Vector3(wind_dir.x * wind_speed * 0.85, 1.2, wind_dir.y * wind_speed * 0.85)
	var tree_mat: ParticleProcessMaterial = tree_flames.process_material as ParticleProcessMaterial
	tree_mat.gravity = flame_mat.gravity
	var smoke_mat: ParticleProcessMaterial = thick_smoke_particles.process_material as ParticleProcessMaterial
	if smoke_mat != null:
		smoke_mat.gravity = Vector3(wind_dir.x * 2.4 * wind_speed, 2.2, wind_dir.y * 2.4 * wind_speed)
	var sub_mat: ParticleProcessMaterial = subsurface_smoke_particles.process_material as ParticleProcessMaterial
	if sub_mat != null:
		sub_mat.gravity = Vector3(wind_dir.x * 1.1 * wind_speed, 1.4, wind_dir.y * 1.1 * wind_speed)

func trigger_steam_burst() -> void:
	steam_burst_particles.restart()
	steam_burst_particles.emitting = true

func _on_graphics_quality_changed(_quality: int) -> void:
	_apply_quality_ratio()

func _apply_quality_ratio() -> void:
	var ratio: float = 0.75
	match GameState.current_graphics_quality:
		GameState.GraphicsQuality.LOW:
			ratio = 0.40
		GameState.GraphicsQuality.MEDIUM:
			ratio = 0.75
		GameState.GraphicsQuality.HIGH:
			ratio = 1.0
	tree_flames.amount_ratio = ratio * last_intensity
	flame_particles.amount_ratio = ratio * last_intensity
	thick_smoke_particles.amount_ratio = ratio * clampf(last_intensity + 0.25, 0.0, 1.0)
	subsurface_smoke_particles.amount_ratio = ratio
	if ember_sparks != null:
		ember_sparks.amount_ratio = ratio * last_intensity
		ember_sparks.emitting = burning_now and GameState.current_graphics_quality != GameState.GraphicsQuality.LOW
