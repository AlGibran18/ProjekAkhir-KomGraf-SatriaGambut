# simulation/player/held_tools_3d.gd - Pengelola visual 3D alat di tangan pemain First-Person (Sekop, Nozzle Semprot, Tombak Gambut) dengan weapon sway, equip tween, dan animasi halus.
class_name HeldTools3D
extends Node3D

@onready var shovel_model: Node3D = $ShovelModel
@onready var nozzle_model: Node3D = $NozzleModel
@onready var peat_spear_model: Node3D = $PeatSpearModel
@onready var water_jet_particles: GPUParticles3D = $NozzleModel/WaterJetParticles

var base_position: Vector3 = Vector3(0.32, -0.28, -0.52)
var bob_time: float = 0.0
var action_swing: float = 0.0
var equip_offset_y: float = 0.0
var sway_target: Vector2 = Vector2.ZERO
var is_using_continuous: bool = false
var active_tool: ToolEnums.ToolType = ToolEnums.ToolType.SEMPROT_PERMUKAAN

func _ready() -> void:
	position = base_position
	EventBus.tool_selected.connect(_on_tool_selected)
	EventBus.graphics_quality_changed.connect(_on_quality_changed)
	_on_quality_changed(int(GameState.current_graphics_quality))
	EventBus.tool_action_performed.connect(_on_tool_action_performed)
	_on_tool_selected(GameState.current_tool)

func _on_quality_changed(quality: int) -> void:
	if water_jet_particles == null:
		return
	var ratios: Array[float] = [0.40, 0.75, 1.0]
	water_jet_particles.amount_ratio = ratios[clampi(quality, 0, 2)]

func apply_mouse_sway(relative: Vector2) -> void:
	sway_target.x = clampf(sway_target.x - relative.x * 0.0012, -0.045, 0.045)
	sway_target.y = clampf(sway_target.y + relative.y * 0.0012, -0.045, 0.045)

func set_movement_state(is_moving: bool, is_acting: bool) -> void:
	is_using_continuous = is_acting and GameState.current_water > 0.0
	if water_jet_particles != null:
		water_jet_particles.emitting = is_using_continuous and (active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN)

	if is_moving:
		bob_time += get_process_delta_time() * 9.0
	else:
		bob_time += get_process_delta_time() * 1.8

func _process(delta: float) -> void:
	action_swing = move_toward(action_swing, 0.0, delta * 4.5)
	equip_offset_y = lerpf(equip_offset_y, 0.0, clampf(delta * 10.0, 0.0, 1.0))
	sway_target = sway_target.lerp(Vector2.ZERO, clampf(delta * 10.0, 0.0, 1.0))

	var bob_x: float = cos(bob_time * 0.5) * 0.012
	var bob_y: float = absf(sin(bob_time)) * 0.014
	var action_offset: Vector3 = Vector3.ZERO
	var action_rot: Vector3 = Vector3.ZERO

	if active_tool == ToolEnums.ToolType.SEKAT_BAKAR and action_swing > 0.0:
		action_rot.x = -sin(action_swing * PI) * 0.72
		action_offset = Vector3(0.0, -0.05 * action_swing, -0.14 * action_swing)
	elif active_tool == ToolEnums.ToolType.TOMBAK_GAMBUT and is_using_continuous:
		var thrust: float = sin(Time.get_ticks_msec() * 0.025) * 0.035
		action_offset = Vector3(-0.08, -0.08 + thrust, -0.18)
		action_rot.x = -0.35
	elif active_tool == ToolEnums.ToolType.SEMPROT_PERMUKAAN and is_using_continuous:
		var pulse_z: float = sin(Time.get_ticks_msec() * 0.04) * 0.006
		action_offset = Vector3(0.0, 0.005, 0.02 + pulse_z)

	var target_pos: Vector3 = base_position + Vector3(bob_x + sway_target.x, bob_y + sway_target.y + equip_offset_y, 0.0) + action_offset
	var target_rot: Vector3 = Vector3(action_rot.x + (sway_target.y * 0.8), sway_target.x * 1.1, 0.0)

	position = position.lerp(target_pos, clampf(delta * 16.0, 0.0, 1.0))
	rotation = rotation.lerp(target_rot, clampf(delta * 16.0, 0.0, 1.0))

func _on_tool_selected(tool_type: ToolEnums.ToolType) -> void:
	active_tool = tool_type
	equip_offset_y = -0.22
	shovel_model.visible = (tool_type == ToolEnums.ToolType.SEKAT_BAKAR)
	nozzle_model.visible = (tool_type == ToolEnums.ToolType.SEMPROT_PERMUKAAN)
	peat_spear_model.visible = (tool_type == ToolEnums.ToolType.TOMBAK_GAMBUT)
	if water_jet_particles != null:
		water_jet_particles.emitting = false

func _on_tool_action_performed(tool_type: ToolEnums.ToolType, _pos: Vector2i) -> void:
	if tool_type == ToolEnums.ToolType.SEKAT_BAKAR:
		action_swing = 1.0
