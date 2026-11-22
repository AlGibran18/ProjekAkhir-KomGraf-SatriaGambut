# simulation/player/held_tools_3d.gd - Pengelola visual 3D alat di tangan pemain First-Person (Sekop, Nozzle Semprot, Tombak Gambut), partikel air, dan animasi ayunan.
class_name HeldTools3D
extends Node3D

@onready var shovel_model: Node3D = $ShovelModel
@onready var nozzle_model: Node3D = $NozzleModel
@onready var peat_spear_model: Node3D = $PeatSpearModel
@onready var water_jet_particles: GPUParticles3D = $NozzleModel/WaterJetParticles

var base_position: Vector3 = Vector3(0.32, -0.28, -0.52)
var bob_time: float = 0.0
var action_swing: float = 0.0
var is_using_continuous: bool = false
var active_tool: ToolEnums.ToolType = ToolEnums.ToolType.SEMPROT_PERMUKAAN

func _ready() -> void:
	position = base_position
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.tool_action_performed.connect(_on_tool_action_performed)
	_on_tool_selected(GameState.current_tool)

func set_movement_state(is_moving: bool, is_acting: bool) -> void:
	is_using_continuous = is_acting and GameState.current_water > 0.0
	if water_jet_particles != null:
		water_jet_particles.emitting = is_using_continuous and (active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN)

	if is_moving:
		bob_time += get_process_delta_time() * 9.0
	else:
		bob_time += get_process_delta_time() * 1.8

func _process(delta: float) -> void:
	action_swing = move_toward(action_swing, 0.0, delta * 5.0)

	var bob_x: float = cos(bob_time * 0.5) * 0.012
	var bob_y: float = absf(sin(bob_time)) * 0.014
	var action_offset: Vector3 = Vector3.ZERO
	var action_rot_x: float = 0.0

	if active_tool == ToolEnums.ToolType.SEKAT_BAKAR and action_swing > 0.0:
		action_rot_x = -sin(action_swing * PI) * 0.75
		action_offset = Vector3(0.0, -0.05 * action_swing, -0.14 * action_swing)
	elif active_tool == ToolEnums.ToolType.TOMBAK_GAMBUT and is_using_continuous:
		var thrust: float = sin(Time.get_ticks_msec() * 0.025) * 0.04
		action_offset = Vector3(-0.08, -0.08 + thrust, -0.18)
		action_rot_x = -0.35
	elif active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN and is_using_continuous:
		action_offset = Vector3(randf_range(-0.005, 0.005), randf_range(-0.005, 0.005), 0.02)

	position = base_position + Vector3(bob_x, bob_y, 0.0) + action_offset
	rotation.x = lerpf(rotation.x, action_rot_x, delta * 14.0)

func _on_tool_selected(tool_type: ToolEnums.ToolType) -> void:
	active_tool = tool_type
	shovel_model.visible = (tool_type == ToolEnums.ToolType.SEKAT_BAKAR)
	nozzle_model.visible = (tool_type == ToolEnums.ToolType.SEMPROT_PERMUKAAN)
	peat_spear_model.visible = (tool_type == ToolEnums.ToolType.TOMBAK_GAMBUT)
	if water_jet_particles != null:
		water_jet_particles.emitting = false

func _on_tool_action_performed(tool_type: ToolEnums.ToolType, _pos: Vector2i) -> void:
	if tool_type == ToolEnums.ToolType.SEKAT_BAKAR:
		action_swing = 1.0
