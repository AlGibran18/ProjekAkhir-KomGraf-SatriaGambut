# simulation/view/camera_controller_3d.gd - Kontroler kamera isometrik 3D taktis (pan WASD, zoom scroll mouse, dan rotasi QE) untuk Satria Gambut.
class_name CameraController3D
extends Node3D

@export var move_speed: float = 16.0
@export var zoom_speed: float = 2.0
@export var min_zoom: float = 6.0
@export var max_zoom: float = 26.0

@onready var camera_node: Camera3D = $Camera3D

var current_zoom: float = 14.0

func _ready() -> void:
	if camera_node != null:
		camera_node.position.z = current_zoom

func _process(delta: float) -> void:
	var move_vec: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		move_vec -= transform.basis.z
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		move_vec += transform.basis.z
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		move_vec -= transform.basis.x
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		move_vec += transform.basis.x
	
	move_vec.y = 0.0
	if move_vec.length_squared() > 0.0:
		global_position += move_vec.normalized() * move_speed * delta

	if Input.is_key_pressed(KEY_Q):
		rotation.y += 1.5 * delta
	if Input.is_key_pressed(KEY_E):
		rotation.y -= 1.5 * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(zoom_speed)

func _apply_zoom(amount: float) -> void:
	current_zoom = clampf(current_zoom + amount, min_zoom, max_zoom)
	if camera_node != null:
		camera_node.position.z = current_zoom
