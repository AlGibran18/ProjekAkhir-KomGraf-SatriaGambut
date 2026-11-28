# simulation/player/firefighter_avatar_3d.gd - Animates the field responder and equipped tools.
class_name FirefighterAvatar3D
extends Node3D

var stride: float = 0.0
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var spray_particles: GPUParticles3D
var dig_dust: GPUParticles3D
var tool_mount: Node3D
var tool_meshes: Array[MeshInstance3D] = []
var is_using_tool: bool = false
var active_tool: ToolEnums.ToolType = ToolEnums.ToolType.SEMPROT_PERMUKAAN
var dig_timer: float = 0.0
var action_clock: float = 0.0
var aim_target_world: Vector3 = Vector3.ZERO
var has_aim_target: bool = false
var action_pulse: float = 0.0

var uniform_material: StandardMaterial3D
var helmet_material: StandardMaterial3D

func _ready() -> void:
	var responder: Node3D = preload("res://assets/models/peat_responder.glb").instantiate() as Node3D
	add_child(responder)
	left_leg = responder.get_node("LeftLeg")
	right_leg = responder.get_node("RightLeg")
	left_arm = responder.get_node("LeftArm")
	right_arm = responder.get_node("RightArm")
	var brushed_metal: StandardMaterial3D = preload("res://assets/textures/field/alloy.tres").duplicate()
	brushed_metal.metallic = 0.78
	for mesh_node: Node in responder.find_children("*", "MeshInstance3D", true, false):
		var model: MeshInstance3D = mesh_node as MeshInstance3D
		for surface: int in range(model.mesh.get_surface_count()):
			var material: StandardMaterial3D = model.mesh.surface_get_material(surface) as StandardMaterial3D
			match material.resource_name:
				"Suit":
					if uniform_material == null:
						uniform_material = preload("res://assets/textures/field/cloth.tres").duplicate()
					model.set_surface_override_material(surface, uniform_material)
				"Steel":
					model.set_surface_override_material(surface, brushed_metal)
				"Trousers", "Canvas":
					var textile: StandardMaterial3D = preload("res://assets/textures/field/cloth.tres").duplicate()
					textile.albedo_color = material.albedo_color
					model.set_surface_override_material(surface, textile)
				"Helmet":
					helmet_material = material.duplicate()
					model.set_surface_override_material(surface, helmet_material)
	_build_equipped_tools()
	apply_outfit()
	GameState.outfit_changed.connect(apply_outfit)
	EventBus.tool_action_performed.connect(_on_tool_action)
	EventBus.tool_selected.connect(_on_tool_changed)
	_on_tool_changed(GameState.current_tool)

func set_aim_target(world_target: Vector3, valid: bool) -> void:
	aim_target_world = world_target
	has_aim_target = valid

func animate_movement(delta: float, is_moving: bool, sprinting: bool) -> void:
	if is_moving:
		stride += delta * (11.0 if sprinting else 7.3)
	var amount: float = (0.52 if sprinting else 0.33) if is_moving else 0.0
	dig_timer = maxf(0.0, dig_timer - delta)
	action_pulse = maxf(0.0, action_pulse - delta)
	action_clock += delta
	left_leg.rotation.x = lerpf(left_leg.rotation.x, sin(stride) * amount, minf(1.0, delta * 10.0))
	right_leg.rotation.x = lerpf(right_leg.rotation.x, -sin(stride) * amount, minf(1.0, delta * 10.0))
	var left_pose: float = -sin(stride) * amount * 0.65
	var right_pose: float = sin(stride) * amount * 0.65
	if dig_timer > 0.0:
		left_pose = -0.85 + sin(action_clock * 15.0) * 0.40
		right_pose = -0.95 + sin(action_clock * 15.0) * 0.40
	elif is_using_tool:
		if active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN:
			left_pose = -1.02 + sin(action_clock * 11.0) * 0.04
			right_pose = -1.18 + sin(action_clock * 11.0) * 0.05
		elif active_tool == ToolEnums.ToolType.TOMBAK_GAMBUT:
			left_pose = -0.67 + sin(action_clock * 13.0) * 0.11
			right_pose = -0.81 + sin(action_clock * 13.0) * 0.11
	if has_aim_target and (is_using_tool or dig_timer > 0.0):
		# Arms follow the highlighted grid cell: tilt up for distant/raised
		# targets and down for close ground work, within natural pose limits.
		var local_aim: Vector3 = to_local(aim_target_world)
		var distance_xz: float = maxf(0.2, Vector2(local_aim.x, local_aim.z).length())
		var elevation: float = atan2(local_aim.y - 1.4, distance_xz)
		var pitch_offset: float = clampf(elevation, -0.70, 0.55)
		left_pose -= pitch_offset * 0.60
		right_pose -= pitch_offset * 0.60
		var turn: float = clampf(atan2(local_aim.x, maxf(0.3, -local_aim.z)), -0.48, 0.48)
		left_arm.rotation.y = lerpf(left_arm.rotation.y, turn * 0.50, minf(1.0, delta * 11.0))
		right_arm.rotation.y = lerpf(right_arm.rotation.y, turn * 0.55, minf(1.0, delta * 11.0))
	else:
		left_arm.rotation.y = lerpf(left_arm.rotation.y, 0.0, minf(1.0, delta * 11.0))
		right_arm.rotation.y = lerpf(right_arm.rotation.y, 0.0, minf(1.0, delta * 11.0))
	left_arm.rotation.x = lerpf(left_arm.rotation.x, left_pose, minf(1.0, delta * 12.0))
	right_arm.rotation.x = lerpf(right_arm.rotation.x, right_pose, minf(1.0, delta * 12.0))
	if spray_particles != null:
		spray_particles.emitting = visible and is_using_tool and active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN
	if tool_mount != null:
		if has_aim_target and (is_using_tool or dig_timer > 0.0):
			var muzzle: Vector3 = tool_mount.global_position
			if muzzle.distance_to(aim_target_world) > 0.15:
				tool_mount.look_at(aim_target_world, Vector3.UP)
		else:
			tool_mount.rotation = tool_mount.rotation.lerp(Vector3.ZERO, minf(1.0, delta * 9.0))

func _tool_metal(tint: Color) -> Material:
	var m: StandardMaterial3D = preload("res://assets/textures/field/alloy.tres").duplicate()
	m.albedo_color = tint
	m.metallic = 0.76
	m.roughness = 0.62
	return m

func _build_equipped_tools() -> void:
	var metal: Material = _tool_metal(Color(0.44, 0.54, 0.58))
	var gold: Material = _tool_metal(Color(1.0, 0.78, 0.16))
	tool_mount = Node3D.new()
	tool_mount.name = "ToolMount"
	right_arm.add_child(tool_mount)
	tool_mount.position = Vector3(0, -0.55, -0.16)
	tool_meshes.clear()
	for tool_id in range(3):
		var tool: MeshInstance3D = MeshInstance3D.new()
		tool.name = ["TPPShovel", "TPPNozzle", "TPPSpear"][tool_id]
		var mesh: CylinderMesh = CylinderMesh.new()
		mesh.top_radius = 0.026 if tool_id != 1 else 0.065
		mesh.bottom_radius = 0.032 if tool_id != 1 else 0.05
		mesh.height = [1.02, 0.44, 1.10][tool_id]
		tool.mesh = mesh
		tool.material_override = metal
		tool.rotation.x = PI * 0.5
		tool.position = Vector3(0, 0, -0.28)
		tool_mount.add_child(tool)
		tool_meshes.append(tool)
	var nozzle_head: MeshInstance3D = MeshInstance3D.new()
	var nozzle_mesh: CylinderMesh = CylinderMesh.new()
	nozzle_mesh.top_radius = 0.045
	nozzle_mesh.bottom_radius = 0.080
	nozzle_mesh.height = 0.15
	nozzle_head.mesh = nozzle_mesh
	nozzle_head.rotation.x = PI * 0.5
	nozzle_head.position = Vector3(0, 0, -0.53)
	nozzle_head.material_override = gold
	tool_meshes[1].add_child(nozzle_head)
	spray_particles = GPUParticles3D.new()
	spray_particles.name = "TPPWaterJet"
	spray_particles.amount = 95
	spray_particles.lifetime = 0.32
	spray_particles.emitting = false
	spray_particles.position = Vector3(0, 0, -0.58)
	spray_particles.visibility_aabb = AABB(Vector3(-4, -4, -10), Vector3(8, 8, 12))
	var process_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0, 0, -1)
	process_mat.particle_flag_align_y = true
	process_mat.spread = 6.0
	process_mat.initial_velocity_min = 8.0
	process_mat.initial_velocity_max = 13.0
	process_mat.gravity = Vector3(0, -5.0, 0)
	process_mat.color = Color(0.56, 0.86, 1.0, 0.78)
	spray_particles.process_material = process_mat
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.060, 0.25)
	quad.material = preload("res://environment/vfx/water_drop.tres")
	spray_particles.draw_pass_1 = quad
	tool_mount.add_child(spray_particles)
	_create_dig_dust()

func apply_outfit() -> void:
	uniform_material.albedo_color = GameState.UNIFORM_COLORS[GameState.uniform_index]
	helmet_material.albedo_color = GameState.HELMET_COLORS[GameState.helmet_index]

func set_action_state(tool: ToolEnums.ToolType, continuous: bool) -> void:
	active_tool = tool
	is_using_tool = continuous
	if spray_particles != null and not continuous:
		spray_particles.emitting = false
	_update_equipped_tool()

func _on_tool_changed(tool: ToolEnums.ToolType) -> void:
	active_tool = tool
	is_using_tool = false
	_update_equipped_tool()

func _update_equipped_tool() -> void:
	for i in range(tool_meshes.size()):
		tool_meshes[i].visible = i == (0 if active_tool == ToolEnums.ToolType.SEKAT_BAKAR else (1 if active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN else 2))

func _on_tool_action(tool: ToolEnums.ToolType, _pos: Vector2i) -> void:
	if tool == ToolEnums.ToolType.SEKAT_BAKAR:
		dig_timer = 0.60
		action_pulse = 0.60
		if dig_dust != null and visible:
			dig_dust.restart()
			dig_dust.emitting = true

func _create_dig_dust() -> void:
	dig_dust = GPUParticles3D.new()
	dig_dust.name = "FirebreakSoilDust"
	dig_dust.amount = 24
	dig_dust.lifetime = 0.45
	dig_dust.one_shot = true
	dig_dust.explosiveness = 0.92
	dig_dust.emitting = false
	dig_dust.position = Vector3(0, 0.22, -1.12)
	dig_dust.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
	var proc: ParticleProcessMaterial = ParticleProcessMaterial.new()
	proc.direction = Vector3.UP
	proc.spread = 58.0
	proc.initial_velocity_min = 0.5
	proc.initial_velocity_max = 2.0
	proc.gravity = Vector3(0, -7.0, 0)
	proc.color = Color(0.42, 0.30, 0.16, 0.68)
	dig_dust.process_material = proc
	var mesh: SphereMesh = SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.43, 0.31, 0.17, 0.65)
	mesh.material = mat
	dig_dust.draw_pass_1 = mesh
	add_child(dig_dust)
