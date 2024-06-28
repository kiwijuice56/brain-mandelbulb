class_name Viewer
extends Node3D

@export var mouse_sensitivity: float = 0.001
@export var move_speed: float = 5.0
@export var cam_rot_speed: float = 1.0

var velocity: Vector3

@onready var cam: Camera3D = get_node("Camera3D")

# Modified from:
# https://kidscancode.org/godot_recipes/3.x/g101/3d/101_3d_07/
func _physics_process(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var vertical_input_dir: float = Input.get_action_strength("move_up") - Input.get_action_strength("move_down")
	var cam_dir: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down").normalized()
	position += (input_dir.y * global_transform.basis.z + input_dir.x * global_transform.basis.x + 
	vertical_input_dir * global_transform.basis.y).normalized() * move_speed * delta
	rotate_y(-cam_dir.x * cam_rot_speed * delta)
	cam.rotate_x(-cam_dir.y * cam_rot_speed * delta)
	cam.rotation.x = clamp(cam.rotation.x, -1.2, 1.2)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		cam.rotate_x(-event.relative.y * mouse_sensitivity)
		cam.rotation.x = clamp(cam.rotation.x, -1.2, 1.2)
