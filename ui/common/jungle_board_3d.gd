# ui/common/jungle_board_3d.gd - Objek 3D low-poly papan kayu rimbun jungle bernuansa kelapa sawit (pelepah, tandan buah, sulur) sebagai latar teks UI.
class_name JungleBoard3D
extends Node3D

class MeshBuilder extends RefCounted:
	var verts: PackedVector3Array = PackedVector3Array()
	var norms: PackedVector3Array = PackedVector3Array()
	var cols: PackedColorArray = PackedColorArray()

	func tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
		var n: Vector3 = (b - a).cross(c - a)
		if n.length_squared() < 0.0000001:
			return
		n = n.normalized()
		verts.append_array(PackedVector3Array([a, b, c]))
		norms.append_array(PackedVector3Array([n, n, n]))
		cols.append_array(PackedColorArray([color, color, color]))

	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
		tri(a, b, c, color)
		tri(a, c, d, color)

	func box(center: Vector3, half: Vector3, color: Color, tilt: float = 0.0, shade_top: float = 0.14) -> void:
		var rot: Basis = Basis(Vector3.BACK, tilt)
		var p: Array[Vector3] = []
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					p.append(center + rot * Vector3(half.x * sx, half.y * sy, half.z * sz))
		var top: Color = color.lightened(shade_top)
		var side: Color = color.darkened(0.18)
		quad(p[5], p[7], p[3], p[1], color)
		quad(p[0], p[2], p[6], p[4], side)
		quad(p[2], p[3], p[7], p[6], top)
		quad(p[4], p[5], p[1], p[0], side)
		quad(p[1], p[3], p[2], p[0], side)
		quad(p[4], p[6], p[7], p[5], side)

	func sphere(center: Vector3, radius: float, color: Color, rings: int = 3, segments: int = 6) -> void:
		for r in range(rings):
			var a0: float = PI * float(r) / float(rings)
			var a1: float = PI * float(r + 1) / float(rings)
			for s in range(segments):
				var b0: float = TAU * float(s) / float(segments)
				var b1: float = TAU * float(s + 1) / float(segments)
				var p00: Vector3 = center + radius * Vector3(sin(a0) * cos(b0), cos(a0), sin(a0) * sin(b0))
				var p01: Vector3 = center + radius * Vector3(sin(a0) * cos(b1), cos(a0), sin(a0) * sin(b1))
				var p10: Vector3 = center + radius * Vector3(sin(a1) * cos(b0), cos(a1), sin(a1) * sin(b0))
				var p11: Vector3 = center + radius * Vector3(sin(a1) * cos(b1), cos(a1), sin(a1) * sin(b1))
				var shade: Color = color.lightened(0.18 * (cos((a0 + a1) * 0.5) * 0.5 + 0.5))
				tri(p00, p10, p11, shade)
				tri(p00, p11, p01, shade)

	func tube(points: PackedVector3Array, radius: float, color: Color, sides: int = 5) -> void:
		for i in range(points.size() - 1):
			var dir: Vector3 = (points[i + 1] - points[i]).normalized()
			var side: Vector3 = dir.cross(Vector3.BACK)
			if side.length_squared() < 0.001:
				side = Vector3.RIGHT
			side = side.normalized()
			var up: Vector3 = side.cross(dir).normalized()
			for k in range(sides):
				var a0: float = TAU * float(k) / float(sides)
				var a1: float = TAU * float(k + 1) / float(sides)
				var o0: Vector3 = (side * cos(a0) + up * sin(a0)) * radius
				var o1: Vector3 = (side * cos(a1) + up * sin(a1)) * radius
				var shade: Color = color.lightened(0.12 * sin(a0 + 0.8))
				quad(points[i] + o0, points[i + 1] + o0, points[i + 1] + o1, points[i] + o1, shade)

	func to_mesh() -> ArrayMesh:
		var arrays: Array = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = norms
		arrays[Mesh.ARRAY_COLOR] = cols
		var mesh: ArrayMesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return mesh

var board_size: Vector2 = Vector2(3.6, 1.2)
var bleed: float = 0.16
var limit: Vector2 = Vector2(1.8, 0.6)
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var wood: MeshBuilder = MeshBuilder.new()
var leaves: MeshBuilder = MeshBuilder.new()
var fruit: MeshBuilder = MeshBuilder.new()

func build(image_size: Vector2, bleed_units: float, seed_value: int, foliage_amount: float = 1.0) -> void:
	rng.seed = seed_value
	bleed = bleed_units
	board_size = image_size - Vector2(bleed, bleed) * 2.0
	limit = image_size * 0.5 - Vector2(0.012, 0.012)
	_build_planks()
	_build_frame()
	_build_ropes()
	_build_foliage(foliage_amount)
	_attach(wood, false)
	_attach(leaves, true)
	_attach(fruit, false)

func _attach(builder: MeshBuilder, double_sided: bool) -> void:
	if builder.verts.is_empty():
		return
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = builder.to_mesh()
	var material: StandardMaterial3D = StandardMaterial3D.new()
	if builder == wood:
		material = preload("res://assets/textures/field/timber.tres").duplicate()
		material.uv1_scale = Vector3(0.4, 0.65, 0.4)
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	if double_sided:
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	add_child(instance)

func _fit(v: Vector3) -> Vector3:
	return Vector3(clampf(v.x, -limit.x, limit.x), clampf(v.y, -limit.y, limit.y), v.z)

func _wood_color(base: Color, spread: float) -> Color:
	var shift: float = rng.randf_range(-spread, spread)
	return Color(clampf(base.r + shift, 0.0, 1.0), clampf(base.g + shift * 0.8, 0.0, 1.0), clampf(base.b + shift * 0.5, 0.0, 1.0))

func _build_planks() -> void:
	var half_w: float = board_size.x * 0.5
	var half_h: float = board_size.y * 0.5
	var plank_count: int = clampi(int(round(board_size.y / 0.34)), 2, 5)
	var plank_h: float = board_size.y / float(plank_count)
	wood.box(Vector3(0.0, 0.0, -0.03), Vector3(half_w, half_h, 0.03), Color(0.17, 0.10, 0.05), 0.0, 0.0)
	var thickness: float = 0.055
	for i in range(plank_count):
		var cy: float = -half_h + plank_h * (float(i) + 0.5)
		var inset_l: float = rng.randf_range(0.0, 0.05)
		var inset_r: float = rng.randf_range(0.0, 0.05)
		var width: float = board_size.x - inset_l - inset_r
		var cx: float = (inset_l - inset_r) * 0.5
		var color: Color = _wood_color(Color(0.68, 0.46, 0.24), 0.05)
		wood.box(Vector3(cx, cy, 0.0), Vector3(width * 0.5, plank_h * 0.5 - 0.008, thickness), color, rng.randf_range(-0.006, 0.006))
		var grain_lines: int = rng.randi_range(2, 3)
		for g in range(grain_lines):
			var gy: float = cy + rng.randf_range(-plank_h * 0.36, plank_h * 0.36)
			var gx0: float = cx - width * 0.5 + rng.randf_range(0.04, width * 0.3)
			var gx1: float = gx0 + rng.randf_range(width * 0.25, width * 0.6)
			var gc: Color = color.darkened(0.28)
			wood.quad(Vector3(gx0, gy, thickness + 0.003), Vector3(gx1, gy - 0.004, thickness + 0.003), Vector3(gx1, gy + 0.008, thickness + 0.003), Vector3(gx0, gy + 0.006, thickness + 0.003), gc)
		if rng.randf() < 0.7:
			var kx: float = cx + rng.randf_range(-width * 0.4, width * 0.4)
			var ky: float = cy + rng.randf_range(-plank_h * 0.25, plank_h * 0.25)
			wood.sphere(Vector3(kx, ky, thickness), 0.028, color.darkened(0.4), 2, 5)
		for side in [-1.0, 1.0]:
			wood.sphere(Vector3(cx + side * (width * 0.5 - 0.07), cy, thickness + 0.004), 0.017, Color(0.15, 0.13, 0.11), 2, 5)
	var moss_patches: int = int(clampf(board_size.x * 2.0, 3.0, 9.0))
	for m in range(moss_patches):
		var mx: float = rng.randf_range(-half_w, half_w)
		var top: bool = rng.randf() < 0.65
		var my: float = half_h - 0.01 if top else -half_h + rng.randf_range(0.0, 0.08)
		var mw: float = rng.randf_range(0.10, 0.3)
		var mh: float = rng.randf_range(0.04, 0.10)
		var moss: Color = Color(0.20, 0.42, 0.14).lightened(rng.randf_range(0.0, 0.16))
		wood.quad(Vector3(mx - mw, my, 0.062), Vector3(mx + mw, my, 0.062), Vector3(mx + mw * 0.6, my - mh, 0.064), Vector3(mx - mw * 0.6, my - mh, 0.064), moss)

func _build_frame() -> void:
	var half_w: float = board_size.x * 0.5
	var half_h: float = board_size.y * 0.5
	var log_color: Color = Color(0.34, 0.21, 0.11)
	for sy in [-1.0, 1.0]:
		var pts: PackedVector3Array = PackedVector3Array()
		for k in range(0, 9):
			var t: float = float(k) / 8.0
			pts.append(Vector3(lerpf(-half_w - 0.06, half_w + 0.06, t), sy * (half_h + 0.01) + sin(t * PI * 2.0) * 0.006, 0.07))
		wood.tube(pts, 0.052, log_color, 6)
	for sx in [-1.0, 1.0]:
		var pts: PackedVector3Array = PackedVector3Array()
		for k in range(0, 5):
			var t: float = float(k) / 4.0
			pts.append(Vector3(sx * (half_w - 0.02), lerpf(-half_h - 0.03, half_h + 0.03, t), 0.075))
		wood.tube(pts, 0.048, log_color.lightened(0.04), 6)

func _build_ropes() -> void:
	var half_w: float = board_size.x * 0.5
	var half_h: float = board_size.y * 0.5
	var rope: Color = Color(0.67, 0.55, 0.32)
	for sx in [-1.0, 1.0]:
		var pts: PackedVector3Array = PackedVector3Array()
		var base_x: float = sx * (half_w * 0.72)
		for k in range(0, 6):
			var t: float = float(k) / 5.0
			pts.append(Vector3(base_x + sin(t * 9.0) * 0.012, half_h + 0.02 + t * (bleed * 0.85), 0.09))
		wood.tube(pts, 0.014, rope, 4)
		wood.sphere(Vector3(base_x, half_h + 0.02, 0.095), 0.03, rope.darkened(0.15), 2, 6)

func _leaf_color(t: float, bias: float) -> Color:
	var dark: Color = Color(0.07, 0.25, 0.10)
	var light: Color = Color(0.34, 0.60, 0.16)
	return dark.lerp(light, clampf(t + bias, 0.0, 1.0))

func _frond(origin: Vector3, angle: float, length: float, droop: float, leaflets: int, leaflet_len: float) -> void:
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	var points: Array[Vector3] = []
	var steps: int = 12
	for k in range(steps + 1):
		var t: float = float(k) / float(steps)
		var p2: Vector2 = Vector2(origin.x, origin.y) + dir * length * t + Vector2(0.0, -1.0) * droop * length * t * t
		points.append(_fit(Vector3(p2.x, p2.y, origin.z + t * 0.05)))
	var rachis: PackedVector3Array = PackedVector3Array(points)
	leaves.tube(rachis, 0.011, Color(0.36, 0.40, 0.14), 4)
	for i in range(leaflets):
		var t: float = 0.12 + 0.88 * float(i) / float(maxi(1, leaflets - 1))
		var idx: float = t * float(steps)
		var lo: int = mini(int(floor(idx)), steps - 1)
		var frac: float = idx - float(lo)
		var p: Vector3 = points[lo].lerp(points[lo + 1], frac)
		var tangent: Vector3 = (points[lo + 1] - points[lo]).normalized()
		var normal: Vector3 = Vector3(-tangent.y, tangent.x, 0.0)
		var size_factor: float = sin(clampf(t, 0.05, 1.0) * PI) * 0.65 + 0.45
		for side in [-1.0, 1.0]:
			var out_dir: Vector3 = (tangent * 0.55 + normal * side * 1.0 + Vector3(0.0, -0.22, 0.12 * side)).normalized()
			var tip: Vector3 = p + out_dir * leaflet_len * size_factor
			tip.z += rng.randf_range(-0.03, 0.05)
			tip = _fit(tip)
			var half_base: Vector3 = tangent * 0.03
			var color: Color = _leaf_color(t, rng.randf_range(-0.08, 0.10))
			leaves.tri(p - half_base, p + half_base, tip, color)
			leaves.tri(p - half_base, tip, tip - tangent * 0.015 + Vector3(0, 0, 0.012), color.darkened(0.12))

func _fruit_bunch(center: Vector3, scale_value: float) -> void:
	var spikes: Color = Color(0.20, 0.10, 0.06)
	for k in range(15):
		var offset: Vector3 = Vector3(rng.randf_range(-0.07, 0.07), rng.randf_range(-0.08, 0.08), rng.randf_range(-0.02, 0.06)) * scale_value
		var red: float = rng.randf_range(0.0, 1.0)
		var color: Color = Color(0.92, 0.38, 0.06).lerp(Color(0.62, 0.10, 0.04), red)
		fruit.sphere(center + offset, 0.042 * scale_value, color, 2, 6)
	fruit.sphere(center + Vector3(0, 0, -0.01), 0.08 * scale_value, spikes, 2, 6)

func _vine(start: Vector3, end: Vector3, sag: float, leaf_count: int) -> void:
	var pts: PackedVector3Array = PackedVector3Array()
	var steps: int = 10
	for k in range(steps + 1):
		var t: float = float(k) / float(steps)
		var p: Vector3 = start.lerp(end, t)
		p.y -= sin(t * PI) * sag
		p.z += 0.03
		pts.append(p)
	leaves.tube(pts, 0.009, Color(0.18, 0.30, 0.10), 4)
	for i in range(leaf_count):
		var t: float = rng.randf_range(0.05, 0.95)
		var idx: int = clampi(int(t * float(steps)), 0, steps - 1)
		var p: Vector3 = pts[idx].lerp(pts[idx + 1], t * float(steps) - float(idx))
		var a: float = rng.randf_range(0.0, TAU)
		var r: float = rng.randf_range(0.04, 0.075)
		var tip: Vector3 = _fit(p + Vector3(cos(a) * r, sin(a) * r - 0.02, rng.randf_range(0.0, 0.04)))
		var side: Vector3 = Vector3(-sin(a), cos(a), 0.0) * r * 0.45
		var c: Color = _leaf_color(rng.randf(), 0.05)
		leaves.tri(p + side, p - side, tip, c)

func _build_foliage(amount: float) -> void:
	var half_w: float = board_size.x * 0.5
	var half_h: float = board_size.y * 0.5
	var big: float = clampf(board_size.y * 1.05, 0.65, 1.15) * amount
	var corners: Array = [
		{"pos": Vector3(-half_w + 0.02, half_h + 0.0, 0.09), "base": PI * 0.62, "spread": [-0.55, -0.05, 0.5, 0.95]},
		{"pos": Vector3(half_w - 0.02, half_h + 0.0, 0.09), "base": PI * 0.38, "spread": [0.55, 0.05, -0.5, -0.95]}
	]
	for corner in corners:
		for offset in corner["spread"]:
			var angle: float = float(corner["base"]) + float(offset) + rng.randf_range(-0.12, 0.12)
			_frond(corner["pos"], angle, big * rng.randf_range(0.85, 1.15), rng.randf_range(0.25, 0.6), 13, big * 0.36)
	var low_scale: float = big * 0.62
	_frond(Vector3(-half_w + 0.03, -half_h + 0.02, 0.1), PI * 1.15, low_scale, 0.15, 8, low_scale * 0.32)
	_frond(Vector3(-half_w + 0.03, -half_h + 0.02, 0.1), PI * 1.42, low_scale * 0.8, 0.1, 8, low_scale * 0.3)
	_frond(Vector3(half_w - 0.03, -half_h + 0.02, 0.1), -PI * 0.15, low_scale, 0.15, 8, low_scale * 0.32)
	_frond(Vector3(half_w - 0.03, -half_h + 0.02, 0.1), -PI * 0.42, low_scale * 0.8, 0.1, 8, low_scale * 0.3)
	_fruit_bunch(Vector3(half_w - 0.16, -half_h + 0.11, 0.12), clampf(board_size.y * 1.2, 1.0, 1.8))
	var vine_count: int = clampi(int(board_size.x * 1.4), 2, 6)
	for v in range(vine_count):
		var x0: float = rng.randf_range(-half_w * 0.8, half_w * 0.5)
		var x1: float = x0 + rng.randf_range(0.35, 0.75)
		_vine(Vector3(x0, half_h + 0.03, 0.1), Vector3(minf(x1, half_w * 0.9), half_h + 0.03, 0.1), rng.randf_range(0.06, 0.16), rng.randi_range(5, 9))
	_vine(Vector3(-half_w + 0.01, half_h, 0.11), Vector3(-half_w + 0.03, -half_h * 0.2, 0.11), 0.05, 6)
