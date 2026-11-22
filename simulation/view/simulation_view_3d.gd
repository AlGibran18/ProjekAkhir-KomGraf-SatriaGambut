# simulation/view/simulation_view_3d.gd - Pengelola visual 3D hutan gambut: terrain gambut, vegetasi Quaternius skala akurat, sumur air, parit sekat, VFX api/asap, batas perimeter, dan kabut dinamis.
class_name SimulationView3D
extends Node3D

@onready var multi_mesh_instance: MultiMeshInstance3D = $TerrainMultiMesh
@onready var cursor_highlight: MeshInstance3D = $CursorHighlight
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

var healthy_trees: Array[PackedScene] = [
	preload("res://assets/models/nature/glTF/CommonTree_1.gltf"),
	preload("res://assets/models/nature/glTF/CommonTree_2.gltf"),
	preload("res://assets/models/nature/glTF/Pine_1.gltf"),
	preload("res://assets/models/nature/glTF/Pine_2.gltf")
]
var dead_trees: Array[PackedScene] = [
	preload("res://assets/models/nature/glTF/DeadTree_1.gltf"),
	preload("res://assets/models/nature/glTF/DeadTree_2.gltf"),
	preload("res://assets/models/nature/glTF/DeadTree_3.gltf")
]
var fern_scene: PackedScene = preload("res://assets/models/nature/glTF/Fern_1.gltf")
var bush_scene: PackedScene = preload("res://assets/models/nature/glTF/Bush_Common.gltf")
var grass_scene: PackedScene = preload("res://assets/models/nature/glTF/Grass_Common_Tall.gltf")

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

func setup_view(simulator: GridSimulator) -> void:
	grid_simulator = simulator
	_clear_dynamic_containers()
	_init_ground_mesh(simulator.grid_width, simulator.grid_height)
	_init_perimeter_walls(simulator.grid_width, simulator.grid_height)
	_init_forest_vegetation(simulator.grid_width, simulator.grid_height)
	_init_border_forest(simulator.grid_width, simulator.grid_height)
	_refresh_all_visuals()

func activate_planning_camera() -> void:
	if planning_camera != null and grid_simulator != null:
		var cell_sz: float = GameState.CELL_SIZE
		var cx: float = float(grid_simulator.grid_width - 1) * cell_sz * 0.5
		var cz: float = float(grid_simulator.grid_height - 1) * cell_sz * 0.5
		planning_camera.global_position = Vector3(cx, 38.0, cz + 26.0)
		planning_camera.look_at(Vector3(cx, 0.0, cz), Vector3.UP)
		planning_camera.current = true

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

func _init_ground_mesh(width: int, height: int) -> void:
	var cell_sz: float = GameState.CELL_SIZE
	var total_count: int = width * height
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = total_count

	var box_mesh: BoxMesh = BoxMesh.new()
	box_mesh.size = Vector3(cell_sz * 0.98, 0.16, cell_sz * 0.98)

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.92
	box_mesh.material = mat
	mm.mesh = box_mesh

	var idx: int = 0
	for y in range(height):
		for x in range(width):
			var world_pos: Vector3 = Vector3(float(x) * cell_sz, -0.08, float(y) * cell_sz)
			var xform: Transform3D = Transform3D(Basis(), world_pos)
			mm.set_instance_transform(idx, xform)
			mm.set_instance_color(idx, Color(0.18, 0.13, 0.08))
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

	_add_wall_collider(Vector3(cx, 5.0, min_z - 0.5), Vector3(span_x, 12.0, 1.0))
	_add_wall_collider(Vector3(cx, 5.0, max_z + 0.5), Vector3(span_x, 12.0, 1.0))
	_add_wall_collider(Vector3(min_x - 0.5, 5.0, cz), Vector3(1.0, 12.0, span_z))
	_add_wall_collider(Vector3(max_x + 0.5, 5.0, cz), Vector3(1.0, 12.0, span_z))

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

			var in_spawn_clearing: bool = (x >= (width / 2) - 1 and x <= (width / 2) + 1 and y <= 2)
			if not in_spawn_clearing and rand_a > 0.30:
				var tree_idx: int = int(rand_b * float(healthy_trees.size())) % healthy_trees.size()
				var tree_instance: Node3D = healthy_trees[tree_idx].instantiate() as Node3D
				var tree_scale: float = 0.85 + (rand_a * 0.30)
				tree_instance.scale = Vector3(tree_scale, tree_scale, tree_scale)
				tree_instance.rotation.y = rand_b * TAU
				tree_instance.position = Vector3((rand_b - 0.5) * 1.4, 0.0, (rand_a - 0.5) * 1.4)
				tree_holder.add_child(tree_instance)

			var plant_holder: Node3D = Node3D.new()
			plant_holder.name = "PlantHolder"
			cell_holder.add_child(plant_holder)

			if rand_b > 0.25:
				var fern_inst: Node3D = fern_scene.instantiate() as Node3D
				var fern_scale: float = 0.14 + (rand_a * 0.06)
				fern_inst.scale = Vector3(fern_scale, fern_scale, fern_scale)
				fern_inst.position = Vector3((rand_a - 0.5) * 1.8, 0.0, (rand_b - 0.5) * 1.8)
				fern_inst.rotation.y = rand_a * TAU
				plant_holder.add_child(fern_inst)

			if rand_a > 0.40:
				var bush_inst: Node3D = bush_scene.instantiate() as Node3D
				var bush_scale: float = 0.55 + (rand_b * 0.20)
				bush_inst.scale = Vector3(bush_scale, bush_scale, bush_scale)
				bush_inst.position = Vector3((rand_b - 0.5) * 1.6, 0.0, (rand_a - 0.5) * 1.6)
				bush_inst.rotation.y = rand_b * TAU
				plant_holder.add_child(bush_inst)

			if rand_b > 0.15:
				var grass_inst: Node3D = grass_scene.instantiate() as Node3D
				var grass_scale: float = 0.45 + (rand_a * 0.20)
				grass_inst.scale = Vector3(grass_scale, grass_scale, grass_scale)
				grass_inst.position = Vector3((rand_a - 0.4) * 1.9, 0.0, (rand_b - 0.6) * 1.9)
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
				var s: float = 0.95 + (rand_val * 0.35)
				tree_inst.scale = Vector3(s, s, s)
				tree_inst.rotation.y = rand_val * TAU
				tree_inst.position = Vector3(float(x) * cell_sz, 0.0, float(y) * cell_sz)
				border_forest_container.add_child(tree_inst)

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
		cursor_highlight.visible = true
		var cell_sz: float = GameState.CELL_SIZE
		cursor_highlight.position = Vector3(float(pos.x) * cell_sz, 0.03, float(pos.y) * cell_sz)

func _on_well_placed(pos: Vector2i) -> void:
	if well_nodes.has(pos):
		return
	var well_inst: Node3D = water_well_scene.instantiate() as Node3D
	well_inst.position = Vector3(float(pos.x) * GameState.CELL_SIZE, 0.0, float(pos.y) * GameState.CELL_SIZE)
	props_container.add_child(well_inst)
	well_nodes[pos] = well_inst
	if cell_visual_nodes.has(pos):
		var holder: Node3D = cell_visual_nodes[pos]
		var tree_h: Node3D = holder.get_node_or_null("TreeHolder")
		if tree_h != null:
			tree_h.visible = false

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
			target_color = Color(0.90, 0.28, 0.05, 1.0)
		elif cell.has_ember():
			target_color = Color(0.16, 0.10, 0.07, 1.0)
		elif cell.is_firebreak:
			target_color = Color(0.24, 0.18, 0.12, 1.0)
		elif cell.is_burnt:
			target_color = Color(0.08, 0.07, 0.06, 1.0)
		else:
			var moisture_ratio: float = clampf(cell.soil_moisture / 0.65, 0.0, 1.0)
			var dry_peat: Color = Color(0.32, 0.22, 0.13)
			var moist_peat: Color = Color(0.14, 0.16, 0.09)
			target_color = dry_peat.lerp(moist_peat, moisture_ratio)

	multi_mesh_instance.multimesh.set_instance_color(index, target_color)

	if cell.is_firebreak and not trench_nodes.has(pos):
		var trench_inst: Node3D = firebreak_trench_scene.instantiate() as Node3D
		trench_inst.position = Vector3(float(pos.x) * GameState.CELL_SIZE, 0.0, float(pos.y) * GameState.CELL_SIZE)
		props_container.add_child(trench_inst)
		trench_nodes[pos] = trench_inst

	if cell_visual_nodes.has(pos):
		var cell_holder: Node3D = cell_visual_nodes[pos]
		var tree_holder: Node3D = cell_holder.get_node_or_null("TreeHolder")
		var plant_holder: Node3D = cell_holder.get_node_or_null("PlantHolder")

		if cell.is_firebreak or cell.has_well:
			if tree_holder != null:
				tree_holder.visible = false
			if plant_holder != null:
				plant_holder.visible = false
		else:
			if tree_holder != null:
				tree_holder.visible = true
				if cell.is_burning() or cell.is_burnt:
					if tree_holder.get_child_count() > 0:
						var first_tree: Node3D = tree_holder.get_child(0)
						if not first_tree.name.begins_with("DeadTree"):
							var old_rot: float = first_tree.rotation.y
							var old_pos: Vector3 = first_tree.position
							first_tree.queue_free()
							var dead_inst: Node3D = dead_trees[0].instantiate() as Node3D
							dead_inst.name = "DeadTree"
							dead_inst.rotation.y = old_rot
							dead_inst.position = old_pos
							dead_inst.scale = Vector3(0.80, 0.80, 0.80)
							tree_holder.add_child(dead_inst)
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
	var target_density: float = lerpf(0.010, 0.032, hazard_ratio)
	var clear_sky: Color = Color(0.58, 0.74, 0.86)
	var smoky_sky: Color = Color(0.66, 0.54, 0.42)
	var target_color: Color = clear_sky.lerp(smoky_sky, hazard_ratio)
	world_env.environment.fog_density = lerpf(world_env.environment.fog_density, target_density, delta * 1.5)
	world_env.environment.fog_light_color = world_env.environment.fog_light_color.lerp(target_color, delta * 1.5)
	world_env.environment.background_color = world_env.environment.background_color.lerp(target_color, delta * 1.5)

func _on_graphics_quality_changed(_quality: int) -> void:
	_apply_sun_quality()

func _apply_sun_quality() -> void:
	if sun_light != null:
		sun_light.shadow_enabled = (GameState.current_graphics_quality != GameState.GraphicsQuality.LOW)
