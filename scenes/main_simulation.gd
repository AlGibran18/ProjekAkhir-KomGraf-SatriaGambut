# scenes/main_simulation.gd - Pengendali scene simulasi utama Satria Gambut, mengorkestrasi transisi kamera sinematik Planning -> FPS -> Pause -> Evaluasi Misi.
class_name MainSimulation
extends Node3D

@onready var grid_simulator: GridSimulator = $GridSimulator
@onready var simulation_view_3d: SimulationView3D = $SimulationView3D
@onready var player: PlayerController3D = $PlayerController3D
@onready var tool_manager: ToolManager = $ToolManager
@onready var hud: HUD = $HUD
@onready var planning_overlay: PlanningOverlay = $UILayer/PlanningOverlay
@onready var pause_menu: PauseMenu = $UILayer/PauseMenu

var has_transitioned_from_planning: bool = false

func _ready() -> void:
	grid_simulator.initialize_level(GameState.current_level_index)
	simulation_view_3d.setup_view(grid_simulator)
	player.set_grid_simulator(grid_simulator)

	var spawn_x: float = float(grid_simulator.grid_width / 2) * GameState.CELL_SIZE
	var spawn_z: float = 1.0 * GameState.CELL_SIZE
	player.set_spawn_position(Vector3(spawn_x, 0.25, spawn_z))

	hud.setup_hud(grid_simulator, player)
	planning_overlay.setup_planning(grid_simulator)
	pause_menu.set_resume_callback(func() -> void: player.activate_fps_camera())

	EventBus.game_phase_changed.connect(_on_phase_changed)
	_on_phase_changed(GameState.current_phase)

func _on_phase_changed(new_phase: ToolEnums.GamePhase) -> void:
	match new_phase:
		ToolEnums.GamePhase.PLANNING:
			has_transitioned_from_planning = false
			simulation_view_3d.activate_planning_camera()
			player.release_mouse_cursor()
		ToolEnums.GamePhase.ACTIVE_FPS:
			if not has_transitioned_from_planning:
				has_transitioned_from_planning = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				simulation_view_3d.transition_to_fps_camera(player.camera_node, func() -> void:
					if GameState.current_phase == ToolEnums.GamePhase.ACTIVE_FPS:
						player.activate_fps_camera()
				)
			else:
				player.activate_fps_camera()
		ToolEnums.GamePhase.PAUSED, ToolEnums.GamePhase.VICTORY, ToolEnums.GamePhase.DEFEAT:
			player.release_mouse_cursor()
