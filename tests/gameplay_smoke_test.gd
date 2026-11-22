# Godot headless functional smoke test.
# Run: godot --headless --path . --script res://tests/gameplay_smoke_test.gd
extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_execute")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _execute() -> void:
	var start_usec: int = Time.get_ticks_usec()
	for level in range(3):
		var sim: GridSimulator = GridSimulator.new()
		root.add_child(sim)
		sim.initialize_level(level)
		_assert(sim.cells.size() == 256, "level %d has 256 grid cells" % (level + 1))
		_assert(GameState.initial_carbon_tons > 0.0, "initial carbon available")
		sim.auto_place_recommended_wells()
		_assert(GameState.placed_wells.size() == GameState.max_wells_allowed, "well count on level %d" % (level + 1))
		var first_well: Vector2i = GameState.placed_wells[0]
		var original_reserve: float = float(GameState.well_reserves[first_well])
		GameState.current_water = 0.0
		var delivered: float = GameState.refill_from_well(first_well, 120.0)
		_assert(delivered > 0.0 and float(GameState.well_reserves[first_well]) < original_reserve, "finite well reserve")
		sim.start_outbreak()
		_assert(GameState.active_fire_cells >= 1, "initial outbreak on level %d" % (level + 1))
		var timing_start: int = Time.get_ticks_usec()
		for i in range(100):
			if GameState.current_phase != ToolEnums.GamePhase.ACTIVE_FPS:
				break
			sim._simulate_tick()
		print("BENCHMARK level %d, 100 ticks: %.2f ms" % [level + 1, float(Time.get_ticks_usec() - timing_start) / 1000.0])
		# Force a completed mission, verify score and victory state independently of random spread.
		GameState.set_game_phase(ToolEnums.GamePhase.ACTIVE_FPS)
		for cell in sim.cells.values():
			cell.surface_fire = 0.0
			cell.subsurface_ember = 0.0
		GameState.station_safe = true
		sim._update_stats()
		sim._check_mission_outcome()
		_assert(GameState.current_phase == ToolEnums.GamePhase.VICTORY, "victory when all hazards cleared")
		_assert(GameState.mission_score >= 0 and GameState.mission_score <= 100, "score in expected range")
		_assert(GameState.mission_medal in ["EMAS", "PERAK", "PERUNGGU"], "medal assigned")
		# Force station loss, verify defeat.
		GameState.set_game_phase(ToolEnums.GamePhase.ACTIVE_FPS)
		GameState.station_safe = false
		sim._check_mission_outcome()
		_assert(GameState.current_phase == ToolEnums.GamePhase.DEFEAT, "station loss triggers defeat")
		root.remove_child(sim)
		sim.free()
	print("Total elapsed: %.2f ms" % (float(Time.get_ticks_usec() - start_usec) / 1000.0))
	if failures > 0:
		printerr("Smoke tests failed: %d" % failures)
		quit(1)
	else:
		print("ALL SMOKE TESTS PASSED")
		quit(0)
