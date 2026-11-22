# environment/vfx/cell_hazard_vfx.gd - Pengelola efek partikel api permukaan, asap miring angin, asap bara gambut, cahaya ember thermal, dan uap tombak gambut.
class_name CellHazardVFX
extends Node3D

@onready var flame_particles: GPUParticles3D = $FlameParticles
@onready var thick_smoke_particles: GPUParticles3D = $ThickSmokeParticles
@onready var subsurface_smoke_particles: GPUParticles3D = $SubsurfaceSmokeParticles
@onready var ember_glow_mesh: MeshInstance3D = $EmberGlowMesh
@onready var steam_burst_particles: GPUParticles3D = $SteamBurstParticles
@onready var fire_light: OmniLight3D = $FireLight

var allow_dynamic_light: bool = false
var pulse_time: float = 0.0
var is_thermal_ember: bool = false
var last_intensity: float = 1.0

func _ready() -> void:
	EventBus.graphics_quality_changed.connect(_on_graphics_quality_changed)
	_apply_quality_ratio()

func _process(delta: float) -> void:
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
	var has_ember: bool = cell.has_ember()
	last_intensity = clampf(cell.surface_fire / 100.0, 0.2, 1.0)
	_apply_quality_ratio()
	fire_light.light_energy = lerpf(0.8, 2.7, last_intensity)
	fire_light.omni_range = lerpf(3.8, 7.0, last_intensity)
	var wind_speed: float = GameState.wind_speed_kmh / 12.0

	flame_particles.emitting = burning
	thick_smoke_particles.emitting = burning
	subsurface_smoke_particles.emitting = (not burning) and has_ember

	var smoke_mat: ParticleProcessMaterial = thick_smoke_particles.process_material as ParticleProcessMaterial
	if smoke_mat != null:
		smoke_mat.gravity = Vector3(wind_dir.x * 2.4 * wind_speed, 2.2, wind_dir.y * 2.4 * wind_speed)

	var sub_mat: ParticleProcessMaterial = subsurface_smoke_particles.process_material as ParticleProcessMaterial
	if sub_mat != null:
		sub_mat.gravity = Vector3(wind_dir.x * 1.1 * wind_speed, 1.4, wind_dir.y * 1.1 * wind_speed)

	is_thermal_ember = thermal_active and has_ember
	ember_glow_mesh.visible = has_ember and (thermal_active or not burning)
	fire_light.visible = burning and allow_dynamic_light and (GameState.current_graphics_quality != GameState.GraphicsQuality.LOW)

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
	flame_particles.amount_ratio = ratio * last_intensity
	thick_smoke_particles.amount_ratio = ratio * clampf(last_intensity + 0.25, 0.0, 1.0)
	subsurface_smoke_particles.amount_ratio = ratio
