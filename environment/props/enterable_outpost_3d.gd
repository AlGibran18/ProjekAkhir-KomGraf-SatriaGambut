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
var status_light: OmniLight3D
var door_hinge: Node3D
var door_tween: Tween
var door_open: bool = false
var door_target_player: Node3D

func _ready() -> void:
	wall = _material(Color(0.38, 0.43, 0.37))
	timber = _material(Color(0.31, 0.22, 0.14))
	roof_mat = _material(Color(0.15, 0.25, 0.25))
	glass_mat = _material(Color(0.17, 0.43, 0.49))
	accent = _material(Color(0.95, 0.71, 0.15))
	floor_mat = _material(Color(0.19, 0.20, 0.19))
	_build_outpost()
	set_physics_process(true)

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
	# Hinged 2.1 m door with a real collision box. Opens toward the west wall
	# before the player reaches it, keeping the center of the entrance clear.
	_create_animated_door()
	_solid("Roof", Vector3(0, 3.27, 0), Vector3(7.80, 0.26, 7.90), roof_mat)
	_visual("RoofRidge", Vector3(0, 3.45, 0), Vector3(0.32, 0.20, 8.0), accent)
	for side_x in [-3.42, 3.42]:
		_visual("WindowFrame", Vector3(side_x, 2.10, -0.20), Vector3(0.23, 1.00, 1.80), timber)
		_visual("WindowBlueGlass", Vector3(side_x + (0.14 if side_x > 0 else -0.14), 2.10, -0.20), Vector3(0.025, 0.75, 1.52), glass_mat)
	_visual("SignBoard", Vector3(0, 2.98, -3.68), Vector3(2.90, 0.31, 0.10), accent)
	_sign("POSKO SATRIA GAMBUT", Vector3(0, 2.98, -3.765), 21)
	_sign("PETA OPERASI  |  BRIEFING", Vector3(0, 2.44, 3.29), 19)
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
	status_light = OmniLight3D.new()
	status_light.name = "ObservationPostStatus"
	status_light.position = Vector3(0, 2.75, -3.85)
	status_light.omni_range = 4.0
	status_light.light_energy = 0.48
	status_light.shadow_enabled = false
	add_child(status_light)

# Automatic proximity entrance: no extra input is required in FPS or TPP.
# The door only closes after the player moves well clear of the doorway.
func _create_animated_door() -> void:
	door_hinge = Node3D.new()
	door_hinge.name = "AnimatedDoorHinge"
	door_hinge.position = Vector3(-1.10, 0.0, -3.48)
	add_child(door_hinge)
	var leaf: AnimatableBody3D = AnimatableBody3D.new()
	leaf.name = "DoorLeafCollider"
	leaf.collision_layer = 1
	leaf.position = Vector3(1.05, 1.12, 0.0)
	door_hinge.add_child(leaf)
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.name = "ReinforcedDoor"
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(2.10, 2.24, 0.11)
	mesh.mesh = box
	mesh.material_override = timber
	leaf.add_child(mesh)
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = Vector3(2.10, 2.24, 0.11)
	collision.shape = shape
	leaf.add_child(collision)
	# Highlight strips and door latch follow the hinge.
	var knob: MeshInstance3D = MeshInstance3D.new()
	knob.name = "DoorLatch"
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 0.095
	sphere.height = 0.19
	knob.mesh = sphere
	knob.position = Vector3(0.88, 0.1, -0.11)
	knob.material_override = accent
	leaf.add_child(knob)
	var marking: MeshInstance3D = MeshInstance3D.new()
	marking.name = "EmergencyDoorStripe"
	var stripe: BoxMesh = BoxMesh.new()
	stripe.size = Vector3(1.84, 0.11, 0.13)
	marking.mesh = stripe
	marking.material_override = accent
	marking.position = Vector3(0, 0.36, 0)
	leaf.add_child(marking)
	# Small outer sign to communicate that this entrance opens automatically.
	_sign("PINTU OTOMATIS", Vector3(0, 2.49, -3.77), 16)

func _physics_process(_delta: float) -> void:
	if door_hinge == null or GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if door_target_player == null or not is_instance_valid(door_target_player):
		door_target_player = get_tree().current_scene.get_node_or_null("PlayerController3D")
	if door_target_player == null:
		return
	var distance: float = door_target_player.global_position.distance_to(global_position + Vector3(0, 0, -3.48))
	# Hysteresis stops jitter and prevents the door closing on the player.
	if not door_open and distance <= 4.2:
		_set_door_open(true)
	elif door_open and distance >= 6.3:
		_set_door_open(false)

func _set_door_open(open: bool) -> void:
	if door_hinge == null or open == door_open:
		return
	door_open = open
	if door_tween != null and door_tween.is_running():
		door_tween.kill()
	door_tween = create_tween()
	door_tween.set_trans(Tween.TRANS_CUBIC)
	door_tween.set_ease(Tween.EASE_IN_OUT)
	# Closed = 0; open ≈ 100 degrees into the room, clear of the outward approach.
	door_tween.tween_property(door_hinge, "rotation:y", deg_to_rad(-100.0) if open else 0.0, 0.85)

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

func _process(_delta: float) -> void:
	if status_light == null:
		return
	status_light.light_color = Color(0.24, 1.0, 0.63) if GameState.station_safe else Color(1.0, 0.18, 0.12)
	status_light.light_energy = 0.48 if GameState.station_safe else (0.55 + 0.35 * sin(float(Time.get_ticks_msec()) * 0.012))

func _sign(message: String, where: Vector3, font_size_px: int) -> void:
	var label: Label3D = Label3D.new()
	label.text = message
	label.font_size = font_size_px
	label.pixel_size = 0.0033
	label.position = where
	label.rotation.y = PI
	label.modulate = Color(0.96, 0.98, 0.91)
	label.no_depth_test = true
	add_child(label)
