# Satria Gambut

<p align="center">
  <img src="assets/textures/satria_gambut_logo.jpg" alt="Satria Gambut Logo" width="260" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Engine-Godot%204.7-478CBF?style=flat-square&logo=godotengine&logoColor=white" alt="Godot 4.7" />
  <img src="https://img.shields.io/badge/Language-GDScript-355570?style=flat-square" alt="GDScript" />
  <img src="https://img.shields.io/badge/Renderer-GL%20Compatibility-558B2F?style=flat-square" alt="GL Compatibility" />
  <img src="https://img.shields.io/badge/Platform-Windows%20Desktop-0078D6?style=flat-square" alt="Windows Desktop" />
  <img src="https://img.shields.io/badge/Mode-Offline%20Standalone-4E342E?style=flat-square" alt="Offline Standalone" />
</p>

## Overview

**Satria Gambut** is an interactive 3D first-person simulation of tropical peatland forest fire suppression, built with Godot Engine 4 as a Computer Graphics final project. It runs as a standalone, offline desktop application.

Unlike ordinary surface forest fires, tropical peatland fires burn both above ground and deep inside dry organic soil layers (0.8 m to 2.8 m deep). Putting out surface flames alone is not enough—subsurface smoldering embers can continue spreading underground and re-ignite to the surface if left untreated.

In this simulation, each `3.0 m × 3.0 m` cell across a `16 × 16` peatland grid tracks four hydrometeorological variables—**Water Table**, **Soil Moisture**, **Rainfall**, and **Air Temperature**—along with peat depth to compute a **Peat Fire Vulnerability Index (PFVI)** score (`0–320`) across four risk categories: *Rendah* (Low), *Sedang* (Medium), *Tinggi* (High), and *Ekstrem* (Extreme).

### Gameplay Flow

1. **Tactical Planning (PFVI Map):** Before entering the forest, inspect the 2D PFVI risk map and weather conditions, then place portable water wells near high-risk zones.
2. **First-Person Fire Suppression:** Enter the 3D peatland forest on foot to contain and extinguish surface flames and deep subsurface embers:
   - **Firebreak (`[1]`):** Dig containment trenches to stop fire from spreading downwind.
   - **Surface Water Spray (`[2]`):** Extinguish burning shrubs and surface flames.
   - **Thermal X-Ray Visor (`[Tab]`):** Reveal PFVI risk heatmaps and glowing underground embers hidden beneath smoky peat soil.
   - **Peat Injection Spear (`[3]`):** Hold left click to inject high-pressure water deep into the peat layer until underground embers are fully cooled.
   - **Water Refill:** Approach a placed blue water well (`<= 4.5 m`) to refill automatically or press `[E]` for an instant refill.
3. **Mission & Carbon Evaluation:** After all active hotspots are extinguished, review mission duration, saved forest area, water usage, and preserved carbon storage.

### Controls

| Input | Action |
| :--- | :--- |
| `W` `A` `S` `D` | Move |
| `Shift` | Sprint |
| `Space` | Jump |
| `Mouse` | Look around |
| `Left Click` (Click / Hold) | Use active tool |
| `1` / `2` / `3` | Switch tool (Firebreak / Surface Spray / Peat Spear) |
| `Tab` | Toggle Thermal X-Ray mode |
| `E` | Instant water refill when near a water well |
| `Esc` | Pause menu / release mouse cursor |

---

## Project Architecture

The project is organized by feature domain to separate simulation logic, 3D rendering, player input, and UI:

- **Call Down, Signal Up & Event Bus (`core/event_bus.gd`):** Systems communicate through typed global signals in `EventBus` rather than direct cross-scene references. The HUD, tool models, 3D view, and audio manager react independently to state events.
- **Model-View Separation (`simulation/model/` vs `simulation/view/`):**
  - `PeatCellData`, `PFVICalculator`, and `GridSimulator` execute cellular automata spread, moisture decay, and re-ignition logic purely in memory (`Dictionary[Vector2i, PeatCellData]`).
  - `SimulationView3D` renders ground tiles with a single `MultiMeshInstance3D` draw call, smoothly interpolates tile colors, manages 4-quadrant vegetation placement with trunk colliders, and spawns `CellHazardVFX` only on active hazard cells.
- **Hardware Compatibility (`core/game_state.gd`):** Configured to use `gl_compatibility` (OpenGL 3.3) with selectable quality presets (**Low**, **Medium**, **High**) and capped dynamic point lights so the simulation runs comfortably on both integrated-GPU laptops and gaming PCs.

### Directory Structure

```text
satria-gambut/
├── project.godot                   # Engine settings, autoloads, gl_compatibility renderer
├── core/
│   ├── event_bus.gd                # Global typed signal bus
│   ├── game_state.gd               # Level presets, weather, water reserves, quality settings
│   └── audio_manager.gd            # Offline WAV sound effect player pool
├── simulation/
│   ├── model/
│   │   ├── peat_cell_data.gd       # Per-cell hydrometeorology, depth, PFVI, and fire state
│   │   ├── pfvi_calculator.gd      # Static PFVI formula and risk color/label helpers
│   │   └── grid_simulator.gd       # Cellular automata fire spread and subsurface re-ignition
│   ├── player/
│   │   ├── player_controller_3d.gd # First-person CharacterBody3D controller and raycasting
│   │   └── held_tools_3d.gd        # First-person 3D shovel, spray nozzle, and peat spear
│   └── view/
│       └── simulation_view_3d.gd   # Ground MultiMesh, 4-quadrant forest, props, and fog
├── environment/
│   ├── props/                      # Water well and firebreak trench 3D scenes
│   └── vfx/                        # Fire, wind-tilted smoke, ember glow, and steam VFX
├── tools/
│   ├── tool_enums.gd               # Tool types, risk categories, and game phases
│   └── tool_manager.gd             # Hotkey handling for tools and thermal mode
├── ui/
│   ├── main_menu/                  # Start screen, scenario selector, guide, settings, credits
│   ├── planning/                   # Tactical 2D PFVI map and water well placement overlay
│   ├── hud/                        # Crosshair, injection bar, minimap, cell info, toolbar
│   ├── pause/                      # Pause menu with live graphics/audio controls
│   └── evaluation/                 # End-of-mission summary and carbon balance report
├── scenes/
│   └── main_simulation.gd          # Main level coordinator linking model, view, player, and UI
└── assets/
    ├── audio/                      # Synthesized offline WAV sound effects
    ├── models/                     # CC0 3D models (Quaternius & Kenney Nature Kit)
    └── textures/                   # Project logo
```

---

## Setup & Running the Project

### Prerequisites

- **Godot Engine 4.x** (Standard / GDScript edition; project configured on Godot `4.7.2`)
- **Git**

### Run in Godot Editor

1. Clone the repository:
   ```bash
   git clone https://github.com/AlGibran18/ProjekAkhir-KomGraf-SatriaGambut.git
   ```
2. Open **Godot Engine 4**, click **Import**, and select the `project.godot` file inside the cloned folder.
3. Click **Import & Edit** to let Godot import the `.gltf`, `.glb`, and `.wav` assets.
4. Press **`F5`** (or click the Play button) to start from `res://ui/main_menu/main_menu.tscn`.

### Export Standalone Desktop Build (`.exe`)

1. In Godot Editor, open **Project -> Export...** and add a **Windows Desktop** preset.
2. Download and install the matching Godot export templates if prompted (one-time setup).
3. Enable **Embed PCK** if you want a single self-contained `.exe`, then click **Export Project**.
4. The exported binary runs completely offline with no internet connection required.

---

## Credits & References

- **Scientific Reference:** Peat Fire Risk (`PeatFR` / `PFVI`) hydrometeorological modeling research by **ITB, University of Nottingham, and IPB** (Prof. Bagus Muljadi & Dr. Adilan Mahdiasa).
- **3D Nature Assets (CC0 1.0):**
  - *Stylized Nature MegaKit* by **Quaternius**
  - *Nature Kit* by **Kenney.nl**
- **Engine:** Godot Engine 4
