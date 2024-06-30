@tool
class_name FractalNavigation extends ColorRect

@export var camera: Camera3D 

func _ready() -> void:
	GlobalData.settings_configuration.updated.connect(_on_settings_updated)
	_on_settings_updated()

func _on_settings_updated() -> void:
	match GlobalData.settings_configuration.graphics_quality:
		0:
			material.set_shader_parameter("max_iter", 64)
		1:
			material.set_shader_parameter("max_iter", 128)
		2:
			material.set_shader_parameter("max_iter", 256)

func _process(_delta) -> void:
	material.set_shader_parameter("_cam_pos", camera.global_position)
	material.set_shader_parameter("_cam_mat", camera.global_transform.basis)
	material.set_shader_parameter("_screen_size", size)
