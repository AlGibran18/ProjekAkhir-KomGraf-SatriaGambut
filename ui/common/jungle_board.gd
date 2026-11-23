# ui/common/jungle_board.gd - Kontainer UI bertema papan kayu jungle sawit: merender objek 3D JungleBoard3D sekali ke tekstur lalu menjadikannya latar anak-anaknya.
class_name JungleBoard
extends MarginContainer

static var texture_cache: Dictionary = {}

@export var bleed: float = 30.0
@export var pad: Vector2 = Vector2(18.0, 10.0)
@export var foliage_amount: float = 1.0
@export var seed_key: int = 7

var board_texture: Texture2D
var rendered_key: String = ""
var render_pending: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("margin_left", int(bleed + pad.x))
	add_theme_constant_override("margin_right", int(bleed + pad.x))
	add_theme_constant_override("margin_top", int(bleed + pad.y))
	add_theme_constant_override("margin_bottom", int(bleed + pad.y))
	resized.connect(_schedule_render)
	_schedule_render()

func _draw() -> void:
	if board_texture != null:
		draw_texture_rect(board_texture, Rect2(Vector2.ZERO, size), false)

func _schedule_render() -> void:
	if render_pending:
		return
	render_pending = true
	get_tree().create_timer(0.08).timeout.connect(_render_board)

func _render_board() -> void:
	render_pending = false
	if not is_inside_tree() or size.x < 48.0 or size.y < 32.0:
		return
	var key: String = "%d_%d_%d_%d" % [int(size.x / 4.0), int(size.y / 4.0), seed_key, int(foliage_amount * 10.0)]
	if key == rendered_key:
		return
	if texture_cache.has(key):
		board_texture = texture_cache[key]
		rendered_key = key
		queue_redraw()
		return
	if DisplayServer.get_name() == "headless":
		return
	var scale_factor: float = 2.0
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(int(size.x * scale_factor), int(size.y * scale_factor))
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.handle_input_locally = false
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.58)
	env.ambient_light_energy = 0.9
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38.0, 24.0, 0.0)
	light.light_color = Color(1.0, 0.92, 0.78)
	light.light_energy = 1.6
	viewport.add_child(light)
	var units: Vector2 = size / 100.0
	var builder: JungleBoard3D = JungleBoard3D.new()
	builder.build(units, bleed / 100.0, seed_key * 7919 + int(size.x), foliage_amount)
	viewport.add_child(builder)
	var camera: Camera3D = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = units.y
	camera.position = Vector3(0.0, 0.0, 6.0)
	viewport.add_child(camera)
	camera.current = true
	add_child(viewport)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if not is_instance_valid(viewport):
		return
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null or image.is_empty():
		return
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	texture_cache[key] = texture
	board_texture = texture
	rendered_key = key
	queue_redraw()
