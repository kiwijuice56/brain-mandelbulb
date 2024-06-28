class_name FractalNavigation
extends ColorRect

@onready var cam: Camera3D = get_node("Viewer/Camera3D")

func _process(_delta) -> void:
	material.set_shader_parameter("cam_pos", cam.global_position)
	material.set_shader_parameter("cam_mat", cam.global_transform.basis)
	material.set_shader_parameter("width", get_viewport().size.x)
	material.set_shader_parameter("height", get_viewport().size.y)
