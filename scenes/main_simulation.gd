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
var mission_director: MissionDirector
var weather_ambience: WeatherAmbience3D
var forest_audio: ForestAudioAmbience
var lightning_system: StormLightning3D
var cinematic_capture: CinematicCapture
var mission_telemetry: MissionTelemetry
var navigation_world_arrow: NavigationWorldArrow3D

func _ready() -> void:
	AudioManager.play_game_music()
	grid_simulator.initialize_level(GameState.current_level_index)
	simulation_view_3d.setup_view(grid_simulator)
	player.set_grid_simulator(grid_simulator)
	navigation_world_arrow = NavigationWorldArrow3D.new()
	navigation_world_arrow.name = "NavigationWorldArrow"
	navigation_world_arrow.initialize(player)
	player.add_child(navigation_world_arrow)

	var spawn_x: float = float(grid_simulator.grid_width / 2) * GameState.CELL_SIZE
	var spawn_z: float = 1.0 * GameState.CELL_SIZE
	player.set_spawn_position(Vector3(spawn_x, 0.25, spawn_z))

	weather_ambience = WeatherAmbience3D.new()
	weather_ambience.initialize(player, simulation_view_3d)
	simulation_view_3d.add_child(weather_ambience)

	forest_audio = ForestAudioAmbience.new()
	forest_audio.initialize(player, grid_simulator)
	add_child(forest_audio)

	lightning_system = StormLightning3D.new()
	lightning_system.initialize(weather_ambience, forest_audio, simulation_view_3d)
	add_child(lightning_system)

	hud.setup_hud(grid_simulator, player)
	planning_overlay.setup_planning(grid_simulator)
	pause_menu.set_resume_callback(func() -> void: player.activate_fps_camera())
	mission_director = MissionDirector.new()
	mission_director.initialize(grid_simulator, player)
	add_child(mission_director)

	cinematic_capture = CinematicCapture.new()
	cinematic_capture.initialize(player, hud, mission_director)
	add_child(cinematic_capture)

	mission_telemetry = MissionTelemetry.new()
	mission_telemetry.name = "MissionTelemetry"
	mission_telemetry.initialize(grid_simulator)
	add_child(mission_telemetry)

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
		ToolEnums.GamePhase.PAUSED, ToolEnums.GamePhase.VICTORY, ToolEnums.GamePhase.DEFEAT, ToolEnums.GamePhase.ABORTED:
			player.release_mouse_cursor()
