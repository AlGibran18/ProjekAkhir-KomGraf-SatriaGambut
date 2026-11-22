# V8.5 — optional floating world arrow for both FPS and TPP cameras.
# Uses the exact cell selected by MissionDirector; it never changes player targeting.
class_name NavigationWorldArrow3D
extends Node3D

var player: PlayerController3D
var target_cell: Vector2i = Vector2i(-1, -1)
var target_type: String = ""
var pointer: Node3D
var arrow_color: Color = Color(0.21, 1.0, 0.79)
var arrow_material: StandardMaterial3D
var phase_elapsed: float = 0.0

func initialize(actor: PlayerController3D) -> void:
	player = actor

func _ready() -> void:
	_build_arrow()
	EventBus.navigator_target_changed.connect(_on_target_changed)
	GameState.guide_display_changed.connect(_on_visibility_changed)
	EventBus.game_phase_changed.connect(_on_phase_changed)
	set_process(true)

func _on_target_changed(cell: Vector2i, category: String) -> void:
	target_cell = cell
	target_type = category
	_update_color()

func _on_visibility_changed(_enabled: bool) -> void:
	_update_visibility()

func _on_phase_changed(_phase: ToolEnums.GamePhase) -> void:
	_update_visibility()

func _update_visibility() -> void:
	visible = _can_display()

func _can_display() -> bool:
	return player != null and target_cell != Vector2i(-1, -1) 		and GameState.show_world_guide_arrow 		and GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS 		and not player.cinematic_mode_enabled and not player.tactical_map_open

func _build_arrow() -> void:
	pointer = Node3D.new()
	pointer.name = "FloatingDirectionArrow"
	add_child(pointer)
	arrow_material = StandardMaterial3D.new()
	arrow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arrow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	arrow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arrow_material.albedo_color = Color(0.15, 0.95, 0.77, 0.68)
	arrow_material.emission_enabled = true
	arrow_material.emission = Color(0.11, 0.65, 0.51)
	arrow_material.emission_energy_multiplier = 0.45
	# Shaft extends toward forward (-Z).
	var shaft: MeshInstance3D = MeshInstance3D.new()
	shaft.name = "ArrowShaft"
	var shaft_mesh: BoxMesh = BoxMesh.new()
	shaft_mesh.size = Vector3(0.085, 0.035, 0.39)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0, 0.12)
	shaft.material_override = arrow_material
	pointer.add_child(shaft)
	# A proper broad triangle arrowhead, not a rectangular prism.
	# Tip faces -Z, with a clear point and wide shoulders.
	var tip: MeshInstance3D = MeshInstance3D.new()
	tip.name = "TriangleArrowHead"
	var triangle: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(0.0, 0.0, -0.50),
		Vector3(-0.26, 0.0, -0.02),
		Vector3(0.26, 0.0, -0.02)
	])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	triangle.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	tip.mesh = triangle
	tip.material_override = arrow_material
	tip.position = Vector3(0.0, 0.015, -0.13)
	pointer.add_child(tip)
	visible = false

func _update_color() -> void:
	match target_type:
		"SUMUR AIR":
			arrow_color = Color(0.28, 0.78, 1.0)
		"POS PENGAMATAN":
			arrow_color = Color(0.22, 1.0, 0.70)
		_:
			arrow_color = Color(1.0, 0.72, 0.24)
	if arrow_material != null:
		arrow_material.albedo_color = Color(arrow_color.r, arrow_color.g, arrow_color.b, 0.78)
		arrow_material.emission = arrow_color * 0.55

func _process(delta: float) -> void:
	visible = _can_display()
	if not visible:
		return
	var camera: Camera3D = player.get_active_player_camera()
	if camera == null or not camera.current:
		return
	var goal: Vector3 = Vector3(float(target_cell.x) * GameState.CELL_SIZE, 0.0, float(target_cell.y) * GameState.CELL_SIZE)
	var to_goal: Vector3 = goal - player.global_position
	to_goal.y = 0.0
	if to_goal.length_squared() < 1.4:
		visible = false
		return
	# Subtle marker below the screen center, leaving aiming reticle clear.
	phase_elapsed += delta
	var forward: Vector3 = -camera.global_transform.basis.z
	var camera_down: Vector3 = -camera.global_transform.basis.y
	var anchor: Vector3 = camera.global_position + forward * 2.25 + camera_down * 0.54
	global_position = anchor + Vector3.UP * (0.022 * sin(phase_elapsed * 3.3))
	# Horizontal direction is stable even if looking steeply up/down.
	pointer.global_position = global_position
	pointer.look_at(global_position + to_goal.normalized(), Vector3.UP)
	pointer.scale = Vector3.ONE * (0.90 + 0.07 * sin(phase_elapsed * 4.5))
