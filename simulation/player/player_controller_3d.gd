# simulation/player/player_controller_3d.gd - Kontroler First-Person (FPS) anti-jatuh dengan gerak akselerasi halus, head-bob, strafe-tilt, sprint FOV, weapon sway, dan raycast 7.5m.
class_name PlayerController3D
extends CharacterBody3D

@export var walk_speed: float = 5.2
@export var sprint_speed: float = 8.2
@export var jump_velocity: float = 4.4

@onready var head_node: Node3D = $Head
@onready var camera_node: Camera3D = $Head/Camera3D
@onready var interaction_ray: RayCast3D = $Head/InteractionRay
@onready var held_tools: HeldTools3D = $Head/Camera3D/HeldTools3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)
var grid_simulator: GridSimulator
var current_targeted_cell: Vector2i = Vector2i(-1, -1)
var safe_spawn_pos: Vector3 = Vector3(24.0, 0.25, 4.5)
var ground_plane: Plane = Plane(Vector3.UP, 0.0)
var was_near_well: bool = false
var head_bob_time: float = 0.0
var cinematic_mode_enabled: bool = false
var tactical_map_open: bool = false
var third_person_enabled: bool = false
var third_person_arm: SpringArm3D
var third_person_camera: Camera3D
var firefighter_avatar: FirefighterAvatar3D
var camera_hint_timer: float = 0.0

func _ready() -> void:
	floor_snap_length = 0.3
	_create_third_person_rig()

func set_grid_simulator(simulator: GridSimulator) -> void:
	grid_simulator = simulator

func set_spawn_position(pos: Vector3) -> void:
	safe_spawn_pos = pos
	global_position = pos
	velocity = Vector3.ZERO
	rotation.y = PI
	head_node.rotation.x = deg_to_rad(-12.0)

func activate_fps_camera() -> void:
	if third_person_enabled and third_person_camera != null:
		third_person_camera.current = true
	else:
		camera_node.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func release_mouse_cursor() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS or tactical_map_open:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = GameState.mouse_sensitivity
		rotate_y(-event.relative.x * sens)
		head_node.rotate_x(-event.relative.y * sens)
		head_node.rotation.x = clampf(head_node.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))
		if held_tools != null:
			held_tools.apply_mouse_sway(event.relative)

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			set_third_person(not third_person_enabled)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			release_mouse_cursor()
			if grid_simulator != null:
				grid_simulator.cancel_injection()
			GameState.set_game_phase(ToolEnums.GamePhase.PAUSED)
		elif event.keycode == KEY_E and was_near_well:
			if _refill_nearby_well(GameState.max_water_capacity) > 0.0:
				AudioManager.play_sfx("refill", -3.0)
				EventBus.educational_toast.emit("Air berhasil ditransfer dari sumur!", false)

	if not cinematic_mode_enabled and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif current_targeted_cell != Vector2i(-1, -1):
			EventBus.cell_clicked.emit(current_targeted_cell)

func _physics_process(delta: float) -> void:
	if tactical_map_open:
		if firefighter_avatar != null:
			firefighter_avatar.set_action_state(GameState.current_tool, false)
		if grid_simulator != null:
			grid_simulator.cancel_injection()
		if held_tools != null:
			held_tools.set_movement_state(false, false)
		return
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		if firefighter_avatar != null:
			firefighter_avatar.set_action_state(GameState.current_tool, false)
		if held_tools != null:
			held_tools.set_movement_state(false, false)
		return

	if global_position.y < -1.0:
		global_position = safe_spawn_pos
		velocity = Vector3.ZERO

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_key_pressed(KEY_SPACE) and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0

	var move_direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var is_moving: bool = move_direction.length_squared() > 0.0
	var is_sprinting: bool = is_moving and Input.is_key_pressed(KEY_SHIFT)
	var current_speed: float = sprint_speed if is_sprinting else walk_speed

	var target_vx: float = move_direction.x * current_speed
	var target_vz: float = move_direction.z * current_speed
	var accel_rate: float = 11.0 if is_moving else 9.0
	velocity.x = lerpf(velocity.x, target_vx, clampf(delta * accel_rate, 0.0, 1.0))
	velocity.z = lerpf(velocity.z, target_vz, clampf(delta * accel_rate, 0.0, 1.0))

	move_and_slide()
	_update_camera_feel(delta, input_dir, is_moving, is_sprinting)
	if firefighter_avatar != null:
		firefighter_avatar.animate_movement(delta, is_moving, is_sprinting)
	_update_raycast_targeting()
	_sync_visual_tool_target()
	_check_well_proximity(delta)

	var is_acting: bool = false
	if not cinematic_mode_enabled and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if GameState.current_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN or GameState.current_tool == ToolEnums.ToolType.TOMBAK_GAMBUT:
			if current_targeted_cell != Vector2i(-1, -1) and grid_simulator != null:
				grid_simulator.apply_continuous_tool(current_targeted_cell, GameState.current_tool, delta)
				is_acting = true
			elif grid_simulator != null:
				grid_simulator.cancel_injection()
	elif grid_simulator != null:
		grid_simulator.cancel_injection()

	if held_tools != null:
		held_tools.set_movement_state(is_moving, is_acting)
	if firefighter_avatar != null:
		firefighter_avatar.set_action_state(GameState.current_tool, is_acting)

func _update_camera_feel(delta: float, input_dir: Vector2, is_moving: bool, is_sprinting: bool) -> void:
	var target_head_y: float = 1.60
	if is_moving and is_on_floor():
		head_bob_time += delta * (11.5 if is_sprinting else 8.5)
		target_head_y += sin(head_bob_time) * (0.048 if is_sprinting else 0.030)
	head_node.position.y = lerpf(head_node.position.y, target_head_y, clampf(delta * 12.0, 0.0, 1.0))

	if camera_node != null:
		var target_roll: float = -input_dir.x * 0.022
		camera_node.rotation.z = lerpf(camera_node.rotation.z, target_roll, clampf(delta * 10.0, 0.0, 1.0))
		var target_fov: float = 79.0 if is_sprinting else 74.0
		camera_node.fov = lerpf(camera_node.fov, target_fov, clampf(delta * 8.0, 0.0, 1.0))

func _update_raycast_targeting() -> void:
	var has_hit: bool = false
	var hit_pos: Vector3 = Vector3.ZERO

	# Third person crosshair comes from the third-person camera, but action
	# range remains capped to the player's original 8 m tool reach.
	if third_person_enabled and third_person_camera != null:
		var viewport_center: Vector2 = get_viewport().get_visible_rect().size * 0.5
		var origin: Vector3 = third_person_camera.project_ray_origin(viewport_center)
		var direction: Vector3 = third_person_camera.project_ray_normal(viewport_center)
		var ray_hit: Variant = ground_plane.intersects_ray(origin, direction)
		if ray_hit != null:
			var candidate: Vector3 = ray_hit
			if global_position.distance_to(candidate) <= 8.0:
				hit_pos = candidate
				has_hit = true
	elif interaction_ray != null and interaction_ray.is_colliding():
		hit_pos = interaction_ray.get_collision_point()
		has_hit = true
	elif camera_node != null:
		var ray_origin: Vector3 = camera_node.global_position
		var ray_dir: Vector3 = -camera_node.global_transform.basis.z
		var plane_hit: Variant = ground_plane.intersects_ray(ray_origin, ray_dir)
		if plane_hit != null:
			var candidate: Vector3 = plane_hit
			if ray_origin.distance_to(candidate) <= 8.0:
				hit_pos = candidate
				has_hit = true

	if not has_hit:
		if current_targeted_cell != Vector2i(-1, -1):
			current_targeted_cell = Vector2i(-1, -1)
			EventBus.cell_hovered.emit(current_targeted_cell, null)
		return

	var cell_sz: float = GameState.CELL_SIZE
	var grid_x: int = int(round(hit_pos.x / cell_sz))
	var grid_y: int = int(round(hit_pos.z / cell_sz))
	var target_grid: Vector2i = Vector2i(grid_x, grid_y)

	if grid_simulator != null and grid_simulator.cells.has(target_grid):
		if target_grid != current_targeted_cell:
			current_targeted_cell = target_grid
			var cell_data: PeatCellData = grid_simulator.get_cell_data(target_grid)
			EventBus.cell_hovered.emit(target_grid, cell_data)
	else:
		if current_targeted_cell != Vector2i(-1, -1):
			current_targeted_cell = Vector2i(-1, -1)
			EventBus.cell_hovered.emit(current_targeted_cell, null)

# Both camera modes use the SAME grid cell chosen by gameplay targeting.
# Visuals never expand range or grant an action on another cell.
func _sync_visual_tool_target() -> void:
	var valid: bool = current_targeted_cell != Vector2i(-1, -1)
	var world_target: Vector3 = Vector3.ZERO
	if valid:
		world_target = Vector3(
			float(current_targeted_cell.x) * GameState.CELL_SIZE, 0.08,
			float(current_targeted_cell.y) * GameState.CELL_SIZE
		)
	if held_tools != null:
		held_tools.set_aim_target(world_target, valid)
	if firefighter_avatar != null:
		firefighter_avatar.set_aim_target(world_target, valid)

func _check_well_proximity(delta: float) -> void:
	var near_well: bool = false
	for well_pos in GameState.placed_wells:
		var world_well: Vector3 = Vector3(float(well_pos.x) * GameState.CELL_SIZE, global_position.y, float(well_pos.y) * GameState.CELL_SIZE)
		if global_position.distance_to(world_well) <= 4.5:
			near_well = true
			break

	if near_well != was_near_well:
		was_near_well = near_well
		EventBus.well_proximity_changed.emit(near_well)

	if near_well and GameState.current_water < GameState.max_water_capacity:
		if _refill_nearby_well(95.0 * delta) > 0.0:
			AudioManager.play_refill_throttled()

# Mengambil air hanya dari sumur yang berada dalam jangkauan dan masih berisi.
func _refill_nearby_well(requested: float) -> float:
	for well_pos in GameState.placed_wells:
		var location: Vector3 = Vector3(float(well_pos.x) * GameState.CELL_SIZE, global_position.y, float(well_pos.y) * GameState.CELL_SIZE)
		if global_position.distance_to(location) <= 4.5:
			var transferred: float = GameState.refill_from_well(well_pos, requested)
			if transferred > 0.0:
				return transferred
	return 0.0

# TPP has a spring-arm anti-clipping camera and a visual-only character rig.
# The original CharacterBody3D collider, gameplay tools and hotkeys remain unchanged.
func _create_third_person_rig() -> void:
	third_person_arm = SpringArm3D.new()
	third_person_arm.name = "ThirdPersonSpringArm"
	third_person_arm.spring_length = 4.3
	third_person_arm.margin = 0.18
	third_person_arm.collision_mask = 1
	third_person_arm.position = Vector3(0.48, -0.02, 0.0)
	head_node.add_child(third_person_arm)
	third_person_camera = Camera3D.new()
	third_person_camera.name = "ThirdPersonCamera"
	third_person_camera.fov = 73.0
	third_person_arm.add_child(third_person_camera)
	firefighter_avatar = FirefighterAvatar3D.new()
	firefighter_avatar.name = "VisibleFirefighter"
	add_child(firefighter_avatar)
	firefighter_avatar.visible = false
	firefighter_avatar.apply_outfit()

func set_third_person(enabled: bool) -> void:
	third_person_enabled = enabled
	if firefighter_avatar != null:
		firefighter_avatar.visible = enabled
	if held_tools != null:
		held_tools.visible = not enabled and not cinematic_mode_enabled
	if GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS:
		activate_fps_camera()
	EventBus.educational_toast.emit("KAMERA: TPP - di belakang karakter [V]" if enabled else "KAMERA: FPS - sudut pandang mata [V]", false)

func get_active_player_camera() -> Camera3D:
	return third_person_camera if third_person_enabled else camera_node
