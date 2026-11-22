# V8.3 — Enterable wildfire observation post with open doorway and furnished interior.
# Built using low-poly box geometry to avoid extra asset downloads.
class_name EnterableOutpost3D
extends Node3D

var wall: Material
var timber: Material
var roof_mat: Material
var glass_mat: Material
var accent: Material
var floor_mat: Material

func _ready() -> void:
	wall = _material(Color(0.38, 0.43, 0.37))
	timber = _material(Color(0.31, 0.22, 0.14))
	roof_mat = _material(Color(0.15, 0.25, 0.25))
	glass_mat = _material(Color(0.17, 0.43, 0.49))
	accent = _material(Color(0.95, 0.71, 0.15))
	floor_mat = _material(Color(0.19, 0.20, 0.19))
	_build_outpost()

func _build_outpost() -> void:
	# Open entrance points toward the player's north-side starting area (-Z).
	# Coordinates are relative to scene placement at Vector3(24, 0, 8.2).
	_solid("RaisedFloor", Vector3(0, 0.06, 0), Vector3(7.0, 0.12, 7.2), floor_mat)
	_solid("BackWall", Vector3(0, 1.60, 3.55), Vector3(7.0, 3.20, 0.18), wall)
	_solid("WestWall", Vector3(-3.48, 1.60, 0), Vector3(0.18, 3.20, 7.2), wall)
	_solid("EastWall", Vector3(3.48, 1.60, 0), Vector3(0.18, 3.20, 7.2), wall)
	# Two front wall pieces form a walk-through 2.2-meter doorway.
	_solid("FrontLeft", Vector3(-2.34, 1.60, -3.55), Vector3(2.32, 3.20, 0.18), wall)
	_solid("FrontRight", Vector3(2.34, 1.60, -3.55), Vector3(2.32, 3.20, 0.18), wall)
	_solid("DoorLintel", Vector3(0, 2.90, -3.55), Vector3(2.35, 0.55, 0.20), timber)
	# Open door is visual only: no physical barrier across the entrance.
	_visual("OpenDoorPanel", Vector3(1.13, 1.05, -3.32), Vector3(0.10, 2.05, 1.65), timber)
	_solid("Roof", Vector3(0, 3.27, 0), Vector3(7.80, 0.26, 7.90), roof_mat)
	_visual("RoofRidge", Vector3(0, 3.45, 0), Vector3(0.32, 0.20, 8.0), accent)
	for side_x in [-3.42, 3.42]:
		_visual("WindowFrame", Vector3(side_x, 2.10, -0.20), Vector3(0.23, 1.00, 1.80), timber)
		_visual("WindowBlueGlass", Vector3(side_x + (0.14 if side_x > 0 else -0.14), 2.10, -0.20), Vector3(0.025, 0.75, 1.52), glass_mat)
	_visual("SignBoard", Vector3(0, 2.98, -3.68), Vector3(2.90, 0.31, 0.10), accent)
	# Trestle legs + field planning table; east side leaves a clear walk path.
	_solid("DeskTop", Vector3(1.75, 0.90, 1.10), Vector3(1.75, 0.12, 0.88), timber)
	_solid("DeskLegA", Vector3(1.12, 0.47, 0.82), Vector3(0.12, 0.82, 0.12), dark_mat())
	_solid("DeskLegB", Vector3(2.37, 0.47, 1.38), Vector3(0.12, 0.82, 0.12), dark_mat())
	_visual("TacticalMapBoard", Vector3(0, 1.76, 3.41), Vector3(3.00, 1.40, 0.08), glass_mat)
	_visual("MapGridH1", Vector3(0, 1.40, 3.34), Vector3(2.70, 0.025, 0.03), accent)
	_visual("MapGridH2", Vector3(0, 1.86, 3.34), Vector3(2.70, 0.025, 0.03), accent)
	_visual("MapGridV1", Vector3(-0.70, 1.75, 3.34), Vector3(0.025, 1.16, 0.03), accent)
	_visual("MapGridV2", Vector3(0.70, 1.75, 3.34), Vector3(0.025, 1.16, 0.03), accent)
	_visual("StorageShelf", Vector3(-2.70, 1.24, 1.70), Vector3(0.65, 0.13, 2.00), timber)
	_visual("SupplyCase", Vector3(-2.70, 1.54, 1.70), Vector3(0.50, 0.49, 0.60), accent)
	_visual("RadioBase", Vector3(1.80, 1.07, 1.1), Vector3(0.31, 0.23, 0.19), dark_mat())
	_visual("RadioAntenna", Vector3(1.8, 1.28, 1.1), Vector3(0.025, 0.27, 0.025), accent)
	var light: OmniLight3D = OmniLight3D.new()
	light.name = "InteriorSafetyLight"
	light.position = Vector3(0, 2.90, 0)
	light.light_color = Color(1.0, 0.84, 0.52)
	light.light_energy = 0.48
	light.omni_range = 6.2
	light.shadow_enabled = false
	add_child(light)

func _material(color: Color) -> Material:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m

func dark_mat() -> Material:
	return _material(Color(0.095, 0.13, 0.14))

func _visual(part_name: String, pos: Vector3, dimensions: Vector3, mat: Material) -> void:
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.name = part_name
	mesh_instance.position = pos
	var box: BoxMesh = BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.material_override = mat
	add_child(mesh_instance)

func _solid(part_name: String, pos: Vector3, dimensions: Vector3, mat: Material) -> void:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = part_name
	body.collision_layer = 1
	body.position = pos
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = dimensions
	mesh_instance.mesh = box
	mesh_instance.material_override = mat
	body.add_child(mesh_instance)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
