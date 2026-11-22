# V8.2 — Lightweight procedural firefighter shown only in third-person.
# Uses meshes, not imported skeletons, to keep the existing game entirely offline.
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

func _ready() -> void:
	var red: Material = _mat(Color(0.80, 0.11, 0.10))
	var yellow: Material = _mat(Color(1.0, 0.72, 0.10))
	var dark: Material = _mat(Color(0.08, 0.11, 0.12))
	var skin: Material = _mat(Color(0.75, 0.47, 0.27))
	_part("Body", Vector3(0, 1.12, 0), Vector3(0.48, 0.67, 0.28), red)
	_part("ReflectiveStripe", Vector3(0, 1.13, -0.15), Vector3(0.52, 0.11, 0.05), yellow)
	_part("Neck", Vector3(0, 1.55, 0), Vector3(0.13, 0.12, 0.13), skin)
	_part("Head", Vector3(0, 1.77, 0), Vector3(0.28, 0.33, 0.27), skin)
	_part("Helmet", Vector3(0, 1.98, 0), Vector3(0.38, 0.16, 0.36), red)
	_part("HelmetBrim", Vector3(0, 1.89, -0.04), Vector3(0.48, 0.06, 0.49), yellow)
	_part("Backpack", Vector3(0, 1.14, 0.25), Vector3(0.40, 0.52, 0.18), dark)
	left_leg = Node3D.new()
	right_leg = Node3D.new()
	left_arm = Node3D.new()
	right_arm = Node3D.new()
	for limb in [left_leg, right_leg, left_arm, right_arm]:
		add_child(limb)
	left_leg.position = Vector3(-0.13, 0.78, 0.0)
	right_leg.position = Vector3(0.13, 0.78, 0.0)
	left_arm.position = Vector3(-0.32, 1.45, 0.0)
	right_arm.position = Vector3(0.32, 1.45, 0.0)
	_limb(left_leg, Vector3(0, -0.35, 0), Vector3(0.18, 0.7, 0.20), dark)
	_limb(right_leg, Vector3(0, -0.35, 0), Vector3(0.18, 0.7, 0.20), dark)
	_limb(left_arm, Vector3(0, -0.29, 0), Vector3(0.18, 0.56, 0.20), red)
	_limb(right_arm, Vector3(0, -0.29, 0), Vector3(0.18, 0.56, 0.20), red)
	_part("BootLeft", Vector3(-0.13, 0.11, -0.05), Vector3(0.21, 0.20, 0.30), dark)
	_part("BootRight", Vector3(0.13, 0.11, -0.05), Vector3(0.21, 0.20, 0.30), dark)
	_upgrade_gear()
	apply_outfit()
	EventBus.tool_action_performed.connect(_on_tool_action)
	EventBus.tool_selected.connect(_on_tool_changed)
	_on_tool_changed(GameState.current_tool)

func animate_movement(delta: float, is_moving: bool, sprinting: bool) -> void:
	if is_moving:
		stride += delta * (11.0 if sprinting else 7.3)
	var amount: float = (0.52 if sprinting else 0.33) if is_moving else 0.0
	dig_timer = maxf(0.0, dig_timer - delta)
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
	left_arm.rotation.x = lerpf(left_arm.rotation.x, left_pose, minf(1.0, delta * 12.0))
	right_arm.rotation.x = lerpf(right_arm.rotation.x, right_pose, minf(1.0, delta * 12.0))
	if spray_particles != null:
		spray_particles.emitting = visible and is_using_tool and active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN
	if tool_mount != null:
		tool_mount.rotation.x = -0.35 if is_using_tool and active_tool == ToolEnums.ToolType.TOMBAK_GAMBUT else 0.0

func _mat(tint: Color) -> Material:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.78
	return m

func _part(name_str: String, where: Vector3, dims: Vector3, mat: Material) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = name_str
	var geometry: Mesh
	if name_str == "Head":
		var sphere: SphereMesh = SphereMesh.new()
		sphere.radius = dims.x * 0.55
		sphere.height = dims.y
		geometry = sphere
	elif name_str == "Helmet":
		var dome: SphereMesh = SphereMesh.new()
		dome.radius = dims.x * 0.56
		dome.height = dims.y
		geometry = dome
	else:
		var box: BoxMesh = BoxMesh.new()
		box.size = dims
		geometry = box
	mesh.mesh = geometry
	mesh.material_override = mat
	mesh.position = where
	add_child(mesh)

func _limb(parent: Node3D, where: Vector3, dims: Vector3, mat: Material) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	var capsule: CapsuleMesh = CapsuleMesh.new()
	capsule.radius = dims.x * 0.52
	capsule.height = dims.y
	part.mesh = capsule
	part.material_override = mat
	part.position = where
	parent.add_child(part)

# Decorative firefighter equipment: visor, armor, gloves, utility belt and tank.
func _upgrade_gear() -> void:
	var dark: Material = _mat(Color(0.07, 0.105, 0.12))
	var metal: Material = _mat(Color(0.44, 0.54, 0.58))
	var gold: Material = _mat(Color(1.0, 0.78, 0.16))
	var glass: Material = _mat(Color(0.21, 0.69, 0.79))
	_part("ArmorFront", Vector3(0, 1.20, -0.157), Vector3(0.46, 0.46, 0.075), dark)
	_part("ArmorMark", Vector3(0, 1.23, -0.205), Vector3(0.28, 0.07, 0.02), gold)
	_part("ShoulderL", Vector3(-0.32, 1.43, 0), Vector3(0.23, 0.19, 0.31), dark)
	_part("ShoulderR", Vector3(0.32, 1.43, 0), Vector3(0.23, 0.19, 0.31), dark)
	_part("Belt", Vector3(0, 0.79, 0.0), Vector3(0.52, 0.13, 0.33), dark)
	_part("BeltBuckle", Vector3(0, 0.79, -0.17), Vector3(0.10, 0.08, 0.03), metal)
	_part("Mask", Vector3(0, 1.73, -0.145), Vector3(0.26, 0.14, 0.05), dark)
	_part("Visor", Vector3(0, 1.84, -0.17), Vector3(0.29, 0.13, 0.035), glass)
	_part("Tank", Vector3(0, 1.16, 0.40), Vector3(0.31, 0.58, 0.22), metal)
	_part("TankCap", Vector3(0, 1.46, 0.41), Vector3(0.25, 0.08, 0.18), dark)
	_part("Radio", Vector3(0.27, 1.24, -0.14), Vector3(0.10, 0.19, 0.07), dark)
	_part("RadioAntenna", Vector3(0.28, 1.39, -0.13), Vector3(0.025, 0.21, 0.025), metal)
	_part("KneeLeft", Vector3(-0.13, 0.51, -0.115), Vector3(0.20, 0.17, 0.08), gold)
	_part("KneeRight", Vector3(0.13, 0.51, -0.115), Vector3(0.20, 0.17, 0.08), gold)
	_gear_on_limb(left_arm, "GloveLeft", Vector3(0, -0.56, -0.02), Vector3(0.19, 0.16, 0.20), dark)
	_gear_on_limb(right_arm, "GloveRight", Vector3(0, -0.56, -0.02), Vector3(0.19, 0.16, 0.20), dark)
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
	process_mat.spread = 6.0
	process_mat.initial_velocity_min = 8.0
	process_mat.initial_velocity_max = 13.0
	process_mat.gravity = Vector3(0, -5.0, 0)
	process_mat.color = Color(0.56, 0.86, 1.0, 0.78)
	spray_particles.process_material = process_mat
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.04, 0.15)
	var water_mat: StandardMaterial3D = StandardMaterial3D.new()
	water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	water_mat.albedo_color = Color(0.54, 0.86, 1.0, 0.68)
	quad.material = water_mat
	spray_particles.draw_pass_1 = quad
	tool_mount.add_child(spray_particles)
	_create_dig_dust()
func _gear_on_limb(limb: Node3D, part_name: String, where: Vector3, dims: Vector3, mat: Material) -> void:
	var model: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = dims
	model.mesh = box
	model.name = part_name
	model.material_override = mat
	model.position = where
	limb.add_child(model)

func apply_outfit() -> void:
	var suit_color: Color = GameState.UNIFORM_COLORS[GameState.uniform_index]
	var helmet_color: Color = GameState.HELMET_COLORS[GameState.helmet_index]
	for name_str in ["Body"]:
		var model: MeshInstance3D = get_node_or_null(name_str) as MeshInstance3D
		if model != null:
			model.material_override = _mat(suit_color)
	for item in [left_arm, right_arm]:
		var arm_node: Node3D = item as Node3D
		for child in arm_node.get_children():
			if child is MeshInstance3D and child.name.begins_with("Glove") == false:
				(child as MeshInstance3D).material_override = _mat(suit_color)
	for name_str in ["Helmet"]:
		var model: MeshInstance3D = get_node_or_null(name_str) as MeshInstance3D
		if model != null:
			model.material_override = _mat(helmet_color)

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
