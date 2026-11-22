# tools/tool_manager.gd - Pengelola pemilihan alat aktif pemadam dan pintasan keyboard taktis pada simulasi Satria Gambut.
class_name ToolManager
extends Node

func _unhandled_input(event: InputEvent) -> void:
	if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_select_tool(ToolEnums.ToolType.SEKAT_BAKAR)
			KEY_2:
				_select_tool(ToolEnums.ToolType.SEMPROT_PERMUKAAN)
			KEY_3:
				_select_tool(ToolEnums.ToolType.TOMBAK_GAMBUT)
			KEY_TAB:
				_toggle_thermal_mode()

func _select_tool(tool_type: ToolEnums.ToolType) -> void:
	GameState.current_tool = tool_type
	EventBus.tool_selected.emit(tool_type)

func _toggle_thermal_mode() -> void:
	GameState.is_thermal_active = not GameState.is_thermal_active
	EventBus.thermal_mode_toggled.emit(GameState.is_thermal_active)
