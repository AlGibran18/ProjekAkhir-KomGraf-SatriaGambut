# V8.2 — Lightweight procedural firefighter shown only in third-person.
# Uses meshes, not imported skeletons, to keep the existing game entirely offline.
class_name FirefighterAvatar3D
extends Node3D

var stride: float = 0.0
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D

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

func animate_movement(delta: float, is_moving: bool, sprinting: bool) -> void:
	if is_moving:
		stride += delta * (11.0 if sprinting else 7.3)
	var amount: float = (0.52 if sprinting else 0.33) if is_moving else 0.0
	left_leg.rotation.x = lerpf(left_leg.rotation.x, sin(stride) * amount, minf(1.0, delta * 10.0))
	right_leg.rotation.x = lerpf(right_leg.rotation.x, -sin(stride) * amount, minf(1.0, delta * 10.0))
	left_arm.rotation.x = lerpf(left_arm.rotation.x, -sin(stride) * amount * 0.65, minf(1.0, delta * 10.0))
	right_arm.rotation.x = lerpf(right_arm.rotation.x, sin(stride) * amount * 0.65, minf(1.0, delta * 10.0))

func _mat(tint: Color) -> Material:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.78
	return m

func _part(name_str: String, where: Vector3, dims: Vector3, mat: Material) -> void:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = name_str
	var box: BoxMesh = BoxMesh.new()
	box.size = dims
	mesh.mesh = box
	mesh.material_override = mat
	mesh.position = where
	add_child(mesh)

func _limb(parent: Node3D, where: Vector3, dims: Vector3, mat: Material) -> void:
	var part: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = dims
	part.mesh = box
	part.material_override = mat
	part.position = where
	parent.add_child(part)
