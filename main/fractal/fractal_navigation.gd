@tool
class_name FractalNavigation extends ColorRect

@export var camera: Camera3D 

func _ready() -> void:
	GlobalData.settings_configuration.updated.connect(_on_settings_updated)
	_on_settings_updated()

func _on_settings_updated() -> void:
	match GlobalData.settings_configuration.graphics_quality:
		0:
			material.set_shader_parameter("bulb_iter", 5)
			material.set_shader_parameter("collision_threshold", 1.0e-2)
			material.set_shader_parameter("light_iter", 32)
			material.set_shader_parameter("max_iter", 96)
		1:
			material.set_shader_parameter("bulb_iter", 6)
			material.set_shader_parameter("collision_threshold", 1.0e-3)
			material.set_shader_parameter("light_iter", 48)
			material.set_shader_parameter("max_iter", 128)
		2:
			material.set_shader_parameter("bulb_iter", 8)
			material.set_shader_parameter("collision_threshold", 1.0e-4)
			material.set_shader_parameter("light_iter", 64)
			material.set_shader_parameter("max_iter", 512)

func _process(_delta) -> void:
	material.set_shader_parameter("_cam_pos", camera.global_position)
	material.set_shader_parameter("_cam_mat", camera.global_transform.basis)
	material.set_shader_parameter("_screen_size", size)
