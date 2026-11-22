# simulation/view/simulation_view_3d.gd - Pengelola visual 3D hutan gambut: terrain tanpa celah, vegetasi 4-kuadran ber-collider, posko satgas, pagar kayu, animasi tween, dan transisi kamera.
class_name SimulationView3D
extends Node3D

@onready var multi_mesh_instance: MultiMeshInstance3D = $TerrainMultiMesh
@onready var cursor_highlight: Node3D = $CursorHighlight
@onready var ground_collider: StaticBody3D = $GroundCollider
@onready var perimeter_walls: StaticBody3D = $PerimeterWalls
@onready var forest_container: Node3D = $ForestContainer
@onready var border_forest_container: Node3D = $BorderForestContainer
@onready var props_container: Node3D = $PropsContainer
@onready var vfx_container: Node3D = $VfxContainer
@onready var planning_camera: Camera3D = $PlanningCamera
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D

var grid_simulator: GridSimulator
var cell_visual_nodes: Dictionary = {}
var well_nodes: Dictionary = {}
var trench_nodes: Dictionary = {}
var vfx_nodes: Dictionary = {}
var current_cell_colors: Dictionary = {}
var target_cell_colors: Dictionary = {}
var animating_cells: Dictionary = {}
var target_cursor_pos: Vector3 = Vector3.ZERO
var camera_tween: Tween

var healthy_trees: Array[PackedScene] = [
	preload("res://assets/models/nature/glTF/CommonTree_2.gltf"),
	preload("res://assets/models/nature/glTF/CommonTree_3.gltf"),
	preload("res://assets/models/nature/glTF/CommonTree_4.gltf"),
	preload("res://assets/models/nature/glTF/Pine_3.gltf"),
	preload("res://assets/models/nature/glTF/Pine_4.gltf")
]
var dead_trees: Array[PackedScene] = [
	preload("res://assets/models/nature/glTF/DeadTree_1.gltf"),
	preload("res://assets/models/nature/glTF/DeadTree_2.gltf"),
	preload("res://assets/models/nature/glTF/DeadTree_3.gltf")
]
var fern_scene: PackedScene = preload("res://assets/models/nature/glTF/Fern_1.gltf")
var plant_big_scene: PackedScene = preload("res://assets/models/nature/glTF/Plant_1_Big.gltf")
var bush_scene: PackedScene = preload("res://assets/models/nature/glTF/Bush_Common.gltf")
var grass_scene: PackedScene = preload("res://assets/models/nature/glTF/Grass_Common_Tall.gltf")
var rock_med_scene: PackedScene = preload("res://assets/models/nature/glTF/Rock_Medium_1.gltf")
var mushroom_scene: PackedScene = preload("res://assets/models/nature/glTF/Mushroom_Common.gltf")

var kenney_log_scene: PackedScene = preload("res://assets/models/kenney/log.glb")
var kenney_stump_scene: PackedScene = preload("res://assets/models/kenney/stump_old.glb")
var kenney_tent_scene: PackedScene = preload("res://assets/models/kenney/tent_detailedOpen.glb")
var kenney_log_stack_scene: PackedScene = preload("res://assets/models/kenney/log_stackLarge.glb")
var kenney_sign_scene: PackedScene = preload("res://assets/models/kenney/sign.glb")
var kenney_fence_scene: PackedScene = preload("res://assets/models/kenney/fence_simple.glb")
var kenney_campfire_scene: PackedScene = preload("res://assets/models/kenney/campfire_stones.glb")

var water_well_scene: PackedScene = preload("res://environment/props/water_well_prop.tscn")
var firebreak_trench_scene: PackedScene = preload("res://environment/props/firebreak_trench.tscn")
var hazard_vfx_scene: PackedScene = preload("res://environment/vfx/cell_hazard_vfx.tscn")

func _ready() -> void:
	EventBus.cell_state_updated.connect(_on_cell_state_updated)
	EventBus.cell_hovered.connect(_on_cell_hovered)
	EventBus.thermal_mode_toggled.connect(_on_thermal_mode_toggled)
	EventBus.well_placed.connect(_on_well_placed)
	EventBus.well_removed.connect(_on_well_removed)
	EventBus.steam_burst_requested.connect(_on_steam_burst_requested)
	EventBus.game_phase_changed.connect(_on_game_phase_changed)
	EventBus.graphics_quality_changed.connect(_on_graphics_quality_changed)
	_apply_sun_quality()

func _process(delta: float) -> void:
	_update_dynamic_fog(delta)
	_animate_cursor(delta)
	_animate_cell_colors(delta)

func setup_view(simulator: GridSimulator) -> void:
	grid_simulator = simulator
	_clear_dynamic_containers()
	_init_ground_mesh(simulator.grid_width, simulator.grid_height)
	_init_perimeter_walls(simulator.grid_width, simulator.grid_height)
	_init_forest_vegetation(simulator.grid_width, simulator.grid_height)
	_init_border_forest(simulator.grid_width, simulator.grid_height)
	_init_posko_and_fences(simulator.grid_width, simulator.grid_height)
	_refresh_all_visuals()

func activate_planning_camera() -> void:
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	if planning_camera != null and grid_simulator != null:
		var cell_sz: float = GameState.CELL_SIZE
		var cx: float = float(grid_simulator.grid_width - 1) * cell_sz * 0.5
		var cz: float = float(grid_simulator.grid_height - 1) * cell_sz * 0.5
		planning_camera.fov = 55.0
		planning_camera.global_position = Vector3(cx, 38.0, cz + 26.0)
		planning_camera.look_at(Vector3(cx, 0.0, cz), Vector3.UP)
		planning_camera.current = true

func transition_to_fps_camera(target_cam: Camera3D, on_finished: Callable) -> void:
	if planning_camera == null or target_cam == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	if camera_tween != null and camera_tween.is_valid():
		camera_tween.kill()
	planning_camera.current = true
	camera_tween = create_tween()
	camera_tween.set_parallel(true)
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.tween_property(planning_camera, "global_transform", target_cam.global_transform, 0.70)
	camera_tween.tween_property(planning_camera, "fov", target_cam.fov, 0.70)
	camera_tween.chain().tween_callback(on_finished)

func _clear_dynamic_containers() -> void:
	for child in forest_container.get_children():
		child.queue_free()
	for child in border_forest_container.get_children():
		child.queue_free()
	for child in props_container.get_children():
		child.queue_free()
	for child in vfx_container.get_children():
		child.queue_free()
	cell_visual_nodes.clear()
	well_nodes.clear()
	trench_nodes.clear()
	vfx_nodes.clear()
	current_cell_colors.clear()
	target_cell_colors.clear()
	animating_cells.clear()

func _init_ground_mesh(width: int, height: int) -> void:
	var cell_sz: float = GameState.CELL_SIZE
	var total_count: int = width * height
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = total_count

	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(cell_sz, 0.16, cell_sz)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	box_mesh.material = mat
	mm.mesh = box_mesh

	var idx: int = 0
	var base_col: Color = Color(0.18, 0.13, 0.08)
	for y in range(height):
		for x in range(width):
			var pos: Vector2i = Vector2i(x, y)
			var world_pos: Vector3 = Vector3(float(x) * cell_sz, -0.08, float(y) * cell_sz)
			var xform: Transform3D = Transform3D(Basis(), world_pos)
			mm.set_instance_transform(idx, xform)
			mm.set_instance_color(idx, base_col)
			current_cell_colors[pos] = base_col
			target_cell_colors[pos] = base_col
			idx += 1

	multi_mesh_instance.multimesh = mm

func _init_perimeter_walls(width: int, height: int) -> void:
	for child in perimeter_walls.get_children():
		child.queue_free()

	var cell_sz: float = GameState.CELL_SIZE
	var min_x: float = -cell_sz * 0.5
	var max_x: float = (float(width) - 0.5) * cell_sz
	var min_z: float = -cell_sz * 0.5
	var max_z: float = (float(height) - 0.5) * cell_sz
	var span_x: float = max_x - min_x + 2.0
	var span_z: float = max_z - min_z + 2.0
	var cx: float = (min_x + max_x) * 0.5
	var cz: float = (min_z + max_z) * 0.5

	_add_wall_collider(Vector3(cx, 5.0, min_z - 0.4), Vector3(span_x, 12.0, 0.8))
	_add_wall_collider(Vector3(cx, 5.0, max_z + 0.4), Vector3(span_x, 12.0, 0.8))
	_add_wall_collider(Vector3(min_x - 0.4, 5.0, cz), Vector3(0.8, 12.0, span_z))
	_add_wall_collider(Vector3(max_x + 0.4, 5.0, cz), Vector3(0.8, 12.0, span_z))

func _add_wall_collider(pos: Vector3, size: Vector3) -> void:
	var col: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	perimeter_walls.add_child(col)

func _init_forest_vegetation(width: int, height: int) -> void:
	var cell_sz: float = GameState.CELL_SIZE
	for y in range(height):
		for x in range(width):
			var pos: Vector2i = Vector2i(x, y)
			var cell_holder: Node3D = Node3D.new()
			cell_holder.name = "Cell_%d_%d" % [x, y]
			cell_holder.position = Vector3(float(x) * cell_sz, 0.0, float(y) * cell_sz)
			forest_container.add_child(cell_holder)

			var hash_a: float = sin(float(x * 17 + y * 31)) * 43758.5453
			var rand_a: float = hash_a - floorf(hash_a)
			var hash_b: float = cos(float(x * 23 - y * 13)) * 19283.123
			var rand_b: float = hash_b - floorf(hash_b)

			var tree_holder: Node3D = Node3D.new()
			tree_holder.name = "TreeHolder"
			cell_holder.add_child(tree_holder)

			var plant_holder: Node3D = Node3D.new()
			plant_holder.name = "PlantHolder"
			cell_holder.add_child(plant_holder)

			var in_spawn_zone: bool = (x >= (width / 2) - 2 and x <= (width / 2) + 2 and y <= 2)
			if not in_spawn_zone:
				var q1_pos: Vector3 = Vector3(-0.78 + (rand_b - 0.5) * 0.25, 0.0, -0.78 + (rand_a - 0.5) * 0.25)
				if rand_a > 0.36:
					var tree_idx: int = int(rand_b * float(healthy_trees.size())) % healthy_trees.size()
					var tree_instance: Node3D = healthy_trees[tree_idx].instantiate() as Node3D
					var scale_xz: float = 1.10 + (rand_a * 0.25)
					var scale_y: float = 1.55 + (rand_a * 0.35)
					tree_instance.scale = Vector3(scale_xz, scale_y, scale_xz)
					tree_instance.rotation.y = rand_b * TAU
					tree_instance.position = q1_pos
					tree_holder.add_child(tree_instance)

					var trunk_body: StaticBody3D = StaticBody3D.new()
					trunk_body.name = "TreeCollider"
					trunk_body.position = q1_pos + Vector3(0.0, 1.2, 0.0)
					var trunk_col: CollisionShape3D = CollisionShape3D.new()
					var cyl: CylinderShape3D = CylinderShape3D.new()
					cyl.radius = 0.28
					cyl.height = 2.4
					trunk_col.shape = cyl
					trunk_body.add_child(trunk_col)
					tree_holder.add_child(trunk_body)

				var q2_pos: Vector3 = Vector3(0.82 + (rand_a - 0.5) * 0.22, 0.0, -0.75 + (rand_b - 0.5) * 0.22)
				if rand_b > 0.30:
					if rand_a > 0.45:
						var fern_inst: Node3D = fern_scene.instantiate() as Node3D
						var fs: float = 0.15 + (rand_a * 0.04)
						fern_inst.scale = Vector3(fs, fs, fs)
						fern_inst.position = q2_pos
						fern_inst.rotation.y = rand_a * TAU
						plant_holder.add_child(fern_inst)
					else:
						var pbig_inst: Node3D = plant_big_scene.instantiate() as Node3D
						var ps: float = 0.24 + (rand_b * 0.08)
						pbig_inst.scale = Vector3(ps, ps, ps)
						pbig_inst.position = q2_pos
						pbig_inst.rotation.y = rand_b * TAU
						plant_holder.add_child(pbig_inst)

				var q3_pos: Vector3 = Vector3(-0.75 + (rand_b - 0.5) * 0.22, 0.0, 0.82 + (rand_a - 0.5) * 0.22)
				if rand_a > 0.38:
					if rand_b > 0.72:
						var log_inst: Node3D = kenney_log_scene.instantiate() as Node3D
						log_inst.scale = Vector3(2.2, 2.2, 2.2)
						log_inst.position = q3_pos
						log_inst.rotation.y = rand_a * TAU
						plant_holder.add_child(log_inst)
					elif rand_b > 0.56:
						var stump_inst: Node3D = kenney_stump_scene.instantiate() as Node3D
						stump_inst.scale = Vector3(2.2, 2.2, 2.2)
						stump_inst.position = q3_pos
						stump_inst.rotation.y = rand_b * TAU
						plant_holder.add_child(stump_inst)
					else:
						var bush_inst: Node3D = bush_scene.instantiate() as Node3D
						var bs: float = 0.55 + (rand_b * 0.17)
						bush_inst.scale = Vector3(bs, bs, bs)
						bush_inst.position = q3_pos
						bush_inst.rotation.y = rand_b * TAU
						plant_holder.add_child(bush_inst)

				var q4_pos: Vector3 = Vector3(0.78 + (rand_a - 0.5) * 0.22, 0.0, 0.78 + (rand_b - 0.5) * 0.22)
				if rand_b > 0.20:
					if rand_a > 0.82:
						var rock_inst: Node3D = rock_med_scene.instantiate() as Node3D
						var rs: float = 0.24 + (rand_b * 0.10)
						rock_inst.scale = Vector3(rs, rs, rs)
						rock_inst.position = q4_pos
						rock_inst.rotation.y = rand_a * TAU
						plant_holder.add_child(rock_inst)
					elif rand_a > 0.70:
						var mush_inst: Node3D = mushroom_scene.instantiate() as Node3D
						var ms: float = 0.65 + (rand_b * 0.20)
						mush_inst.scale = Vector3(ms, ms, ms)
						mush_inst.position = q4_pos
						mush_inst.rotation.y = rand_b * TAU
						plant_holder.add_child(mush_inst)
					else:
						var grass_inst: Node3D = grass_scene.instantiate() as Node3D
						var gs: float = 0.45 + (rand_a * 0.17)
						grass_inst.scale = Vector3(gs, gs, gs)
						grass_inst.position = q4_pos
						grass_inst.rotation.y = rand_a * PI
						plant_holder.add_child(grass_inst)

			cell_visual_nodes[pos] = cell_holder

func _init_border_forest(width: int, height: int) -> void:
	var cell_sz: float = GameState.CELL_SIZE
	for y in range(-3, height + 3):
		for x in range(-3, width + 3):
			if x >= 0 and x < width and y >= 0 and y < height:
				continue
			var hash_val: float = sin(float(x * 19 + y * 41)) * 28374.11
			var rand_val: float = hash_val - floorf(hash_val)
			if rand_val > 0.35:
				var tree_idx: int = int(rand_val * float(healthy_trees.size())) % healthy_trees.size()
				var tree_inst: Node3D = healthy_trees[tree_idx].instantiate() as Node3D
				var scale_xz: float = 1.15 + (rand_val * 0.30)
				var scale_y: float = 1.65 + (rand_val * 0.40)
				tree_inst.scale = Vector3(scale_xz, scale_y, scale_xz)
				tree_inst.rotation.y = rand_val * TAU
				tree_inst.position = Vector3(float(x) * cell_sz, 0.0, float(y) * cell_sz)
				border_forest_container.add_child(tree_inst)

func _init_posko_and_fences(width: int, height: int) -> void:
	var cell_sz: float = GameState.CELL_SIZE
	var tent_a: Node3D = kenney_tent_scene.instantiate() as Node3D
	tent_a.scale = Vector3(3.5, 3.5, 3.5)
	tent_a.position = Vector3(5.4 * cell_sz, 0.0, 0.4 * cell_sz)
	tent_a.rotation.y = 0.25
	props_container.add_child(tent_a)

	var tent_b: Node3D = kenney_tent_scene.instantiate() as Node3D
	tent_b.scale = Vector3(3.5, 3.5, 3.5)
	tent_b.position = Vector3(10.2 * cell_sz, 0.0, 0.4 * cell_sz)
	tent_b.rotation.y = -0.3
	props_container.add_child(tent_b)

	var stack_a: Node3D = kenney_log_stack_scene.instantiate() as Node3D
	stack_a.scale = Vector3(2.4, 2.4, 2.4)
	stack_a.position = Vector3(6.8 * cell_sz, 0.0, 0.4 * cell_sz)
	props_container.add_child(stack_a)

	var camp_a: Node3D = kenney_campfire_scene.instantiate() as Node3D
	camp_a.scale = Vector3(2.4, 2.4, 2.4)
	camp_a.position = Vector3(9.0 * cell_sz, 0.0, 0.5 * cell_sz)
	props_container.add_child(camp_a)

	var sign_a: Node3D = kenney_sign_scene.instantiate() as Node3D
	sign_a.scale = Vector3(2.8, 2.8, 2.8)
	sign_a.position = Vector3(7.1 * cell_sz, 0.0, 1.8 * cell_sz)
	sign_a.rotation.y = PI
	props_container.add_child(sign_a)

	for x in range(width):
		var fn_top: Node3D = kenney_fence_scene.instantiate() as Node3D
		fn_top.scale = Vector3(cell_sz, cell_sz, cell_sz)
		fn_top.position = Vector3(float(x) * cell_sz, 0.0, -0.05)
		props_container.add_child(fn_top)

		var fn_bot: Node3D = kenney_fence_scene.instantiate() as Node3D
		fn_bot.scale = Vector3(cell_sz, cell_sz, cell_sz)
		fn_bot.position = Vector3(float(x) * cell_sz, 0.0, float(height) * cell_sz - cell_sz * 0.05)
		props_container.add_child(fn_bot)

	for y in range(height):
		var fn_left: Node3D = kenney_fence_scene.instantiate() as Node3D
		fn_left.scale = Vector3(cell_sz, cell_sz, cell_sz)
		fn_left.rotation.y = PI * 0.5
		fn_left.position = Vector3(-0.05, 0.0, float(y) * cell_sz)
		props_container.add_child(fn_left)

		var fn_right: Node3D = kenney_fence_scene.instantiate() as Node3D
		fn_right.scale = Vector3(cell_sz, cell_sz, cell_sz)
		fn_right.rotation.y = -PI * 0.5
		fn_right.position = Vector3(float(width) * cell_sz - cell_sz * 0.05, 0.0, float(y) * cell_sz)
		props_container.add_child(fn_right)

func _refresh_all_visuals() -> void:
	if grid_simulator == null or multi_mesh_instance.multimesh == null:
		return
	for pos in grid_simulator.cells.keys():
		var cell: PeatCellData = grid_simulator.cells[pos]
		_update_cell_visual(pos, cell)

func _on_cell_state_updated(pos: Vector2i, cell: PeatCellData) -> void:
	_update_cell_visual(pos, cell)

func _on_thermal_mode_toggled(_enabled: bool) -> void:
	_refresh_all_visuals()

func _on_game_phase_changed(_new_phase: ToolEnums.GamePhase) -> void:
	_refresh_all_visuals()

func _on_cell_hovered(pos: Vector2i, cell: PeatCellData) -> void:
	if cell == null or pos == Vector2i(-1, -1) or GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		cursor_highlight.visible = false
	else:
		var cell_sz: float = GameState.CELL_SIZE
		var dest: Vector3 = Vector3(float(pos.x) * cell_sz, 0.05, float(pos.y) * cell_sz)
		if not cursor_highlight.visible:
			cursor_highlight.position = dest
			cursor_highlight.visible = true
		target_cursor_pos = dest

func _animate_cursor(delta: float) -> void:
	if cursor_highlight.visible:
		cursor_highlight.position = cursor_highlight.position.lerp(target_cursor_pos, clampf(delta * 20.0, 0.0, 1.0))

func _animate_cell_colors(delta: float) -> void:
	if animating_cells.is_empty() or multi_mesh_instance.multimesh == null or grid_simulator == null:
		return
	var done_list: Array[Vector2i] = []
	var blend: float = clampf(delta * 8.0, 0.0, 1.0)
	for pos in animating_cells.keys():
		var cur: Color = current_cell_colors.get(pos, Color.WHITE)
		var target: Color = target_cell_colors.get(pos, Color.WHITE)
		var next_col: Color = cur.lerp(target, blend)
		if next_col.is_equal_approx(target):
			next_col = target
			done_list.append(pos)
		current_cell_colors[pos] = next_col
		var idx: int = (pos.y * grid_simulator.grid_width) + pos.x
		if idx >= 0 and idx < multi_mesh_instance.multimesh.instance_count:
			multi_mesh_instance.multimesh.set_instance_color(idx, next_col)
	for p in done_list:
		animating_cells.erase(p)

func _on_well_placed(pos: Vector2i) -> void:
	if well_nodes.has(pos):
		return
	var well_inst: Node3D = water_well_scene.instantiate() as Node3D
	well_inst.position = Vector3(float(pos.x) * GameState.CELL_SIZE, 0.0, float(pos.y) * GameState.CELL_SIZE)
	well_inst.scale = Vector3(0.05, 0.05, 0.05)
	props_container.add_child(well_inst)
	well_nodes[pos] = well_inst
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_BACK)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(well_inst, "scale", Vector3.ONE, 0.25)
	if cell_visual_nodes.has(pos):
		var holder: Node3D = cell_visual_nodes[pos]
		var tree_h: Node3D = holder.get_node_or_null("TreeHolder")
		if tree_h != null:
			tree_h.visible = false
			tree_h.process_mode = Node.PROCESS_MODE_DISABLED

func _on_well_removed(pos: Vector2i) -> void:
	if well_nodes.has(pos):
		var node: Node3D = well_nodes[pos]
		node.queue_free()
		well_nodes.erase(pos)
	if cell_visual_nodes.has(pos):
		var holder: Node3D = cell_visual_nodes[pos]
		var tree_h: Node3D = holder.get_node_or_null("TreeHolder")
		if tree_h != null:
			tree_h.visible = true
			tree_h.process_mode = Node.PROCESS_MODE_INHERIT

func _on_steam_burst_requested(pos: Vector2i) -> void:
	if vfx_nodes.has(pos):
		var vfx: CellHazardVFX = vfx_nodes[pos]
		vfx.trigger_steam_burst()
	else:
		var temp_vfx: CellHazardVFX = hazard_vfx_scene.instantiate() as CellHazardVFX
		temp_vfx.position = Vector3(float(pos.x) * GameState.CELL_SIZE, 0.0, float(pos.y) * GameState.CELL_SIZE)
		vfx_container.add_child(temp_vfx)
		temp_vfx.trigger_steam_burst()
		get_tree().create_timer(1.5).timeout.connect(func() -> void:
			if is_instance_valid(temp_vfx):
				temp_vfx.queue_free()
		)

func _update_cell_visual(pos: Vector2i, cell: PeatCellData) -> void:
	if multi_mesh_instance.multimesh == null or grid_simulator == null:
		return
	var index: int = (pos.y * grid_simulator.grid_width) + pos.x
	if index < 0 or index >= multi_mesh_instance.multimesh.instance_count:
		return

	var target_color: Color = Color.WHITE
	var show_heatmap: bool = GameState.is_thermal_active or (GameState.current_phase == ToolEnums.GamePhase.PLANNING)

	if show_heatmap:
		if cell.has_well:
			target_color = Color(0.15, 0.65, 1.0, 1.0)
		elif cell.has_ember():
			target_color = Color(1.0, 0.14, 0.04, 1.0)
		elif cell.is_burning():
			target_color = Color(1.0, 0.65, 0.10, 1.0)
		elif cell.is_firebreak:
			target_color = Color(0.18, 0.18, 0.24, 1.0)
		else:
			target_color = PFVICalculator.get_risk_color(cell.risk_category)
	else:
		if cell.has_well:
			target_color = Color(0.16, 0.34, 0.28, 1.0)
		elif cell.is_burning():
			target_color = Color(0.88, 0.28, 0.06, 1.0)
		elif cell.has_ember():
			target_color = Color(0.16, 0.10, 0.07, 1.0)
		elif cell.is_firebreak:
			target_color = Color(0.24, 0.18, 0.12, 1.0)
		elif cell.is_burnt:
			target_color = Color(0.09, 0.07, 0.06, 1.0)
		else:
			var moisture_ratio: float = clampf(cell.soil_moisture / 0.65, 0.0, 1.0)
			var dry_peat: Color = Color(0.32, 0.22, 0.13)
			var moist_peat: Color = Color(0.14, 0.16, 0.09)
			target_color = dry_peat.lerp(moist_peat, moisture_ratio)

	target_cell_colors[pos] = target_color
	animating_cells[pos] = true

	if cell.is_firebreak and not trench_nodes.has(pos):
		var trench_inst: Node3D = firebreak_trench_scene.instantiate() as Node3D
		trench_inst.position = Vector3(float(pos.x) * GameState.CELL_SIZE, 0.0, float(pos.y) * GameState.CELL_SIZE)
		trench_inst.scale = Vector3(1.0, 0.05, 1.0)
		props_container.add_child(trench_inst)
		trench_nodes[pos] = trench_inst
		var tw_t: Tween = create_tween()
		tw_t.set_trans(Tween.TRANS_BACK)
		tw_t.set_ease(Tween.EASE_OUT)
		tw_t.tween_property(trench_inst, "scale", Vector3.ONE, 0.22)

	if cell_visual_nodes.has(pos):
		var cell_holder: Node3D = cell_visual_nodes[pos]
		var tree_holder: Node3D = cell_holder.get_node_or_null("TreeHolder")
		var plant_holder: Node3D = cell_holder.get_node_or_null("PlantHolder")

		if cell.is_firebreak or cell.has_well:
			if tree_holder != null:
				tree_holder.visible = false
				tree_holder.process_mode = Node.PROCESS_MODE_DISABLED
			if plant_holder != null:
				plant_holder.visible = false
		else:
			if tree_holder != null:
				tree_holder.visible = true
				tree_holder.process_mode = Node.PROCESS_MODE_INHERIT
				if cell.is_burning() or cell.is_burnt:
					if tree_holder.get_child_count() > 0:
						var first_tree: Node3D = tree_holder.get_child(0)
						if not first_tree.name.begins_with("DeadTree") and not first_tree.name.begins_with("TreeCollider"):
							var old_rot: float = first_tree.rotation.y
							var old_pos: Vector3 = first_tree.position
							first_tree.queue_free()
							var dead_inst: Node3D = dead_trees[0].instantiate() as Node3D
							dead_inst.name = "DeadTree"
							dead_inst.rotation.y = old_rot
							dead_inst.position = old_pos
							dead_inst.scale = Vector3(0.05, 0.05, 0.05)
							tree_holder.add_child(dead_inst)
							var tw_d: Tween = create_tween()
							tw_d.set_trans(Tween.TRANS_QUAD)
							tw_d.set_ease(Tween.EASE_OUT)
							tw_d.tween_property(dead_inst, "scale", Vector3(1.05, 1.30, 1.05), 0.24)
			if plant_holder != null:
				plant_holder.visible = not cell.is_burnt

	_sync_cell_vfx(pos, cell)

func _sync_cell_vfx(pos: Vector2i, cell: PeatCellData) -> void:
	if cell.is_active_hazard():
		if not vfx_nodes.has(pos):
			var vfx_inst: CellHazardVFX = hazard_vfx_scene.instantiate() as CellHazardVFX
			vfx_inst.position = Vector3(float(pos.x) * GameState.CELL_SIZE, 0.0, float(pos.y) * GameState.CELL_SIZE)
			vfx_container.add_child(vfx_inst)
			vfx_nodes[pos] = vfx_inst
		var vfx: CellHazardVFX = vfx_nodes[pos]
		var can_light: bool = vfx_nodes.size() <= 5
		vfx.update_state(cell, GameState.is_thermal_active, GameState.wind_direction, can_light)
	else:
		if vfx_nodes.has(pos):
			var old_vfx: CellHazardVFX = vfx_nodes[pos]
			vfx_nodes.erase(pos)
			get_tree().create_timer(1.2).timeout.connect(func() -> void:
				if is_instance_valid(old_vfx):
					old_vfx.queue_free()
			)

func _update_dynamic_fog(delta: float) -> void:
	if world_env == null or world_env.environment == null:
		return
	var hazard_ratio: float = clampf(float(GameState.active_fire_cells) / 14.0, 0.0, 1.0)
	var rain_ratio: float = clampf(GameState.global_rainfall_rate / 12.0, 0.0, 1.0)
	var target_density: float = lerpf(0.010, 0.032, hazard_ratio) + rain_ratio * 0.004
	var clear_sky: Color = Color(0.58, 0.74, 0.86)
	var smoky_sky: Color = Color(0.66, 0.54, 0.42)
	var target_color: Color = clear_sky.lerp(smoky_sky, hazard_ratio)
	target_color = target_color.lerp(Color(0.36, 0.43, 0.51), rain_ratio * 0.45)
	world_env.environment.fog_density = lerpf(world_env.environment.fog_density, target_density, delta * 1.5)
	world_env.environment.fog_light_color = world_env.environment.fog_light_color.lerp(target_color, delta * 1.5)
	world_env.environment.background_color = world_env.environment.background_color.lerp(target_color, delta * 1.5)

func _on_graphics_quality_changed(_quality: int) -> void:
	_apply_sun_quality()

func _apply_sun_quality() -> void:
	if sun_light != null:
		sun_light.shadow_enabled = (GameState.current_graphics_quality != GameState.GraphicsQuality.LOW)
